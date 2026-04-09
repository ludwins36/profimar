"""
Rutas de prueba: health de la API y test de conexión a la base de datos.
No dependen de tablas; sirven para verificar que el servicio y SQL Server responden.
"""
from fastapi import APIRouter, HTTPException

from app.core import database
from app.core.config import get_settings

router = APIRouter(prefix="/test", tags=["Test"])

_VALID_IDENT_CHARS = frozenset("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_")


def _parse_table_identifier(raw_name: str) -> tuple[str, str]:
    """
    Devuelve (schema_name, table_name) a partir de 'tabla' o 'esquema.tabla'.
    Valida que sean identificadores SQL seguros (sin inyección).
    """
    raw_name = (raw_name or "").strip()
    if not raw_name:
        raise HTTPException(status_code=400, detail="El nombre de tabla es obligatorio")

    if "." in raw_name:
        schema_name, only_table = raw_name.split(".", 1)
        schema_name = schema_name.strip() or "dbo"
        only_table = only_table.strip()
    else:
        schema_name = "dbo"
        only_table = raw_name

    if not only_table:
        raise HTTPException(status_code=400, detail="Nombre de tabla inválido")

    if not set(schema_name).issubset(_VALID_IDENT_CHARS) or not set(only_table).issubset(_VALID_IDENT_CHARS):
        raise HTTPException(status_code=400, detail="Nombre de tabla inválido")

    return schema_name, only_table


@router.get("")
async def test_health():
    """Comprueba que la API responde y la configuración se carga."""
    settings = get_settings()
    return {
        "status": "ok",
        "app": settings.app_name,
        "database_config": settings.database_url_style,
    }


@router.get("/db")
async def test_db_connection():
    """
    Prueba la conexión a SQL Server.
    Ejecuta una consulta simple (SELECT 1) sin usar ninguna tabla.
    """
    try:
        row = await database.fetch_one_dict("SELECT 1 AS test, @@VERSION AS version", ())
        if not row:
            raise HTTPException(status_code=503, detail="La consulta no devolvió resultado")
        return {
            "status": "ok",
            "database": "connected",
            "test": row.get("test"),
            "server_version": (row.get("version") or "").strip()[:200],
        }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=503,
            detail=f"Error de conexión a la base de datos: {e!s}",
        ) from e


@router.get("/tables")
async def list_db_tables():
    """
    Devuelve la lista de todas las tablas de la base de datos actual.
    Usa INFORMATION_SCHEMA (solo tablas base, sin vistas).
    """
    query = """
        SELECT TABLE_SCHEMA AS schema_name, TABLE_NAME AS table_name
        FROM INFORMATION_SCHEMA.TABLES
        WHERE TABLE_TYPE = 'BASE TABLE'
        ORDER BY TABLE_SCHEMA, TABLE_NAME
    """
    try:
        rows = await database.fetch_all_dict(query, ())
        tables = [
            {"schema": r["schema_name"], "name": r["table_name"], "full_name": f"{r['schema_name']}.{r['table_name']}"}
            for r in rows
        ]
        return {"status": "ok", "count": len(tables), "tables": tables}
    except Exception as e:
        raise HTTPException(
            status_code=503,
            detail=f"Error al listar tablas: {e!s}",
        ) from e


@router.get("/table-detail/{table_name}")
async def table_detail(table_name: str):
    """
    Devuelve el detalle de una tabla por nombre.
    Acepta formato: tabla o esquema.tabla (ej: dbo.intArticulo).
    """
    schema_name, only_table = _parse_table_identifier(table_name)

    columns_query = """
        SELECT
            c.TABLE_SCHEMA AS schema_name,
            c.TABLE_NAME AS table_name,
            c.COLUMN_NAME AS column_name,
            c.DATA_TYPE AS data_type,
            c.CHARACTER_MAXIMUM_LENGTH AS max_length,
            c.NUMERIC_PRECISION AS numeric_precision,
            c.NUMERIC_SCALE AS numeric_scale,
            c.IS_NULLABLE AS is_nullable,
            c.ORDINAL_POSITION AS ordinal_position
        FROM INFORMATION_SCHEMA.COLUMNS c
        WHERE c.TABLE_SCHEMA = ? AND c.TABLE_NAME = ?
        ORDER BY c.ORDINAL_POSITION
    """

    pk_query = """
        SELECT k.COLUMN_NAME AS pk_column
        FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS t
        INNER JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE k
            ON t.CONSTRAINT_NAME = k.CONSTRAINT_NAME
            AND t.TABLE_SCHEMA = k.TABLE_SCHEMA
            AND t.TABLE_NAME = k.TABLE_NAME
        WHERE t.TABLE_SCHEMA = ?
          AND t.TABLE_NAME = ?
          AND t.CONSTRAINT_TYPE = 'PRIMARY KEY'
        ORDER BY k.ORDINAL_POSITION
    """

    try:
        columns = await database.fetch_all_dict(columns_query, (schema_name, only_table))
        if not columns:
            raise HTTPException(
                status_code=404,
                detail=f"La tabla '{schema_name}.{only_table}' no existe",
            )

        pk_rows = await database.fetch_all_dict(pk_query, (schema_name, only_table))
        pk_columns = [r["pk_column"] for r in pk_rows]

        return {
            "status": "ok",
            "table": {
                "schema": schema_name,
                "name": only_table,
                "full_name": f"{schema_name}.{only_table}",
                "primary_key": pk_columns,
            },
            "columns_count": len(columns),
            "columns": columns,
        }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=503,
            detail=f"Error al obtener detalle de tabla: {e!s}",
        ) from e


@router.get("/table-sample/{table_name}")
async def table_sample(table_name: str, limit: int = 0):
    """
    Devuelve filas de una tabla.
    - limit > 0: primeras N filas (SQL TOP N, sin tope máximo).
    - limit = 0: todas las filas (SELECT * completo; puede ser pesado).
    Acepta formato: tabla o esquema.tabla (ej: dbo.intArticulo).
    """
    if limit < 0:
        raise HTTPException(status_code=400, detail="limit no puede ser negativo")
    schema_name, only_table = _parse_table_identifier(table_name)

    exists_query = """
        SELECT 1 AS ok
        FROM INFORMATION_SCHEMA.TABLES
        WHERE TABLE_SCHEMA = ? AND TABLE_NAME = ? AND TABLE_TYPE = 'BASE TABLE'
    """
    quoted = f"[{schema_name.replace(']', ']]')}].[{only_table.replace(']', ']]')}]"

    try:
        exists = await database.fetch_one_dict(exists_query, (schema_name, only_table))
        if not exists:
            raise HTTPException(
                status_code=404,
                detail=f"La tabla '{schema_name}.{only_table}' no existe",
            )

        if limit == 0:
            select_sql = f"SELECT * FROM {quoted}"
        else:
            select_sql = f"SELECT TOP ({limit}) * FROM {quoted}"
        rows = await database.fetch_all_dict(select_sql, ())
        return {
            "status": "ok",
            "table": {
                "schema": schema_name,
                "name": only_table,
                "full_name": f"{schema_name}.{only_table}",
            },
            "limit": limit,
            "all_rows": limit == 0,
            "count": len(rows),
            "rows": rows,
        }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=503,
            detail=f"Error al leer la tabla: {e!s}",
        ) from e
