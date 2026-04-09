"""
Punto de entrada de la aplicación FastAPI - Profimar.
"""
from contextlib import asynccontextmanager

from fastapi import FastAPI

from app.api.routes import clients, orders, products, test
from app.core.config import get_settings
                

@asynccontextmanager
async def lifespan(app: FastAPI):
    """Eventos al iniciar y cerrar la aplicación."""
    # Startup
    yield
    # Shutdown (limpieza si hiciera falta)


def create_app() -> FastAPI:
    """Factory de la aplicación."""
    settings = get_settings()
    app = FastAPI(
        title=settings.app_name,
        description="API con FastAPI + SQL Server (pymssql)",
        version="0.1.0",
        lifespan=lifespan,
    )
    app.include_router(products.router, prefix="/api")
    app.include_router(clients.router, prefix="/api")
    app.include_router(orders.router, prefix="/api")
    app.include_router(test.router, prefix="/api")
    return app


app = create_app()


@app.get("/")
async def root():
    """Health check / raíz."""
    return {"app": get_settings().app_name, "status": "ok"}
