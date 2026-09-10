"""
Rutas de órdenes: encabezado, líneas de detalle, orden completa (vnttxn)
y listado legacy (tabla Ordenes).
"""
from decimal import Decimal
from typing import Any

import pyodbc
from fastapi import APIRouter, HTTPException, Query

from app.core import database
from app.schemas.order import OrdenListResponse, OrdenResponse
from app.schemas.order_completa import OrdenCompletaCreate
from app.schemas.order_encabezado import OrdenEncabezadoCreate, filas_a_columnas_sql
from app.schemas.order_lineas import OrdenLineaCreate, linea_a_columnas_sql
from app.services import order_erp

_SP_GENERAR_ID = "dbo.gnpGenerarIdUno"
_GNP_VNT_ID_DEFAULTS = {
    "str_tipo_txn": "VEN",
    "var_generacion_id": "M",
    "str_tabla": "vntTxn",
    "str_campo_id": "vntId",
}

router = APIRouter(prefix="/orders", tags=["Órdenes"])

_TABLE_ENCABEZADO = "vnttxn"
_TABLE_LINEAS = "vntdettxn"
_TABLE_FPAGO = "vntFPagoTxn"

# PK por tabla para recuperar la fila insertada (sin OUTPUT INSERTED.*)
_TABLE_PK: dict[str, list[str]] = {
    _TABLE_ENCABEZADO: ["vntid"],
    _TABLE_LINEAS: ["pvdId"],
    _TABLE_FPAGO: ["fptId"],
}


def _insert_row(cursor: pyodbc.Cursor, table: str, columnas: list[str], valores: list[Any]) -> dict:
    if not columnas:
        raise ValueError("No hay campos para insertar")
    columnas, valores = order_erp.filtrar_columnas_identity(columnas, valores)
    if not columnas:
        raise ValueError("No hay campos para insertar (solo columnas IDENTITY)")
    row = database.insert_and_fetch_row(
        cursor,
        table,
        columnas,
        valores,
        _TABLE_PK.get(table),
    )
    if not row:
        raise RuntimeError("INSERT realizado pero no se pudo recuperar la fila insertada")
    return row


def _insert_identity_row(
    cursor: pyodbc.Cursor,
    table: str,
    identity_col: str,
    columnas: list[str],
    valores: list[Any],
    *,
    fallback_col: str | None = None,
) -> dict:
    """
    INSERT en tabla con PK identity y recupera la fila.

    SCOPE_IDENTITY() debe ir en el mismo batch que el INSERT. Si falla, intenta
    fallback por una columna de negocio (ej. vntid ORDER BY identity DESC).
    """
    if not columnas:
        raise ValueError(f"No hay campos para insertar en {table}")

    insert_sql = database.build_insert_sql(table, columnas)
    sql = (
        f"{insert_sql}; "
        f"SELECT TOP 1 * FROM {database.bracket_ident(table)} "
        f"WHERE {database.bracket_ident(identity_col)} = SCOPE_IDENTITY();"
    )
    cursor.execute(sql, tuple(valores))

    row: dict[str, Any] | None = None
    while True:
        if cursor.description is not None:
            row = database.cursor_row_to_dict(cursor)
            if row:
                break
        if not cursor.nextset():
            break

    if not row and fallback_col:
        fb_idx = next(
            (i for i, c in enumerate(columnas) if c.lower() == fallback_col.lower()),
            None,
        )
        if fb_idx is not None and valores[fb_idx] is not None:
            cursor.execute(
                f"SELECT TOP 1 * FROM {database.bracket_ident(table)} "
                f"WHERE {database.bracket_ident(fallback_col)} = ? "
                f"ORDER BY {database.bracket_ident(identity_col)} DESC",
                (valores[fb_idx],),
            )
            row = database.cursor_row_to_dict(cursor)

    if not row:
        raise RuntimeError(
            f"INSERT en {table} realizado pero no se recuperó la fila: {valores!s}"
        )
    return row


