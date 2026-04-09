"""
Fase 1: encabezado de pedido (columnas tipo PEDIDO* según esquema ERP).
Ajusta los nombres en ENCABEZADO_COLUMN_MAP si tu tabla usa otros identificadores.
"""
from datetime import date, datetime, time
from decimal import Decimal
from typing import Any, Optional

from pydantic import BaseModel, ConfigDict, Field, model_validator


# snake_case (API) -> nombre de columna en SQL Server
ENCABEZADO_COLUMN_MAP: dict[str, str] = {
    "pedido_numero": "PEDIDONUMERO",
    "pedido_tipo": "PEDIDOTIPO",
    "pedido_fecha": "PEDIDOFECHA",
    "pedido_hora": "PEDIDOHORA",
    "pedido_cliente": "PEDIDOCLIENTE",
    "pedido_vendedor": "PEDIDOVENDEDOR",
    "pedido_condicion": "PEDIDOCONDICION",
    "pedido_direccion": "PEDIDODIRECCION",
    "pedido_telefono": "PEDIDOTELEFONO",
    "pedido_observacion": "PEDIDOOBSERVACION",
    "pedido_total": "PEDIDOTOTAL",
    "pedido_estado": "PEDIDOESTADO",
    "pedido_usuario": "PEDIDOUSUARIO",
    "pedido_terminal": "PEDIDOTERMINAL",
    "pedido_fecha_mod": "PEDIDOFECHAMOD",
    "pedido_hora_mod": "PEDIDOHORAMOD",
    "pedido_usuario_mod": "PEDIDOUSUARIOMOD",
    "pedido_terminal_mod": "PEDIDOTERMINALMOD",
    "pedido_sucursal": "PEDIDOSUCURSAL",
    "pedido_moneda": "PEDIDOMONEDA",
    "pedido_cambio": "PEDIDOCAMBIO",
    "pedido_lista_precio": "PEDIDOLISTAPRECIO",
    "pedido_forma_pago": "PEDIDOFORMAPAGO",
    "pedido_entrega": "PEDIDOENTREGA",
    "pedido_factura": "PEDIDOFACTURA",
    "pedido_nit": "PEDIDONIT",
    "pedido_razon_social": "PEDIDORAZONSOCIAL",
}


class OrdenEncabezadoCreate(BaseModel):
    """
    Encabezado de pedido. Campos opcionales: envía solo los que existan en tu tabla.
    Puedes añadir columnas extra (p. ej. PEDIDOXYZ) si el modelo las acepta vía dict — ver uso en rutas.
    """

    model_config = ConfigDict(extra="allow", str_strip_whitespace=True)

    pedido_numero: Optional[str] = None
    pedido_tipo: Optional[str] = None
    pedido_fecha: Optional[date] = None
    pedido_hora: Optional[time] = None
    pedido_cliente: Optional[str] = None
    pedido_vendedor: Optional[str] = None
    pedido_condicion: Optional[str] = None
    pedido_direccion: Optional[str] = None
    pedido_telefono: Optional[str] = None
    pedido_observacion: Optional[str] = None
    pedido_total: Optional[Decimal] = None
    pedido_estado: Optional[str] = None
    pedido_usuario: Optional[str] = None
    pedido_terminal: Optional[str] = None
    pedido_fecha_mod: Optional[datetime] = None
    pedido_hora_mod: Optional[str] = None
    pedido_usuario_mod: Optional[str] = None
    pedido_terminal_mod: Optional[str] = None
    pedido_sucursal: Optional[str] = None
    pedido_moneda: Optional[str] = None
    pedido_cambio: Optional[Decimal] = None
    pedido_lista_precio: Optional[str] = None
    pedido_forma_pago: Optional[str] = None
    pedido_entrega: Optional[str] = None
    pedido_factura: Optional[str] = None
    pedido_nit: Optional[str] = None
    pedido_razon_social: Optional[str] = None

    @model_validator(mode="after")
    def _al_menos_un_campo(self) -> "OrdenEncabezadoCreate":
        data = self.model_dump(exclude_none=True)
        if not data:
            raise ValueError("Debe enviar al menos un campo del encabezado")
        return self


def filas_a_columnas_sql(payload: OrdenEncabezadoCreate) -> tuple[list[str], list[Any]]:
    """Convierte el body a listas de nombres de columna SQL y valores."""
    raw = payload.model_dump(exclude_none=True)
    columnas: list[str] = []
    valores: list[Any] = []
    for clave, valor in raw.items():
        if clave in ENCABEZADO_COLUMN_MAP:
            col_sql = ENCABEZADO_COLUMN_MAP[clave]
        elif clave.isupper() and clave.replace("_", "").isalnum():
            col_sql = clave
        else:
            col_sql = clave.upper()
        columnas.append(col_sql)
        valores.append(valor)
    return columnas, valores
