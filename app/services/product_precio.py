"""
Precio por cantidad desde vntListaPrecioCantidad.
"""
from __future__ import annotations

from decimal import Decimal
from typing import Any, Optional

from app.core import database

_TABLE = "vntListaPrecioCantidad"
_COLS = "cantId, lprid, artId, cantInicial, cantFinal, cantPrecio, monid, horid"


def _to_decimal(value: Any, default: Optional[Decimal] = None) -> Optional[Decimal]:
    if value is None:
        return default
    try:
        return Decimal(str(value))
    except Exception:
        return default


def _row_to_tramo(row: dict[str, Any]) -> dict[str, Any]:
    return {
        "cant_id": int(row["cantId"]),
        "lpr_id": str(row["lprid"]).strip() if row.get("lprid") is not None else "",
        "art_id": str(row["artId"]).strip() if row.get("artId") is not None else "",
        "cant_inicial": _to_decimal(row.get("cantInicial"), Decimal("0")) or Decimal("0"),
        "cant_final": _to_decimal(row.get("cantFinal"), Decimal("0")) or Decimal("0"),
        "cant_precio": _to_decimal(row.get("cantPrecio"), Decimal("0")) or Decimal("0"),
        "mon_id": str(row["monid"]).strip() if row.get("monid") is not None else None,
        "hor_id": str(row["horid"]).strip() if row.get("horid") is not None else None,
    }


async def tramos_por_articulos(
    art_ids: list[str],
    lpr_id: str,
) -> dict[str, list[dict[str, Any]]]:
    """
    Todos los tramos de vntListaPrecioCantidad por artId para una lista lpr_id.
    Retorna { art_id: [ tramo, ... ] } ordenados por cantInicial.
    """
    ids = [a.strip() for a in art_ids if a and str(a).strip()]
    lpr = (lpr_id or "").strip()
    if not ids or not lpr:
        return {}

    placeholders = ",".join("?" for _ in ids)
    rows = await database.fetch_all_dict(
        f"""
        SELECT {_COLS}
        FROM {_TABLE}
        WHERE lprid = ?
          AND artId IN ({placeholders})
        ORDER BY artId, cantInicial, cantId
        """,
        tuple([lpr] + ids),
    )
    out: dict[str, list[dict[str, Any]]] = {aid: [] for aid in ids}
    for row in rows or []:
        art_id = str(row.get("artId") or "").strip()
        if not art_id:
            continue
        out.setdefault(art_id, []).append(_row_to_tramo(row))
    return out
