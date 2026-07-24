USE [dbTest]
GO
/****** Object:  StoredProcedure [dbo].[nvnpAprobarTxnEcommerce]    Script Date: 13/06/2026 7:25:42 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[nvnpAprobarTxnEcommerce]
(
    @strVntId   VARCHAR(50),
    @strMensaje VARCHAR(500) OUTPUT,
    @strURL     VARCHAR(MAX) OUTPUT
)
AS
BEGIN

    SET NOCOUNT ON;
    DECLARE @strAsientoPrevio VARCHAR(5000) = 'N';

    BEGIN TRY

        SET @strMensaje = '';
        SET @strURL = '';

        DECLARE @strPveIdFacturacion VARCHAR (50) = '';
        SET @strPveIdFacturacion = (SELECT TOP 1 pveid FROM vntTxn WHERE vntId = @strVntId);

        EXEC dbo.vmaApruebaUno @strvntId = @strVntId,
                               @strPveIdFacturacion = @strPveIdFacturacion,
                               @lngNumeroFacturaManual = -1,
                               @strMensajeSalida = @strMensaje OUTPUT
        
        --===============================================================================
        -- SI NO TIENE MENSAJE DE ERROR, SE PROCEDE A OBTENER LA URL DE LA FACTURA
        --===============================================================================
        IF LEN(ISNULL(@strMensaje, '')) = 0
        BEGIN
            SET @strMensaje = ''

            --==============================================
            -- SE OBTIENE EL SERVIDOR Y LA BD DE IMPUESTOS
            --==============================================
            DECLARE @isfBaseImpuestos VARCHAR (50),
                    @isfServidorSQL   VARCHAR (50)

            SELECT @isfBaseImpuestos = isfBaseImpuestos,
                   @isfServidorSQL   = isfServidorSQL
            FROM iptServidorFactura

            SET @isfBaseImpuestos = ISNULL(@isfBaseImpuestos, '')
            SET @isfServidorSQL   = ISNULL(@isfServidorSQL, '')

            --====================================================================================================
            -- DEBEN ESTAR CONFIGURADOS EL SERVIDOR Y LA BD DE IMPUESTOS PARA OBTENER LA URL DE LA FACTURA
            --====================================================================================================
            IF NOT(@isfBaseImpuestos = '' OR @isfServidorSQL = '')
            BEGIN

                DECLARE @SQL NVARCHAR(MAX)
                DECLARE @isfReporting VARCHAR(MAX)
                SET @SQL = 'SELECT @isfReporting = isfReporting FROM ' + @isfServidorSQL + '.' + @isfBaseImpuestos + '.dbo.iptServidorFactura'
                EXEC sp_executesql @SQL, N'@isfReporting VARCHAR(500) OUTPUT', @isfReporting = @isfReporting OUTPUT

                SET @strURL = @isfReporting + '&strEmpId=' + @isfBaseImpuestos + '&facId=' + @strVntId
            END
            RETURN 1;
        END

        RETURN 0;

    END TRY
    BEGIN CATCH

        SET @strMensaje = ERROR_MESSAGE();
        SET @strURL = '';

        RETURN 0;

    END CATCH
END
