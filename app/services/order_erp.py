"""
Utilidades de inserción para pedidos (vnttxn / vntdettxn / vntFPagoTxn).
Validaciones de maestros: fase posterior (no implementadas).
"""
from __future__ import annotations

from datetime import date, datetime
from decimal import Decimal
from typing import Any, Optional

from app.core import database
from app.schemas.order_completa import OrdenLineaItem
from app.schemas.order_encabezado import OrdenEncabezadoCreate
from app.schemas.order_lineas import OrdenLineaCreate, LINEAS_SOLO_API, linea_a_columnas_sql
from app.services import product_stock, pve_almacen

_SKIP_INSERT_COLUMNS = frozenset({"vntnumero", "pvdid", "fptid"})
_TABLE_PVE = "gntPuntoventa"
_TABLE_DIRECTORIO = "gntDirectorio"
_TABLE_ARTICULO = "intArticulo"
_TABLE_EXISTENCIA = "intExistencia"
_TABLE_FPAGO = "vntFPagoTxn"
VNT_ESTADO_INSERT = "R"
VNT_CON_FACTURA_INSERT = True
VNT_MONTOS_CERO_INSERT = Decimal("0.000000")
VNT_EXPORTADO_AL_FISCAL_INSERT = "S"
VNT_ANULA_FACTURA_ORIGINAL_INSERT = "S"
VNT_NOTA01_INSERT = 0
VNT_FACTURAR_MOTOR_IMPOSITIVO_INSERT = "S"
_VNT_MONTOS_CERO_KEYS: tuple[tuple[str, ...], ...] = (
    ("vnt_anticipo_moneda", "vntAnticipoMoneda"),
    ("vnt_recargo_moneda", "vntRecargoMoneda"),
    ("vnt_descuento_moneda", "vntDescuentoMoneda"),
    ("vnt_descuento_articulo", "vntDescuentoArticulo"),
    ("vnt_dfr_monto", "vntDFRMonto"),
    ("vnt_venta_gravada_tasa_cero", "vntVentaGravadaATasaCero"),
)
PVD_CON_SOLICITUD_INSERT = "N"
FPT_TIPO_RECARGO_DEFAULT = 0
FPT_TASA_PENAL_DEFAULT = Decimal("0")
FPT_PLAZO_INSERT = 30
FPT_DIAS_ANIO_INSERT = 30
FPA_DF_DEFAULT = True
FPT_DESTINO_INGRESO_DEFAULT = "C"

_SQL_PVE_ENCABEZADO = f"""
SELECT TOP 1
    sucId AS suc_id,
    venId AS ven_id,
    monId AS mon_id,
    lprId AS lpr_id,
    tdoId AS tdo_id
FROM {_TABLE_PVE}
WHERE pveId = ?
"""

_SQL_DIR_ID_POR_RUC = f"""
SELECT TOP 1
    dirId AS dir_id,
    dirRazonSocial AS dir_razon_social
FROM {_TABLE_DIRECTORIO}
WHERE dirRuc = ?
"""


def almacen_desde_encabezado(payload: OrdenEncabezadoCreate) -> str | None:
    """Obtiene almId del encabezado (pedido_almacen / alm_id / almacen)."""
    data = payload.model_dump(exclude_none=True)
    for key in ("pedido_almacen", "alm_id", "almacen"):
        val = data.get(key)
        if val is not None and str(val).strip():
            return str(val).strip()
    return None


def aplicar_almacen_linea(
    payload: OrdenLineaCreate,
    almacen: str | None,
) -> OrdenLineaCreate:
    """Asigna pvdDescripcion = almacen del encabezado si la línea no lo trae."""
    if not almacen:
        return payload
    data = payload.model_dump(exclude_none=True)
    if data.get("pvd_descripcion") or data.get("ped_descripcion"):
        return payload
    data["pvd_descripcion"] = almacen
    return OrdenLineaCreate(**data)


def vnt_fecha_doc_hoy() -> datetime:
    return datetime.combine(date.today(), datetime.min.time())


def resp_id_desde_encabezado(data: dict[str, Any]) -> str | None:
    """
    respId exigido por vmaApruebaTxn al aprobar.
    En pedidos ERP aprobados suele coincidir con venId (vendedor).
    """
    for key in ("resp_id", "respid", "respId"):
        val = data.get(key)
        if val is not None and str(val).strip():
            return str(val).strip()
    for key in ("ven_id", "pedido_vendedor"):
        val = data.get(key)
        if val is not None and str(val).strip():
            return str(val).strip()
    return None


