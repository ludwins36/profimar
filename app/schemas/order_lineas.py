"""
Líneas de pedido — tabla vntdettxn (columnas pvdId, vntid, artId, pvdPrecioMoneda, etc.).
Ajusta LINEAS_COLUMN_MAP si tu BD difiere.
"""
from datetime import date, datetime
from decimal import Decimal
from typing import Any, Optional

from pydantic import BaseModel, ConfigDict, model_validator

# snake_case (API) -> nombre de columna en SQL Server (vntdettxn)
LINEAS_COLUMN_MAP: dict[str, str] = {
    "pvd_id": "pvdId",
    "vnt_id": "vntid",
    "art_id": "artId",
    "uni_id": "uniid",
    "pvd_precio_moneda": "pvdPrecioMoneda",
    "pvd_cantidad_vendida": "pvdCantidadVendida",
    "pvd_cantidad_entregada": "pvdCantidadEntregada",
    "pvd_impreso": "pvdImpreso",
    "pvd_descripcion": "pvdDescripcion",
    "pvd_usuario": "pvdUsuario",
    "pvd_fecha_cambio": "pvdFechaCambio",
    "pvd_descuento_articulo": "pvdDescuentoArticulo",
    "lot_id": "lotid",
    "pro_id": "proid",
    "can_id": "canid",
    "tdo_id": "tdoid",
    "pvd_seleccion": "pvdSeleccion",
    "pvd_impresion": "pvdImpresion",
    "plt_id": "pltid",
    "act_id": "actId",
    "pli_id": "pliId",
    "pvd_usuario_creacion": "pvdUsuarioCreacion",
    "pvd_fecha_creacion": "pvdFechaCreacion",
    "pvd_con_solicitud": "pvdConSolicitud",
    "cod_barra": "codBarra",
    "pvd_destino": "pvdDestino",
    "txn_origen_id": "txnOrigenid",
    "pvd_descripcion_articulo": "pvdDescripcionArticulo",
    "pvd_articulo_devuelto": "pvdArticuloDevuelto",
    "pvd_recargo": "pvdRecargo",
    "pvd_fecha_entrega": "pvdFechaEntrega",
    "pvd_porcentaje_utilidad": "pvdPorcentajeUtilidad",
    # Alias legacy (API anterior) -> columnas vntdettxn
    "ped_id": "vntid",
    "ped_precio_sin_iva": "pvdPrecioMoneda",
    "ped_cantidad_v": "pvdCantidadVendida",
    "ped_cantidad_p": "pvdCantidadEntregada",
    "ped_descripcion": "pvdDescripcion",
    "ped_articulo_de": "pvdDescripcionArticulo",
    "ped_fecha_entre": "pvdFechaEntrega",
    "ped_recargo": "pvdRecargo",
    "ped_usuario_cr": "pvdUsuarioCreacion",
    "ped_fecha_cre": "pvdFechaCreacion",
    "ped_origen": "txnOrigenid",
}

# Campos solo API (no insertar en vntdettxn)
LINEAS_SOLO_API: frozenset[str] = frozenset({
    "pedido_almacen", "alm_id", "almacen",
})


class OrdenLineaCreate(BaseModel):
    """
    Una línea de pedido (vntdettxn). Campos opcionales; envía los que necesites.
    pvdConSolicitud se asigna en servidor siempre como N; no enviar pvd_con_solicitud.
    También puedes enviar columnas extra con el nombre exacto de SQL (p. ej. artId).
    """

    model_config = ConfigDict(extra="allow", str_strip_whitespace=True)

    pvd_id: Optional[int] = None
    vnt_id: Optional[str] = None
    art_id: Optional[str] = None
    uni_id: Optional[str] = None
    pvd_precio_moneda: Optional[Decimal] = None
    pvd_cantidad_vendida: Optional[Decimal] = None
    pvd_cantidad_entregada: Optional[Decimal] = None
    pvd_impreso: Optional[bool] = None
    pvd_descripcion: Optional[str] = None
    pvd_usuario: Optional[str] = None
    pvd_fecha_cambio: Optional[datetime] = None
    pvd_descuento_articulo: Optional[Decimal] = None
    lot_id: Optional[str] = None
    pro_id: Optional[str] = None
    can_id: Optional[str] = None
    tdo_id: Optional[str] = None
    pvd_seleccion: Optional[bool] = None
    pvd_impresion: Optional[bool] = None
    plt_id: Optional[str] = None
    act_id: Optional[str] = None
    pli_id: Optional[str] = None
    pvd_usuario_creacion: Optional[str] = None
    pvd_fecha_creacion: Optional[datetime] = None
    cod_barra: Optional[str] = None
    pvd_destino: Optional[str] = None
    txn_origen_id: Optional[str] = None
    pvd_descripcion_articulo: Optional[str] = None
    pvd_articulo_devuelto: Optional[bool] = None
    pvd_recargo: Optional[Decimal] = None
    pvd_fecha_entrega: Optional[datetime] = None
    pvd_porcentaje_utilidad: Optional[Decimal] = None
    # Alias legacy
    ped_id: Optional[str] = None
    ped_precio_sin_iva: Optional[Decimal] = None
    ped_cantidad_v: Optional[Decimal] = None
    ped_cantidad_p: Optional[Decimal] = None
    ped_descripcion: Optional[str] = None
    ped_articulo_de: Optional[str] = None
    ped_fecha_entre: Optional[date] = None
    ped_recargo: Optional[Decimal] = None
    ped_usuario_cr: Optional[str] = None
    ped_fecha_cre: Optional[datetime] = None
    ped_origen: Optional[str] = None

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
        if clave in LINEAS_SOLO_API:
            continue
        if clave in LINEAS_COLUMN_MAP:
            col_sql = LINEAS_COLUMN_MAP[clave]
        elif clave.isupper() and clave.replace("_", "").isalnum():
            col_sql = clave
        elif "_" not in clave and any(c.islower() for c in clave):
            col_sql = clave
        else:
            col_sql = clave.upper()
        columnas.append(col_sql)
        valores.append(valor)
    return columnas, valores
