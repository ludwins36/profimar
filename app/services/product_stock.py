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
    alm_ids: Optional[list[str]] = None,
) -> list[dict[str, Any]]:
    """
    Completa existencia_venta.
    Un alm_id: misma regla que vmaApruebaTxn.
    Varios almacenes del PVE: artTipo I usa el máximo de vmaExitencia (una línea no se parte);
    otros tipos usan la suma de exiExistencia ya calculada.
    """
    if not pve_id:
        return rows
    destinos = [alm_id.strip()] if alm_id and alm_id.strip() else list(alm_ids or [])
    destinos = [a for a in destinos if a]
    if not destinos:
        return rows
    out: list[dict[str, Any]] = []
    for row in rows:
        row = dict(row)
        art_id = str(row["artId"])
        uni_id = str(row.get("uniid") or "").strip() or None
        art_tipo = str(row.get("artTipo") or "")
        exi_alm = _to_decimal(row.get("existencia_almacen"))
        if len(destinos) == 1:
            row["existencia_venta"] = await existencia_venta(
                pve_id=pve_id,
                alm_id=destinos[0],
                art_id=art_id,
                uni_id=uni_id,
                art_tipo=art_tipo,
                existencia_almacen=exi_alm,
            )
        elif (art_tipo or "").strip().upper() != _ART_TIPO_INVENTARIABLE:
            row["existencia_venta"] = exi_alm
        else:
            mejor = Decimal("0")
            for aid in destinos:
                disp = await existencia_venta(
                    pve_id=pve_id,
                    alm_id=aid,
                    art_id=art_id,
                    uni_id=uni_id,
                    art_tipo=art_tipo,
                    existencia_almacen=Decimal("0"),
                )
                if disp > mejor:
                    mejor = disp
            row["existencia_venta"] = mejor
        out.append(row)
    return out