def _insert_fpago_row(cursor: pyodbc.Cursor, columnas: list[str], valores: list[Any]) -> dict:
    """INSERT en vntFPagoTxn (PK identity fptId)."""
    return _insert_identity_row(
        cursor,
        _TABLE_FPAGO,
        "fptId",
        columnas,
        valores,
        fallback_col="vntid",
    )


def _insert_linea_row(cursor: pyodbc.Cursor, columnas: list[str], valores: list[Any]) -> dict:
    """INSERT en vntdettxn (PK identity pvdId)."""
    columnas, valores = order_erp.filtrar_columnas_identity(columnas, valores)
    return _insert_identity_row(
        cursor,
        _TABLE_LINEAS,
        "pvdId",
        columnas,
        valores,
        fallback_col="vntid",
    )


def _http_error_from_db(e: Exception, contexto: str, table: str) -> HTTPException:
    err = str(e).lower()
    msg = str(e)
    if "invalid object name" in err or "42s02" in err:
        return HTTPException(
            status_code=503,
            detail=f"Revise el nombre de la tabla ({table}): {e!s}",
        )
    if "779257" in msg or "779367" in msg or "778543" in msg:
        return HTTPException(
            status_code=400,
            detail={
                "mensaje": contexto,
                "error_erp": msg,
                "sugerencia": (
                    "Error de trigger ERP. Revise maestros del encabezado, "
                    "precios vs lista (lprid) y campos de línea; en SSMS use "
                    "scripts/ejemplo_insert_orden_completa.sql."
                ),
            },
        )
    if "778967" in msg or "779083" in msg or "779585" in msg:
        return HTTPException(
            status_code=400,
            detail={
                "mensaje": contexto,
                "error_erp": msg,
                "sugerencia": (
                    "Trigger vntFPagoTxn_ITrig: fpaid∈gntFPago (778967), "
                    "monid∈gntMoneda (779083), vntid∈vntTxn (779585)."
                ),
            },
        )
    return HTTPException(status_code=503, detail=f"{contexto}: {e!s}")


def _get_row_value(row: dict[str, Any], *keys: str) -> Any:
    lower_map = {k.lower(): v for k, v in row.items()}
    for key in keys:
        if key in row and row[key] is not None:
            return row[key]
        lk = key.lower()
        if lk in lower_map and lower_map[lk] is not None:
            return lower_map[lk]
    return None


def _claves_linea_desde_encabezado(
    encabezado_row: dict[str, Any],
    encabezado_payload: OrdenEncabezadoCreate,
) -> dict[str, Any]:
    """Extrae vntid del encabezado para propagar a cada línea (vntdettxn)."""
    claves: dict[str, Any] = {}
    vnt_id = _get_row_value(encabezado_row, "vntid", "vntId", "VNTID")
    if vnt_id is not None:
        claves["vnt_id"] = str(vnt_id)
    return claves


def _row_to_orden_response(row: dict[str, Any]) -> OrdenResponse:
    """Convierte una fila dict a OrdenResponse (tabla legacy Ordenes)."""
    return OrdenResponse(
        id=row["id"],
        cliente_id=row["cliente_id"],
        fecha_orden=row["fecha_orden"],
        total=Decimal(str(row["total"])),
        estado=row["estado"],
        creado_en=row.get("creado_en"),
        actualizado_en=row.get("actualizado_en"),
    )


