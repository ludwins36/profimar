"""
Modelo de dominio para la tabla Ordenes.
"""
from dataclasses import dataclass
from datetime import datetime
from decimal import Decimal
from typing import Optional


@dataclass
class Orden:
    """Modelo de dominio para un registro de la tabla Ordenes."""

    id: int
    cliente_id: int
    fecha_orden: datetime
    total: Decimal
    estado: str
    creado_en: Optional[datetime] = None
    actualizado_en: Optional[datetime] = None

    @classmethod
    def from_row(cls, row: dict) -> "Orden":
        """Construye Orden desde una fila dict."""
        return cls(
            id=row["id"],
            cliente_id=row["cliente_id"],
            fecha_orden=row["fecha_orden"],
            total=Decimal(str(row["total"])),
            estado=row["estado"],
            creado_en=row.get("creado_en"),
            actualizado_en=row.get("actualizado_en"),
        )
