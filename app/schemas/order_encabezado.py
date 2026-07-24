"""
Encabezado de pedido — tabla vnttxn (columnas según esquema ERP Profimar).
Ajusta ENCABEZADO_COLUMN_MAP si tu BD difiere.
"""
from datetime import datetime
from decimal import Decimal
from typing import Any, Optional

from pydantic import BaseModel, ConfigDict, Field, model_validator

# snake_case (API) -> nombre de columna en SQL Server (vnttxn)
ENCABEZADO_COLUMN_MAP: dict[str, str] = {
    # PK e IDs de relación
    "vnt_id": "vntid",
    "ttx_id": "ttxId",
    "tdo_id": "tdoid",
    "ven_id": "venid",
    "cli_id": "cliid",
    "mde_id": "mdeid",
    "pve_id": "pveid",
    "mon_id": "monid",
    "lpr_id": "lprid",
    "mod_id": "modId",
    "can_id": "canid",
    "lug_id": "lugid",
    "resp_id": "respid",
    "slt_id": "sltid",
    "suc_id": "sucid",
    "act_id": "actid",
    "tip_id": "tipId",
    "agt_id": "agtid",
    "dre_id": "dreId",
    "cta_id_proveedor": "ctaIdProveedor",
    "pro_id": "proId",
    "dos_id": "dosId",
    "tip_id1": "tipId1",
    "tip_id2": "tipId2",
    # Campos vnt*
    "vnt_referencia": "vntReferencia",
    "vnt_numero": "vntNumero",
    "vnt_estado": "vntEstado",
    "vnt_fecha_doc": "vntFechaDoc",
    "vnt_tc": "vntTC",
    "vnt_con_factura": "vntConFactura",
    "vnt_ruc": "vntRUC",
    "vnt_razon_social": "vntRazonSocial",
    "vnt_anticipo_moneda": "vntAnticipoMoneda",
    "vnt_articulo_moneda": "vntArticuloMoneda",
    "vnt_recargo_moneda": "vntRecargoMoneda",
    "vnt_descuento_moneda": "vntDescuentoMoneda",
    "vnt_total_moneda": "vntTotalMoneda",
    "vnt_descripcion": "vntDescripcion",
    "vnt_usuario": "vntUsuario",
    "vnt_fecha_cambio": "vntFechaCambio",
    "vnt_otros_anticipos": "vntOtrosAnticipos",
    "vnt_exportado_al_fiscal": "vntExportadoAlFiscal",
    "vnt_descuento_articulo": "vntDescuentoArticulo",
    "vnt_numero_personas": "vntNumeroPersonas",
    "vnt_porcentaje_comision": "vntPorcentajeComision",
    "vnt_numero_cuotas_comision": "vntNumeroCuotasComision",
    "vnt_txn_impresa": "vntTxnImpresa",
    "vnt_cortesia": "vntCortesia",
    "vnt_comision_moneda": "vntComisionMoneda",
    "vnt_comision_momento": "vntComisionMomento",
    "vnt_nro_factura": "vntNroFactura",
    "vnt_correlativo_txn": "vntCorrelativoTxn",
    "vnt_anula_factura_original": "vntAnulaFacturaOriginal",
    "vnt_txn_cerrada": "vntTxnCerrada",
    "vnt_fecha_cierre": "vntFechaCierre",
    "vnt_nota01": "vntNota01",
    "vnt_nota02": "vntNota02",
    "vnt_fecha_creacion": "vntFechaCreacion",
    "vnt_venta_con_planificacion": "vntVentaConPlanificacion",
    "vnt_usuario_creacion": "vntUsuarioCreacion",
    "vnt_usuario_descuento": "vntUsuarioDescuento",
    "vnt_con_dfr": "vntConDFR",
    "vnt_dfr_monto": "vntDFRMonto",
    "rel_persona": "relPersona",
    "vnt_devolucion_ndc": "vntDevolucionNDC",
    "vnt_fecha_ven_contrato": "vntFechaVenContrato",
    "vnt_nro_contrato": "vntNroContrato",
    "vnt_url": "vntUrl",
    "vnt_venta_gravada_tasa_cero": "vntVentaGravadaATasaCero",
    "vnt_observacion": "vntObservacion",
    "vnt_fecha_anulacion": "vntFechaAnulacion",
    "vnt_fecha_aprobacion": "vntFechaAprobacion",
    "vnt_usuario_anulacion": "vntUsuarioAnulacion",
    "vnt_usuario_aprobacion": "vntUsuarioAprobacion",
    "vnt_ruta": "vntruta",
    "vnt_porcentaje_utilidad": "vntPorcentajeUtilidad",
    "vnt_estado_sin": "vntEstadoSIN",
    "vnt_facturar_motor_imposivo": "vntFacturarMotorImposivo",
    # Alias legacy (pedido_* del API anterior) -> columnas vnttxn
    "pedido_numero": "vntReferencia",
    "pedido_tipo": "ttxId",
    "pedido_fecha": "vntFechaDoc",
    "pedido_cliente": "cliid",
    "pedido_vendedor": "venid",
    "pedido_condicion": "modId",
    "pedido_direccion": "dreId",
    "pedido_observacion": "vntObservacion",
    "pedido_total": "vntTotalMoneda",
    "pedido_estado": "vntEstado",
    "pedido_usuario": "vntUsuario",
    "pedido_fecha_mod": "vntFechaCambio",
    "pedido_usuario_mod": "vntUsuarioCreacion",
    "pedido_sucursal": "sucid",
    "pedido_moneda": "monid",
    "pedido_cambio": "vntTC",
    "pedido_lista_precio": "lprid",
    "pedido_forma_pago": "mdeid",
    "pedido_entrega": "lugid",
    "pedido_factura": "vntNroFactura",
    "pedido_nit": "vntRUC",
    "pedido_razon_social": "vntRazonSocial",
}