async def _generar_vnt_id(str_tipo_txn: str | None = None) -> str:
    """Genera vntId llamando a dbo.gnpGenerarIdUno (ventas / vntTxn)."""
    tipo = (str_tipo_txn or _GNP_VNT_ID_DEFAULTS["str_tipo_txn"]).strip() or "VEN"
    try:
        row = await database.execute_gnp_generar_id_uno(
            tipo,
            _GNP_VNT_ID_DEFAULTS["var_generacion_id"],
            _GNP_VNT_ID_DEFAULTS["str_tabla"],
            _GNP_VNT_ID_DEFAULTS["str_campo_id"],
        )
    except Exception as e:
        raise HTTPException(
            status_code=503,
            detail=f"Error al ejecutar {_SP_GENERAR_ID}: {e!s}",
        ) from e

    if not row:
        raise HTTPException(
            status_code=503,
            detail=f"{_SP_GENERAR_ID} no devolvió resultado",
        )

    mensaje = (row.get("mensaje") or "").strip()
    nuevo_id = (row.get("nuevo_id") or "").strip()
    return_code = int(row.get("return_code") or 0)

    if mensaje:
        raise HTTPException(
            status_code=400,
            detail={
                "mensaje": mensaje,
                "return_code": return_code,
                "nuevo_id": nuevo_id,
            },
        )

    if not nuevo_id:
        raise HTTPException(
            status_code=503,
            detail=f"{_SP_GENERAR_ID} no generó vntId (return_code={return_code})",
        )

    return nuevo_id


async def _preparar_encabezado(
    payload: OrdenEncabezadoCreate,
    *,
    lineas: list | None = None,
) -> OrdenEncabezadoCreate:
    """Genera vnt_id, vntFechaDoc, vntEstado=R, vntConFactura=1, ttxId y defaults ERP en servidor."""
    tipo_txn = payload.ttx_id or payload.pedido_tipo or _GNP_VNT_ID_DEFAULTS["str_tipo_txn"]
    vnt_id = await _generar_vnt_id(tipo_txn)
    data = payload.model_dump(exclude_none=True)
    
    for key in ("vnt_id", "vntid", "vntId"):
        data.pop(key, None)

    data["vnt_id"] = vnt_id
    fecha_doc = order_erp.vnt_fecha_doc_hoy()
    data["vnt_fecha_doc"] = fecha_doc
    data["vnt_estado"] = order_erp.VNT_ESTADO_INSERT
    if not data.get("ttx_id") and not data.get("pedido_tipo"):
        data["ttx_id"] = tipo_txn
    try:
        data = await order_erp.resolver_cliente_desde_ruc(data)
        data = await order_erp.aplicar_defaults_desde_pve(data)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e)) from e
    data = order_erp.aplicar_defaults_encabezado(data)
    data = await order_erp.aplicar_defaults_contabilidad(
        data,
        lineas=lineas,
        fecha_doc=fecha_doc,
    )
    return OrdenEncabezadoCreate(**data)


async def _insert_encabezado(payload: OrdenEncabezadoCreate) -> dict[str, Any]:
    payload = await _preparar_encabezado(payload)
    columnas, valores = filas_a_columnas_sql(payload)
    if not columnas:
        raise HTTPException(status_code=400, detail="No hay campos para insertar en el encabezado")
    try:
        row = await database.insert_and_fetch_dict(
            _TABLE_ENCABEZADO,
            columnas,
            valores,
            _TABLE_PK.get(_TABLE_ENCABEZADO),
        )
    except HTTPException:
        raise
    except Exception as e:
        raise _http_error_from_db(e, "Error al insertar encabezado", _TABLE_ENCABEZADO) from e
    return row or {}


async def _insert_linea(payload: OrdenLineaCreate) -> dict[str, Any]:
    payload = order_erp.aplicar_defaults_linea(payload)
    try:
        usuario_sql = await order_erp.usuario_sql_sistema()
        data = payload.model_dump(exclude_none=True)
        data["pvd_usuario"] = usuario_sql
        payload = OrdenLineaCreate(**data)
    except Exception as e:
        raise HTTPException(
            status_code=503,
            detail=f"Error al obtener SYSTEM_USER: {e!s}",
        ) from e
    columnas, valores = linea_a_columnas_sql(payload)
    columnas, valores = order_erp.filtrar_columnas_identity(columnas, valores)
    if not columnas:
        raise HTTPException(status_code=400, detail="No hay campos para insertar en la línea")
    try:
        row = await database.insert_and_fetch_dict(
            _TABLE_LINEAS,
            columnas,
            valores,
            _TABLE_PK.get(_TABLE_LINEAS),
        )
    except HTTPException:
        raise
    except Exception as e:
        raise _http_error_from_db(e, "Error al insertar línea", _TABLE_LINEAS) from e
    return row or {}


