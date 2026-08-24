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
        description="exiExistencia: un alm_id, suma de almacenes del pve_id, o suma total",
    )
    existencia_venta: Optional[Decimal] = Field(
        None,
        description="Disponible para aprobar VEN (vmaExitencia si artTipo=I; requiere pve_id)",
    )


class ProductoListResponse(BaseModel):
    """Respuesta paginada o lista de productos."""

    items: list[ProductoResponse]
    total: int


class PrecioCantidadItem(BaseModel):
    """Tramo de precio por cantidad (vntListaPrecioCantidad)."""

    cant_id: int = Field(..., description="cantId")
    lpr_id: str = Field(..., description="lprid (lista de precios)")
    art_id: str = Field(..., description="artId")
    cant_inicial: Decimal = Field(..., description="cantInicial (desde)")
    cant_final: Decimal = Field(..., description="cantFinal (hasta)")
    cant_precio: Decimal = Field(..., description="cantPrecio")
    mon_id: Optional[str] = Field(None, description="monid")
    hor_id: Optional[str] = Field(None, description="horid")


class PrecioCantidadListResponse(BaseModel):
    """Lista de precios por tramo de cantidad."""

    items: list[PrecioCantidadItem]
    total: int
