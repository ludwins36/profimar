"""
Rutas de productos: obtención de registros desde intArticulo.
"""
from decimal import Decimal
from typing import Any, Optional

from fastapi import APIRouter, HTTPException, Query

from app.core import database
from app.schemas.product import ProductoListResponse, ProductoResponse

router = APIRouter(prefix="/products", tags=["Productos"])

# Estructura tablas intArticulo e intexistencia
_TABLE = "intArticulo"
_TABLE_EXISTENCIA = "intexistencia"
_COLS = (
    "a.artId, a.artNombre, a.garId, a.uniid, a.artCodigoFabrica, a.artPrecioVenta, "
    "a.artPrecioVentaDos, a.artMarca, a.monid, a.carId"
)
_COLS_SIMPLE = (
    "artId, artNombre, garId, uniid, artCodigoFabrica, artPrecioVenta, artPrecioVentaDos, "
    "artMarca, monid, carId"
)


def _safe_decimal(v: Any, default: Optional[Decimal] = None) -> Optional[Decimal]:
    """Convierte a Decimal de forma segura; si falla devuelve default."""
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
    """Convierte a int de forma segura; cadena vacía o inválida -> None."""
    if v is None:
        return None
    s = str(v).strip()
    if not s:
        return None
    try:
        return int(s)
    except (ValueError, TypeError):
        return None


def _row_to_producto_response(row: dict[str, Any], include_existencia: bool = False) -> ProductoResponse:
    """Convierte una fila dict (intArticulo) a ProductoResponse."""
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
        marca=row.get("artMarca"),
        existencia=_safe_decimal(row.get("total_existencia")) if include_existencia else None,
    )


@router.get("", response_model=ProductoListResponse)
async def listar_productos(
    skip: int = Query(0, ge=0, description="Registros a saltar"),
    limit: int = Query(20, ge=1, le=100000, description="Máximo de registros"),
) -> ProductoListResponse:
    """Lista artículos desde intArticulo con paginación y suma de existencia por artId."""
    query = f"""
        SELECT {_COLS},
               ISNULL(SUM(e.exiExistencia), 0) AS total_existencia
        FROM {_TABLE} a
        LEFT JOIN {_TABLE_EXISTENCIA} e ON e.artId = a.artId
        GROUP BY a.artId, a.artNombre, a.garId, a.uniid, a.artCodigoFabrica, a.artPrecioVenta, a.artPrecioVentaDos, a.artMarca, a.monid, a.carId
        ORDER BY a.artId
        OFFSET ? ROWS FETCH NEXT ? ROWS ONLY
    """
    params: tuple = (skip, limit)
    count_query = f"SELECT COUNT(*) AS total FROM {_TABLE}"

    try:
        rows = await database.fetch_all_dict(query, params)
        count_result = await database.fetch_one_dict(count_query, ())
        total = count_result["total"] if count_result else 0
    except Exception as e:
        raise HTTPException(
            status_code=503,
            detail=f"Error al conectar con la base de datos: {e!s}",
        ) from e

    items = [_row_to_producto_response(r, include_existencia=True) for r in rows]
    return ProductoListResponse(items=items, total=total)


@router.get("/{art_id}", response_model=ProductoResponse)
async def obtener_producto(art_id: str) -> ProductoResponse:
    """
    Obtiene un artículo por artId (clave de intArticulo).
    Tabla: intArticulo. Filtro: WHERE artId = ?
    """
    # art_id = (art_id or "").strip()
    if not art_id:
        raise HTTPException(status_code=400, detail="artId no puede estar vacío")
    try:
        query = f"""
            SELECT {_COLS},
                   ISNULL(SUM(e.exiExistencia), 0) AS total_existencia
            FROM {_TABLE} a
            LEFT JOIN {_TABLE_EXISTENCIA} e ON e.artId = a.artId
            WHERE a.artId = ?
            GROUP BY a.artId, a.artNombre, a.garId, a.uniid, a.artCodigoFabrica, a.artPrecioVenta, a.artPrecioVentaDos, a.artMarca, a.monid, a.carId
        """
        row = await database.fetch_one_dict(query, (art_id,))
    except Exception as e:
        raise HTTPException(
            status_code=503,
            detail=f"Error al conectar con la base de datos: {e!s}",
        ) from e
    if not row:
        raise HTTPException(status_code=404, detail="Producto no encontrado")
    return _row_to_producto_response(row, include_existencia=True)
