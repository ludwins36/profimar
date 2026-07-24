# request.json — ejemplo de orden completa

Archivo de prueba para `POST /api/orders`. Contiene un encabezado (`vnttxn`) y dos líneas (`vntdettxn`).

```bash
# Probar con la API
curl -X POST http://localhost:8000/api/orders -H "Content-Type: application/json" -d @request.json

# Probar sin levantar la API
python scripts/test_crear_orden_completa.py --completa --json request.json
```

Valores de ejemplo válidos en **dbTest** local (cliente, PVE, almacén y artículos con existencia).

---

## Encabezado (`encabezado`)

| Campo API | Columna ERP | Qué es | De dónde sale |
|-----------|-------------|--------|---------------|
| `pedido_tipo` | `vnttxn.ttxId` | Tipo de transacción (venta = `VEN`). | Catálogo `gntTipoTxn`. En ecommerce suele ser fijo `VEN`; la API también lo asigna por defecto. |
| `pedido_numero` | `vnttxn.vntReferencia` | Referencia o número externo del pedido web. | Sistema origen (e-commerce). **No** es el `vntId` del ERP. |
| `pedido_cliente` | `vnttxn.cliid` | Cliente que compra. | Maestro `gntCliente`. Consultar `GET /api/clientes`. |
| `pedido_vendedor` | `vnttxn.venid` | Vendedor asignado. | Maestro `gntVendedor`. Si no se envía `resp_id`, la API lo usa también como responsable (`respid`). |
| `pedido_total` | `vnttxn.vntTotalMoneda` | Total del pedido en moneda del documento. | Calculado en el origen; debe cuadrar con la suma de líneas. |
| `pedido_moneda` | `vnttxn.monid` | Moneda (`DOL`, `BOL`, …). | Maestro `gntMoneda` (validado por trigger `vntTxn_ITrig`). |
| `pedido_sucursal` | `vnttxn.sucid` | Sucursal comercial. | Maestro `gntSucursal` (ej. `LPZ`). |
| `pedido_forma_pago` | `vnttxn.mdeid` | Código que se guarda en `mdeid`. | Maestro asociado a `mdeid`. **Nota:** en el ERP `mdeid` es motivo de devolución, no la forma de pago contable; al aprobar se genera `vntFPagoTxn` vía `vmaGeneraFpagoTxn`. |
| `pedido_lista_precio` | `vnttxn.lprid` | Lista de precios aplicada. | Maestro `gntListaPrecio` (ej. `UNICA`). |
| `pedido_condicion` | `vnttxn.modId` | Condición / módulo de venta del documento. | Parámetros de ventas `gntParametroModulo` (ej. `vn`). No es un dato del producto. |
| `pve_id` | `vnttxn.pveid` | Punto de venta desde el cual se aprueba/factura. | Maestro `gntPuntoventa`. Debe ser compatible con `pedido_almacen`. Ver `GET /api/puntos-venta` y `GET /api/puntos-venta/{pve_id}/almacenes`. |
| `pedido_usuario` | `vnttxn.vntUsuario` | Usuario ERP que registra el pedido. | Maestro `gntUsuario` / usuario de sesión ecommerce mapeado al ERP. |
| `pedido_almacen` | `vntdettxn.pvdDescripcion` | Almacén de despacho (`almId`). **Obligatorio** en orden completa. | No se inserta en `vnttxn`; la API lo copia a cada línea. Origen: `intExistencia` / almacenes del PVE. Ver `GET /api/almacenes?pve_id=...` y stock en `GET /api/products?pve_id=...&alm_id=...`. |

### Valores de ejemplo en este archivo

| Campo | Valor | Notas |
|-------|-------|-------|
| `pedido_cliente` | `7954661011` | Cliente de prueba |
| `pedido_vendedor` | `4689684` | Vendedor de prueba |
| `pve_id` | `PVCEN01` | Compatible con almacén `ALMCHICOTI` |
| `pedido_almacen` | `ALMCHICOTI` | Usar con `PVCEN01` o `PVCEN03`, no con `PVMSC03` |

