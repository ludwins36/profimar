"""
Conexión a SQL Server con pyodbc.
pyodbc es síncrono; las operaciones se ejecutan en un thread pool
para no bloquear el event loop de FastAPI (patrón async-friendly).
"""
import asyncio
from contextlib import asynccontextmanager, contextmanager
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


async def execute_proc_fetch_all_dict(
    sql: str,
    params: Optional[Tuple[Any, ...]] = None,
) -> List[dict]:
    """
    Ejecuta EXEC de un procedimiento almacenado y devuelve el primer conjunto
    de resultados como lista de diccionarios.
    """
    def _execute() -> List[dict]:
        with get_sync_connection() as conn:
            cursor = conn.cursor()
            cursor.execute(sql, params or ())
            if cursor.description is None:
                return []
            columns = [col[0] for col in cursor.description]
            return [dict(zip(columns, row)) for row in cursor.fetchall()]

    return await run_in_thread(_execute)


async def insert_returning_dict(
    sql: str,
    params: Optional[Tuple[Any, ...]] = None,
) -> Optional[dict]:
    """INSERT con OUTPUT INSERTED.*; devuelve la fila insertada o None."""
    def _execute() -> Optional[dict]:
        with get_sync_connection() as conn:
            cursor = conn.cursor()
            cursor.execute(sql, params or ())
            conn.commit()
            row = cursor.fetchone()
            if row is None:
                return None
            columns = [col[0] for col in cursor.description]
            return dict(zip(columns, row))

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
