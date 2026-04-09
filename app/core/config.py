"""
Configuración de la aplicación mediante variables de entorno.
Carga desde archivo .env (python-dotenv).
"""
from functools import lru_cache
from typing import Optional

from pydantic import Field, model_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Configuración validada con Pydantic desde .env."""

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore",
    )

    # App
    app_name: str = Field(default="Profimar", description="Nombre de la aplicación")
    debug: bool = Field(default=False, description="Modo debug")

    # SQL Server (pyodbc)
    mssql_server: str = Field(..., description="Host o instancia (ej: localhost\\SQLEXPRESS)")
    mssql_port: int = Field(default=0, description="Puerto (0 = instancia nombrada, sin puerto)")
    mssql_user: str = Field(default="", description="Usuario (vacío si Windows Auth)")
    mssql_password: str = Field(default="", description="Contraseña (vacía si Windows Auth)")
    mssql_database: str = Field(..., description="Nombre de la base de datos")
    mssql_driver: str = Field(
        default="ODBC Driver 17 for SQL Server",
        description="Nombre del driver ODBC",
    )
    mssql_trusted_connection: bool = Field(
        default=False,
        description="True = autenticación Windows (Trusted_Connection)",
        validation_alias="MSSQL_USE_WINDOWS_AUTH",
    )

    @model_validator(mode="after")
    def check_auth(self) -> "Settings":
        if self.mssql_trusted_connection and (self.mssql_user or self.mssql_password):
            raise ValueError(
                "Con Windows Auth (mssql_use_windows_auth=true) no uses MSSQL_USER ni MSSQL_PASSWORD"
            )
        if not self.mssql_trusted_connection and not self.mssql_user:
            raise ValueError("Sin Windows Auth debes indicar MSSQL_USER")
        return self

    def get_connection_string(self) -> str:
        """Cadena de conexión para pyodbc."""
        parts = [
            f"DRIVER={{{self.mssql_driver}}};",
            f"DATABASE={self.mssql_database};",
        ]
        if self.mssql_port and self.mssql_port > 0:
            parts.append(f"SERVER={self.mssql_server},{self.mssql_port};")
        else:
            parts.append(f"SERVER={self.mssql_server};")
        if self.mssql_trusted_connection:
            parts.append("Trusted_Connection=yes;")
        else:
            parts.append(f"UID={self.mssql_user};PWD={self.mssql_password};")
        return "".join(parts)

    @property
    def database_url_style(self) -> str:
        """Representación legible (sin contraseña) para logs."""
        auth = "Windows Auth" if self.mssql_trusted_connection else f"user={self.mssql_user}"
        return f"server={self.mssql_server};database={self.mssql_database};{auth}"


@lru_cache
def get_settings() -> Settings:
    """Singleton de configuración (cacheado)."""
    return Settings()