# Campos solo API (no insertar en vnttxn)
ENCABEZADO_SOLO_API: frozenset[str] = frozenset({
    "pedido_almacen", "alm_id", "almacen",
    "pedido_fecha", "pedido_estado",  # fecha/estado los asigna el servidor
    "cliente_ruc",  # se resuelve a pedido_cliente (cliid) vía gntDirectorio.dirRuc
})


class OrdenEncabezadoCreate(BaseModel):
    """
    Encabezado de pedido (vnttxn). Campos opcionales; envía los que necesites.
    El vntId lo genera la API con gnpGenerarIdUno (no enviar vnt_id / vntid).
    vntFechaDoc y vntEstado (R) los asigna el servidor; no enviar pedido_fecha ni pedido_estado.
    respId (responsable) lo asigna el servidor desde pedido_vendedor si no se envía resp_id.
    Con `pve_id`, la API completa pedido_sucursal, pedido_vendedor, pedido_usuario (venId),
    pedido_moneda y pedido_lista_precio desde gntPuntoventa si no vienen en el request.
    Con `cliente_ruc`, la API busca dirId en gntDirectorio (dirRuc) y asigna pedido_cliente.
    vntArticuloMoneda, vntTC y tdoId los completa el servidor si faltan (contabilidad al aprobar).
    pedido_almacen = almId legacy en encabezado; en orden completa el almacén va por línea en pvdDescripcion.
    """

    model_config = ConfigDict(extra="allow", str_strip_whitespace=True)

    # IDs (vnt_id se asigna en servidor; no enviar)
    ttx_id: Optional[str] = None
    tdo_id: Optional[str] = None
    ven_id: Optional[str] = None
    cli_id: Optional[str] = None
    mde_id: Optional[str] = None
    pve_id: Optional[str] = None
    mon_id: Optional[str] = None
    lpr_id: Optional[str] = None
    mod_id: Optional[str] = None
    can_id: Optional[str] = None
    lug_id: Optional[str] = None
    suc_id: Optional[str] = None
    dre_id: Optional[str] = None
    # Datos principales
    vnt_referencia: Optional[str] = None
    vnt_numero: Optional[int] = None
    vnt_tc: Optional[Decimal] = None
    vnt_ruc: Optional[str] = None
    vnt_razon_social: Optional[str] = None
    vnt_total_moneda: Optional[Decimal] = None
    vnt_descripcion: Optional[str] = None
    vnt_observacion: Optional[str] = None
    vnt_usuario: Optional[str] = None
    vnt_usuario_creacion: Optional[str] = None
    vnt_fecha_cambio: Optional[datetime] = None
    vnt_fecha_creacion: Optional[datetime] = None
    vnt_nro_factura: Optional[str] = None
    vnt_con_factura: Optional[bool] = None
    # Alias legacy (compatibilidad con requests anteriores)
    pedido_numero: Optional[str] = None
    pedido_tipo: Optional[str] = None
    cliente_ruc: Optional[str] = Field(
        None,
        description="RUC/NIT del cliente (dirRuc). La API resuelve dirId → pedido_cliente/cliid",
    )
    pedido_cliente: Optional[str] = None
    pedido_vendedor: Optional[str] = None
    resp_id: Optional[str] = Field(
        None,
        description="respid en vnttxn (responsable). Si no se envía, la API usa pedido_vendedor/ven_id",
    )
    pedido_condicion: Optional[str] = None
    pedido_direccion: Optional[str] = None
    pedido_observacion: Optional[str] = None
    pedido_total: Optional[Decimal] = None
    pedido_usuario: Optional[str] = Field(
        None,
        description="vntUsuario en vnttxn. Si no se envía, la API usa venId del pve_id (gntPuntoventa)",
    )
    pedido_fecha_mod: Optional[datetime] = None
    pedido_usuario_mod: Optional[str] = None
    pedido_sucursal: Optional[str] = None
    pedido_moneda: Optional[str] = None
    pedido_cambio: Optional[Decimal] = None
    pedido_lista_precio: Optional[str] = None
    pedido_forma_pago: Optional[str] = None
    pedido_entrega: Optional[str] = None
    pedido_factura: Optional[str] = None
    pedido_nit: Optional[str] = None
    pedido_razon_social: Optional[str] = None
    pedido_almacen: Optional[str] = Field(
        None,
        description=(
            "Legacy: almId único para todas las líneas si no se asigna por producto. "
            "En orden completa la API asigna pvdDescripcion por línea según existencia del PVE"
        ),
    )

    @model_validator(mode="after")
    def _al_menos_un_campo(self) -> "OrdenEncabezadoCreate":
        data = self.model_dump(exclude_none=True)
        if not data:
            raise ValueError("Debe enviar al menos un campo del encabezado")
        return self


def filas_a_columnas_sql(payload: OrdenEncabezadoCreate) -> tuple[list[str], list[Any]]:
    """Convierte el body a nombres de columna SQL y valores (respeta camelCase del mapa)."""
    raw = payload.model_dump(exclude_none=True)
    columnas: list[str] = []
    valores: list[Any] = []
    for clave, valor in raw.items():
        if clave in ENCABEZADO_SOLO_API:
            continue
        if clave in ENCABEZADO_COLUMN_MAP:
            col_sql = ENCABEZADO_COLUMN_MAP[clave]
        elif clave.isupper() and clave.replace("_", "").isalnum():
            col_sql = clave
        elif "_" not in clave and any(c.islower() for c in clave):
            col_sql = clave
        else:
            col_sql = clave.upper()
        columnas.append(col_sql)
        valores.append(valor)
    return columnas, valores