def _to_decimal(value: Any) -> Optional[Decimal]:
    if value is None:
        return None
    try:
        return Decimal(str(value))
    except Exception:
        return None


def pve_id_desde_encabezado(data: dict[str, Any]) -> str | None:
    for key in ("pve_id", "pveid", "pveId"):
        val = data.get(key)
        if val is not None and str(val).strip():
            return str(val).strip()
    return None


def mon_id_desde_encabezado(data: dict[str, Any]) -> str | None:
    for key in ("mon_id", "monid", "pedido_moneda"):
        val = data.get(key)
        if val is not None and str(val).strip():
            return str(val).strip()
    return None


def articulo_moneda_desde_lineas(lineas: list[OrdenLineaItem]) -> Decimal:
    """Suma pvdPrecioMoneda * pvdCantidadVendida (regla ERP para vntArticuloMoneda)."""
    total = Decimal("0")
    for item in lineas:
        raw = item.model_dump(exclude_none=True)
        precio = _to_decimal(raw.get("pvd_precio_moneda") or raw.get("ped_precio_sin_iva"))
        if precio is None:
            continue
        cant = _to_decimal(
            raw.get("pvd_cantidad_vendida") or raw.get("ped_cantidad_v") or raw.get("ped_cantidad_p")
        )
        if cant is None:
            cant = Decimal("1")
        total += precio * cant
    return total


def _campo_vacio(data: dict[str, Any], *keys: str) -> bool:
    for key in keys:
        val = data.get(key)
        if val is not None and str(val).strip():
            return False
    return True


async def tipo_cambio_para_fecha(fecha_doc: date) -> Optional[Decimal]:
    """TC de moneda central (gntTipoCambio) vigente a la fecha del documento."""
    row = await database.fetch_one_dict(
        """
        SELECT TOP 1 tcaTC AS tc
        FROM gntTipoCambio
        WHERE monid = (SELECT TOP 1 monId FROM gntMoneda WHERE monTipo = 'C')
          AND tcaFecha <= ?
        ORDER BY tcaFecha DESC
        """,
        (fecha_doc,),
    )
    if not row or row.get("tc") is None:
        return None
    return _to_decimal(row["tc"])


async def tipo_cambio_ultimo() -> Optional[Decimal]:
    """Último tcaTC registrado en gntTipoCambio (por tcaFechaCreacion)."""
    row = await database.fetch_one_dict(
        """
        SELECT TOP 1 tcaTC AS tc
        FROM dbo.gntTipoCambio
        ORDER BY tcaFechaCreacion DESC
        """,
    )
    if not row or row.get("tc") is None:
        return None
    return _to_decimal(row["tc"])


def _str_db_val(row: dict[str, Any], key: str) -> str | None:
    val = row.get(key)
    if val is None:
        return None
    s = str(val).strip()
    return s or None


async def fetch_pve_encabezado_defaults(pve_id: str) -> dict[str, str]:
    """Maestros del encabezado desde gntPuntoventa (sucursal, vendedor, moneda, lista, tdo)."""
    row = await database.fetch_one_dict(_SQL_PVE_ENCABEZADO, (pve_id.strip(),))
    if not row:
        raise ValueError(f"Punto de venta no encontrado: {pve_id.strip()}")
    out: dict[str, str] = {}
    for key in ("suc_id", "ven_id", "mon_id", "lpr_id", "tdo_id"):
        val = _str_db_val(row, key)
        if val:
            out[key] = val
    return out


