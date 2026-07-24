/*
  Diagnóstico: columnas del encabezado que faltan vs un pedido existente.

  Ejecutar en SSMS (dbTest).

  1. Cambie @vntIdPlantilla (p. ej. PVEN121279).
  2. Primera grilla: todas las columnas NO NULL de la plantilla.
  3. Segunda grilla: solo las que NO envía request.json / test Python.
  4. Al final: definición del trigger vntTxn_ITrig.

  INSERT mínimo (= request.json / test Python):
    pveid, vntFechaDoc, vntReferencia, cliid, venid, modId, vntTotalMoneda,
    vntEstado, vntUsuario, sucid, monid, lprid, mdeid, vntid
*/

USE [dbTest];
GO

DECLARE @vntIdPlantilla varchar(50) = N'PVEN121279';

IF NOT EXISTS (SELECT 1 FROM vnttxn WHERE vntid = @vntIdPlantilla)
BEGIN
    RAISERROR(N'No existe vntid plantilla: %s. Cambie @vntIdPlantilla.', 16, 1, @vntIdPlantilla);
    RETURN;
END

DECLARE @inner nvarchar(max) = N'';

SELECT @inner = @inner + CASE WHEN @inner = N'' THEN N'' ELSE N' UNION ALL ' END
    + N'SELECT '''
    + REPLACE(c.name, '''', '''''')
    + N''' AS columna, CAST(t.[' + c.name + N'] AS sql_variant) AS valor_en_plantilla, '
    + CASE WHEN c.name IN (
        N'pveid', N'vntFechaDoc', N'vntReferencia', N'cliid', N'venid',
        N'modId', N'vntTotalMoneda', N'vntEstado', N'vntUsuario',
        N'sucid', N'monid', N'lprid', N'mdeid', N'vntid'
      ) THEN N'1' ELSE N'0' END
    + N' AS en_insert_minimo, '
    + CAST(c.column_id AS nvarchar(10))
    + N' AS orden_tabla'
    + N' FROM vnttxn t WHERE t.vntid = @pid'
FROM sys.columns c
INNER JOIN sys.tables tb ON tb.object_id = c.object_id
WHERE tb.name = N'vnttxn'
  AND c.is_identity = 0
ORDER BY c.column_id;

DECLARE @sql nvarchar(max) = N'
;WITH cols AS (' + @inner + N')
SELECT
    columna,
    CAST(valor_en_plantilla AS nvarchar(4000)) AS valor_en_plantilla,
    CASE en_insert_minimo WHEN 1 THEN N''Sí'' ELSE N''No'' END AS en_insert_minimo,
    orden_tabla
FROM cols
WHERE valor_en_plantilla IS NOT NULL
ORDER BY en_insert_minimo, orden_tabla;
';

PRINT '=== Todas las columnas NO NULL de la plantilla (No = candidatas a faltar) ===';
EXEC sp_executesql @sql, N'@pid varchar(50)', @pid = @vntIdPlantilla;

SET @sql = N'
;WITH cols AS (' + @inner + N')
SELECT
    columna,
    CAST(valor_en_plantilla AS nvarchar(4000)) AS valor_en_plantilla,
    orden_tabla
FROM cols
WHERE valor_en_plantilla IS NOT NULL
  AND en_insert_minimo = 0
ORDER BY orden_tabla;
';

PRINT '';
PRINT '=== SOLO las que FALTAN en el INSERT mínimo ===';
EXEC sp_executesql @sql, N'@pid varchar(50)', @pid = @vntIdPlantilla;

PRINT '';
PRINT '=== Fila completa plantilla ===';
EXEC sp_executesql N'SELECT * FROM vnttxn WHERE vntid = @pid', N'@pid varchar(50)', @pid = @vntIdPlantilla;

PRINT '';
PRINT '=== Definición vntTxn_ITrig (busque 779257 / nsp_ApruebaUno ~ línea 53) ===';
SELECT OBJECT_DEFINITION(OBJECT_ID(N'vntTxn_ITrig')) AS definicion_trigger;

GO