async def _ejecutar_aprobacion_ecommerce(vnt_id: str) -> dict[str, Any]:
    """Ejecuta dbo.nvnpAprobarTxnEcommerce para una orden VEN en estado R."""
    vnt_id = vnt_id.strip()
    if not vnt_id:
        raise HTTPException(status_code=400, detail="vnt_id es obligatorio")
    try:
        return await database.execute_nvnp_aprobar_txn_ecommerce(vnt_id)
    except Exception as e:
        raise HTTPException(
            status_code=503,
            detail=f"Error al ejecutar nvnpAprobarTxnEcommerce: {e!s}",
        ) from e


def _respuesta_aprobacion(vnt_id: str, aprobacion: dict[str, Any]) -> dict[str, Any]:
    str_mensaje = aprobacion.get("str_mensaje") or ""
    str_url = aprobacion.get("str_url") or ""
    return {
        "status": "ok" if not str_mensaje else "error_aprobacion",
        "vnt_id": vnt_id,
        "str_mensaje": str_mensaje,
        "str_url": str_url,
        "return_code": aprobacion.get("return_code", 0),
    }


@router.post("", status_code=201)
async def crear_orden_completa(payload: OrdenCompletaCreate):
    """
    Crea una **orden completa** en un solo request: encabezado + líneas de productos.

    ## Flujo
    1. Asigna fecha actual, `vntEstado = R`, `ttxId` (default `VEN`), `respId`, `vntArticuloMoneda`, `vntTC`, `tdoId` y genera `vnt_id`.
    2. Inserta encabezado en `vnttxn`, luego líneas en `vntdettxn` (`pvdConSolicitud = N`)
       y al final la forma de pago en `vntFPagoTxn`.
       Por cada línea asigna `pvdDescripcion` = almacén del PVE con existencia para ese artículo.
    3. Si viene `datos_envio`, se agrega como línea extra (`uni_id=PZA`, cantidades=1).

    Forma de pago (`vntFPagoTxn`):
    - `fpaid` ← `pedido_forma_pago` (obligatorio)
    - `fptCobrosQR` ← `pedido_pago_qr`
    - `fptReferenciaIngreso` ← `pedido_pago_referencia`
    - `fpaReferencia` ← `pedido_pago_dir` (directorio banco)
    - `fptUsuario` ← `SYSTEM_USER` si pago QR (`pedido_pago_qr=S`); si no, RUC
    - Sin QR: `fptPlazo`/`fptDiasAño` = 30
    - Pago QR: `fptPeriodoCapital`/`fptPeriodoInteres`=0, formas=`AVP`,
      `fptNota`=`vntId`, `fptDiaFijo`=0, `fptDiasAño`=360
    - `fptNroDocumento` ← `vntId` solo si `TRANSFER`; resto NULL
    - `fptDestinoIngreso` ← `B` si TRANSFER, `C` si CONCTACTE (resto `C`)
    - resto de columnas con defaults ERP (monto, moneda, fecha, etc.)

    La aprobación ERP (`dbo.nvnpAprobarTxnEcommerce`) es un paso aparte: `POST /api/orders/{vnt_id}/aprobar`.

    Validaciones de maestros/catálogo: fase posterior (no aplicadas).

    ## Ejemplo
    Ver `request.json` y su documentación en `request.md`.
    ```json
    {
      "status": "ok",
      "encabezado": { "...": "fila insertada en vnttxn" },
      "lineas": [ { "...": "fila 1" }, { "...": "fila 2" } ],
      "total_lineas": 2
    }
    ```
    """
    lineas = payload.lineas_con_envio()
    encabezado_payload = await _preparar_encabezado(
        payload.encabezado,
        lineas=lineas,
    )

    pve_id = order_erp.pve_id_desde_encabezado(encabezado_payload.model_dump(exclude_none=True))
    if pve_id:
        try:
            lineas = await order_erp.asignar_almacenes_lineas(pve_id, lineas)
        except ValueError as e:
            raise HTTPException(status_code=400, detail=str(e)) from e

    try:
        datos_fpago = await order_erp.preparar_datos_fpago(encabezado_payload)
        usuario_sql = await order_erp.usuario_sql_sistema()
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e)) from e
    except Exception as e:
        raise HTTPException(
            status_code=503,
            detail=f"Error al preparar forma de pago: {e!s}",
        ) from e

    def _tx(cursor: pyodbc.Cursor) -> tuple[dict[str, Any], list[dict[str, Any]], dict[str, Any]]:
        col_enc, val_enc = filas_a_columnas_sql(encabezado_payload)
        col_enc, val_enc = order_erp.filtrar_columnas_identity(col_enc, val_enc)

        encabezado_row = _insert_row(cursor, _TABLE_ENCABEZADO, col_enc, val_enc)
        claves = _claves_linea_desde_encabezado(encabezado_row, encabezado_payload)
        almacen_legacy = order_erp.almacen_desde_encabezado(encabezado_payload)

        vnt_id = str(claves.get("vnt_id") or "").strip()
        if not vnt_id:
            raise RuntimeError("No se pudo obtener vnt_id tras insertar el encabezado")

        lineas_rows: list[dict[str, Any]] = []
        for idx, item in enumerate(lineas, start=1):
            linea = order_erp.item_a_linea_create(
                item,
                claves,
                almacen_legacy=almacen_legacy,
                usuario_sql=usuario_sql,
            )
            col_lin, val_lin = linea_a_columnas_sql(linea)
            col_lin, val_lin = order_erp.filtrar_columnas_identity(col_lin, val_lin)
            try:
                lineas_rows.append(_insert_linea_row(cursor, col_lin, val_lin))
            except Exception as e:
                raise RuntimeError(f"Error en línea {idx}: {e!s}") from e

        col_fp, val_fp = order_erp.columnas_valores_fpago(datos_fpago, vnt_id)
        fpago_row = _insert_fpago_row(cursor, col_fp, val_fp)
        return encabezado_row, lineas_rows, fpago_row

    try:
        encabezado_row, lineas_rows, fpago_row = await database.run_transaction(_tx)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e)) from e
    except RuntimeError as e:
        err = str(e).lower()
        if "invalid object name" in err or "42s02" in err:
            raise HTTPException(status_code=503, detail=str(e)) from e
        if "779257" in str(e) or "779367" in str(e) or "778543" in str(e):
            raise _http_error_from_db(e, f"Trigger ERP al insertar", _TABLE_LINEAS) from e
        raise HTTPException(status_code=503, detail=str(e)) from e
    except Exception as e:
        raise _http_error_from_db(e, "Error al crear la orden completa", _TABLE_ENCABEZADO) from e

    return {
        "status": "ok",
        "encabezado": encabezado_row,
        "forma_pago": fpago_row,
        "lineas": lineas_rows,
        "total_lineas": len(lineas_rows),
    }


