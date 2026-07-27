"""
Conexión a SQL Server con pyodbc.
pyodbc es síncrono; las operaciones se ejecutan en un thread pool
para no bloquear el event loop de FastAPI (patrón async-friendly).
"""
import asyncio
from contextlib import asynccontextmanager, contextmanager
from decimal import Decimal
from typing import Any, AsyncGenerator, Generator, List, Optional, Tuple

import pyodbc

from app.core.config import get_settings


def _get_connection() -> pyodbc.Connection:
    """Crea una conexión síncrona (para uso en threads)."""
    conn_str = get_settings().get_connection_string()
    return pyodbc.connect(conn_str)


@contextmanager
def get_sync_connection() -> Generator[pyodbc.Connection, None, None]:
    """Context manager síncrono para una conexión (tests o scripts)."""
    conn = _get_connection()
    try:
        yield conn
    finally:
        conn.close()


async def run_in_thread(func: Any, *args: Any, **kwargs: Any) -> Any:
    """Ejecuta una función síncrona en un thread del pool (no bloquea el event loop)."""
    loop = asyncio.get_event_loop()
    return await loop.run_in_executor(None, lambda: func(*args, **kwargs))


async def fetch_all(
    query: str,
    params: Optional[Tuple[Any, ...]] = None,
) -> List[tuple]:
    """
    Ejecuta una consulta SELECT y devuelve todas las filas.
    Usar ? como placeholder en la query (estilo pyodbc).
    """
    def _execute() -> List[tuple]:
        with get_sync_connection() as conn:
            cursor = conn.cursor()
            cursor.execute(query, params or ())
            return cursor.fetchall()

    return await run_in_thread(_execute)


async def fetch_all_dict(
    query: str,
    params: Optional[Tuple[Any, ...]] = None,
) -> List[dict]:
    """
    Ejecuta una consulta SELECT y devuelve filas como listas de diccionarios
    (claves = nombres de columnas). Usar ? como placeholder.
    """
    def _execute() -> List[dict]:
        with get_sync_connection() as conn:
            cursor = conn.cursor()
            cursor.execute(query, params or ())
            columns = [col[0] for col in cursor.description]
            return [dict(zip(columns, row)) for row in cursor.fetchall()]

    return await run_in_thread(_execute)


async def fetch_one(
    query: str,
    params: Optional[Tuple[Any, ...]] = None,
) -> Optional[tuple]:
    """Ejecuta una consulta y devuelve una sola fila o None."""
    def _execute() -> Optional[tuple]:
        with get_sync_connection() as conn:
            cursor = conn.cursor()
            cursor.execute(query, params or ())
            return cursor.fetchone()

    return await run_in_thread(_execute)


async def fetch_one_dict(
    query: str,
    params: Optional[Tuple[Any, ...]] = None,
) -> Optional[dict]:
    """Ejecuta una consulta y devuelve una fila como dict o None."""
    def _execute() -> Optional[dict]:
        with get_sync_connection() as conn:
            cursor = conn.cursor()
            cursor.execute(query, params or ())
            row = cursor.fetchone()
            if row is None:
                return None
            columns = [col[0] for col in cursor.description]
            return dict(zip(columns, row))

    return await run_in_thread(_execute)


# Mismo patrón que SSMS: EXEC + 2 SELECT (salidas OUTPUT y return value)
_SP_GNP_GENERAR_ID_UNO = """
DECLARE @return_value int,
        @strNuevoIdTxn varchar(50),
        @strMensajeSalida varchar(4000);

EXEC @return_value = [dbo].[gnpGenerarIdUno]
    @strTipoTxn = ?,
    @varGeneracionId = ?,
    @strTabla = ?,
    @strCampoId = ?,
    @strNuevoIdTxn = @strNuevoIdTxn OUTPUT,
    @strMensajeSalida = @strMensajeSalida OUTPUT;

SELECT @strNuevoIdTxn AS [@strNuevoIdTxn],
       @strMensajeSalida AS [@strMensajeSalida];

SELECT @return_value AS [Return Value];
"""


def _collect_cursor_result_sets(cursor: pyodbc.Cursor) -> list[list[dict]]:
    """Recorre todos los conjuntos de resultados (EXEC + SELECTs) vía nextset()."""
    sets: list[list[dict]] = []
    while True:
        if cursor.description:
            columns = [col[0] for col in cursor.description]
            sets.append([dict(zip(columns, row)) for row in cursor.fetchall()])
        if not cursor.nextset():
            break
    return sets


def _normalize_result_key(key: str) -> str:
    return key.replace("@", "").strip().lower().replace(" ", "")


