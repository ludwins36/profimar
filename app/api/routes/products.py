"""
Rutas de productos: obtención de registros desde intArticulo.
"""
from decimal import Decimal
from typing import Any, Optional

from fastapi import APIRouter, HTTPException, Query

from app.core import database
from app.schemas.product import (
    PrecioCantidadItem,
    PrecioCantidadListResponse,
    ProductoListResponse,
    ProductoResponse,
)
from app.services import product_precio, pve_almacen

router = APIRouter(prefix="/products", tags=["Productos"])

_TABLE = "intArticulo"
_TABLE_EXISTENCIA = "intexistencia"
_TABLE_PRECIO_CANTIDAD = "vntListaPrecioCantidad"
_COLS = (
    "a.artId, a.artNombre, a.garId, a.uniid, a.artCodigoFabrica, a.artPrecioVenta, "
    "a.artPrecioVentaDos, a.artPrecioVentaTres, a.artPrecioVentaCuatro, a.artPrecioVentaCinco, "
    "a.artMarca, a.monid, a.carId, a.artTipo"
)
_COLS_PRECIO_CANTIDAD = (
    "cantId, lprid, artId, cantInicial, cantFinal, cantPrecio, monid, horid"
)

# Almacenes del PVE: gntPuntoVentaAlmacen + almId default de gntPuntoventa.
_JOIN_EXISTENCIA_PVE = f"""
LEFT JOIN {_TABLE_EXISTENCIA} e
    ON e.artId = a.artId
   AND LTRIM(RTRIM(e.almId)) IN (
        SELECT LTRIM(RTRIM(w.alm_id))
        FROM (
            SELECT pveId, LTRIM(RTRIM(almId)) AS alm_id FROM gntPuntoVentaAlmacen
            UNION ALL
            SELECT pveId, LTRIM(RTRIM(almId)) AS alm_id FROM gntPuntoventa
        ) AS w
        WHERE w.pveId = ?
          AND w.alm_id IS NOT NULL
          AND LTRIM(RTRIM(w.alm_id)) <> ''
    )
"""


def _safe_decimal(v: Any, default: Optional[Decimal] = None) -> Optional[Decimal]:
    if v is None:
        return default
    s = str(v).strip()
    if not s or s.upper() == "NONE":
        return default
    try:
        return Decimal(s)
    except Exception:
        return default


def _safe_int(v: Any) -> Optional[int]:
    if v is None:
        return None
    s = str(v).strip()
    if not s:
        return None
    try:
        return int(s)
    except (ValueError, TypeError):
        return None


def _row_to_producto_response(row: dict[str, Any]) -> ProductoResponse:
    precios_raw = row.get("precios_cantidad") or []
    precios = [
        PrecioCantidadItem(**p) if isinstance(p, dict) else p
        for p in precios_raw
    ]
    return ProductoResponse(
        id=str(row["artId"]),
        nombre=row["artNombre"] or "",
        moneda_id=row["monid"] or "",
        categoria_id=row["carId"] or "",
        gar_id=_safe_int(row.get("garId")),
        uni_id=str(row["uniid"]).strip() if row.get("uniid") is not None else None,
        codigo_fabrica=row.get("artCodigoFabrica"),
        precio_venta=_safe_decimal(row.get("artPrecioVenta"), Decimal("0")) or Decimal("0"),
        precio_venta_dos=_safe_decimal(row.get("artPrecioVentaDos")),
        precio_venta_tres=_safe_decimal(row.get("artPrecioVentaTres")),
        precio_venta_cuatro=_safe_decimal(row.get("artPrecioVentaCuatro")),
        precio_venta_cinco=_safe_decimal(row.get("artPrecioVentaCinco")),
        marca=row.get("artMarca"),
        art_tipo=str(row.get("artTipo")).strip() if row.get("artTipo") is not None else None,
        existencia=_safe_decimal(row.get("existencia_almacen"), Decimal("0")) or Decimal("0"),
        lista_precio=str(row["lista_precio"]).strip() if row.get("lista_precio") else None,
        precios_cantidad=precios,
    )


async def _resolver_lista_precio(
    *,
    lpr_id: Optional[str],
    pve_id: Optional[str],
) -> Optional[str]:
    if lpr_id and lpr_id.strip():
        return lpr_id.strip()
    if not pve_id:
        return None
    pve = await pve_almacen.obtener_punto_venta(pve_id)
    if not pve:
        return None
    return pve.get("lista_precio_id")


