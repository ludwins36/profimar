"""
Orden completa: encabezado + lista de líneas (productos) en un solo request.
"""
from datetime import date, datetime
from decimal import Decimal
from typing import Optional

from pydantic import BaseModel, ConfigDict, Field, model_validator

from app.schemas.order_encabezado import OrdenEncabezadoCreate


class OrdenLineaItem(BaseModel):
    """Línea de pedido (vntdettxn). `vnt_id` lo asigna la API; almacén por línea en `pvd_descripcion`."""

    model_config = ConfigDict(extra="allow", str_strip_whitespace=True)

    art_id: Optional[str] = None
    uni_id: Optional[str] = None
    pvd_precio_moneda: Optional[Decimal] = None
    pvd_cantidad_vendida: Optional[Decimal] = None
    pvd_cantidad_entregada: Optional[Decimal] = None
    pvd_descripcion: Optional[str] = None
    pvd_descripcion_articulo: Optional[str] = None
    pvd_destino: Optional[str] = None
    pvd_fecha_entrega: Optional[datetime] = None
    pvd_recargo: Optional[Decimal] = None
    can_id: Optional[str] = None
    act_id: Optional[str] = None
    pli_id: Optional[str] = None
    pvd_usuario_creacion: Optional[str] = None
    pvd_fecha_creacion: Optional[datetime] = None
    txn_origen_id: Optional[str] = None
    ped_precio_sin_iva: Optional[Decimal] = None
    ped_cantidad_v: Optional[Decimal] = None
    ped_cantidad_p: Optional[Decimal] = None
    ped_descripcion: Optional[str] = None
    ped_articulo_de: Optional[str] = None
    ped_fecha_entre: Optional[date] = None


class DatosEnvioCreate(BaseModel):
    """Costo/artículo de envío: se inserta como línea adicional en vntdettxn."""

    model_config = ConfigDict(extra="forbid", str_strip_whitespace=True)

    art_id: str = Field(..., min_length=1, description="Artículo de envío (ej. TAL002)")
    ped_precio_sin_iva: Decimal = Field(..., description="Precio de envío sin IVA")


_ENVIO_UNI_ID = "PZA"
_ENVIO_CANTIDAD = Decimal("1")


def datos_envio_a_linea(datos_envio: DatosEnvioCreate) -> OrdenLineaItem:
    """Convierte datos_envio en línea con uni_id=PZA y cantidades fijas en 1."""
    return OrdenLineaItem(
        art_id=datos_envio.art_id,
        uni_id=_ENVIO_UNI_ID,
        ped_precio_sin_iva=datos_envio.ped_precio_sin_iva,
        ped_cantidad_v=_ENVIO_CANTIDAD,
        ped_cantidad_p=_ENVIO_CANTIDAD,
    )


class OrdenCompletaCreate(BaseModel):
    """Request para crear una orden completa (encabezado + detalle)."""

    encabezado: OrdenEncabezadoCreate
    lineas: list[OrdenLineaItem] = Field(..., min_length=1, description="Productos de la orden")
    datos_envio: Optional[DatosEnvioCreate] = Field(
        None,
        description="Si se envía, se agrega como línea extra (uni_id=PZA, cantidad=1)",
    )

    @model_validator(mode="after")
    def _requiere_pve(self) -> "OrdenCompletaCreate":
        data = self.encabezado.model_dump(exclude_none=True)
        tiene_pve = any(str(data.get(k, "")).strip() for k in ("pve_id", "pveid", "pveId"))
        if not tiene_pve:
            raise ValueError(
                "encabezado.pve_id es obligatorio "
                "(la API asigna almacén por línea según existencia en gntPuntoVentaAlmacen)"
            )
        forma_pago = str(data.get("pedido_forma_pago") or "").strip()
        if not forma_pago:
            raise ValueError(
                "encabezado.pedido_forma_pago es obligatorio "
                "(se inserta en vntFPagoTxn.fpaid)"
            )
        return self

    def lineas_con_envio(self) -> list[OrdenLineaItem]:
        """Productos + línea de envío (si viene datos_envio)."""
        if self.datos_envio is None:
            return list(self.lineas)
        return [*self.lineas, datos_envio_a_linea(self.datos_envio)]
