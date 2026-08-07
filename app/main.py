"""
Punto de entrada de la aplicación FastAPI - Profimar.
"""
from contextlib import asynccontextmanager

from fastapi import FastAPI

from app.api.routes import clients, logs_ui, orders, products, pve_almacenes, test
from app.core.config import get_settings
from app.core.request_log_store import request_log_store
from app.middleware import RequestLoggingMiddleware


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Eventos al iniciar y cerrar la aplicación."""
    settings = get_settings()
    request_log_store.resize(settings.logs_max_entries)
    yield


def create_app() -> FastAPI:
    """Factory de la aplicación."""
    settings = get_settings()
    app = FastAPI(
        title=settings.app_name,
        description="API con FastAPI + SQL Server (pyodbc)",
        version="0.1.0",
        lifespan=lifespan,
    )
    app.add_middleware(RequestLoggingMiddleware)
    app.include_router(products.router, prefix="/api")
    app.include_router(pve_almacenes.router_puntos_venta, prefix="/api")
    app.include_router(pve_almacenes.router_almacenes, prefix="/api")
    app.include_router(clients.router, prefix="/api")
    app.include_router(orders.router, prefix="/api")
    app.include_router(test.router, prefix="/api")
    app.include_router(logs_ui.router)
    return app


app = create_app()


@app.get("/")
async def root():
    """Health check / raíz."""
    return {"app": get_settings().app_name, "status": "ok"}
