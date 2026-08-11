/*
Prueba INSERT permanente en vntFPagoTxn desde SSMS.
Usa las mismas columnas/defaults que la API.

IMPORTANTE:
- No contiene BEGIN TRANSACTION.
- No contiene ROLLBACK.
- Si el INSERT es correcto, la fila queda guardada inmediatamente.
*/

USE [dbTest];
GO

SET NOCOUNT ON;

/* ========== 0) Diagnóstico de restricciones ========== */

PRINT '=== Triggers sobre vntFPagoTxn ===';

SELECT
    t.name AS trigger_name,
    t.is_disabled
FROM sys.triggers AS t
WHERE t.parent_id = OBJECT_ID('dbo.vntFPagoTxn');


PRINT '=== CHECK constraints ===';

SELECT
    cc.name,
    cc.definition
FROM sys.check_constraints AS cc
WHERE cc.parent_object_id = OBJECT_ID('dbo.vntFPagoTxn');


PRINT '=== Formas de pago válidas (gntFPago) ===';

SELECT fpaId
FROM dbo.gntFPago
ORDER BY fpaId;


PRINT '=== Monedas (gntMoneda) ===';

SELECT TOP (20)
    monId,
    monTipo
FROM dbo.gntMoneda
ORDER BY monId;


/* ========== 1) Parámetros del INSERT ========== */

DECLARE @vntId              varchar(50)    = N'PVEN121346';
DECLARE @monId              varchar(50)    = N'DOL';
DECLARE @fpaId              varchar(50)    = N'TRANSFER';
DECLARE @fpaReferencia      varchar(50)    = N'CAJVEN01CRI';
DECLARE @fpaFechaReferencia datetime       = '20260811';
DECLARE @fptMontoMoneda     decimal(24,12) = 30.00;
DECLARE @fptUsuario         varchar(50)    = N'4543695';
DECLARE @fptFechaCambio     datetime       = '2026-08-11T10:32:23.637';
DECLARE @fptTasaPenal       decimal(24,12) = 0;
DECLARE @fptDestinoIngreso  varchar(1)     = N'B'; -- TRANSFER → B
DECLARE @fpaDF              bit            = 1;
DECLARE @fptTipoRecargo     int            = 0;
DECLARE @fptCobrosQR        varchar(1)     = N'S';


/* ========== 2) Verificar venta antes del INSERT ========== */

SELECT
    v.vntId,
    v.vntEstado,
    v.monId AS monid_encabezado,
    v.vntTotalMoneda,
    v.vntFechaDoc,
    v.pveId,
    (
        SELECT COUNT(*)
        FROM dbo.vntFPagoTxn AS f
        WHERE f.vntId = v.vntId
    ) AS fpagos_actuales
FROM dbo.vntTxn AS v
WHERE v.vntId = @vntId;


/* ========== 3) INSERT permanente ========== */

BEGIN TRY

    INSERT INTO dbo.vntFPagoTxn (
        vntId,
        monId,
        fpaId,
        fpaReferencia,
        fpaFechaReferencia,
        fptMontoMoneda,
        fptUsuario,
        fptFechaCambio,
        fptTasaPenal,
        fptDestinoIngreso,
        fpaDF,
        fptTipoRecargo,
        fptCobrosQR
    )
    VALUES (
        @vntId,
        @monId,
        @fpaId,
        @fpaReferencia,
        @fpaFechaReferencia,
        @fptMontoMoneda,
        @fptUsuario,
        @fptFechaCambio,
        @fptTasaPenal,
        @fptDestinoIngreso,
        @fpaDF,
        @fptTipoRecargo,
        @fptCobrosQR
    );

    DECLARE @fptId int = CONVERT(int, SCOPE_IDENTITY());

    SELECT
        N'INSERT OK — fila guardada permanentemente' AS resultado,
        @fptId AS fptId,
        @fptDestinoIngreso AS destino;

    SELECT *
    FROM dbo.vntFPagoTxn
    WHERE fptId = @fptId;

END TRY
BEGIN CATCH

    /*
    No se ejecuta ROLLBACK porque no existe una transacción manual.
    Si el INSERT falla, la instrucción no guarda la fila.
    */

    SELECT
        ERROR_NUMBER()   AS error_number,
        ERROR_SEVERITY() AS severity,
        ERROR_STATE()    AS state,
        ERROR_LINE()     AS linea,
        ERROR_MESSAGE()  AS mensaje,
        CASE ERROR_NUMBER()
            WHEN 778967 THEN N'fpaId no existe en gntFPago'
            WHEN 779083 THEN N'monId no existe en gntMoneda'
            WHEN 779585 THEN N'vntId no existe en vntTxn'
            WHEN 547     THEN N'CHECK/FK: revisar que fptDestinoIngreso sea B o C'
            ELSE N'Ver el mensaje generado por SQL Server'
        END AS interpretacion;

END CATCH;
GO