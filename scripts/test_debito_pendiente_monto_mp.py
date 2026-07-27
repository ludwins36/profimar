"""
Prueba local de execute_proc_fetch_all_dict + extracción del total MontoMp.

Verifica el paso 3 de calcular_saldo_disponible (debito_pendiente_monto_mp):
  - EXEC dbo.nctpDebitoPendienteDeCobroFvenc
  - suma correcta de la columna MontoMp

Uso desde la raíz del proyecto (con el venv activado):
    .venv\\Scripts\\python.exe scripts/test_debito_pendiente_monto_mp.py --ruc 3176869
    .venv\\Scripts\\python.exe scripts/test_debito_pendiente_monto_mp.py --ruc 3176869 --completo

Requiere .env / variables de conexión SQL Server igual que la API.
"""
from __future__ import annotations

import argparse
import asyncio
import json
import sys
from decimal import Decimal
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from app.core import database
from app.core.config import get_settings
from app.services import client_saldo, order_erp


def log(msg: str) -> None:
    print(msg, flush=True)


def _to_decimal(value: object, default: Decimal = Decimal("0")) -> Decimal:
    if value is None:
        return default
    try:
        return Decimal(str(value))
    except Exception:
        return default


def _row_get(row: dict, *keys: str) -> object:
    lower_map = {str(k).lower(): v for k, v in row.items()}
    for key in keys:
        if key in row and row[key] is not None:
            return row[key]
        lk = key.lower()
        if lk in lower_map and lower_map[lk] is not None:
            return lower_map[lk]
    return None


async def resolver_dir_id(cliente_ruc: str) -> tuple[str, dict]:
    log("\n=== 1) Resolver cliente por RUC (gntDirectorio) ===")
    cliente = await client_saldo.fetch_cliente_limite_por_ruc(cliente_ruc)
    log(json.dumps(cliente, indent=2, default=str))
    return str(cliente["dir_id"]), cliente


async def probar_execute_proc(dir_id: str) -> tuple[list[dict], Decimal]:
    """Verifica execute_proc_fetch_all_dict y la suma de MontoMp."""
    emp_id = get_settings().mssql_database
    sql = f"""
        EXEC {client_saldo._SP_DEBITO_PENDIENTE}
            ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?
    """
    params = (
        emp_id,
        client_saldo._FECHA_INICIAL,
        client_saldo._FECHA_FINAL,
        "*",
        dir_id,
        "*",
        "A",
        "DOL",
        "*",
        "*",
        "S",
        "*",
        "*",
    )

    log("\n=== 2) EXEC nctpDebitoPendienteDeCobroFvenc ===")
    log(f"strEmpId = {emp_id!r}")
    log(f"strCtaCte = {dir_id!r}")
    log(
        f"fechas = {client_saldo._FECHA_INICIAL.date()} → "
        f"{client_saldo._FECHA_FINAL.date()}"
    )
    log(f"sql = {sql.strip()}")

    # Diagnóstico: todos los result sets (PRINT/USE suelen dejar el primero vacío)
    def _dump_all_sets() -> list[list[dict]]:
        with database.get_sync_connection() as conn:
            cursor = conn.cursor()
            cursor.execute(sql, params)
            return database._collect_cursor_result_sets(cursor)

    all_sets = await database.run_in_thread(_dump_all_sets)
    log(f"\nResult sets totales: {len(all_sets)}")
    for i, rs in enumerate(all_sets):
        extra = f" columnas={list(rs[0].keys())}" if rs else ""
        log(f"  set[{i}]: {len(rs)} filas{extra}")

    rows = await database.execute_proc_fetch_all_dict(sql, params)

    log(f"\nFilas devueltas por execute_proc_fetch_all_dict: {len(rows)}")
    if rows:
        log(f"Columnas: {list(rows[0].keys())}")
        log("Primeras filas:")
        log(json.dumps(rows[:5], indent=2, default=str))

    total = Decimal("0")
    for row in rows:
        mp = _row_get(row, "MontoMp", "montomp", "MONTOMP")
        total += _to_decimal(mp)
        log(f"  MontoMp = {mp!r}  →  acumulado = {total}")

    log(f"\n=== TOTAL MontoMp = {total} ===")
    return rows, total


async def probar_funcion_servicio(dir_id: str) -> Decimal:
    log("\n=== 3) client_saldo.debito_pendiente_monto_mp(dir_id) ===")
    total = await client_saldo.debito_pendiente_monto_mp(dir_id)
    log(f"total = {total}")
    return total


async def probar_completo(cliente_ruc: str) -> None:
    log("\n=== 4) client_saldo.calcular_saldo_disponible (flujo completo) ===")
    resultado = await client_saldo.calcular_saldo_disponible(cliente_ruc)
    log(json.dumps(resultado, indent=2, default=str))


async def resolver_dir_id(cliente_ruc: str) -> tuple[str, dict]:
    log("\n=== 1) Resolver cliente por RUC (gntDirectorio) ===")
    cliente = await client_saldo.fetch_cliente_limite_por_ruc(cliente_ruc)
    log(json.dumps(cliente, indent=2, default=str))
    return str(cliente["dir_id"]), cliente


async def run(cliente_ruc: str, completo: bool) -> None:
    settings = get_settings()
    log(f"BD: {settings.mssql_database} @ {settings.mssql_server}")
    log(f"RUC: {cliente_ruc}")

    dir_id, cliente = await resolver_dir_id(cliente_ruc)
    _rows, total_manual = await probar_execute_proc(dir_id)
    total_servicio = await probar_funcion_servicio(dir_id)

    if total_manual != total_servicio:
        raise AssertionError(
            f"Totales no coinciden: manual={total_manual} vs servicio={total_servicio}"
        )
    log("\n✓ Totales coinciden (execute_proc_fetch_all_dict + extracción MontoMp OK)")

    if completo:
        await probar_completo(cliente_ruc)
        esperado = cliente["monto_limite"]
        if (cliente["mon_id"] or "").upper() == "BOL":
            tc = await order_erp.tipo_cambio_ultimo()
            if tc and tc > 0:
                esperado = esperado / tc
        esperado = esperado - total_manual
        log(f"\nSaldo esperado (manual): {esperado}")


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Prueba execute_proc_fetch_all_dict + suma MontoMp",
    )
    parser.add_argument(
        "--ruc",
        default="3176869",
        help="RUC del cliente (default: 3176869)",
    )
    parser.add_argument(
        "--completo",
        action="store_true",
        help="También ejecuta calcular_saldo_disponible (flujo completo)",
    )
    args = parser.parse_args()

    try:
        asyncio.run(run(args.ruc, args.completo))
    except ValueError as e:
        log(f"\n=== FALLO (ValueError) ===\n{e}")
        return 1
    except AssertionError as e:
        log(f"\n=== ASSERTION ===\n{e}")
        return 1
    except Exception as e:
        log(f"\n=== ERROR ===\n{e}")
        return 1

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
