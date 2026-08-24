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
- Request logs (privado): http://127.0.0.1:8000/private/logs?token=TU_LOGS_SECRET  

### Logging de requests

En `.env`:

```env
LOG_REQUESTS=true
LOGS_SECRET=cambiar-este-secreto
LOGS_MAX_ENTRIES=500
```

- `LOG_REQUESTS=true` activa el middleware (method, path, query, body, status, duración).
- La UI `/private/logs` exige `?token=` o header `X-Logs-Token` igual a `LOGS_SECRET`.
- Los logs viven en memoria (anillo); se pierden al reiniciar el proceso.

## APIs disponibles

> Prefijo global: `/api`

| Método | Ruta | Descripción |
|--------|------|-------------|
| GET | `/` | Health check básico de la app |
| GET | `/private/logs?token=SECRET` | UI interactiva de request logs (requiere `LOGS_SECRET`) |
| GET | `/private/logs/api?token=SECRET` | JSON de logs (filtros method/path) |
| DELETE | `/private/logs/api?token=SECRET` | Limpia logs en memoria |
| GET | `/api/test` | Estado general de API + configuración |
| GET | `/api/test/db` | Prueba conexión a SQL Server (`SELECT 1`) |
| GET | `/api/test/tables` | Lista tablas base de la BD actual |
| GET | `/api/test/table-detail/{table_name}` | Estructura de una tabla (columnas + PK) |
| GET | `/api/test/table-sample/{table_name}?limit=N` | Muestra filas de una tabla |
| GET | `/api/products` | Lista productos con existencia agregada |
| GET | `/api/products/precios-cantidad` | Precios por tramo de cantidad (`vntListaPrecioCantidad`) |
| GET | `/api/products/{art_id}` | Obtiene un producto por `artId` |
| GET | `/api/clients` | Lista clientes |
| POST | `/api/clients` | Crea cliente en directorio |
| GET | `/api/clients/get-saldo` | Ejecuta SP de débito pendiente |
| GET | `/api/clients/{dir_id}` | Obtiene cliente por `dirId` |
| GET | `/api/tipo-cambio` | Última tasa de cambio (`gntTipoCambio`); opcional `?fecha=` |
| GET | `/api/tipo-cambio/convertir` | Convierte monto BOL↔DOL (`?monto=&moneda=BOL\|DOL`) |
| POST | `/api/orders` | Crea orden completa (encabezado + líneas en transacción) |
| POST | `/api/orders/encabezado` | Inserta encabezado (genera `vntId` con SP si falta) |
| POST | `/api/orders/lineas` | Inserta una línea de pedido |
| GET | `/api/orders` | Lista órdenes legacy (filtros opcionales) |
| GET | `/api/orders/{orden_id}` | Obtiene orden legacy por ID |

## Tablas y objetos usados por API

### Productos

- `GET /api/products`
  - Tablas: `intArticulo` (alias `a`), `intexistencia` (alias `e`).
  - Join: `LEFT JOIN intexistencia e ON e.artId = a.artId`.
  - Columnas de `intArticulo`: `artId`, `artNombre`, `garId`, `uniid`, `artCodigoFabrica`, `artPrecioVenta`, `artPrecioVentaDos`, `artMarca`, `monid`, `carId`.
  - Columna agregada: `SUM(e.exiExistencia)` como `total_existencia`.
- `GET /api/products/{art_id}`
  - Misma estructura que el listado, con filtro `WHERE a.artId = ?`.
- `GET /api/products/precios-cantidad`
  - Tabla: `vntListaPrecioCantidad`.
  - Filtros opcionales: `art_id`, `lpr_id`.
  - Columnas: `cantId`, `lprid`, `artId`, `cantInicial`, `cantFinal`, `cantPrecio`, `monid`, `horid`.

### Clientes

- `GET /api/clients`
  - Tabla: `gntdirectorio`.
  - Columnas: `dirId`, `dirNombre`, `dirRuc`, `dirRazonSocial`, `dirInternet`, `dirRendicionesVencidasPermitidas`.
- `POST /api/clients`
  - Tabla: `gntdirectorio`.
  - Lectura para consecutivo: `MAX(TRY_CAST(dirId AS INT))`.
  - Inserta columnas: `dirId`, `dirNombre`, `dirRuc`, `dirRazonSocial`, `dirInternet`, `dirRendicionesVencidasPermitidas`.
- `GET /api/clients/{dir_id}`
  - Tabla: `gntdirectorio`.
  - Filtro: `WHERE dirId = ?`.
