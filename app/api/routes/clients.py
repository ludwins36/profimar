"""
Rutas de clientes: obtención de registros desde gntdirectorio.
"""
from typing import Any, Optional

from fastapi import APIRouter, Depends, HTTPException, Query

from app.core import database
from app.schemas.client import ClienteCreate, ClienteListResponse, ClienteResponse
from app.schemas.saldo import GetSaldoQuery, GetSaldoResponse, parse_get_saldo_query, tuple_for_exec

# Procedimiento ya creado en la BD; solo se ejecuta desde la API.
_SP_DEBITO_PENDIENTE = "dbo.nctpDebitoPendienteDeCobroFvenc"

router = APIRouter(prefix="/clients", tags=["Clientes"])

# Estructura tabla gntdirectorio
_TABLE = "gntdirectorio"
_COLS = "dirId, dirNombre, dirRuc, dirRazonSocial, dirInternet, dirRendicionesVencidasPermitidas"


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


def _row_to_cliente_response(row: dict[str, Any]) -> ClienteResponse:
    """Convierte una fila dict (gntdirectorio) a ClienteResponse."""
    return ClienteResponse(
        id=str(row["dirId"]),
        nombre=row.get("dirNombre"),
        nit=row.get("dirRuc"),
        razon_social=row.get("dirRazonSocial"),
        correo=row.get("dirInternet"),
        notas_vencidas_permitidas=_safe_int(row.get("dirRendicionesVencidasPermitidas")),
    )


@router.get("", response_model=ClienteListResponse)
async def listar_clientes(
    skip: int = Query(0, ge=0, description="Registros a saltar"),
    limit: int = Query(20, ge=1, le=100, description="Máximo de registros"),
) -> ClienteListResponse:
    """Lista clientes desde gntdirectorio con paginación."""
    query = f"""
        SELECT {_COLS}
        FROM {_TABLE}
        ORDER BY dirId
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

    items = [_row_to_cliente_response(r) for r in rows]
    return ClienteListResponse(items=items, total=total)


@router.post("", response_model=ClienteResponse, status_code=201)
async def crear_cliente(payload: ClienteCreate) -> ClienteResponse:
    """Crea un cliente en gntdirectorio. dirId se genera automáticamente (último dirId + 1)."""
    try:
        max_row = await database.fetch_one_dict(
            "SELECT MAX(TRY_CAST(dirId AS INT)) AS max_id FROM gntdirectorio",
            (),
        )
        max_id = max_row.get("max_id") if max_row else None
        next_id = (max_id or 0) + 1
        dir_id = str(next_id)
    except Exception as e:
        raise HTTPException(
            status_code=503,
            detail=f"Error al obtener el siguiente dirId: {e!s}",
        ) from e

    query = f"""
        INSERT INTO {_TABLE}
        (dirId, dirNombre, dirRuc, dirRazonSocial, dirInternet, dirRendicionesVencidasPermitidas)
        VALUES (?, ?, ?, ?, ?, ?)
    """
    params = (
        dir_id,
        payload.nombre or None,
        payload.nit or None,
        payload.razon_social or None,
        payload.correo or None,
        payload.notas_vencidas_permitidas,
    )
    try:
        await database.execute_write(query, params)
    except Exception as e:
        err_msg = str(e).lower()
        if "unique" in err_msg or "duplicate" in err_msg or "primary key" in err_msg or "violation" in err_msg:
            raise HTTPException(status_code=409, detail=f"Ya existe un cliente con dirId '{dir_id}'") from e
        raise HTTPException(
            status_code=503,
            detail=f"Error al crear el cliente: {e!s}",
        ) from e

    row = await database.fetch_one_dict(
        f"SELECT {_COLS} FROM {_TABLE} WHERE dirId = ?",
        (dir_id,),
    )
    if not row:
        raise HTTPException(status_code=500, detail="Cliente creado pero no se pudo recuperar")
    return _row_to_cliente_response(row)


@router.get("/get-saldo", response_model=GetSaldoResponse)
async def get_saldo(q: GetSaldoQuery = Depends(parse_get_saldo_query)) -> GetSaldoResponse:
    """Ejecuta el procedimiento almacenado; devuelve `status` y `body` con las filas del SP."""
    sql = f"""
        EXEC {_SP_DEBITO_PENDIENTE}
            ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?
    """
    params = tuple_for_exec(q)
    try:
        rows = await database.execute_proc_fetch_all_dict(sql, params)
        return GetSaldoResponse(status="ok", body=rows)
    except Exception as e:
        raise HTTPException(
            status_code=503,
            detail=f"Error al ejecutar el procedimiento: {e!s}",
        ) from e


@router.get("/{dir_id}", response_model=ClienteResponse)
async def obtener_cliente(dir_id: str) -> ClienteResponse:
    """Obtiene un cliente por dirId (código cliente, PK)."""
    dir_id = (dir_id or "").strip()
    if not dir_id:
        raise HTTPException(status_code=400, detail="dirId no puede estar vacío")
    try:
        query = f"""
            SELECT {_COLS}
            FROM {_TABLE}
            WHERE dirId = ?
        """
        row = await database.fetch_one_dict(query, (dir_id,))
    except Exception as e:
        raise HTTPException(
            status_code=503,
            detail=f"Error al conectar con la base de datos: {e!s}",
        ) from e
    if not row:
        raise HTTPException(status_code=404, detail="Cliente no encontrado")
    return _row_to_cliente_response(row)