async def _aplicar_precios_cantidad(
    rows: list[dict[str, Any]],
    *,
    lpr_id: Optional[str],
) -> list[dict[str, Any]]:
    out: list[dict[str, Any]] = []
    if not rows:
        return out
    if not lpr_id:
        for row in rows:
            row = dict(row)
            row["precios_cantidad"] = []
            out.append(row)
        return out

    art_ids = [str(r["artId"]) for r in rows if r.get("artId") is not None]
    tramos = await product_precio.tramos_por_articulos(art_ids, lpr_id)
    for row in rows:
        row = dict(row)
        row["lista_precio"] = lpr_id
        art_id = str(row.get("artId") or "").strip()
        row["precios_cantidad"] = tramos.get(art_id, [])
        out.append(row)
    return out


def _build_existencia_sql(
    *,
    pve_id: Optional[str],
) -> tuple[str, str, list[Any], str]:
    """Existencia = SUM(exiExistencia) de almacenes del PVE, o de todos si no hay pve_id."""
    extra: list[Any] = []
    group_by = (
        "a.artId, a.artNombre, a.garId, a.uniid, a.artCodigoFabrica, a.artPrecioVenta, "
        "a.artPrecioVentaDos, a.artPrecioVentaTres, a.artPrecioVentaCuatro, a.artPrecioVentaCinco, "
        "a.artMarca, a.monid, a.carId, a.artTipo"
    )
    existencia_expr = "ISNULL(SUM(e.exiExistencia), 0) AS existencia_almacen"
    if pve_id:
        join_existencia = _JOIN_EXISTENCIA_PVE
        extra.append(pve_id.strip())
    else:
        join_existencia = f"LEFT JOIN {_TABLE_EXISTENCIA} e ON e.artId = a.artId"
    return existencia_expr, join_existencia, extra, group_by


def _build_list_query(
    *,
    pve_id: Optional[str],
    solo_disponibles: bool = False,
) -> tuple[str, str, list[Any], list[Any]]:
    """
    Lista con paginación. Si solo_disponibles, filtra HAVING existencia > 0
    *antes* del OFFSET (no en Python sobre la página).
    """
    existencia_expr, join_existencia, extra, group_by = _build_existencia_sql(pve_id=pve_id)
    having_sql = ""
    if solo_disponibles:
        having_sql = "HAVING ISNULL(SUM(e.exiExistencia), 0) > 0"

    query = f"""
        SELECT {_COLS}, {existencia_expr}
        FROM {_TABLE} a
        {join_existencia}
        GROUP BY {group_by}
        {having_sql}
        ORDER BY a.artId
        OFFSET ? ROWS FETCH NEXT ? ROWS ONLY
    """

    if solo_disponibles:
        # Mismos joins/params que la lista, pero solo cuenta artículos con stock.
        count_query = f"""
            SELECT COUNT(*) AS total
            FROM (
                SELECT a.artId
                FROM {_TABLE} a
                {join_existencia}
                GROUP BY a.artId
                HAVING ISNULL(SUM(e.exiExistencia), 0) > 0
            ) AS t
        """
        count_params = list(extra)
    else:
        count_query = f"SELECT COUNT(*) AS total FROM {_TABLE}"
        count_params = []

    return query, count_query, extra, count_params


@router.get("", response_model=ProductoListResponse)
async def listar_productos(
    skip: int = Query(0, ge=0, description="Registros a saltar"),
    limit: int = Query(20, ge=1, le=1000, description="Máximo de registros"),
    pve_id: Optional[str] = Query(
        None,
        description="Punto de venta. existencia = suma de exiExistencia en sus almacenes.",
    ),
    lpr_id: Optional[str] = Query(
        None,
        description="Lista de precios (lprid). Si falta y hay pve_id, usa gntPuntoventa.lprid.",
    ),
    solo_disponibles: bool = Query(
        False,
        description="Solo artículos con existencia > 0 (requiere pve_id); filtro en SQL antes de paginar",
    ),
) -> ProductoListResponse:
    """
    Lista artículos desde intArticulo.

    `existencia` = SUM(intExistencia.exiExistencia) de los almacenes del `pve_id`.
    `precios_cantidad` = todos los tramos de `vntListaPrecioCantidad` para la lista
    `lpr_id` o la del PVE.
    """
    if solo_disponibles and not (pve_id and pve_id.strip()):
        raise HTTPException(
            status_code=400,
            detail="solo_disponibles requiere pve_id",
        )

    pve_id = pve_id.strip() if pve_id else None
    lpr_id = lpr_id.strip() if lpr_id else None

    if pve_id:
        alm_ids_pve = await pve_almacen.ids_almacenes_de_pve(pve_id)
        if not alm_ids_pve:
            raise HTTPException(
                status_code=400,
                detail="El punto de venta no tiene almacenes configurados",
            )

    lista_precio = await _resolver_lista_precio(lpr_id=lpr_id, pve_id=pve_id)

    query, count_query, extra, count_params = _build_list_query(
        pve_id=pve_id,
        solo_disponibles=solo_disponibles,
    )
    params: tuple[Any, ...] = tuple(extra + [skip, limit])

    try:
        rows = await database.fetch_all_dict(query, params)
        count_result = await database.fetch_one_dict(count_query, tuple(count_params))
        total = count_result["total"] if count_result else 0
    except Exception as e:
        raise HTTPException(
            status_code=503,
            detail=f"Error al conectar con la base de datos: {e!s}",
        ) from e

    rows = await _aplicar_precios_cantidad(rows, lpr_id=lista_precio)
    items = [_row_to_producto_response(r) for r in rows]
    return ProductoListResponse(items=items, total=total)