- `GET /api/clients/get-saldo`
  - Objeto SQL: procedimiento almacenado `dbo.nctpDebitoPendienteDeCobroFvenc`.
  - Usa 13 parámetros (según schema `GetSaldoQuery`).

### Órdenes

- `POST /api/orders` **(recomendado)**
  - Crea la orden completa: fecha actual + `gnpGenerarIdUno` → INSERT encabezado + líneas + forma de pago en transacción.
  - Tablas: `vnttxn` + `vntdettxn` + `vntFPagoTxn`. No enviar `vnt_id` ni `pvd_id` (IDENTITY).
  - **Forma de pago (`vntFPagoTxn`):**
    - `pedido_forma_pago` → `fpaid` (obligatorio).
    - `pedido_pago_qr` → `fptCobrosQR`.
    - `pedido_pago_referencia` → `fptReferenciaIngreso`: **cuenta bancaria** (`cprId`). Solo aplica cuando `pedido_forma_pago=TRANSFER` y `pedido_pago_qr=N` (si no, omitir el campo).
    - `pedido_pago_dir` → `fpaReferencia`: directorio del banco (`bntCuentaPropia.dirid`).
    - `fptUsuario` = RUC (`cliente_ruc`); `fptPlazo`/`fptDiasAño` = 30; `fptNroDocumento` = `vntId` solo si TRANSFER.
    - `fptDiasAño` = `gntDirectorio.dirNroDiasCliente`; `fptPlazo` = `cttParametro.parDiasDefaultDebito`.
  - **Validaciones de maestros/catálogo:** pendientes (fase posterior). Ejemplo: `request.json`.
  - Respuesta:
    ```json
    {
      "status": "ok",
      "encabezado": { "...": "fila insertada" },
      "forma_pago": { "...": "fila en vntFPagoTxn" },
      "lineas": [ { "...": "producto 1" }, { "...": "producto 2" } ],
      "total_lineas": 2
    }
    ```
- `POST /api/orders/encabezado`
  - Genera `vnt_id` + fecha actual. Tabla `vnttxn`.
- `POST /api/orders/lineas`
  - Tabla `vntdettxn`. Sin validaciones de catálogo (fase posterior).
  - Mapeos frecuentes: `vnt_id`→`vntid`, `art_id`→`artId`, `pvd_precio_moneda`→`pvdPrecioMoneda`, `pvd_cantidad_vendida`→`pvdCantidadVendida`, `pvd_cantidad_entregada`→`pvdCantidadEntregada`, `pvd_descripcion`→`pvdDescripcion`, `pvd_fecha_entrega`→`pvdFechaEntrega`.
  - Alias legacy: `ped_precio_sin_iva`→`pvdPrecioMoneda`, `ped_cantidad_v`→`pvdCantidadVendida`, `ped_id`→`vntid`.
  - Devuelve fila insertada con INSERT + SELECT (compatible con triggers).
- `GET /api/orders`
  - Tabla legacy: `Ordenes`.
  - Columnas: `id`, `cliente_id`, `fecha_orden`, `total`, `estado`, `creado_en`, `actualizado_en`.
  - Filtros opcionales: `cliente_id`, `estado`.
- `GET /api/orders/{orden_id}`
  - Tabla legacy: `Ordenes`.
  - Filtro: `WHERE id = ?`.

### Endpoints de diagnóstico (`/api/test`)

- `GET /api/test`
  - No consulta tablas; solo configuración cargada.
- `GET /api/test/db`
  - Sin tablas; consulta de prueba `SELECT 1 AS test, @@VERSION AS version`.
- `GET /api/test/tables`
  - Vista de sistema: `INFORMATION_SCHEMA.TABLES`.
- `GET /api/test/table-detail/{table_name}`
  - Vistas de sistema: `INFORMATION_SCHEMA.COLUMNS`, `INFORMATION_SCHEMA.TABLE_CONSTRAINTS`, `INFORMATION_SCHEMA.KEY_COLUMN_USAGE`.
- `GET /api/test/table-sample/{table_name}`
  - Valida en `INFORMATION_SCHEMA.TABLES` y luego consulta dinámica a la tabla solicitada.

## Conexión “asíncrona”

`pyodbc` es síncrono. En `app/core/database.py` las consultas se ejecutan en un **thread pool** (`run_in_executor`), de modo que el event loop de FastAPI no se bloquea y la API responde de forma concurrente. En las consultas se usan placeholders **`?`** (estilo pyodbc).

## Licencia

Uso interno / proyecto Profimar.