@router.post("/encabezado", status_code=201)
async def crear_orden_encabezado(payload: OrdenEncabezadoCreate):
    """
    **Fase 1:** crea solo el encabezado del pedido (INSERT en la tabla configurada).

    El body usa nombres en snake_case; se mapean a columnas de `vnttxn` (p. ej. `pedido_cliente` → `cliid`).
    `vnt_id` se genera con `gnpGenerarIdUno` (VEN / vntTxn). `vntEstado` siempre es R en servidor.
    No envíes `vnt_id` ni `pedido_estado` en el body.
    """
    row = await _insert_encabezado(payload)
    return {"status": "ok", "body": row}


@router.post("/lineas", status_code=201)
async def crear_orden_linea(payload: OrdenLineaCreate):
    """
    **Fase 2:** inserta una línea de pedido (detalle de productos).

    El body usa snake_case (`vnt_id`, `art_id`, `pvd_precio_moneda`, …) mapeados a
    columnas de `vntdettxn`. `pvdConSolicitud` se asigna en servidor siempre como `N`.
    """
    row = await _insert_linea(payload)
    return {"status": "ok", "body": row}


@router.post("/{vnt_id}/aprobar")
async def aprobar_orden_ecommerce(vnt_id: str):
    """
    Aprueba una orden VEN previamente insertada (estado `R`) en el ERP.

    Ejecuta `dbo.nvnpAprobarTxnEcommerce` con el `vnt_id` indicado.
    `str_mensaje` vacío = aprobación OK; con texto = error ERP (la orden ya existe en BD).
    """
    vnt_id = vnt_id.strip()
    aprobacion = await _ejecutar_aprobacion_ecommerce(vnt_id)
    return _respuesta_aprobacion(vnt_id, aprobacion)


