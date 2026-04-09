"""
Modelo de dominio para la tabla intArticulo.
"""
from dataclasses import dataclass
from decimal import Decimal
from typing import Optional


@dataclass
class Producto:
    """Modelo de dominio para un registro de la tabla intArticulo."""

    art_id: str
    art_nombre: str
    gar_id: Optional[int]
    uni_id: Optional[str]
    art_codigo_fabrica: Optional[str]
    art_precio_venta: Decimal
    art_precio_venta_dos: Optional[Decimal]
    art_marca: Optional[str]

    @classmethod
    def from_row(cls, row: dict) -> "Producto":
        """Construye Producto desde una fila dict."""
        def _decimal(v):
            if v is None:
                return None
            return Decimal(str(v))

        return cls(
            art_id=str(row["artId"]),
            art_nombre=row["artNombre"],
            gar_id=row.get("garId"),
            uni_id=str(row["uniid"]).strip() if row.get("uniid") is not None else None,
            art_codigo_fabrica=row.get("artCodigoFabrica"),
            art_precio_venta=Decimal(str(row["artPrecioVenta"])),
            art_precio_venta_dos=_decimal(row.get("artPrecioVentaDos")),
            art_marca=row.get("artMarca"),
        )