def _parse_gnp_generar_id_results(result_sets: list[list[dict]]) -> Optional[dict]:
    """Interpreta los SELECT de salida como en SQL Server Management Studio."""
    nuevo_id = ""
    mensaje = ""
    return_code = 0

    for result_set in result_sets:
        if not result_set:
            continue
        norm = {_normalize_result_key(k): v for k, v in result_set[0].items()}

        if "strnuevoidtxn" in norm:
            val = norm.get("strnuevoidtxn")
            if val is not None:
                nuevo_id = str(val).strip()
            msg_val = norm.get("strmensajesalida")
            if msg_val is not None and str(msg_val).strip():
                mensaje = str(msg_val).strip()

        if "returnvalue" in norm:
            rv = norm.get("returnvalue")
            if rv is not None:
                return_code = int(rv)

    if not nuevo_id and not any(result_sets):
        return None

    return {
        "nuevo_id": nuevo_id,
        "mensaje": mensaje,
        "return_code": return_code,
    }


async def execute_gnp_generar_id_uno(
    str_tipo_txn: str,
    var_generacion_id: str,
    str_tabla: str,
    str_campo_id: str,
) -> Optional[dict]:
    """Ejecuta dbo.gnpGenerarIdUno y devuelve return_code, nuevo_id y mensaje."""
    params = (str_tipo_txn, var_generacion_id, str_tabla, str_campo_id)

    def _execute() -> Optional[dict]:
        with get_sync_connection() as conn:
            cursor = conn.cursor()
            cursor.execute(_SP_GNP_GENERAR_ID_UNO, params)
            return _parse_gnp_generar_id_results(_collect_cursor_result_sets(cursor))

    return await run_in_thread(_execute)


_SP_NVNP_APROBAR_TXN_ECOMMERCE = """
DECLARE @return_value int,
        @strMensaje varchar(500),
        @strURL varchar(max);

EXEC @return_value = [dbo].[nvnpAprobarTxnEcommerce]
    @strVntId = ?,
    @strMensaje = @strMensaje OUTPUT,
    @strURL = @strURL OUTPUT;

SELECT @strMensaje AS [@strMensaje],
       @strURL AS [@strURL];

SELECT @return_value AS [Return Value];
"""


def _parse_nvnp_aprobar_results(result_sets: list[list[dict]]) -> dict:
    """Interpreta salidas OUTPUT de nvnpAprobarTxnEcommerce."""
    mensaje = ""
    url = ""
    return_code = 0

    for result_set in result_sets:
        if not result_set:
            continue
        norm = {_normalize_result_key(k): v for k, v in result_set[0].items()}

        if "strmensaje" in norm:
            val = norm.get("strmensaje")
            if val is not None:
                mensaje = str(val).strip()
            url_val = norm.get("strurl")
            if url_val is not None:
                url = str(url_val).strip()

        if "returnvalue" in norm:
            rv = norm.get("returnvalue")
            if rv is not None:
                return_code = int(rv)

    return {
        "str_mensaje": mensaje,
        "str_url": url,
        "return_code": return_code,
    }


async def execute_nvnp_aprobar_txn_ecommerce(vnt_id: str) -> dict:
    """
    Ejecuta dbo.nvnpAprobarTxnEcommerce (aprobación VEN ecommerce).
    Usa autocommit: el SP maneja transacciones internas.
    """
    vnt_id = vnt_id.strip()

    def _execute() -> dict:
        with get_sync_connection() as conn:
            conn.autocommit = True
            cursor = conn.cursor()
            cursor.execute("SET ANSI_WARNINGS OFF")
            cursor.execute(_SP_NVNP_APROBAR_TXN_ECOMMERCE, (vnt_id,))
            return _parse_nvnp_aprobar_results(_collect_cursor_result_sets(cursor))

    return await run_in_thread(_execute)


_SP_VMA_EXISTENCIA = """
DECLARE @decExistencia DECIMAL(24,12);
EXEC [dbo].[vmaExitencia]
    @strPveId = ?,
    @strAlmacen = ?,
    @strArtId = ?,
    @strUnidaDestino = ?,
    @decExistencia = @decExistencia OUTPUT;
SELECT @decExistencia AS existencia;
"""


async def execute_vma_existencia(
    pve_id: str,
    alm_id: str,
    art_id: str,
    uni_id: str,
) -> Optional[Decimal]:
    """Ejecuta dbo.vmaExitencia (misma regla que vmaApruebaTxn al aprobar VEN)."""

    def _execute() -> Optional[Decimal]:
        with get_sync_connection() as conn:
            cursor = conn.cursor()
            cursor.execute(_SP_VMA_EXISTENCIA, (pve_id, alm_id, art_id, uni_id))
            sets = _collect_cursor_result_sets(cursor)
            for result_set in sets:
                if result_set and "existencia" in result_set[0]:
                    val = result_set[0]["existencia"]
                    return Decimal(str(val)) if val is not None else Decimal("0")
            return None

    return await run_in_thread(_execute)


async def execute_proc_fetch_all_dict(
    sql: str,
    params: Optional[Tuple[Any, ...]] = None,
) -> List[dict]:
    """
    Ejecuta EXEC de un procedimiento almacenado y devuelve filas como dicts.

    Recorre todos los result sets (nextset): muchos SP hacen PRINT / USE / SELECT
    y el primer conjunto puede venir sin description o vacío.
    Devuelve el primer conjunto no vacío; si ninguno tiene filas, [].
    """
    def _execute() -> List[dict]:
        with get_sync_connection() as conn:
            cursor = conn.cursor()
            cursor.execute(sql, params or ())
            for result_set in _collect_cursor_result_sets(cursor):
                if result_set:
                    return result_set
            return []

    return await run_in_thread(_execute)


