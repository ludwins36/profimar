"""
Schemas Pydantic para la entidad Orden.
"""
from datetime import datetime
from decimal import Decimal
from typing import Optional

from pydantic import BaseModel, ConfigDict, Field


class OrdenBase(BaseModel):
    """Campos comunes para orden."""

    cliente_id: int = Field(..., gt=0)
    fecha_orden: datetime
    total: Decimal = Field(..., ge=0, decimal_places=2)
    estado: str = Field(..., max_length=50)


class OrdenCreate(OrdenBase):
    """Schema para crear una orden."""

    pass


class OrdenUpdate(BaseModel):
    """Schema para actualización parcial."""

    cliente_id: Optional[int] = Field(None, gt=0)
    fecha_orden: Optional[datetime] = None
    total: Optional[Decimal] = Field(None, ge=0, decimal_places=2)
    estado: Optional[str] = Field(None, max_length=50)


class OrdenResponse(OrdenBase):
    """Schema de respuesta."""

    model_config = ConfigDict(from_attributes=True)

    id: int
    creado_en: Optional[datetime] = None
    actualizado_en: Optional[datetime] = None


class OrdenListResponse(BaseModel):
    """Respuesta paginada de órdenes."""

    items: list[OrdenResponse]
    total: int