@router.get("", response_model=OrdenListResponse)
async def listar_ordenes(
    skip: int = Query(0, ge=0, description="Registros a saltar"),
    limit: int = Query(20, ge=1, le=100, description="Máximo de registros"),
    cliente_id: int | None = Query(None, description="Filtrar por cliente"),
    estado: str | None = Query(None, description="Filtrar por estado"),
) -> OrdenListResponse:
    """Lista órdenes (tabla Ordenes) con paginación y filtros opcionales."""
    conditions = []
    params: list = []

    if cliente_id is not None:
        conditions.append("cliente_id = ?")
        params.append(cliente_id)

    if estado:
        conditions.append("estado = ?")
        params.append(estado)

    where = ("WHERE " + " AND ".join(conditions)) if conditions else ""
    params.extend([skip, limit])

    query = f"""
        SELECT id, cliente_id, fecha_orden, total, estado, creado_en, actualizado_en
        FROM Ordenes
        {where}
        ORDER BY id
        OFFSET ? ROWS FETCH NEXT ? ROWS ONLY
    """
    count_query = "SELECT COUNT(*) AS total FROM Ordenes " + (
        " WHERE " + " AND ".join(conditions) if conditions else ""
    )
    count_params = params[:-2] if params else ()

    try:
        rows = await database.fetch_all_dict(query, tuple(params))
        count_result = await database.fetch_one_dict(
            count_query, tuple(count_params) if count_params else ()
        )
        total = count_result["total"] if count_result else 0
    except Exception as e:
        raise HTTPException(
            status_code=503,
            detail=f"Error al conectar con la base de datos: {e!s}",
        ) from e

    items = [_row_to_orden_response(r) for r in rows]
    return OrdenListResponse(items=items, total=total)


@router.get("/{vnt_id}")
async def obtener_orden(vnt_id: str):
    """
    Obtiene una orden ERP por `vntId` (ej. `PVEN125040`).

    Lee encabezado (`vnttxn`), líneas (`vntdettxn`) y forma de pago (`vntFPagoTxn`).
    """
    vnt_id = (vnt_id or "").strip()
    if not vnt_id:
        raise HTTPException(status_code=400, detail="vnt_id no puede estar vacío")

    try:
        encabezado = await database.fetch_one_dict(
            f"""
            SELECT *
            FROM {_TABLE_ENCABEZADO}
            WHERE LTRIM(RTRIM(vntid)) = ?
            """,
            (vnt_id,),
        )
        if not encabezado:
            raise HTTPException(status_code=404, detail="Orden no encontrada")

        lineas = await database.fetch_all_dict(
            f"""
            SELECT *
            FROM {_TABLE_LINEAS}
            WHERE LTRIM(RTRIM(vntid)) = ?
            ORDER BY pvdId
            """,
            (vnt_id,),
        )
        forma_pago = await database.fetch_all_dict(
            f"""
            SELECT *
            FROM {_TABLE_FPAGO}
            WHERE LTRIM(RTRIM(vntid)) = ?
            ORDER BY fptId
            """,
            (vnt_id,),
        )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=503,
            detail=f"Error al consultar la orden: {e!s}",
        ) from e

    return {
        "status": "ok",
        "vnt_id": vnt_id,
        "encabezado": encabezado,
        "lineas": lineas or [],
        "forma_pago": forma_pago or [],
        "total_lineas": len(lineas or []),
    }