async def resolver_cliente_desde_ruc(data: dict[str, Any]) -> dict[str, Any]:
    """
    Resuelve cliente_ruc (dirRuc) → pedido_cliente (cliid / dirId en gntDirectorio).
    También asigna vntRUC (desde el RUC del request) y vntRazonSocial (dirRazonSocial).
    Si no hay registro, lanza ValueError.
    """
    ruc_val = data.get("cliente_ruc")
    if ruc_val is None or not str(ruc_val).strip():
        return data

    ruc = str(ruc_val).strip()

    # vntRUC siempre desde el RUC del request (si no vino explícito)
    if _campo_vacio(data, "vnt_ruc", "pedido_nit", "vntRUC"):
        data["vnt_ruc"] = ruc

    if not _campo_vacio(data, "pedido_cliente", "cli_id", "cliid"):
        # Cliente ya vino; aún así completa razón social desde el RUC si falta
        if _campo_vacio(data, "vnt_razon_social", "pedido_razon_social", "vntRazonSocial"):
            row = await database.fetch_one_dict(_SQL_DIR_ID_POR_RUC, (ruc,))
            razon = _str_db_val(row, "dir_razon_social") if row else None
            if razon:
                data["vnt_razon_social"] = razon
        data.pop("cliente_ruc", None)
        return data

    row = await database.fetch_one_dict(_SQL_DIR_ID_POR_RUC, (ruc,))
    dir_id = _str_db_val(row, "dir_id") if row else None
    if not dir_id:
        raise ValueError("No existe cliente")

    data["pedido_cliente"] = dir_id
    if _campo_vacio(data, "vnt_razon_social", "pedido_razon_social", "vntRazonSocial"):
        razon = _str_db_val(row, "dir_razon_social") if row else None
        if razon:
            data["vnt_razon_social"] = razon
    data.pop("cliente_ruc", None)
    return data


async def aplicar_defaults_desde_pve(data: dict[str, Any]) -> dict[str, Any]:
    """
    Completa campos del encabezado desde gntPuntoventa cuando viene pve_id.
    Solo rellena valores que no vengan en el request.
    """
    pve_id = pve_id_desde_encabezado(data)
    if not pve_id:
        return data

    pve = await fetch_pve_encabezado_defaults(pve_id)

    if _campo_vacio(data, "pedido_sucursal", "suc_id", "sucid") and pve.get("suc_id"):
        data["pedido_sucursal"] = pve["suc_id"]
    if _campo_vacio(data, "pedido_vendedor", "ven_id", "venid") and pve.get("ven_id"):
        data["pedido_vendedor"] = pve["ven_id"]
    if _campo_vacio(data, "pedido_usuario", "vnt_usuario", "vntUsuario") and pve.get("ven_id"):
        data["pedido_usuario"] = pve["ven_id"]
    if _campo_vacio(data, "pedido_moneda", "mon_id", "monid") and pve.get("mon_id"):
        data["pedido_moneda"] = pve["mon_id"]
    if _campo_vacio(data, "pedido_lista_precio", "lpr_id", "lprid") and pve.get("lpr_id"):
        data["pedido_lista_precio"] = pve["lpr_id"]
    if _campo_vacio(data, "tdo_id", "tdoid", "tdoId") and pve.get("tdo_id"):
        data["tdo_id"] = pve["tdo_id"]

    return data


def _linea_cantidad_requerida(raw: dict[str, Any]) -> Decimal:
    cant = _to_decimal(
        raw.get("pvd_cantidad_vendida") or raw.get("ped_cantidad_v") or raw.get("ped_cantidad_p")
    )
    if cant is None or cant <= 0:
        return Decimal("1")
    return cant


def _requerimientos_lineas(lineas: list[OrdenLineaItem]) -> list[dict[str, Any]]:
    reqs: list[dict[str, Any]] = []
    for item in lineas:
        raw = item.model_dump(exclude_none=True)
        art_id = raw.get("art_id")
        if art_id is None or not str(art_id).strip():
            raise ValueError("Cada línea debe incluir art_id para asignar almacén")
        reqs.append(
            {
                "art_id": str(art_id).strip(),
                "uni_id": str(raw.get("uni_id") or "").strip() or None,
                "cantidad": _linea_cantidad_requerida(raw),
            }
        )
    return reqs


async def _fetch_articulos_meta(art_ids: list[str]) -> dict[str, dict[str, str | None]]:
    if not art_ids:
        return {}
    placeholders = ",".join("?" for _ in art_ids)
    rows = await database.fetch_all_dict(
        f"""
        SELECT artId AS art_id, artTipo AS art_tipo, uniId AS uni_id
        FROM {_TABLE_ARTICULO}
        WHERE artId IN ({placeholders})
        """,
        tuple(art_ids),
    )
    out: dict[str, dict[str, str | None]] = {}
    for row in rows:
        art_id = _str_db_val(row, "art_id")
        if not art_id:
            continue
        out[art_id] = {
            "art_tipo": _str_db_val(row, "art_tipo"),
            "uni_id": _str_db_val(row, "uni_id"),
        }
    return out


