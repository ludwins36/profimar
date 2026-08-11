"""Rutas de tipo de cambio (gntTipoCambio)."""
from datetime import date
from typing import Optional

from fastapi import APIRouter, HTTPException, Query

from app.schemas.tipo_cambio import TipoCambioResponse
from app.services import order_erp

router = APIRouter(prefix="/tipo-cambio", tags=["Tipo de cambio"])


@router.get("", response_model=TipoCambioResponse)
async def get_tipo_cambio(
    fecha: Optional[date] = Query(
        None,
        description="Si se envía, TC vigente a esa fecha (moneda central). Si no, el último registrado.",
    ),
) -> TipoCambioResponse:
    """Retorna la tasa de cambio desde `gntTipoCambio`."""
    try:
        if fecha is not None:
            tc = await order_erp.tipo_cambio_para_fecha(fecha)
        else:
            tc = await order_erp.tipo_cambio_ultimo()
    except Exception as e:
        raise HTTPException(
            status_code=503,
            detail=f"Error al consultar tipo de cambio: {e!s}",
        ) from e

    if tc is None:
        raise HTTPException(
            status_code=404,
            detail="No hay tipo de cambio registrado",
        )

    return TipoCambioResponse(tipo_cambio=tc, fecha=fecha)
