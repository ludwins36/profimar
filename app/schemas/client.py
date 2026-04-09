"""
Schemas Pydantic para la entidad Cliente (tabla gntdirectorio).
"""
from typing import Optional

from pydantic import BaseModel, ConfigDict, Field


class ClienteBase(BaseModel):
    """Campos comunes para cliente."""

    nombre: Optional[str] = Field(None, max_length=250, description="dirNombre")
    nit: Optional[str] = Field(None, max_length=50, description="dirRuc")
    razon_social: Optional[str] = Field(None, max_length=250, description="dirRazonSocial")
    correo: Optional[str] = Field(None, max_length=50, description="dirInternet")
    notas_vencidas_permitidas: Optional[int] = Field(None, description="dirRendicionesVencidasPermitidas")


class ClienteCreate(ClienteBase):
    """Schema para crear un cliente. dirId se genera automáticamente (MAX(dirId)+1)."""


class ClienteUpdate(BaseModel):
    """Schema para actualización parcial."""

    nombre: Optional[str] = Field(None, max_length=250)
    nit: Optional[str] = Field(None, max_length=50)
    razon_social: Optional[str] = Field(None, max_length=250)
    correo: Optional[str] = Field(None, max_length=50)
    notas_vencidas_permitidas: Optional[int] = None


class ClienteResponse(ClienteBase):
    """Schema de respuesta."""

    model_config = ConfigDict(from_attributes=True)

    id: str = Field(..., description="dirId - código cliente PK varchar(50)")


class ClienteListResponse(BaseModel):
    """Respuesta paginada de clientes."""

    items: list[ClienteResponse]
    total: int
