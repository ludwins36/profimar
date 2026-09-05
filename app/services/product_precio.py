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


def _row_get(row: dict[str, Any], *keys: str) -> Any:
    lower = {str(k).lower(): v for k, v in row.items()}
    for key in keys:
        if key in row and row[key] is not None:
            return row[key]
        lk = key.lower()
        if lk in lower and lower[lk] is not None:
            return lower[lk]
    return None


def _row_to_tramo(row: dict[str, Any]) -> dict[str, Any]:
    mon = _row_get(row, "monid", "monId")
    hor = _row_get(row, "horid", "horId")
    return {
        "cant_id": int(_row_get(row, "cantId") or 0),
        "lpr_id": str(_row_get(row, "lprid", "lprId") or "").strip(),
        "art_id": str(_row_get(row, "artId") or "").strip(),
        "cant_inicial": _to_decimal(_row_get(row, "cantInicial"), Decimal("0")) or Decimal("0"),
        "cant_final": _to_decimal(_row_get(row, "cantFinal"), Decimal("0")) or Decimal("0"),
        "cant_precio": _to_decimal(_row_get(row, "cantPrecio"), Decimal("0")) or Decimal("0"),
        "mon_id": str(mon).strip() if mon is not None else None,
        "hor_id": str(hor).strip() if hor is not None else None,
    }


async def tramos_por_articulos(
    art_ids: list[str],
    lpr_id: Optional[str] = None,
) -> dict[str, list[dict[str, Any]]]:
    """
    Tramos de vntListaPrecioCantidad por artId.
    Si lpr_id viene, filtra esa lista; si no, trae todos los tramos del artículo.
    """
    ids = [a.strip() for a in art_ids if a and str(a).strip()]
    if not ids:
        return {}

    placeholders = ",".join("?" for _ in ids)
    params: list[Any] = list(ids)
    lpr_filter = ""
    lpr = (lpr_id or "").strip()
    if lpr:
        lpr_filter = "AND LTRIM(RTRIM(lprid)) = ?"
        params.append(lpr)

    rows = await database.fetch_all_dict(
        f"""
        SELECT {_COLS}
        FROM {_TABLE}
        WHERE LTRIM(RTRIM(artId)) IN ({placeholders})
        {lpr_filter}
        ORDER BY artId, lprid, cantInicial, cantId
        """,
        tuple(params),
    )
    out: dict[str, list[dict[str, Any]]] = {aid: [] for aid in ids}
    for row in rows or []:
        art_id = str(_row_get(row, "artId") or "").strip()
        if not art_id:
            continue
        out.setdefault(art_id, []).append(_row_to_tramo(row))
    return out
