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
PVD_CON_SOLICITUD_INSERT = "N"
FPT_TIPO_RECARGO_DEFAULT = 0
FPT_TASA_PENAL_DEFAULT = Decimal("0")
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
SELECT TOP 1 dirId AS dir_id
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
    Si no hay registro, lanza ValueError.
    """
    ruc_val = data.get("cliente_ruc")
    if ruc_val is None or not str(ruc_val).strip():
        return data

    ruc = str(ruc_val).strip()
    if not _campo_vacio(data, "pedido_cliente", "cli_id", "cliid"):
        data.pop("cliente_ruc", None)
        return data

    row = await database.fetch_one_dict(_SQL_DIR_ID_POR_RUC, (ruc,))
    dir_id = _str_db_val(row, "dir_id") if row else None
    if not dir_id:
        raise ValueError("No existe cliente")

    data["pedido_cliente"] = dir_id
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
    """Asigna pvdConSolicitud = N y codBarra = artId si no viene cod_barra."""
    data = payload.model_dump(exclude_none=True)
    for key in ("pvd_con_solicitud", "pvdConSolicitud"):
        data.pop(key, None)
    data["pvd_con_solicitud"] = PVD_CON_SOLICITUD_INSERT
    art_id = data.get("art_id")
    if art_id and not data.get("cod_barra"):
        data["cod_barra"] = str(art_id).strip()
    return OrdenLineaCreate(**data)


def item_a_linea_create(
    item: OrdenLineaItem,
    claves_encabezado: dict[str, Any],
    *,
    almacen_legacy: str | None = None,
) -> OrdenLineaCreate:
    merged = {**claves_encabezado, **item.model_dump(exclude_none=True)}
    for key in ("pvd_id", "pvdid", "pvdId", *LINEAS_SOLO_API):
        merged.pop(key, None)
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


def columnas_valores_fpago(
    encabezado: OrdenEncabezadoCreate | dict[str, Any],
    vnt_id: str,
) -> tuple[list[str], list[Any]]:
    """
    Arma INSERT de vntFPagoTxn con defaults ERP y overrides del request:
    fpaid, fptCobrosQR, fpaReferencia, fptDestinoIngreso.
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

    fecha_ref = data.get("vnt_fecha_doc") or data.get("pedido_fecha")
    if fecha_ref is None:
        fecha_ref = datetime.now()

    usuario = _primer_str(data, "pedido_usuario", "vnt_usuario", "vntUsuario")
    cobros_qr = _primer_str(data, "pedido_pago_qr", "fpt_cobros_qr", "fptCobrosQR")
    referencia = _primer_str(
        data, "pedido_pago_referencia", "fpa_referencia", "fpaReferencia"
    )

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
    ]
    valores: list[Any] = [
        vnt_id.strip(),
        mon_id,
        fpa_id,
        referencia,
        fecha_ref,
        _to_decimal(monto),
        usuario,
        datetime.now(),
        FPT_TASA_PENAL_DEFAULT,
        destino_ingreso_desde_forma_pago(fpa_id),
        FPA_DF_DEFAULT,
        FPT_TIPO_RECARGO_DEFAULT,
        cobros_qr,
    ]
    return columnas, valores
