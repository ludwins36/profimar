"""
Prueba local de INSERT de encabezado (vnttxn) sin levantar la API.

Por defecto solo inserta el encabezado (equivalente a POST /api/orders/encabezado).

Uso desde la raíz del proyecto:
    python scripts/test_crear_orden_completa.py
    python scripts/test_crear_orden_completa.py --solo-preparar
    python scripts/test_crear_orden_completa.py --completa
    python scripts/test_crear_orden_completa.py --json request.json

Requiere .env / variables de conexión SQL Server igual que la API.
"""
from __future__ import annotations

import argparse
import asyncio
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from fastapi import HTTPException

from app.api.routes import orders as orders_mod
from app.api.routes.orders import crear_orden_completa
from app.schemas.order_completa import OrdenCompletaCreate
from app.schemas.order_encabezado import OrdenEncabezadoCreate, filas_a_columnas_sql
from app.services import order_erp


def log(msg: str) -> None:
    print(msg, flush=True)


def cargar_encabezado(json_path: Path) -> OrdenEncabezadoCreate:
    raw = json.loads(json_path.read_text(encoding="utf-8"))
    if "encabezado" in raw:
        data = raw["encabezado"]
    else:
        data = raw
    return OrdenEncabezadoCreate(**data)


def cargar_orden_completa(json_path: Path) -> OrdenCompletaCreate:
    raw = json.loads(json_path.read_text(encoding="utf-8"))
    if "encabezado" not in raw:
        raise ValueError('Para --completa el JSON debe tener "encabezado" y "lineas"')
    if not raw.get("lineas"):
        raise ValueError('Para --completa el JSON debe incluir al menos una línea en "lineas"')
    return OrdenCompletaCreate(**raw)


async def mostrar_preparacion_encabezado(encabezado: OrdenEncabezadoCreate) -> None:
    log("\n=== PREPARACIÓN encabezado (antes del INSERT) ===")
    enc = await orders_mod._preparar_encabezado(encabezado)
    vnt_id = enc.model_dump(exclude_none=True).get("vnt_id")
    log(f"vnt_id generado: {vnt_id}")

    col, val = filas_a_columnas_sql(enc)
    col, val = order_erp.filtrar_columnas_identity(col, val)
    log(f"\nTabla {orders_mod._TABLE_ENCABEZADO}")
    for c, v in zip(col, val):
        log(f"  {c} = {v!r}")


async def insertar_solo_encabezado(encabezado: OrdenEncabezadoCreate, solo_preparar: bool) -> None:
    await mostrar_preparacion_encabezado(encabezado)

    if solo_preparar:
        log("\n(--solo-preparar: no se ejecutó INSERT en la BD)")
        return

    log("\n=== INSERT encabezado (_insert_encabezado) ===")
    row = await orders_mod._insert_encabezado(encabezado)
    log("\n=== OK ===")
    log(json.dumps({"status": "ok", "encabezado": row}, indent=2, default=str))


async def insertar_orden_completa(payload: OrdenCompletaCreate, solo_preparar: bool) -> None:
    await mostrar_preparacion_encabezado(payload.encabezado)

    if solo_preparar:
        log("\n(--solo-preparar: no se ejecutó INSERT en la BD)")
        return

    log("\n=== INSERT orden completa (crear_orden_completa) ===")
    resultado = await crear_orden_completa(payload)
    log("\n=== OK ===")
    log(json.dumps(resultado, indent=2, default=str))


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Prueba INSERT de pedido desde Python (default: solo encabezado)",
    )
    parser.add_argument(
        "--json",
        type=Path,
        default=ROOT / "request.json",
        help="Ruta al JSON de prueba (default: request.json en la raíz)",
    )
    parser.add_argument(
        "--solo-preparar",
        action="store_true",
        help="Solo muestra columnas/valores; no inserta en la BD",
    )
    parser.add_argument(
        "--completa",
        action="store_true",
        help="Inserta encabezado + líneas (crear_orden_completa)",
    )
    args = parser.parse_args()

    log(f"JSON: {args.json.resolve()}")
    log(f"Modo: {'orden completa' if args.completa else 'solo encabezado'}")

    if not args.json.is_file():
        log(f"ERROR: no existe {args.json}")
        return 1

    try:
        if args.completa:
            payload = cargar_orden_completa(args.json)
            coro = insertar_orden_completa(payload, args.solo_preparar)
        else:
            encabezado = cargar_encabezado(args.json)
            coro = insertar_solo_encabezado(encabezado, args.solo_preparar)
    except Exception as e:
        log(f"ERROR al parsear JSON / schema: {e}")
        return 1

    try:
        asyncio.run(coro)
    except HTTPException as e:
        log(f"\n=== FALLO HTTP {e.status_code} ===")
        if isinstance(e.detail, dict):
            log(json.dumps(e.detail, indent=2, default=str))
        else:
            log(str(e.detail))
        return 1
    except Exception as e:
        log(f"\n=== ERROR ===\n{e}")
        return 1

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
