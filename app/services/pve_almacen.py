"""
Consultas PVE ↔ almacén (gntPuntoventa + gntPuntoVentaAlmacen), alineadas con vmaExitencia.
"""
from __future__ import annotations

from typing import Any, Optional

from app.core import database

_TABLE_PVE = "gntPuntoventa"
_TABLE_PVE_ALM = "gntPuntoVentaAlmacen"
_TABLE_ALM = "intAlmacen"

# Misma unión que vmaExitencia: almacenes extra + almacén default del PVE.
_SQL_ALMACENES_PVE = f"""
SELECT
    LTRIM(RTRIM(w.alm_id)) AS alm_id,
    MAX(CASE WHEN w.es_default = 1 THEN 1 ELSE 0 END) AS es_default
FROM (
    SELECT pveId, LTRIM(RTRIM(almId)) AS alm_id, CAST(0 AS bit) AS es_default
    FROM {_TABLE_PVE_ALM}
    WHERE almId IS NOT NULL AND LTRIM(RTRIM(almId)) <> ''
    UNION ALL
    SELECT pveId, LTRIM(RTRIM(almId)) AS alm_id, CAST(1 AS bit) AS es_default
    FROM {_TABLE_PVE}
    WHERE almId IS NOT NULL AND LTRIM(RTRIM(almId)) <> ''
) AS w
WHERE w.pveId = ?
GROUP BY LTRIM(RTRIM(w.alm_id))
ORDER BY es_default DESC, alm_id
"""

_SQL_PVE_BASE = f"""
SELECT
    p.pveId AS pve_id,
    p.pveNombre AS nombre,
    p.sucid AS sucursal_id,
    p.pveHabilitado AS habilitado,
    p.monid AS moneda_id,
    p.lprid AS lista_precio_id,
    p.fpaid AS forma_pago_id,
    LTRIM(RTRIM(p.almId)) AS almacen_default
FROM {_TABLE_PVE} p
"""

_SQL_ALMACENES_VINCULADOS = f"""
SELECT DISTINCT LTRIM(RTRIM(w.alm_id)) AS alm_id
FROM (
    SELECT pveId, LTRIM(RTRIM(almId)) AS alm_id FROM {_TABLE_PVE_ALM}
    UNION ALL
    SELECT pveId, LTRIM(RTRIM(almId)) AS alm_id FROM {_TABLE_PVE}
) AS w
WHERE w.alm_id IS NOT NULL AND LTRIM(RTRIM(w.alm_id)) <> ''
"""


def _str_val(row: dict[str, Any], key: str) -> Optional[str]:
    val = row.get(key)
    if val is None:
        return None
    s = str(val).strip()
    return s or None


def _bool_default(val: Any) -> bool:
    if val is None:
        return False
    if isinstance(val, bool):
        return val
    try:
        return int(val) == 1
    except (TypeError, ValueError):
        return str(val).strip() in ("1", "True", "true")


async def _nombres_almacenes(alm_ids: set[str]) -> dict[str, str]:
    if not alm_ids:
        return {}
    placeholders = ",".join("?" for _ in alm_ids)
    rows = await database.fetch_all_dict(
        f"SELECT almId, almNombre FROM {_TABLE_ALM} WHERE almId IN ({placeholders})",
        tuple(sorted(alm_ids)),
    )
    out: dict[str, str] = {}
    for row in rows:
        aid = _str_val(row, "almId")
        if aid:
            out[aid] = _str_val(row, "almNombre") or aid
    return out


async def ids_almacenes_de_pve(pve_id: str) -> list[str]:
    return [a["alm_id"] for a in await almacenes_de_pve(pve_id)]


async def almacenes_de_pve(pve_id: str) -> list[dict[str, Any]]:
    rows = await database.fetch_all_dict(_SQL_ALMACENES_PVE, (pve_id.strip(),))
    nombres = await _nombres_almacenes({_str_val(r, "alm_id") or "" for r in rows})
    out: list[dict[str, Any]] = []
    for row in rows:
        alm_id = _str_val(row, "alm_id")
        if not alm_id:
            continue
        out.append(
            {
                "alm_id": alm_id,
                "nombre": nombres.get(alm_id),
                "es_default": _bool_default(row.get("es_default")),
            }
        )
    return out


