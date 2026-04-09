# Profimar

API REST con **FastAPI** y **SQL Server** (pyodbc), arquitectura modular.

## Estructura del proyecto

```
profimar/
├── app/
│   ├── api/              # Capa API
│   │   └── routes/       # Rutas por recurso
│   ├── core/             # Configuración y conexión
│   │   ├── config.py     # Variables de entorno (Pydantic)
│   │   └── database.py   # Conexión pyodbc (uso async vía thread pool)
│   ├── models/           # Modelos de dominio / tablas
│   ├── schemas/          # Schemas Pydantic (validación)
│   └── main.py           # Entrada FastAPI
├── scripts/              # SQL y utilidades
├── .env.example
├── requirements.txt
└── README.md
```

## Requisitos

- Python 3.10+
- SQL Server accesible (local o remoto)
- **Driver ODBC para SQL Server** instalado (ej. "ODBC Driver 17 for SQL Server" o 18)

## Instalación

```bash
python -m venv .venv
.venv\Scripts\activate   # Windows
pip install -r requirements.txt
```

## Configuración

1. Copiar variables de entorno:
   ```bash
   copy .env.example .env
   ```
2. Editar `.env` con tu servidor, usuario, contraseña y base de datos.
3. (Opcional) Crear las tablas en SQL Server (en este orden):
   ```bash
   # scripts/create_tabla_productos.sql
   # scripts/create_tabla_clientes.sql
   # scripts/create_tabla_ordenes.sql
   ```

## Ejecutar

```bash
uvicorn app.main:app --reload
```

- API: http://127.0.0.1:8000  
- Docs: http://127.0.0.1:8000/docs  

## Rutas

| Método | Ruta | Descripción |
|--------|------|-------------|
| GET | `/api/products` | Lista productos (skip, limit, solo_activos) |
| GET | `/api/products/{id}` | Un producto por ID |
| GET | `/api/clients` | Lista clientes (skip, limit, solo_activos) |
| GET | `/api/clients/{id}` | Un cliente por ID |
| GET | `/api/orders` | Lista órdenes (skip, limit, cliente_id, estado) |
| GET | `/api/orders/{id}` | Una orden por ID |

## Conexión “asíncrona”

`pyodbc` es síncrono. En `app/core/database.py` las consultas se ejecutan en un **thread pool** (`run_in_executor`), de modo que el event loop de FastAPI no se bloquea y la API responde de forma concurrente. En las consultas se usan placeholders **`?`** (estilo pyodbc).

## Licencia

Uso interno / proyecto Profimar.
