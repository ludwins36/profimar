"""Schema de respuesta para tipo de cambio (gntTipoCambio)."""
from datetime import date
from decimal import Decimal
from typing import Literal, Optional

from pydantic import BaseModel, Field

MonedaConversion = Literal["BOL", "DOL"]


class TipoCambioResponse(BaseModel):
    """Último TC o el vigente a una fecha."""

    status: str = Field(default="ok")
    tipo_cambio: Decimal = Field(..., description="tcaTC de gntTipoCambio")
    fecha: Optional[date] = Field(
        None,
        description="Fecha consultada; null = último registro por tcaFechaCreacion",
    )


class ConvertirMontoResponse(BaseModel):
    """Conversión BOL ↔ DOL usando el último tipo de cambio."""

    status: str = Field(default="ok")
    monto_origen: Decimal
    moneda_origen: MonedaConversion
    monto_destino: Decimal
    moneda_destino: MonedaConversion
    tipo_cambio: Decimal = Field(..., description="tcaTC usado (BOL/DOL)")