async def _fetch_existencia_por_almacen(
    art_ids: list[str],
    alm_ids: list[str],
) -> dict[tuple[str, str], Decimal]:
    if not art_ids or not alm_ids:
        return {}
    ph_art = ",".join("?" for _ in art_ids)
    ph_alm = ",".join("?" for _ in alm_ids)
    rows = await database.fetch_all_dict(
        f"""
        SELECT artId AS art_id, almId AS alm_id, ISNULL(exiExistencia, 0) AS existencia
        FROM {_TABLE_EXISTENCIA}
        WHERE artId IN ({ph_art}) AND almId IN ({ph_alm})
        """,
        tuple(art_ids + alm_ids),
    )
    out: dict[tuple[str, str], Decimal] = {}
    for row in rows:
        art_id = _str_db_val(row, "art_id")
        alm_id = _str_db_val(row, "alm_id")
        if not art_id or not alm_id:
            continue
        exi = _to_decimal(row.get("existencia"))
        out[(art_id, alm_id)] = exi if exi is not None else Decimal("0")
    return out


async def _existencia_venta_linea(
    pve_id: str,
    alm_id: str,
    req: dict[str, Any],
    art_meta: dict[str, dict[str, str | None]],
    existencia_map: dict[tuple[str, str], Decimal],
) -> Decimal:
    art_id = req["art_id"]
    meta = art_meta.get(art_id, {})
    exi_alm = existencia_map.get((art_id, alm_id), Decimal("0"))
    return await product_stock.existencia_venta(
        pve_id=pve_id,
        alm_id=alm_id,
        art_id=art_id,
        uni_id=req["uni_id"] or meta.get("uni_id"),
        art_tipo=meta.get("art_tipo"),
        existencia_almacen=exi_alm,
    )


async def seleccionar_almacen_para_linea(
    pve_id: str,
    req: dict[str, Any],
    almacenes: list[dict[str, Any]],
    art_meta: dict[str, dict[str, str | None]],
    existencia_map: dict[tuple[str, str], Decimal],
) -> str | None:
    """
    Elige un almId del PVE con existencia para una línea.
    Prioridad: almacén default del PVE, menor holgura, luego alm_id.
    """
    candidatos: list[tuple[str, bool, Decimal]] = []
    for alm in almacenes:
        alm_id = alm["alm_id"]
        disp = await _existencia_venta_linea(pve_id, alm_id, req, art_meta, existencia_map)
        if disp >= req["cantidad"]:
            candidatos.append((alm_id, bool(alm.get("es_default")), disp - req["cantidad"]))
    if not candidatos:
        return None
    candidatos.sort(key=lambda x: (not x[1], x[2], x[0]))
    return candidatos[0][0]


async def asignar_almacenes_lineas(
    pve_id: str,
    lineas: list[OrdenLineaItem],
) -> list[OrdenLineaItem]:
    """
    Asigna pvdDescripcion (almId) por línea según existencia en almacenes del PVE.
    Cada producto puede despacharse desde un almacén distinto.
    """
    almacenes = await pve_almacen.almacenes_de_pve(pve_id)
    if not almacenes:
        raise ValueError("El punto de venta no tiene almacenes configurados")

    reqs = _requerimientos_lineas(lineas)
    art_ids = sorted({r["art_id"] for r in reqs})
    alm_ids = [a["alm_id"] for a in almacenes]
    art_meta = await _fetch_articulos_meta(art_ids)
    existencia_map = await _fetch_existencia_por_almacen(art_ids, alm_ids)

    out: list[OrdenLineaItem] = []
    for item, req in zip(lineas, reqs):
        raw = item.model_dump(exclude_none=True)
        if raw.get("pvd_descripcion") or raw.get("ped_descripcion"):
            out.append(item)
            continue

        alm_id = await seleccionar_almacen_para_linea(
            pve_id, req, almacenes, art_meta, existencia_map
        )
        if not alm_id:
            raise ValueError(
                f"Ningún almacén del punto de venta tiene existencia para el artículo {req['art_id']}"
            )
        raw["pvd_descripcion"] = alm_id
        out.append(OrdenLineaItem(**raw))
    return out


