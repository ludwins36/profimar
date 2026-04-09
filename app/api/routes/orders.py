"""
Rutas de órdenes: encabezado, líneas de detalle y consultas legacy (tabla Ordenes).
"""

from decimal import Decimal

from typing import Any



from fastapi import APIRouter, HTTPException, Query



from app.core import database

from app.schemas.order import OrdenListResponse, OrdenResponse

from app.schemas.order_encabezado import OrdenEncabezadoCreate, filas_a_columnas_sql
from app.schemas.order_lineas import OrdenLineaCreate, linea_a_columnas_sql



router = APIRouter(prefix="/orders", tags=["Órdenes"])



# Tabla de encabezado de pedido en SQL Server (ajusta al nombre real de tu BD)

_TABLE_ENCABEZADO = "PEDIDO"

# Tabla de líneas / detalle (ajusta al nombre real en tu BD)
_TABLE_LINEAS = "PEDIDOLINEA"



def _bracket_ident(name: str) -> str:

    return f"[{name.replace(']', ']]')}]"





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





@router.post("/encabezado", status_code=201)

async def crear_orden_encabezado(payload: OrdenEncabezadoCreate):

    """

    **Fase 1:** crea solo el encabezado del pedido (INSERT en la tabla configurada).

    El body usa nombres en snake_case; se mapean a columnas `PEDIDO*` en SQL Server.

    """

    columnas, valores = filas_a_columnas_sql(payload)

    if not columnas:

        raise HTTPException(status_code=400, detail="No hay campos para insertar")

    col_sql = ", ".join(_bracket_ident(c) for c in columnas)

    placeholders = ", ".join("?" * len(valores))

    sql = f"""

        INSERT INTO {_bracket_ident(_TABLE_ENCABEZADO)} ({col_sql})

        OUTPUT INSERTED.*

        VALUES ({placeholders})

    """

    try:

        row = await database.insert_returning_dict(sql, tuple(valores))

    except Exception as e:

        err = str(e).lower()

        if "invalid object name" in err or "42s02" in err:

            raise HTTPException(

                status_code=503,

                detail=f"Revise el nombre de la tabla de encabezado ({_TABLE_ENCABEZADO}): {e!s}",

            ) from e

        raise HTTPException(

            status_code=503,

            detail=f"Error al insertar encabezado: {e!s}",

        ) from e

    return {"status": "ok", "body": row or {}}


@router.post("/lineas", status_code=201)
async def crear_orden_linea(payload: OrdenLineaCreate):
    """
    **Fase 2:** inserta una línea de pedido (detalle de productos).

    El body usa snake_case (`ped_id`, `art_id`, `ped_precio_sin_iva`, …) mapeados a
    columnas camelCase (`pedId`, `artId`, `pedPrecioSinIva`, …). También puedes
    enviar columnas extra con el nombre exacto de SQL.
    """
    columnas, valores = linea_a_columnas_sql(payload)
    if not columnas:
        raise HTTPException(status_code=400, detail="No hay campos para insertar")
    col_sql = ", ".join(_bracket_ident(c) for c in columnas)
    placeholders = ", ".join("?" * len(valores))
    sql = f"""
        INSERT INTO {_bracket_ident(_TABLE_LINEAS)} ({col_sql})
        OUTPUT INSERTED.*
        VALUES ({placeholders})
    """
    try:
        row = await database.insert_returning_dict(sql, tuple(valores))
    except Exception as e:
        err = str(e).lower()
        if "invalid object name" in err or "42s02" in err:
            raise HTTPException(
                status_code=503,
                detail=f"Revise el nombre de la tabla de líneas ({_TABLE_LINEAS}): {e!s}",
            ) from e
        raise HTTPException(
            status_code=503,
            detail=f"Error al insertar línea: {e!s}",
        ) from e
    return {"status": "ok", "body": row or {}}


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





@router.get("/{orden_id}", response_model=OrdenResponse)

async def obtener_orden(orden_id: int) -> OrdenResponse:

    """Obtiene una orden por ID (tabla Ordenes)."""

    query = """

        SELECT id, cliente_id, fecha_orden, total, estado, creado_en, actualizado_en

        FROM Ordenes

        WHERE id = ?

    """

    row = await database.fetch_one_dict(query, (orden_id,))

    if not row:

        raise HTTPException(status_code=404, detail="Orden no encontrada")

    return _row_to_orden_response(row)
