"""
Puntos de venta y almacenes vinculados (para armar pedido_almacen + pve_id coherentes).
"""
from typing import Optional

from fastapi import APIRouter, HTTPException, Query

from app.schemas.punto_venta import (
    AlmacenListResponse,
    AlmacenResponse,
    PuntoVentaListResponse,
    PuntoVentaResponse,
)
from app.services import pve_almacen

router_puntos_venta = APIRouter(prefix="/puntos-venta", tags=["PVE y almacenes"])
router_almacenes = APIRouter(prefix="/almacenes", tags=["PVE y almacenes"])


def _db_error(exc: Exception) -> HTTPException:
    return HTTPException(
        status_code=503,
        detail=f"Error al conectar con la base de datos: {exc!s}",
    )


@router_puntos_venta.get("", response_model=PuntoVentaListResponse)
async def listar_puntos_venta(
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=1000),
    sucursal_id: Optional[str] = Query(None, description="Filtrar por sucId"),
    alm_id: Optional[str] = Query(
        None,
        description="Solo PVE que pueden usar este almacén (pedido_almacen)",
    ),
    solo_habilitados: bool = Query(
        False,
        description="Solo PVE con pveHabilitado = S",
    ),
) -> PuntoVentaListResponse:
    """
    Lista puntos de venta con sus almacenes permitidos.

    Use `alm_id` para saber qué `pve_id` puede despachar desde un almacén concreto.
    """
    try:
        items, total = await pve_almacen.listar_puntos_venta(
            sucursal_id=sucursal_id,
            alm_id=alm_id,
            solo_habilitados=solo_habilitados,
            skip=skip,
            limit=limit,
        )
    except Exception as e:
        raise _db_error(e) from e
    return PuntoVentaListResponse(
        items=[PuntoVentaResponse(**item) for item in items],
        total=total,
    )


@router_puntos_venta.get("/{pve_id}", response_model=PuntoVentaResponse)
async def obtener_punto_venta(pve_id: str) -> PuntoVentaResponse:
    """Detalle de un PVE y almacenes que usa vmaExitencia al aprobar VEN."""
    if not pve_id.strip():
        raise HTTPException(status_code=400, detail="pve_id no puede estar vacío")
    try:
        row = await pve_almacen.obtener_punto_venta(pve_id)
    except Exception as e:
        raise _db_error(e) from e
    if not row:
        raise HTTPException(status_code=404, detail="Punto de venta no encontrado")
    return PuntoVentaResponse(**row)


@router_almacenes.get("", response_model=AlmacenListResponse)
async def listar_almacenes(
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=1000),
    alm_id: Optional[str] = Query(None, description="Filtrar un almacén concreto"),
    pve_id: Optional[str] = Query(
        None,
        description="Filtrar almacenes vinculados a un PVE",
    ),
) -> AlmacenListResponse:
    """
    Lista almacenes con los PVE que pueden usarlos.

    Útil antes del catálogo: elija un par `(pve_id, alm_id)` de esta respuesta
    y úselo en `GET /api/products` y en `POST /api/orders`.
    """
    try:
        items, total = await pve_almacen.listar_almacenes(
            alm_id=alm_id,
            pve_id=pve_id,
            skip=skip,
            limit=limit,
        )
    except Exception as e:
        raise _db_error(e) from e
    return AlmacenListResponse(
        items=[AlmacenResponse(**item) for item in items],
        total=total,
    )