async def aplicar_defaults_contabilidad(
    data: dict[str, Any],
    *,
    lineas: list[OrdenLineaItem] | None = None,
    fecha_doc: datetime | None = None,
) -> dict[str, Any]:
    """
    Defaults para aprobación contable (vmaGeneraAsientoVentas / cntPosteoCn).
    Solo completa campos que no vengan en el request.
    """
    if lineas and _campo_vacio(data, "vnt_articulo_moneda", "vntArticuloMoneda"):
        total_lineas = articulo_moneda_desde_lineas(lineas)
        if total_lineas > 0:
            data["vnt_articulo_moneda"] = total_lineas

    if _campo_vacio(data, "vnt_tc", "vntTC", "pedido_cambio"):
        fdoc = fecha_doc.date() if isinstance(fecha_doc, datetime) else date.today()
        tc = await tipo_cambio_para_fecha(fdoc)
        if tc is not None:
            data["vnt_tc"] = tc

    return data


def aplicar_defaults_encabezado(data: dict[str, Any]) -> dict[str, Any]:
    """Defaults de servidor para vnttxn (fecha/estado se aplican en la ruta)."""
    resp = resp_id_desde_encabezado(data)
    if resp:
        data["resp_id"] = resp
    # Siempre con factura (ignora valor del request)
    for key in ("vnt_con_factura", "vntConFactura"):
        data.pop(key, None)
    data["vnt_con_factura"] = VNT_CON_FACTURA_INSERT
    # Montos auxiliares siempre 0.000000
    for keys in _VNT_MONTOS_CERO_KEYS:
        for key in keys:
            data.pop(key, None)
        data[keys[0]] = VNT_MONTOS_CERO_INSERT
    # vntDescripcion = vntId generado
    vnt_id = _primer_str(data, "vnt_id", "vntid", "vntId")
    if vnt_id:
        for key in ("vnt_descripcion", "vntDescripcion"):
            data.pop(key, None)
        data["vnt_descripcion"] = vnt_id
    # Flags / notas fijos de servidor
    for key in ("vnt_exportado_al_fiscal", "vntExportadoAlFiscal"):
        data.pop(key, None)
    data["vnt_exportado_al_fiscal"] = VNT_EXPORTADO_AL_FISCAL_INSERT
    for key in ("vnt_anula_factura_original", "vntAnulaFacturaOriginal"):
        data.pop(key, None)
    data["vnt_anula_factura_original"] = VNT_ANULA_FACTURA_ORIGINAL_INSERT
    for key in ("vnt_nota01", "vntNota01"):
        data.pop(key, None)
    data["vnt_nota01"] = VNT_NOTA01_INSERT
    for key in ("vnt_facturar_motor_imposivo", "vntFacturarMotorImposivo"):
        data.pop(key, None)
    data["vnt_facturar_motor_imposivo"] = VNT_FACTURAR_MOTOR_IMPOSITIVO_INSERT
    # mdeid siempre NULL (ignora mde_id del request; forma de pago va a vntFPagoTxn)
    for key in ("mde_id", "mdeid", "mdeId"):
        data.pop(key, None)
    return data


def filtrar_columnas_identity(columnas: list[str], valores: list[Any]) -> tuple[list[str], list[Any]]:
    """Quita vntNumero y pvdId (IDENTITY) antes del INSERT."""
    out_c: list[str] = []
    out_v: list[Any] = []
    for c, v in zip(columnas, valores):
        if c.replace("_", "").lower() in _SKIP_INSERT_COLUMNS:
            continue
        out_c.append(c)
        out_v.append(v)
    return out_c, out_v


