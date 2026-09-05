"""
Precio por cantidad desde vntListaPrecioCantidad (primer tramo = menor cantInicial).
"""
from __future__ import annotations

from decimal import Decimal
from typing import Any, Optional

from app.core import database

_TABLE = "vntListaPrecioCantidad"


def _to_decimal(value: Any) -> Optional[Decimal]:
    if value is None:
        return None
    try:
        return Decimal(str(value))
    except Exception:
        return None


async def primer_tramo_por_articulos(
    art_ids: list[str],
    lpr_id: str,
) -> dict[str, dict[str, Optional[Decimal]]]:
    """
    Por cada artId, el tramo con menor cantInicial de la lista lpr_id.
    Retorna { art_id: { precio_cantidad, cantidad_minima } }.
    """
    ids = [a.strip() for a in art_ids if a and str(a).strip()]
    lpr = (lpr_id or "").strip()
    if not ids or not lpr:
        return {}

    placeholders = ",".join("?" for _ in ids)
    rows = await database.fetch_all_dict(
        f"""
        SELECT artId, cantInicial, cantPrecio
        FROM (
            SELECT
                artId,
                cantInicial,
                cantPrecio,
                ROW_NUMBER() OVER (
                    PARTITION BY artId
                    ORDER BY cantInicial, cantId
                ) AS rn
            FROM {_TABLE}
            WHERE lprid = ?
              AND artId IN ({placeholders})
        ) AS t
        WHERE rn = 1
        """,
        tuple([lpr] + ids),
    )
    out: dict[str, dict[str, Optional[Decimal]]] = {}
    for row in rows or []:
        art_id = str(row.get("artId") or "").strip()
        if not art_id:
            continue
        out[art_id] = {
            "precio_cantidad": _to_decimal(row.get("cantPrecio")),
            "cantidad_minima": _to_decimal(row.get("cantInicial")),
        }
    return out
