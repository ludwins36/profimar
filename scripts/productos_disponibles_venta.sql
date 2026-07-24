/*
  Productos aptos para pedido VEN (opción C: existencia_venta > 0).

  Usa la misma regla que vmaApruebaTxn:
    - artTipo I → dbo.vmaExitencia(pveId, almId, artId, uniId)
    - otros tipos → intExistencia.exiExistencia en el almacén

  Ajuste @pveId y @almId (mismos que request.json: pve_id, pedido_almacen).
*/

USE [dbTest];
GO

DECLARE @pveId varchar(50) = N'PVMSC03',
        @almId varchar(50) = N'ALMCHICOTI';

DECLARE @artId varchar(50),
        @uniId varchar(50),
        @artTipo varchar(10),
        @exAlm decimal(24, 12),
        @exVenta decimal(24, 12);

DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
    SELECT a.artId, a.uniid, a.artTipo, ISNULL(e.exiExistencia, 0)
    FROM intArticulo a
    INNER JOIN intExistencia e ON e.artId = a.artId AND e.almId = @almId
    WHERE e.exiExistencia > 0
    ORDER BY a.artId;

OPEN cur;
FETCH NEXT FROM cur INTO @artId, @uniId, @artTipo, @exAlm;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @exVenta = @exAlm;

    IF @artTipo = N'I'
    BEGIN
        EXEC dbo.vmaExitencia
            @strPveId = @pveId,
            @strAlmacen = @almId,
            @strArtId = @artId,
            @strUnidaDestino = @uniId,
            @decExistencia = @exVenta OUTPUT;
    END

    IF @exVenta > 0
        SELECT @artId AS artId, @uniId AS uniId, @artTipo AS artTipo,
               @exAlm AS existencia_almacen, @exVenta AS existencia_venta;

    FETCH NEXT FROM cur INTO @artId, @uniId, @artTipo, @exAlm;
END

CLOSE cur;
DEALLOCATE cur;

GO