def aplicar_defaults_linea(payload: OrdenLineaCreate) -> OrdenLineaCreate:
    """Asigna pvdConSolicitud=N, pvdFechaCambio=ahora, descuento y codBarra."""
    data = payload.model_dump(exclude_none=False)
    for key in ("pvd_con_solicitud", "pvdConSolicitud"):
        data.pop(key, None)
    data["pvd_con_solicitud"] = PVD_CON_SOLICITUD_INSERT

    # ped_descuento_articulo (request) → pvdDescuentoArticulo
    desc = data.get("ped_descuento_articulo")
    if desc is None:
        desc = data.get("pvd_descuento_articulo")
    data.pop("ped_descuento_articulo", None)
    if desc is not None:
        data["pvd_descuento_articulo"] = _to_decimal(desc)

    # pvdFechaCambio = ahora (servidor; precisión ms como SQL datetime)
    for key in ("pvd_fecha_cambio", "pvdFechaCambio"):
        data.pop(key, None)
    ahora = datetime.now()
    data["pvd_fecha_cambio"] = ahora.replace(microsecond=(ahora.microsecond // 1000) * 1000)

    # pvdUsuario viene en claves desde vntUsuario; no pisar si ya está
    art_id = data.get("art_id")
    if art_id and not data.get("cod_barra"):
        data["cod_barra"] = str(art_id).strip()

    # Quitar None para no reintroducir campos vacíos al modelo
    cleaned = {k: v for k, v in data.items() if v is not None}
    return OrdenLineaCreate(**cleaned)


def item_a_linea_create(
    item: OrdenLineaItem,
    claves_encabezado: dict[str, Any],
    *,
    almacen_legacy: str | None = None,
) -> OrdenLineaCreate:
    merged = {**claves_encabezado, **item.model_dump(exclude_none=True)}
    # ped_descuento_articulo (request) → pvdDescuentoArticulo
    if (
        merged.get("ped_descuento_articulo") is not None
        and merged.get("pvd_descuento_articulo") is None
    ):
        merged["pvd_descuento_articulo"] = merged["ped_descuento_articulo"]
    for key in ("pvd_id", "pvdid", "pvdId", *LINEAS_SOLO_API):
        merged.pop(key, None)
    # Usuario del encabezado gana sobre cualquier valor de la línea
    if claves_encabezado.get("pvd_usuario"):
        merged["pvd_usuario"] = claves_encabezado["pvd_usuario"]
    if merged.get("ped_cantidad_v") is not None and merged.get("ped_cantidad_p") is None:
        merged["ped_cantidad_p"] = merged["ped_cantidad_v"]
    almacen = (
        merged.get("pvd_descripcion")
        or merged.get("ped_descripcion")
        or almacen_legacy
    )
    linea = OrdenLineaCreate(**merged)
    linea = aplicar_almacen_linea(linea, almacen)
    return aplicar_defaults_linea(linea)


def _primer_str(data: dict[str, Any], *keys: str) -> str | None:
    for key in keys:
        val = data.get(key)
        if val is None:
            continue
        s = str(val).strip()
        if s:
            return s
    return None


def destino_ingreso_desde_forma_pago(fpa_id: str) -> str:
    """TRANSFER → B, CONCTACTE → C; resto → C (default observado en ERP)."""
    f = fpa_id.strip().upper()
    if f == "TRANSFER":
        return "B"
    if f == "CONCTACTE":
        return "C"
    return FPT_DESTINO_INGRESO_DEFAULT


_SQL_DIR_NRO_DIAS = """
SELECT TOP 1 dirNroDiasCliente AS dias
FROM gntDirectorio
WHERE dirId = ?
"""

_SQL_PAR_DIAS_DEBITO = """
SELECT TOP 1 parDiasDefaultDebito AS dias
FROM cttParametro
"""

# Columna con ñ en SQL Server (fptDiasAño)
_COL_FPT_DIAS_ANIO = "fptDiasAño"


async def fetch_dir_nro_dias_cliente(dir_id: str) -> int:
    """dirNroDiasCliente del cliente (gntDirectorio)."""
    row = await database.fetch_one_dict(_SQL_DIR_NRO_DIAS, (dir_id.strip(),))
    if not row or row.get("dias") is None:
        return 0
    try:
        return int(row["dias"])
    except (TypeError, ValueError):
        return 0


async def fetch_par_dias_default_debito() -> int:
    """parDiasDefaultDebito desde cttParametro."""
    row = await database.fetch_one_dict(_SQL_PAR_DIAS_DEBITO)
    if not row or row.get("dias") is None:
        return 0
    try:
        return int(row["dias"])
    except (TypeError, ValueError):
        return 0


async def preparar_datos_fpago(
    encabezado: OrdenEncabezadoCreate | dict[str, Any],
) -> dict[str, Any]:
    """
    Resuelve datos de vntFPagoTxn.
    fpaReferencia = pedido_pago_dir;
    fptReferenciaIngreso = pedido_pago_referencia;
    fptUsuario = RUC del request (vntRUC / cliente_ruc);
    fptPlazo = 30; fptDiasAño = 30;
    fptNroDocumento = vntId solo si fpaid=TRANSFER (se aplica al armar columnas).
    """
    if isinstance(encabezado, OrdenEncabezadoCreate):
        data = encabezado.model_dump(exclude_none=False)
    else:
        data = dict(encabezado)

    fpa_id = _primer_str(data, "pedido_forma_pago", "fpaid", "fpa_id")
    if not fpa_id:
        raise ValueError("pedido_forma_pago es obligatorio para insertar vntFPagoTxn")

    mon_id = _primer_str(data, "pedido_moneda", "mon_id", "monid", "monId")
    if not mon_id:
        raise ValueError("No hay moneda en el encabezado para vntFPagoTxn (monid)")

    monto = data.get("pedido_total")
    if monto is None:
        monto = data.get("vnt_total_moneda")
    if monto is None:
        raise ValueError("No hay monto (pedido_total) para vntFPagoTxn (fptMontoMoneda)")

    fpa_referencia = _primer_str(
        data, "pedido_pago_dir", "fpa_referencia", "fpaReferencia"
    )
    if not fpa_referencia:
        raise ValueError(
            "pedido_pago_dir es obligatorio para vntFPagoTxn.fpaReferencia "
            "(directorio de la cuenta bancaria)"
        )

    ruc = _primer_str(data, "vnt_ruc", "pedido_nit", "vntRUC", "cliente_ruc")
    if not ruc:
        raise ValueError(
            "No hay RUC (cliente_ruc / vntRUC) para vntFPagoTxn.fptUsuario"
        )

    fecha_ref = data.get("vnt_fecha_doc") or data.get("pedido_fecha")
    if fecha_ref is None:
        fecha_ref = datetime.now()

    return {
        "fpa_id": fpa_id,
        "mon_id": mon_id,
        "monto": _to_decimal(monto),
        "fecha_ref": fecha_ref,
        "usuario": ruc,
        "cobros_qr": _primer_str(data, "pedido_pago_qr", "fpt_cobros_qr", "fptCobrosQR"),
        "fpa_referencia": fpa_referencia,
        "referencia_ingreso": _primer_str(
            data, "pedido_pago_referencia", "fpt_referencia_ingreso", "fptReferenciaIngreso"
        ),
        "fpt_dias_anio": FPT_DIAS_ANIO_INSERT,
        "fpt_plazo": FPT_PLAZO_INSERT,
        "destino_ingreso": destino_ingreso_desde_forma_pago(fpa_id),
        "es_transfer": fpa_id.strip().upper() == "TRANSFER",
    }


def columnas_valores_fpago(
    datos: dict[str, Any],
    vnt_id: str,
) -> tuple[list[str], list[Any]]:
    """
    Arma INSERT vntFPagoTxn.
    fptNroDocumento = vntId solo si TRANSFER; resto sin esa columna (NULL).
    fptPeriodoCapital / fptFormaPagoCapital / fptPeriodoInteres / fptNota / fptDiaFijo
    se omiten → NULL en BD.
    """
    columnas = [
        "vntid",
        "monid",
        "fpaid",
        "fpaReferencia",
        "fpaFechaReferencia",
        "fptMontoMoneda",
        "fptUsuario",
        "fptFechaCambio",
        "fptTasaPenal",
        "fptDestinoIngreso",
        "fpaDF",
        "fptTipoRecargo",
        "fptCobrosQR",
        "fptReferenciaIngreso",
        "fptPlazo",
        _COL_FPT_DIAS_ANIO,
    ]
    valores: list[Any] = [
        vnt_id.strip(),
        datos["mon_id"],
        datos["fpa_id"],
        datos["fpa_referencia"],
        datos["fecha_ref"],
        datos["monto"],
        datos.get("usuario"),
        datetime.now(),
        FPT_TASA_PENAL_DEFAULT,
        datos["destino_ingreso"],
        FPA_DF_DEFAULT,
        FPT_TIPO_RECARGO_DEFAULT,
        datos.get("cobros_qr"),
        datos.get("referencia_ingreso"),
        datos.get("fpt_plazo", FPT_PLAZO_INSERT),
        datos.get("fpt_dias_anio", FPT_DIAS_ANIO_INSERT),
    ]
    if datos.get("es_transfer"):
        columnas.append("fptNroDocumento")
        valores.append(vnt_id.strip())
    return columnas, valores