def _row_to_precio_cantidad(row: dict[str, Any]) -> PrecioCantidadItem:
    return PrecioCantidadItem(
        cant_id=int(row["cantId"]),
        lpr_id=str(row["lprid"]).strip() if row.get("lprid") is not None else "",
        art_id=str(row["artId"]).strip() if row.get("artId") is not None else "",
        cant_inicial=_safe_decimal(row.get("cantInicial"), Decimal("0")) or Decimal("0"),
        cant_final=_safe_decimal(row.get("cantFinal"), Decimal("0")) or Decimal("0"),
        cant_precio=_safe_decimal(row.get("cantPrecio"), Decimal("0")) or Decimal("0"),
        mon_id=str(row["monid"]).strip() if row.get("monid") is not None else None,
        hor_id=str(row["horid"]).strip() if row.get("horid") is not None else None,
    )


@router.get("/precios-cantidad", response_model=PrecioCantidadListResponse)
async def listar_precios_cantidad(
    art_id: Optional[str] = Query(None, description="Filtra por artId"),
    lpr_id: Optional[str] = Query(None, description="Filtra por lista de precios (lprid)"),
) -> PrecioCantidadListResponse:
    """
    Rangos de precio por cantidad desde `vntListaPrecioCantidad`.

    Si un artículo no aparece, no tiene precio por tramo (usa `artPrecioVenta`).
    """
    where: list[str] = []
    params: list[Any] = []
    if art_id and art_id.strip():
        where.append("artId = ?")
        params.append(art_id.strip())
    if lpr_id and lpr_id.strip():
        where.append("lprid = ?")
        params.append(lpr_id.strip())
    where_sql = f"WHERE {' AND '.join(where)}" if where else ""
    query = f"""
        SELECT {_COLS_PRECIO_CANTIDAD}
        FROM {_TABLE_PRECIO_CANTIDAD}
        {where_sql}
        ORDER BY artId, cantInicial, cantId
    """
    try:
        rows = await database.fetch_all_dict(query, tuple(params))
    except Exception as e:
        raise HTTPException(
            status_code=503,
            detail=f"Error al consultar precios por cantidad: {e!s}",
        ) from e
    items = [_row_to_precio_cantidad(r) for r in rows or []]
    return PrecioCantidadListResponse(items=items, total=len(items))


@router.get("/{art_id}", response_model=ProductoResponse)
async def obtener_producto(
    art_id: str,
    pve_id: Optional[str] = Query(
        None,
        description="Punto de venta. existencia = suma de exiExistencia en sus almacenes.",
    ),
    lpr_id: Optional[str] = Query(
        None,
        description="Lista de precios (lprid). Si falta y hay pve_id, usa gntPuntoventa.lprid.",
    ),
) -> ProductoResponse:
    """Obtiene un artículo por artId."""
    if not art_id:
        raise HTTPException(status_code=400, detail="artId no puede estar vacío")

    pve_id = pve_id.strip() if pve_id else None
    lpr_id = lpr_id.strip() if lpr_id else None

    if pve_id:
        alm_ids_pve = await pve_almacen.ids_almacenes_de_pve(pve_id)
        if not alm_ids_pve:
            raise HTTPException(
                status_code=400,
                detail="El punto de venta no tiene almacenes configurados",
            )

    lista_precio = await _resolver_lista_precio(lpr_id=lpr_id, pve_id=pve_id)

    existencia_expr, join_existencia, extra, group_by = _build_existencia_sql(pve_id=pve_id)
    query = f"""
        SELECT {_COLS}, {existencia_expr}
        FROM {_TABLE} a
        {join_existencia}
        WHERE a.artId = ?
        GROUP BY {group_by}
    """
    params: tuple[Any, ...] = tuple(extra + [art_id])

    try:
        row = await database.fetch_one_dict(query, params)
    except Exception as e:
        raise HTTPException(
            status_code=503,
            detail=f"Error al conectar con la base de datos: {e!s}",
        ) from e
    if not row:
        raise HTTPException(status_code=404, detail="Producto no encontrado")

    enriched = await _aplicar_precios_cantidad([row], lpr_id=lista_precio)
    return _row_to_producto_response(enriched[0])
