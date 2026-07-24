"""
Schemas para puntos de venta y almacenes (gntPuntoventa, gntPuntoVentaAlmacen, intAlmacen).
"""
from typing import Optional

from pydantic import BaseModel, Field


class AlmacenEnPuntoVenta(BaseModel):
    """Almacén usable en un PVE (misma regla que vmaExitencia)."""

    alm_id: str = Field(..., description="Código de almacén (pedido_almacen / pvdDescripcion)")
    nombre: Optional[str] = Field(None, description="almNombre en intAlmacen")
    es_default: bool = Field(
        False,
        description="True si es el almacén default del PVE (gntPuntoventa.almId)",
    )


class PuntoVentaResponse(BaseModel):
    """Punto de venta con almacenes vinculados."""

    pve_id: str
    nombre: Optional[str] = None
    sucursal_id: Optional[str] = Field(None, description="sucId")
    habilitado: Optional[str] = Field(None, description="pveHabilitado (S/N)")
    moneda_id: Optional[str] = None
    lista_precio_id: Optional[str] = Field(None, description="lprId")
    forma_pago_id: Optional[str] = Field(None, description="fpaid default del PVE")
    almacen_default: Optional[str] = Field(
        None,
        description="AlmId principal del PVE; usar como pedido_almacen si no hay otro",
    )
    almacenes: list[AlmacenEnPuntoVenta] = Field(
        default_factory=list,
        description="Almacenes que vmaExitencia considera para este PVE",
    )


class PuntoVentaListResponse(BaseModel):
    items: list[PuntoVentaResponse]
    total: int


class PuntoVentaEnAlmacen(BaseModel):
    pve_id: str
    nombre: Optional[str] = None
    es_default: bool = Field(
        False,
        description="True si ALMCHICOTI es el almacén default de ese PVE",
    )


class AlmacenResponse(BaseModel):
    alm_id: str
    nombre: Optional[str] = None
    puntos_venta: list[PuntoVentaEnAlmacen] = Field(
        default_factory=list,
        description="PVEs que pueden usar este almacén al aprobar VEN",
    )


class AlmacenListResponse(BaseModel):
    items: list[AlmacenResponse]
    total: int
