USE [dbTest]
GO
/****** Object:  StoredProcedure [dbo].[vmaApruebaUno]    Script Date: 13/06/2026 7:41:21 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[vmaApruebaUno] 
	@strvntId varchar(15),
	@strPveIdFacturacion VARCHAR(10)='',--Optional strPveIdFacturacion As String = "", 
	@lngNumeroFacturaManual BIGINT=-1,--Optional lngNumeroFacturaManual As Long = -1
	@strMensajeSalida varchar(500) OUTPUT
  AS BEGIN
	-- DEFINE OPCIONES DE EJECUCION 
	SET NOCOUNT ON;
	SET XACT_ABORT ON;
	
	-- DECLARA VARIABLES
	DECLARE @strNombreParamSP VARCHAR (200);
	DECLARE @strMensajeError VARCHAR(500);
	DECLARE @strLogro VARCHAR(50);
	DECLARE @strFormaP VARCHAR(50);
	DECLARE @strVentaAnulada VARCHAR(50);
	DECLARE @strMotorViajaAimpuesto VARCHAR(50);
	set @strLogro=1
	-- REALIZA PROCESO
	BEGIN TRY
		---- VALIDA PARAMETROS
		--IF (@strEstado = '*') BEGIN
		--	SET @strMensajeError = @strNombreParamSP + ' ERROR: El estado no puede ser *';
		--	RAISERROR (@strMensajeError, 16, 1);
		--	---- THROW 51000, @strMensajeError, 1;
		--END;		
		SET @strNombreParamSP = 'vmaApruebaUno - ' + ISNULL(@strvntId,'');
		-- PROCESOS NO TRANSACCIONALES
		
		BEGIN TRANSACTION
			-- PROCESOS TRANSACCIONALES
			-- EXEC nsp_Aprueba @strCabId = @strCabId, @strEstado = @strEstado;
			   EXEC vmaApruebaTxn @strvntId,@strPveIdFacturacion,@lngNumeroFacturaManual
			-- MENSAJE DE FIN DE PROCESO						
			PRINT @strNombreParamSP;			
	        set @strLogro=2
		COMMIT TRANSACTION  	
	        declare  @msm as varchar(500),@strdosId as varchar(500)
	--		SELECT @strMotorViajaAimpuesto=vntFacturarMotorImposivo FROM vntTxn where vntId=@strvntId
	--if @strMotorViajaAimpuesto='S'begin
     if   isnull((select top 1 cast(vntConFactura as varchar) from vntTxn where vntId=@strvntId and vntConFactura=1 and vntConDFR=0),'0')='1' begin
		if @strLogro=2 and ISNULL((SELECT ippFacturaOnline FROM iptparametro WHERE 1 = 1),'N')='S' and isnull((select top 1 cast(vntConFactura as varchar) from vntTxn where ttxId='VEN'AND vntId=@strvntId),'0')='1'  begin	
		    SET @strFormaP = (SELECT TOP 1 fpaId FROM vntFPagoTxn WHERE vntId = @strvntId);
			IF LEN(ISNULL(@strFormaP,'')) = 0 BEGIN
				SET @strFormaP = 'EFECTIVO';
			END;
		    EXEC proc_NeoEnvioFacturaEstandarOnline @strvntId, @strFormaP, @msm OUTPUT;
		    PRINT @msm
		end else begin 
			select vntConFactura,vntConDFR from vntTxn where vntId = @strvntId
			if @strLogro=2 and ISNULL((SELECT ippFacturaOnline FROM iptparametro WHERE 1 = 1),'N')='S' and isnull((select top 1 cast(vntConFactura as varchar) from vntTxn where ttxId='DVE'AND vntId=@strvntId),'0')='1'  begin	
		    SELECT @strVentaAnulada=vntReferencia,@strdosId=dosId FROM vntTxn WHERE vntId=@strvntId 
	        declare @strUsuario as varchar(50)
			select @strUsuario=SYSTEM_USER
				exec proc_NeoCallWebServicesImpuestosAnular @strVentaAnulada, @strUsuario ,@strdosId,@msm OUTPUT
				PRINT @msm
			end  
		end  
	 end
--	 end
	END TRY
	BEGIN CATCH
		DECLARE @ErrorNumber    INT				= ERROR_NUMBER(); 
		DECLARE @ErrorMessage   NVARCHAR(4000)	= ERROR_MESSAGE();   
		DECLARE @ErrorSeverity	INT				= ERROR_SEVERITY();
        DECLARE @ErrorState		INT				= ERROR_STATE(); 
		DECLARE @ErrorProcedure NVARCHAR(4000)	= ERROR_PROCEDURE();     
		DECLARE @ErrorLine      INT				= ERROR_LINE();
		SET @strMensajeSalida = @ErrorMessage;
		
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;
		RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState,@ErrorProcedure,@ErrorLine) 
			WITH LOG;	
		-- MENSAJE DE ERROR DE PROCESO			
		PRINT @strNombreParamSP + ' Error';
	END CATCH;
END
