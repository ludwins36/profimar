"""
Líneas de pedido (detalle). Columnas según esquema tipo pedId, pedid, artId, uniid, etc.
Ajusta LINEAS_COLUMN_MAP y el nombre de tabla en routes si tu BD difiere.
"""
from datetime import date, datetime
from decimal import Decimal
from typing import Any, Optional

from pydantic import BaseModel, ConfigDict, model_validator


# API snake_case -> nombre de columna en SQL Server (camelCase / tal cual en BD)
LINEAS_COLUMN_MAP: dict[str, str] = {
    "ped_id": "pedId",
    "pedido_folio": "pedid",
    "art_id": "artId",
    "uni_id": "uniid",
    "ped_precio_sin_iva": "pedPrecioSinIva",
    "ped_cantidad_v": "pedCantidadV",
    "ped_cantidad_p": "pedCantidadP",
    "ped_importe": "pedImporte",
    "ped_descripcion": "pedDescripcion",
    "ped_articulo_de": "pedArticuloDe",
    "ped_fecha_entre": "pedFechaEntre",
    "ped_porcentaje_de": "pedPorcentajeDe",
    "ped_monto_desc": "pedMontoDesc",
    "can_id": "canId",
    "lin_id": "linid",
    "ped_subtotal": "pedSubtotal",
    "ped_impuesto": "pedImpuesto",
    "act_id": "actId",
    "pli_id": "pliId",
    "ped_usuario_cr": "pedUsuarioCr",
    "ped_fecha_cre": "pedFechaCre",
    "ped_origen": "pedOrigen",
    "ped_recargo": "pedRecargo",
    "ped_fecha_prom": "pedFechaProm",
    "ped_porcentaje_d": "pedPorcentajeD",
    "ped_monto_des": "pedMontoDes",
}


class OrdenLineaCreate(BaseModel):
    """
    Una línea de pedido. Campos opcionales; envía los que existan en tu tabla.
    También puedes enviar columnas extra con el nombre exacto de SQL (p. ej. pedId, artId).
    """

    model_config = ConfigDict(extra="allow", str_strip_whitespace=True)

    ped_id: Optional[int] = None
    pedido_folio: Optional[str] = None
    art_id: Optional[str] = None
    uni_id: Optional[str] = None
    ped_precio_sin_iva: Optional[Decimal] = None
    ped_cantidad_v: Optional[Decimal] = None
    ped_cantidad_p: Optional[Decimal] = None
    ped_importe: Optional[Decimal] = None
    ped_descripcion: Optional[str] = None
    ped_articulo_de: Optional[str] = None
    ped_fecha_entre: Optional[date] = None
    ped_porcentaje_de: Optional[Decimal] = None
    ped_monto_desc: Optional[Decimal] = None
    can_id: Optional[int] = None
    lin_id: Optional[int] = None
    ped_subtotal: Optional[Decimal] = None
    ped_impuesto: Optional[Decimal] = None
    act_id: Optional[int] = None
    pli_id: Optional[int] = None
    ped_usuario_cr: Optional[str] = None
    ped_fecha_cre: Optional[datetime] = None
    ped_origen: Optional[str] = None
    ped_recargo: Optional[Decimal] = None
    ped_fecha_prom: Optional[datetime] = None
    ped_porcentaje_d: Optional[Decimal] = None
    ped_monto_des: Optional[Decimal] = None

    @model_validator(mode="after")
    def _al_menos_un_campo(self) -> "OrdenLineaCreate":
        data = self.model_dump(exclude_none=True)
        if not data:
            raise ValueError("Debe enviar al menos un campo de la línea")
        return self


def linea_a_columnas_sql(payload: OrdenLineaCreate) -> tuple[list[str], list[Any]]:
    """Convierte el body a nombres de columna SQL y valores (respeta camelCase del mapa)."""
    raw = payload.model_dump(exclude_none=True)
    columnas: list[str] = []
    valores: list[Any] = []
    for clave, valor in raw.items():
        if clave in LINEAS_COLUMN_MAP:
            col_sql = LINEAS_COLUMN_MAP[clave]
        elif clave.isupper() and clave.replace("_", "").isalnum():
            col_sql = clave
        elif "_" not in clave and any(c.islower() for c in clave):
            # camelCase ya alineado con columnas SQL (extras)
            col_sql = clave
        else:
            col_sql = clave.upper()
        columnas.append(col_sql)
        valores.append(valor)
    return columnas, valores
