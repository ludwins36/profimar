"""Schema de respuesta para tipo de cambio (gntTipoCambio)."""
from datetime import date
from decimal import Decimal
from typing import Optional

from pydantic import BaseModel, Field


class TipoCambioResponse(BaseModel):
    """Último TC o el vigente a una fecha."""

    status: str = Field(default="ok")
    tipo_cambio: Decimal = Field(..., description="tcaTC de gntTipoCambio")
    fecha: Optional[date] = Field(
        None,
        description="Fecha consultada; null = último registro por tcaFechaCreacion",
    )
