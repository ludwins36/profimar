/*
  Equivalente SQL de test_crear_orden_completa.py (modo solo encabezado).
  Datos: request.json (raíz del proyecto). Sin validaciones previas ni líneas.

  @guardarCambios: 0 = ROLLBACK (prueba), 1 = COMMIT (guardar).
*/

USE [dbTest];
GO

BEGIN TRANSACTION;

DECLARE @guardarCambios bit = 0;

/* ========== request.json → encabezado ========== */
DECLARE @ttxId varchar(50) = N'VEN',
        @pveid varchar(50) = N'PVMSC03',
        @vntReferencia varchar(50) = N'PVEN022204',
        @cliid varchar(50) = N'7954661011',
        @venid varchar(50) = N'4689684',
        @respid varchar(50) = N'4689684',  /* responsable; vmaApruebaTxn lo exige (= venid en ERP) */
        @modId varchar(50) = N'vn',
        @vntTotalMoneda decimal(18, 6) = 1000.00,
        @vntEstado varchar(1) = N'R',  /* siempre en revisión (API / ecommerce) */
        @vntUsuario varchar(50) = N'4660553',
        @sucid varchar(50) = N'LPZ',
        @monid varchar(50) = N'DOL',
        @lprid varchar(50) = N'UNICA',
        @mdeid varchar(50) = N'TARJETA';

/* ========== Generar vntId (igual que _generar_vnt_id: tipo VEN por defecto) ========== */
DECLARE @return_value int,
        @strNuevoIdTxn varchar(50),
        @strMensajeSalida varchar(4000),
        @vntIdGenerado varchar(50);

EXEC @return_value = [dbo].[gnpGenerarIdUno]
    @strTipoTxn = N'VEN',
    @varGeneracionId = N'M',
    @strTabla = N'vntTxn',
    @strCampoId = N'vntId',
    @strNuevoIdTxn = @strNuevoIdTxn OUTPUT,
    @strMensajeSalida = @strMensajeSalida OUTPUT;

SET @vntIdGenerado = @strNuevoIdTxn;

IF NULLIF(LTRIM(RTRIM(@strMensajeSalida)), N'') IS NOT NULL
BEGIN
    RAISERROR('gnpGenerarIdUno: %s', 16, 1, @strMensajeSalida);
    ROLLBACK TRANSACTION;
    RETURN;
END

SELECT @vntIdGenerado AS vntIdGenerado, @return_value AS return_code;

/* ========== Encabezado (mismas columnas que el test Python / _insert_encabezado) ========== */
INSERT INTO [vnttxn] (
    [ttxId],
    [pveid],
    [vntFechaDoc],
    [vntReferencia],
    [cliid],
    [venid],
    [modId],
    [vntTotalMoneda],
    [vntEstado],
    [vntUsuario],
    [sucid],
    [monid],
    [lprid],
    [mdeid],
    [vntid]
)
VALUES (
    @ttxId,
    @pveid,
    CAST(CAST(GETDATE() AS date) AS datetime),
    @vntReferencia,
    @cliid,
    @venid,
    @respid,
    @modId,
    @vntTotalMoneda,
    @vntEstado,
    @vntUsuario,
    @sucid,
    @monid,
    @lprid,
    @mdeid,
    @vntIdGenerado
);

IF @guardarCambios = 1
BEGIN
    COMMIT TRANSACTION;
    SELECT @vntIdGenerado AS vntid_guardado;
    SELECT * FROM vnttxn WHERE vntid = @vntIdGenerado;
END
ELSE
BEGIN
    ROLLBACK TRANSACTION;
    SELECT N'ROLLBACK — sin filas en BD. vntId: ' + @vntIdGenerado AS aviso;
END

GO
