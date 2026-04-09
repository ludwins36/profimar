"""
Modelo de dominio para la tabla gntdirectorio.
"""
from dataclasses import dataclass
from typing import Optional


@dataclass
class Cliente:
    """Modelo de dominio para un registro de la tabla gntdirectorio."""

    dir_id: str
    dir_nombre: Optional[str]
    dir_ruc: Optional[str]
    dir_razon_social: Optional[str]
    dir_internet: Optional[str]
    dir_rendiciones_vencidas_permitidas: Optional[int]

    @classmethod
    def from_row(cls, row: dict) -> "Cliente":
        """Construye Cliente desde una fila dict."""
        return cls(
            dir_id=str(row["dirId"]),
            dir_nombre=row.get("dirNombre"),
            dir_ruc=row.get("dirRuc"),
            dir_razon_social=row.get("dirRazonSocial"),
            dir_internet=row.get("dirInternet"),
            dir_rendiciones_vencidas_permitidas=cls._safe_int(row.get("dirRendicionesVencidasPermitidas")),
        )

    @staticmethod
    def _safe_int(v) -> Optional[int]:
        if v is None:
            return None
        s = str(v).strip()
        if not s:
            return None
        try:
            return int(s)
        except (ValueError, TypeError):
            return None
