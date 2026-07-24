"""
Schemas Pydantic para la entidad Producto (tabla intArticulo).
"""
from decimal import Decimal
from typing import Optional

from pydantic import BaseModel, ConfigDict, Field


class ProductoBase(BaseModel):
    """Campos comunes para producto."""

    nombre: str = Field(..., min_length=1, max_length=200, description="artNombre")
    gar_id: Optional[int] = Field(None, description="garId")
    moneda_id: Optional[str] = Field(None, description="monid")
    categoria_id: Optional[str] = Field(None, description="carId")
    uni_id: Optional[str] = Field(None, description="uniid - código unidad ej. PZA")
    codigo_fabrica: Optional[str] = Field(None, max_length=100, description="artCodigoFabrica")
    precio_venta: Decimal = Field(..., ge=0, description="artPrecioVenta")
    precio_venta_dos: Optional[Decimal] = Field(None, ge=0, description="artPrecioVentaDos")
    marca: Optional[str] = Field(None, max_length=100, description="artMarca")


class ProductoCreate(ProductoBase):
    """Schema para crear un producto."""

    pass


class ProductoUpdate(BaseModel):
    """Schema para actualización parcial."""

    nombre: Optional[str] = Field(None, min_length=1, max_length=200)
    gar_id: Optional[int] = None
    moneda_id: Optional[str] = None
    categoria_id: Optional[str] = None
    uni_id: Optional[str] = None
    codigo_fabrica: Optional[str] = Field(None, max_length=100)
    precio_venta: Optional[Decimal] = Field(None, ge=0)
    precio_venta_dos: Optional[Decimal] = Field(None, ge=0)
    marca: Optional[str] = Field(None, max_length=100)


class ProductoResponse(ProductoBase):
    """Schema de respuesta (incluye id = artId)."""

    model_config = ConfigDict(from_attributes=True)

    id: str = Field(..., description="artId - código alfanumérico")
    art_tipo: Optional[str] = Field(None, description="artTipo (I = inventariable, usa vmaExitencia al aprobar)")
    existencia: Optional[Decimal] = Field(
        None,
        description="exiExistencia en alm_id (o suma total si no se filtra almacén)",
    )
    existencia_venta: Optional[Decimal] = Field(
        None,
        description="Disponible para aprobar VEN (vmaExitencia si artTipo=I; requiere pve_id+alm_id en GET)",
    )


class ProductoListResponse(BaseModel):
    """Respuesta paginada o lista de productos."""

    items: list[ProductoResponse]
    total: int