async def obtener_punto_venta(pve_id: str) -> Optional[dict[str, Any]]:
    row = await database.fetch_one_dict(
        f"{_SQL_PVE_BASE} WHERE p.pveId = ?",
        (pve_id.strip(),),
    )
    if not row:
        return None
    almacenes = await almacenes_de_pve(pve_id)
    return {
        "pve_id": _str_val(row, "pve_id") or pve_id.strip(),
        "nombre": _str_val(row, "nombre"),
        "sucursal_id": _str_val(row, "sucursal_id"),
        "habilitado": _str_val(row, "habilitado"),
        "moneda_id": _str_val(row, "moneda_id"),
        "lista_precio_id": _str_val(row, "lista_precio_id"),
        "forma_pago_id": _str_val(row, "forma_pago_id"),
        "almacen_default": _str_val(row, "almacen_default"),
        "almacenes": almacenes,
    }


async def listar_puntos_venta(
    *,
    sucursal_id: Optional[str] = None,
    alm_id: Optional[str] = None,
    solo_habilitados: bool = False,
    skip: int = 0,
    limit: int = 100,
) -> tuple[list[dict[str, Any]], int]:
    where: list[str] = ["1=1"]
    params: list[Any] = []

    if sucursal_id:
        where.append("p.sucid = ?")
        params.append(sucursal_id.strip())
    if solo_habilitados:
        where.append("p.pveHabilitado = 'S'")
    if alm_id:
        where.append(
            f"""EXISTS (
                SELECT 1 FROM (
                    SELECT pveId, LTRIM(RTRIM(almId)) AS alm_id FROM {_TABLE_PVE_ALM}
                    UNION ALL
                    SELECT pveId, LTRIM(RTRIM(almId)) FROM {_TABLE_PVE}
                ) AS w
                WHERE w.pveId = p.pveId AND w.alm_id = ?
            )"""
        )
        params.append(alm_id.strip())

    where_sql = " AND ".join(where)
    count_row = await database.fetch_one_dict(
        f"SELECT COUNT(*) AS total FROM {_TABLE_PVE} p WHERE {where_sql}",
        tuple(params),
    )
    total = int(count_row["total"]) if count_row else 0

    rows = await database.fetch_all_dict(
        f"""
        {_SQL_PVE_BASE}
        WHERE {where_sql}
        ORDER BY p.pveId
        OFFSET ? ROWS FETCH NEXT ? ROWS ONLY
        """,
        tuple(params + [skip, limit]),
    )

    items: list[dict[str, Any]] = []
    for row in rows:
        pve_id = _str_val(row, "pve_id")
        if not pve_id:
            continue
        almacenes = await almacenes_de_pve(pve_id)
        items.append(
            {
                "pve_id": pve_id,
                "nombre": _str_val(row, "nombre"),
                "sucursal_id": _str_val(row, "sucursal_id"),
                "habilitado": _str_val(row, "habilitado"),
                "moneda_id": _str_val(row, "moneda_id"),
                "lista_precio_id": _str_val(row, "lista_precio_id"),
                "forma_pago_id": _str_val(row, "forma_pago_id"),
                "almacen_default": _str_val(row, "almacen_default"),
                "almacenes": almacenes,
            }
        )
    return items, total


