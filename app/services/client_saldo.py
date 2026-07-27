"""
Saldo disponible de crédito: límite (gntDirectorio) menos débitos pendientes (SP).
"""
from __future__ import annotations

from datetime import datetime
from decimal import Decimal
from typing import Any, Optional

from app.core import database
from app.core.config import get_settings
from app.services import order_erp

_TABLE_DIRECTORIO = "gntDirectorio"
_SP_DEBITO_PENDIENTE = "dbo.nctpDebitoPendienteDeCobroFvenc"

# Fechas por defecto del ejemplo de prueba del SP
_FECHA_INICIAL = datetime(2019, 11, 30)
_FECHA_FINAL = datetime(2026, 6, 30)


def _to_decimal(value: Any, default: Decimal = Decimal("0")) -> Decimal:
    if value is None:
        return default
    try:
        return Decimal(str(value))
    except Exception:
        return default


def _str_val(row: dict[str, Any], key: str) -> Optional[str]:
    val = row.get(key)
    if val is None:
        return None
    s = str(val).strip()
    return s or None


def _row_get(row: dict[str, Any], *keys: str) -> Any:
    lower_map = {str(k).lower(): v for k, v in row.items()}
    for key in keys:
        if key in row and row[key] is not None:
            return row[key]
        lk = key.lower()
        if lk in lower_map and lower_map[lk] is not None:
            return lower_map[lk]
    return None


async def fetch_cliente_limite_por_ruc(cliente_ruc: str) -> dict[str, Any]:
    """dirId, Monid y dirMontoLimite desde gntDirectorio por dirRuc."""
    ruc = cliente_ruc.strip()
    row = await database.fetch_one_dict(
        f"""
        SELECT TOP 1
            dirId AS dir_id,
            Monid AS mon_id,
            dirMontoLimite AS monto_limite
        FROM {_TABLE_DIRECTORIO}
        WHERE dirRuc = ?
        """,
        (ruc,),
    )
    if not row:
        raise ValueError("No existe cliente")

    dir_id = _str_val(row, "dir_id")
    if not dir_id:
        raise ValueError("No existe cliente")

    mon_id = (_str_val(row, "mon_id") or "").upper()
    monto_limite = _to_decimal(row.get("monto_limite"))
    return {
        "dir_id": dir_id,
        "mon_id": mon_id,
        "monto_limite": monto_limite,
        "cliente_ruc": ruc,
    }


async def monto_limite_en_dolares(
    mon_id: str,
    monto_limite: Decimal,
) -> tuple[Decimal, Optional[Decimal]]:
    """
    Si mon_id es BOL, convierte a DOL con tipo_cambio_ultimo (limite / tcaTC).
    Si no, deja el monto tal cual. Devuelve (limite_dol, tc_usado|None).
    """
    if mon_id != "BOL":
        return monto_limite, None

    tc = await order_erp.tipo_cambio_ultimo()
    if tc is None or tc <= 0:
        raise ValueError(
            "No se pudo obtener tipo de cambio para convertir el límite a dólares"
        )
    return monto_limite / tc, tc


async def debito_pendiente_monto_mp(dir_id: str) -> Decimal:
    """Suma MontoMp del SP nctpDebitoPendienteDeCobroFvenc; 0 si no hay filas."""
    emp_id = get_settings().mssql_database
    sql = f"""
        EXEC {_SP_DEBITO_PENDIENTE}
            ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?
    """
    params = (
        emp_id,
        _FECHA_INICIAL,
        _FECHA_FINAL,
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
    rows = await database.execute_proc_fetch_all_dict(sql, params)
    if not rows:
        return Decimal("0")

    total = Decimal("0")
    for row in rows:
        total += _to_decimal(_row_get(row, "MontoMp", "montomp", "MONTOMP"))
    return total


async def calcular_saldo_disponible(cliente_ruc: str) -> dict[str, Any]:
    """
    saldo = monto_limite_DOL - SUM(MontoMp débitos pendientes).
    Sin débitos: saldo = monto_limite_DOL.
    """
    cliente = await fetch_cliente_limite_por_ruc(cliente_ruc)
    limite_dol, tipo_cambio = await monto_limite_en_dolares(
        cliente["mon_id"],
        cliente["monto_limite"],
    )
    debito = await debito_pendiente_monto_mp(cliente["dir_id"])
    saldo = limite_dol - debito
    return {
        "status": "ok",
        "cliente_ruc": cliente["cliente_ruc"],
        "dir_id": cliente["dir_id"],
        "moneda_origen": cliente["mon_id"] or None,
        "monto_limite_origen": cliente["monto_limite"],
        "tipo_cambio": tipo_cambio,
        "monto_limite": limite_dol,
        "debito_pendiente": debito,
        "saldo": saldo,
    }
