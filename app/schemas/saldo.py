"""Parámetros de query para GET getSaldo (EXEC del SP en la BD)."""
from datetime import datetime
from typing import Any

from fastapi import Query
from pydantic import BaseModel, Field


class GetSaldoResponse(BaseModel):
    """Respuesta del endpoint get-saldo: estado y filas del procedimiento."""

    status: str = Field(default="ok", description="Estado de la operación")
    body: list[dict[str, Any]] = Field(description="Resultado del procedimiento almacenado (filas)")


class GetSaldoQuery(BaseModel):
    """Parámetros que envía la API al procedimiento almacenado."""

    str_emp_id: str = Field(..., max_length=50)
    dat_fecha_inicial: datetime
    dat_fecha_final: datetime
    str_grupo_cta_cte: str = Field(default="*", max_length=50)
    str_cta_cte: str = Field(default="*", max_length=50)
    str_nota: str = Field(default="%", max_length=50)
    str_estado: str = Field(default="A", max_length=50)
    str_moneda: str = Field(default="BOL", max_length=50)
    str_tipo_doc: str = Field(default="*", max_length=50)
    str_opcion_pago: str = Field(default="*", max_length=50)
    str_decimales: str = Field(default="5", max_length=50)
    str_saldo: str = Field(default="*", max_length=50)
    str_dias_vencidos: str = Field(default="*", max_length=10)


def parse_get_saldo_query(
    str_emp_id: str = Query(..., description="strEmpId (empresa / BD)"),
    dat_fecha_inicial: datetime = Query(..., description="Fecha inicial"),
    dat_fecha_final: datetime = Query(..., description="Fecha final"),
    str_grupo_cta_cte: str = Query("*", max_length=50),
    str_cta_cte: str = Query("*", max_length=50),
    str_nota: str = Query("%", max_length=50),
    str_estado: str = Query("A", max_length=50),
    str_moneda: str = Query("BOL", max_length=50),
    str_tipo_doc: str = Query("*", max_length=50),
    str_opcion_pago: str = Query("*", max_length=50),
    str_decimales: str = Query("5", max_length=50),
    str_saldo: str = Query("*", max_length=50),
    str_dias_vencidos: str = Query("*", max_length=10),
) -> GetSaldoQuery:
    return GetSaldoQuery(
        str_emp_id=str_emp_id,
        dat_fecha_inicial=dat_fecha_inicial,
        dat_fecha_final=dat_fecha_final,
        str_grupo_cta_cte=str_grupo_cta_cte,
        str_cta_cte=str_cta_cte,
        str_nota=str_nota,
        str_estado=str_estado,
        str_moneda=str_moneda,
        str_tipo_doc=str_tipo_doc,
        str_opcion_pago=str_opcion_pago,
        str_decimales=str_decimales,
        str_saldo=str_saldo,
        str_dias_vencidos=str_dias_vencidos,
    )


def tuple_for_exec(q: GetSaldoQuery) -> tuple:
    return (
        q.str_emp_id,
        q.dat_fecha_inicial,
        q.dat_fecha_final,
        q.str_grupo_cta_cte,
        q.str_cta_cte,
        q.str_nota,
        q.str_estado,
        q.str_moneda,
        q.str_tipo_doc,
        q.str_opcion_pago,
        q.str_decimales,
        q.str_saldo,
        q.str_dias_vencidos,
    )
