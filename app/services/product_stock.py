"""
Existencia para catálogo: intExistencia por almacén y vmaExitencia (regla de aprobación VEN).
"""
from __future__ import annotations

from decimal import Decimal
from typing import Any, Optional

from app.core import database

_ART_TIPO_INVENTARIABLE = "I"


def _to_decimal(value: Any, default: Decimal = Decimal("0")) -> Decimal:
    if value is None:
        return default
    try:
        return Decimal(str(value))
    except Exception:
        return default


async def existencia_venta(
    *,
    pve_id: str,
    alm_id: str,
    art_id: str,
    uni_id: str | None,
    art_tipo: str | None,
    existencia_almacen: Decimal,
) -> Decimal:
    """
    Stock usable al aprobar un pedido VEN.
    artTipo I → dbo.vmaExitencia; otros tipos → exiExistencia del almacén.
    """
    tipo = (art_tipo or "").strip().upper()
    if tipo == _ART_TIPO_INVENTARIABLE:
        disp = await database.execute_vma_existencia(
            pve_id.strip(),
            alm_id.strip(),
            art_id.strip(),
            (uni_id or "").strip(),
        )
        return disp if disp is not None else Decimal("0")
    return existencia_almacen


async def enriquecer_filas_existencia_venta(
    rows: list[dict[str, Any]],
    *,
    pve_id: Optional[str],
    alm_id: Optional[str],
) -> list[dict[str, Any]]:
    if not (pve_id and alm_id):
        return rows
    out: list[dict[str, Any]] = []
    for row in rows:
        row = dict(row)
        row["existencia_venta"] = await existencia_venta(
            pve_id=pve_id,
            alm_id=alm_id,
            art_id=str(row["artId"]),
            uni_id=str(row.get("uniid") or "").strip() or None,
            art_tipo=str(row.get("artTipo") or ""),
            existencia_almacen=_to_decimal(row.get("existencia_almacen")),
        )
        out.append(row)
    return out
