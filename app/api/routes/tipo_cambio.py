"""Rutas de tipo de cambio (gntTipoCambio)."""
from datetime import date
from decimal import Decimal
from typing import Optional

from fastapi import APIRouter, HTTPException, Query

from app.schemas.tipo_cambio import ConvertirMontoResponse, MonedaConversion, TipoCambioResponse
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


@router.get("/convertir", response_model=ConvertirMontoResponse)
async def convertir_monto(
    monto: Decimal = Query(..., gt=0, description="Monto a convertir"),
    moneda: MonedaConversion = Query(
        ...,
        description="Moneda de origen: BOL (bolivianos) o DOL (dólares)",
    ),
) -> ConvertirMontoResponse:
    """
    Convierte un monto entre bolivianos y dólares con el último `tcaTC`.

    - `BOL` → `DOL`: monto / tipo_cambio
    - `DOL` → `BOL`: monto * tipo_cambio
    """
    try:
        tc = await order_erp.tipo_cambio_ultimo()
    except Exception as e:
        raise HTTPException(
            status_code=503,
            detail=f"Error al consultar tipo de cambio: {e!s}",
        ) from e

    if tc is None or tc <= 0:
        raise HTTPException(
            status_code=404,
            detail="No hay tipo de cambio registrado",
        )

    moneda_origen = moneda
    if moneda_origen == "BOL":
        monto_destino = monto / tc
        moneda_destino: MonedaConversion = "DOL"
    else:
        monto_destino = monto * tc
        moneda_destino = "BOL"

    return ConvertirMontoResponse(
        monto_origen=monto,
        moneda_origen=moneda_origen,
        monto_destino=monto_destino,
        moneda_destino=moneda_destino,
        tipo_cambio=tc,
    )