---

## Líneas (`lineas[]`)

Cada elemento es una fila de `vntdettxn`. La API asigna `vntid` desde el encabezado y `pvdConSolicitud = N`.

| Campo API | Columna ERP | Qué es | De dónde sale |
|-----------|-------------|--------|---------------|
| `art_id` | `vntdettxn.artId` | Código del artículo. | Maestro `intArticulo`. Consultar `GET /api/products`. |
| `uni_id` | `vntdettxn.uniid` | Unidad de medida (ej. `PZA`). | `intUnidadArticulo` / unidad configurada para el artículo. |
| `ped_precio_sin_iva` | `vntdettxn.pvdPrecioMoneda` | Precio unitario sin IVA en moneda del pedido. | Lista `lprid` / catálogo ecommerce. |
| `ped_cantidad_v` | `vntdettxn.pvdCantidadVendida` | Cantidad vendida. | Carrito / pedido ecommerce. |
| `ped_cantidad_p` | `vntdettxn.pvdCantidadEntregada` | Cantidad a entregar. | Pedido ecommerce; si falta, la API puede copiar desde `ped_cantidad_v`. |

### Líneas de ejemplo

| `art_id` | Precio | Cantidad | Total línea |
|----------|--------|----------|-------------|
| `000-008` | 10.00 | 1 | 10.00 |
| `000-39003-0001` | 20.00 | 1 | 20.00 |

Suma = **30.00** (= `pedido_total`).

---

## Campos que asigna la API (no van en request.json)

| Campo | Columna ERP | Origen |
|-------|-------------|--------|
| `vnt_id` | `vnttxn.vntid` | `dbo.gnpGenerarIdUno` (ej. `PVEN121325`) |
| `vnt_fecha_doc` | `vnttxn.vntFechaDoc` | Fecha actual del servidor SQL (`GETDATE`) |
| `vnt_estado` | `vnttxn.vntEstado` | Siempre `R` al crear; pasa a `A` al aprobar |
| `resp_id` | `vnttxn.respid` | `pedido_vendedor` / `ven_id` si no se envía |
| `vnt_articulo_moneda` | `vnttxn.vntArticuloMoneda` | Suma `ped_precio_sin_iva × ped_cantidad_v` de las líneas |
| `vnt_tc` | `vnttxn.vntTC` | `gntTipoCambio` (moneda central) vigente a `vntFechaDoc` |
| `tdo_id` | `vnttxn.tdoid` | `gntPuntoventa.tdoId` del `pve_id` |
| `pvd_con_solicitud` | `vntdettxn.pvdConSolicitud` | Siempre `N` |

---

## Respuesta de `POST /api/orders`

Tras insertar, la API ejecuta `dbo.nvnpAprobarTxnEcommerce` con el `vnt_id` generado.

| Campo respuesta | Significado |
|-----------------|-------------|
| `str_mensaje` | Salida `@strMensaje` del SP. **Vacío** = aprobación OK. Con texto = error ERP (la orden ya quedó insertada). |
| `str_url` | URL de factura fiscal si está configurado `iptServidorFactura`. |
| `status` | `ok` si `str_mensaje` vacío; `error_aprobacion` si hubo mensaje de error. |

---

## Errores frecuentes en pruebas locales

| Síntoma | Causa habitual |
|---------|----------------|
| Existencia / `vmaExitencia` | `pve_id` y `pedido_almacen` incompatibles. Usar `PVCEN01` + `ALMCHICOTI`. |
| `No Existe el responsable` | Falta `respid`; la API lo completa desde vendedor si envías `pedido_vendedor`. |
| Periodo contable / CA | Fecha del documento fuera de `gntParametroModulo` (`cn`, `vn`, `ca`). Ver `scripts/ajuste_periodo_ca_pruebas_local.sql`. |