async def listar_almacenes(
    *,
    alm_id: Optional[str] = None,
    pve_id: Optional[str] = None,
    skip: int = 0,
    limit: int = 100,
) -> tuple[list[dict[str, Any]], int]:
    where: list[str] = ["1=1"]
    params: list[Any] = []

    if alm_id:
        where.append("v.alm_id = ?")
        params.append(alm_id.strip())
    if pve_id:
        where.append("v.pve_id = ?")
        params.append(pve_id.strip())

    where_sql = " AND ".join(where)

    count_row = await database.fetch_one_dict(
        f"""
        SELECT COUNT(DISTINCT v.alm_id) AS total
        FROM (
            SELECT LTRIM(RTRIM(w.alm_id)) AS alm_id, w.pve_id,
                   MAX(CASE WHEN w.es_default = 1 THEN 1 ELSE 0 END) AS es_default
            FROM (
                SELECT pveId AS pve_id, LTRIM(RTRIM(almId)) AS alm_id, CAST(0 AS bit) AS es_default
                FROM {_TABLE_PVE_ALM}
                WHERE almId IS NOT NULL AND LTRIM(RTRIM(almId)) <> ''
                UNION ALL
                SELECT pveId, LTRIM(RTRIM(almId)), CAST(1 AS bit)
                FROM {_TABLE_PVE}
                WHERE almId IS NOT NULL AND LTRIM(RTRIM(almId)) <> ''
            ) AS w
            GROUP BY LTRIM(RTRIM(w.alm_id)), w.pve_id
        ) AS v
        WHERE {where_sql}
        """,
        tuple(params),
    )
    total = int(count_row["total"]) if count_row else 0

    alm_rows = await database.fetch_all_dict(
        f"""
        SELECT v.alm_id
        FROM (
            SELECT LTRIM(RTRIM(w.alm_id)) AS alm_id, w.pve_id
            FROM (
                SELECT pveId AS pve_id, LTRIM(RTRIM(almId)) AS alm_id FROM {_TABLE_PVE_ALM}
                WHERE almId IS NOT NULL AND LTRIM(RTRIM(almId)) <> ''
                UNION ALL
                SELECT pveId, LTRIM(RTRIM(almId)) FROM {_TABLE_PVE}
                WHERE almId IS NOT NULL AND LTRIM(RTRIM(almId)) <> ''
            ) AS w
            GROUP BY LTRIM(RTRIM(w.alm_id)), w.pve_id
        ) AS v
        WHERE {where_sql}
        GROUP BY v.alm_id
        ORDER BY v.alm_id
        OFFSET ? ROWS FETCH NEXT ? ROWS ONLY
        """,
        tuple(params + [skip, limit]),
    )

    if not alm_rows:
        return [], total

    alm_ids = [_str_val(r, "alm_id") for r in alm_rows if _str_val(r, "alm_id")]
    nombres = await _nombres_almacenes(set(alm_ids))

    link_params: list[Any] = list(alm_ids)
    placeholders = ",".join("?" for _ in alm_ids)
    pve_filter = ""
    if pve_id:
        pve_filter = " AND v.pve_id = ?"
        link_params.append(pve_id.strip())

    links = await database.fetch_all_dict(
        f"""
        SELECT v.alm_id, v.pve_id, v.es_default, p.pveNombre AS pve_nombre
        FROM (
            SELECT LTRIM(RTRIM(w.alm_id)) AS alm_id, w.pve_id,
                   MAX(CASE WHEN w.es_default = 1 THEN 1 ELSE 0 END) AS es_default
            FROM (
                SELECT pveId AS pve_id, LTRIM(RTRIM(almId)) AS alm_id, CAST(0 AS bit) AS es_default
                FROM {_TABLE_PVE_ALM}
                WHERE almId IS NOT NULL AND LTRIM(RTRIM(almId)) <> ''
                UNION ALL
                SELECT pveId, LTRIM(RTRIM(almId)), CAST(1 AS bit)
                FROM {_TABLE_PVE}
                WHERE almId IS NOT NULL AND LTRIM(RTRIM(almId)) <> ''
            ) AS w
            GROUP BY LTRIM(RTRIM(w.alm_id)), w.pve_id
        ) AS v
        LEFT JOIN {_TABLE_PVE} p ON p.pveId = v.pve_id
        WHERE v.alm_id IN ({placeholders}){pve_filter}
        ORDER BY v.alm_id, v.es_default DESC, v.pve_id
        """,
        tuple(link_params),
    )

    by_alm: dict[str, dict[str, Any]] = {}
    for aid in alm_ids:
        if not aid:
            continue
        by_alm[aid] = {
            "alm_id": aid,
            "nombre": nombres.get(aid),
            "puntos_venta": [],
        }

    for link in links:
        aid = _str_val(link, "alm_id")
        pid = _str_val(link, "pve_id")
        if not aid or not pid or aid not in by_alm:
            continue
        by_alm[aid]["puntos_venta"].append(
            {
                "pve_id": pid,
                "nombre": _str_val(link, "pve_nombre"),
                "es_default": _bool_default(link.get("es_default")),
            }
        )

    return [by_alm[aid] for aid in alm_ids if aid in by_alm], total