def bracket_ident(name: str) -> str:
    return f"[{name.replace(']', ']]')}]"


def build_insert_sql(table: str, columnas: list[str]) -> str:
    """INSERT sin OUTPUT (compatible con tablas que tienen triggers)."""
    col_sql = ", ".join(bracket_ident(c) for c in columnas)
    placeholders = ", ".join("?" * len(columnas))
    return f"INSERT INTO {bracket_ident(table)} ({col_sql}) VALUES ({placeholders})"


def build_select_inserted_sql(
    table: str,
    columnas: list[str],
    valores: list[Any],
    pk_columns: Optional[list[str]] = None,
) -> tuple[str, tuple[Any, ...]]:
    """
    SELECT de la fila recién insertada.
    Usa PK si está en columnas insertadas; si no, filtra por todos los valores enviados.
    """
    pk_lower = {p.lower() for p in (pk_columns or [])}
    pairs = [(c, v) for c, v in zip(columnas, valores) if c.lower() in pk_lower]
    if not pairs:
        pairs = list(zip(columnas, valores))
    where = " AND ".join(f"{bracket_ident(c)} = ?" for c, _ in pairs)
    params = tuple(v for _, v in pairs)
    sql = f"SELECT TOP 1 * FROM {bracket_ident(table)} WHERE {where}"
    return sql, params


def cursor_row_to_dict(cursor: pyodbc.Cursor) -> Optional[dict]:
    """Convierte la fila actual del cursor en dict."""
    row = cursor.fetchone()
    if row is None or cursor.description is None:
        return None
    columns = [col[0] for col in cursor.description]
    return dict(zip(columns, row))


def insert_and_fetch_row(
    cursor: pyodbc.Cursor,
    table: str,
    columnas: list[str],
    valores: list[Any],
    pk_columns: Optional[list[str]] = None,
) -> Optional[dict]:
    """INSERT + SELECT en el mismo cursor (sin OUTPUT; compatible con triggers)."""
    cursor.execute(build_insert_sql(table, columnas), tuple(valores))
    fetch_sql, fetch_params = build_select_inserted_sql(table, columnas, valores, pk_columns)
    cursor.execute(fetch_sql, fetch_params)
    return cursor_row_to_dict(cursor)


async def insert_and_fetch_dict(
    table: str,
    columnas: list[str],
    valores: list[Any],
    pk_columns: Optional[list[str]] = None,
) -> Optional[dict]:
    """INSERT + SELECT; devuelve la fila insertada (compatible con triggers)."""
    def _execute() -> Optional[dict]:
        with get_sync_connection() as conn:
            cursor = conn.cursor()
            row = insert_and_fetch_row(cursor, table, columnas, valores, pk_columns)
            conn.commit()
            return row

    return await run_in_thread(_execute)


async def insert_returning_dict(
    sql: str,
    params: Optional[Tuple[Any, ...]] = None,
) -> Optional[dict]:
    """
    INSERT con OUTPUT INSERTED.* (legacy).
    No usar en tablas con triggers; preferir insert_and_fetch_dict.
    """
    def _execute() -> Optional[dict]:
        with get_sync_connection() as conn:
            cursor = conn.cursor()
            cursor.execute(sql, params or ())
            conn.commit()
            return cursor_row_to_dict(cursor)

    return await run_in_thread(_execute)


async def run_transaction(callback: Any) -> Any:
    """
    Ejecuta callback(cursor) dentro de una transacción (commit/rollback).
    Útil para operaciones encadenadas en la misma conexión.
    """
    def _execute() -> Any:
        with get_sync_connection() as conn:
            cursor = conn.cursor()
            try:
                result = callback(cursor)
                conn.commit()
                return result
            except Exception:
                conn.rollback()
                raise

    return await run_in_thread(_execute)


async def execute_write(
    query: str,
    params: Optional[Tuple[Any, ...]] = None,
) -> int:
    """Ejecuta INSERT/UPDATE/DELETE y devuelve el número de filas afectadas."""
    def _execute() -> int:
        with get_sync_connection() as conn:
            cursor = conn.cursor()
            cursor.execute(query, params or ())
            conn.commit()
            return cursor.rowcount

    return await run_in_thread(_execute)


@asynccontextmanager
async def connection_scope() -> AsyncGenerator[pyodbc.Connection, None]:
    """
    Context manager async: abre una conexión en un thread y la cierra al salir.
    Útil si necesitas varias operaciones en la misma conexión de forma async.
    """
    conn_holder: List[pyodbc.Connection] = []

    def _open() -> pyodbc.Connection:
        c = _get_connection()
        conn_holder.append(c)
        return c

    conn = await run_in_thread(_open)
    try:
        yield conn
    finally:
        def _close() -> None:
            if conn_holder:
                conn_holder[0].close()
                conn_holder.clear()

        await run_in_thread(_close)
