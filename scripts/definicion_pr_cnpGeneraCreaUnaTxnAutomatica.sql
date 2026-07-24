CREATE PROCEDURE cnpGeneraCreaUnaTxnAutomatica 
	@StrDescripcionOpcional VARCHAR(100),		--StrDescripcionOpcional As String, 
	@strModId VARCHAR(2),						--strModId As String, 
	@strTxnOri VARCHAR(50)						--strTxnOri As String
--WITH ENCRYPTION 
AS BEGIN
	-- DEFINE OPCIONES DE EJECUCION
	SET NOCOUNT ON;

	-- DECLARA VARIABLES
	DECLARE @strNombreParamSP VARCHAR(200);
	DECLARE @strMensajeError VARCHAR(500);
	
	BEGIN TRY
		-- VALIDA PARAMETROS
		SET @strNombreParamSP = 'cnpGeneraCreaUnaTxnAutomatica - ' + ISNULL(@StrDescripcionOpcional,'')
		-- PROCESOS, TRANSACCIONALES SI EL QUE LLAMA INICIO TXN
				--Function cnpGeneraCreaUnaTxnAutomatica(StrDescripcionOpcional As String, strModId As String, strTxnOri As String) As Integer
			DECLARE @strGlosaOriginalEmbarque VARCHAR(1);
		    DECLARE @strDetalladoPorAplicacion VARCHAR(1);
		    DECLARE @strAgrupaDetallado VARCHAR(1);
		    DECLARE @intContador INT;
		    DECLARE @booOtraFormaPago BIT;
		    DECLARE @strCopiarGlosa VARCHAR(1);
		    DECLARE @ttxId VARCHAR(50);
		    DECLARE @ctaId VARCHAR(50);
		    DECLARE @ttxIdOri VARCHAR(50);
		    DECLARE @octId VARCHAR(50);
		    DECLARE @modId VARCHAR(2);
		    DECLARE @monId VARCHAR(50);
		    DECLARE @posPosteado BIT;
		    DECLARE @posFechaDoc DATETIME;
		    DECLARE @posTC DECIMAL(24,12);
		    DECLARE @posDebeC DECIMAL(24,12);
		    DECLARE @posHaberC DECIMAL(24,12);
		    DECLARE @posDescripcion VARCHAR(255);
		    DECLARE @posUsuario VARCHAR(50);
		    DECLARE @posFechaCambio DATETIME;
		    DECLARE @posConFactura VARCHAR(1);
		    DECLARE @posExportadoAlFisco VARCHAR(1);
		    DECLARE @banId VARCHAR(50);
		    DECLARE @odeId VARCHAR(50);
		    DECLARE @cntNroDocumento VARCHAR(50);
		    DECLARE @cntNota VARCHAR(100);
		    DECLARE @cntImporte DECIMAL(24,12);
		    DECLARE @cntFechaProceso DATETIME;
		    DECLARE @posTxnAnulada VARCHAR(1);
		    DECLARE @posDescripcionDetalle VARCHAR(200);
		    DECLARE @proId VARCHAR(50);
		    DECLARE @sucId VARCHAR(50);
		    DECLARE @tdoId VARCHAR(50);
		    DECLARE @strPrimerValor VARCHAR(50);
		    DECLARE @strSegundoValor VARCHAR(50);
		    DECLARE @strDescripcion VARCHAR(255);
		    DECLARE @strTxnTipo VARCHAR(50);
		    DECLARE @varStatus BIT;
		    DECLARE @intStatus INT;
		    DECLARE @strTipoTxn VARCHAR(50);
		    DECLARE @strGlosaCab VARCHAR(255);
		    DECLARE @varTransaccion VARCHAR(50);
		    DECLARE @posDescripcionMod VARCHAR(255);
		    DECLARE @FETCHSTATUS AS INT;    
			DECLARE @tdaId VARCHAR(50);
			DECLARE @posDescripcionTipoDoc VARCHAR(200);
		    
		    SET @strGlosaOriginalEmbarque =''
		    SET @strDetalladoPorAplicacion ='';
		    SET @strAgrupaDetallado ='';
		    SET @intContador =0;
		    SET @strCopiarGlosa ='';
		    SET @ttxId ='';
		    SET @ctaId ='';
		    SET @ttxIdOri ='';
		    SET @octId ='';
		    SET @modId ='';
		    SET @monId ='';
		    SET @posTC =0;
		    SET @posDebeC =0;
		    SET @posHaberC =0;
		    SET @posDescripcion ='';
		    SET @posUsuario ='';
		    SET @posConFactura ='';
		    SET @posExportadoAlFisco ='';
		    SET @banId ='';
		    SET @odeId ='';
		    SET @cntNroDocumento ='';
		    SET @cntNota ='';
		    SET @cntImporte =0;
		    SET @posTxnAnulada ='';
		    SET @posDescripcionDetalle ='';
		    SET @proId ='';
		    SET @sucId ='';
		    SET @tdoId ='';
		    SET @strPrimerValor ='';
		    SET @strSegundoValor ='';
		    SET @strDescripcion ='';
		    SET @strTxnTipo ='';
		    SET @intStatus =0;
		    SET @strTipoTxn ='';
		    SET @strGlosaCab ='';
		    SET @varTransaccion ='';
		    SET @posDescripcionMod ='';
		    SET @FETCHSTATUS= -1;
		    
				SELECT  @strGlosaOriginalEmbarque = isnull(imGlosaOriginal,'N') from imtparametro
				
				SELECT @strAgrupaDetallado =ISNULL(modPosteoAgrupaDetalle,'N') FROM gntParametroModulo WHERE modId=@strModId;
				IF (@strAgrupaDetallado = 'S') BEGIN
					DECLARE curCntPosteoCn CURSOR LOCAL FOR
					SELECT ttxId, ctaId, ttxIdOri, octId, modId, monId, posPosteado, posFechaDoc, posTC
					,posDebeC,posHaberC, posDescripcion, posUsuario, posFechaCambio
					, posConFactura, posExportadoAlFisco, banId, odeId, cntNroDocumento, cntNota, cntImporte
					, cntFechaProceso, posTxnAnulada, posDescripcionDetalle , proId, sucId, tdoId, posDescripcionTipoDoc, tdaId
					 FROM (
					SELECT c.ttxId, c.ctaId, c.ttxIdOri, c.octId, c.modId, c.monId, c.posPosteado, c.posFechaDoc, c.posTC
					, Sum(c.posDebeC) AS posDebeC
					,0 AS posHaberC
					, c.posDescripcion, c.posUsuario, c.posFechaCambio
					, c.posConFactura, c.posExportadoAlFisco, c.banId, c.odeId, c.cntNroDocumento, c.cntNota, c.cntImporte
					, c.cntFechaProceso, c.posTxnAnulada, c.posDescripcionDetalle , c.proId, c.sucId, c.tdoId, c.posDescripcionTipoDoc, c.tdaId
					FROM cntPosteoCn as c GROUP BY c.ttxId, c.ttxIdOri, c.ctaId, c.octId, c.modId, c.monId, c.posPosteado
						, c.posFechaDoc, c.posTC, c.posDescripcion, c.posUsuario, c.posFechaCambio, c.posConFactura
						, c.posExportadoAlFisco, c.banId, c.odeId, c.cntNroDocumento, c.cntNota, c.cntImporte, c.cntFechaProceso
						, c.posTxnAnulada, c.posDescripcionDetalle, c.proId, c.sucId, c.tdoId, c.posDescripcionTipoDoc, c.tdaId
					HAVING c.ttxIdOri=@strTxnOri AND Sum(c.posDebeC) >0) AS A
					UNION ALL
					SELECT c.ttxId, c.ctaId, c.ttxIdOri, c.octId, c.modId, c.monId, c.posPosteado, c.posFechaDoc, c.posTC
					,0  AS posDebeC
					, Sum(c.posHaberC) AS posHaberC
					, c.posDescripcion, c.posUsuario, c.posFechaCambio
					, c.posConFactura, c.posExportadoAlFisco, c.banId, c.odeId, c.cntNroDocumento, c.cntNota, c.cntImporte
					, c.cntFechaProceso, c.posTxnAnulada, c.posDescripcionDetalle , c.proId, c.sucId, c.tdoId, c.posDescripcionTipoDoc, c.tdaId
					FROM cntPosteoCn as c GROUP BY c.ttxId, c.ttxIdOri, c.ctaId, c.octId, c.modId, c.monId, c.posPosteado
						, c.posFechaDoc, c.posTC, c.posDescripcion, c.posUsuario, c.posFechaCambio, c.posConFactura
						, c.posExportadoAlFisco, c.banId, c.odeId, c.cntNroDocumento, c.cntNota, c.cntImporte, c.cntFechaProceso, c.posDescripcionTipoDoc, c.tdaId
						, c.posTxnAnulada, c.posDescripcionDetalle, c.proId, c.sucId, c.tdoId, c.posDescripcionTipoDoc, c.tdaId
					HAVING c.ttxIdOri=@strTxnOri AND Sum(c.posHaberC) >0
					ORDER BY posDebeC DESC
				END ELSE BEGIN		   
					DECLARE curCntPosteoCn CURSOR LOCAL FOR
					select ttxId, ctaId, ttxIdOri, octId, modId, monId, posPosteado, posFechaDoc,posTC, posDebeC,posHaberC, posDescripcion,posUsuario, posFechaCambio, posConFactura, posExportadoAlFisco, banId,odeId, cntNroDocumento, cntNota, cntImporte, cntFechaProceso, posTxnAnulada,posDescripcionDetalle, proId, sucId, tdoId, posDescripcionTipoDoc, tdaId from cntPosteoCn where ttxIdOri = @strTxnOri order by posDebeC Desc;
				END;
				DECLARE @strOctCAnalis VARCHAR(50); 
		        DECLARE @strOctProyecto VARCHAR(50); 
				IF @strModId='cm'BEGIN
					SELECT TOP 1  @strOctCAnalis=canId, @strOctProyecto=proId from cmtFpagoTxn where cmtid = @strTxnOri;	                 	
				END
			OPEN curCntPosteoCn;
			FETCH NEXT FROM curCntPosteoCn INTO @ttxId, @ctaId, @ttxIdOri, @octId, @modId, @monId, @posPosteado, @posFechaDoc,@posTC, @posDebeC,@posHaberC, @posDescripcion,@posUsuario, @posFechaCambio, @posConFactura, @posExportadoAlFisco, @banId,@odeId, @cntNroDocumento, @cntNota, @cntImporte, @cntFechaProceso, @posTxnAnulada,@posDescripcionDetalle, @proId, @sucId, @tdoId, @posDescripcionTipoDoc, @tdaId;
			IF (@@FETCH_STATUS <> 0) BEGIN
				SET @strMensajeError = @strNombreParamSP + ' ERROR: No Existen Datos Para Procesar';
				RAISERROR (@strMensajeError, 16, 1);
			END;
		    SET @FETCHSTATUS = @@FETCH_STATUS;
			SET @intContador = 0;
			SET @booOtraFormaPago = 0;
		--    'Inicia captura de errores
		--        'Parametro para Verificar que glosa Copiar en Compras
			SELECT @strCopiarGlosa = cmdCopiaGlosaCabeceraCn FROM cmtParametro WHERE 1=1;
			IF (@strCopiarGlosa IS NULL OR LEN(@strCopiarGlosa) = 0) BEGIN
				SET @strCopiarGlosa ='N';
			END;
		--        'Recorre transaccionea a postear
				EXEC cnpRecuperaTipoTxn 
					@strModId = @strModId,
					@strTxnOri = @strTxnOri,
					@strTtxId = @ttxId,
					@strRecuperaTipoTxn = @strTipoTxn OUTPUT;
				SET @strPrimerValor = @ttxIdOri;
				SET @strSegundoValor = @ttxIdOri;
		--        'ini gap
				SELECT @strGlosaCab = ISNULL(cjtDescripcion,'') FROM cjttxn WHERE cjtId=@strTxnOri;
				EXEC RemplazarCaracter 
					@strCadena = @strGlosaCab,
					@strCarOrigen = '''',
					@strCarDestino = ' ',
					@strCadenaModificada = @strGlosaCab OUTPUT;
		--        'fin gap
		     WHILE @FETCHSTATUS = 0 BEGIN       
		--            'ini gap
				IF(@strGlosaOriginalEmbarque='S') BEGIN 	
					SELECT @posDescripcionMod=embDescripcion,@strGlosaCab=embDescripcion FROM imtembarquetxn WHERE embid = @strTxnOri				
				END 
				IF (@strModId = 'cj') BEGIN
					EXEC CreaCntTxn 
						@strTipoDoc = @strTipoTxn,
						@fchFechaDoc = @posFechaDoc,
						@strMonId = @monId,
						@strModId = @strModId,
						@varDescripcion = @strGlosaCab,
						@varOdeId = @odeId,
						@varBanId = @banId,
						@varNroDocumento = @cntNroDocumento,
						@varNota = @cntNota,
						@varImporte = @cntImporte,
						@strConFactura = @posConFactura,
						@strExportadoAlFiscal = @posExportadoAlFisco,
						@varTxnOrigen = @ttxIdOri,
						@strintId = @varTransaccion OUTPUT;
				END ELSE BEGIN
					SET @posDescripcionMod =  REPLACE(@posDescripcion, '''', ' ');
					EXEC CreaCntTxn 
						@strTipoDoc = @strTipoTxn,
						@fchFechaDoc = @posFechaDoc,
						@strMonId = @monId,
						@strModId = @strModId,
						@varDescripcion = @posDescripcionMod,
						@varOdeId = @odeId,
						@varBanId = @banId,
						@varNroDocumento = @cntNroDocumento,
						@varNota = @cntNota,
						@varImporte = @cntImporte,
						@strConFactura = @posConFactura,
						@strExportadoAlFiscal = @posExportadoAlFisco,
						@varTxnOrigen = @ttxIdOri,
						@strintId = @varTransaccion OUTPUT;
				END;
		--            'fin gap
				IF (ISNUMERIC(@varTransaccion) = 1) BEGIN
					RETURN;
				END;
					WHILE (@strPrimerValor = @strSegundoValor) BEGIN
		--                'Crea detalle en intDetTxn
						IF (@strCopiarGlosa='S' AND @strModId = 'cm') BEGIN
							SET @strDescripcion = @posDescripcion;
						END ELSE BEGIN
							IF (LEN(@posDescripcionDetalle)>0) BEGIN
								SET @strDescripcion = @posDescripcionDetalle;
							END ELSE BEGIN
								IF (LEN(LTRIM(RTRIM(@posDescripcion)))=0) BEGIN
									SET @strDescripcion = @StrDescripcionOpcional;
								END ELSE BEGIN
									SET @strDescripcion = @posDescripcion;
								END;
							END;
						END;
				IF @strModId='cm' AND (@strOctProyecto IS NOT NULL AND @strOctCAnalis IS NOT NULL)AND isnull(@octId,'')='' BEGIN
					SELECT @octId=@strOctCAnalis, @proId=@strOctProyecto	                 	
				END 
					IF(@strGlosaOriginalEmbarque='S') begin 	
						SELECT @strDescripcion=embDescripcion FROM imtembarquetxn where embid = @strTxnOri				
					END 				
						EXEC CreaDetCntTxn 
							@strTxnId = @varTransaccion,
							@strCuenta = @ctaId,
							@varOtraCuenta = @octId,
							@varDescripcion = @strDescripcion,
							@dblTc = @posTC,
							@dblDebe = @posDebeC,
							@dblHaber = @posHaberC,
							@varDebeOtraMoneda = 0,
							@varHaberOtraMoneda = 0,
							@varProId = @proId,
							@varPosDescripcionTipoDoc = @posDescripcionTipoDoc,
							@varTdaId = @tdaId;
						SET @strTxnTipo = @ttxId;
						FETCH NEXT FROM curCntPosteoCn INTO @ttxId, @ctaId, @ttxIdOri, @octId, @modId, @monId, @posPosteado, @posFechaDoc,@posTC, @posDebeC,@posHaberC, @posDescripcion,@posUsuario, @posFechaCambio, @posConFactura, @posExportadoAlFisco, @banId,@odeId, @cntNroDocumento, @cntNota, @cntImporte, @cntFechaProceso, @posTxnAnulada,@posDescripcionDetalle, @proId, @sucId, @tdoId, @posDescripcionTipoDoc, @tdaId;
						IF (@@FETCH_STATUS <> 0) BEGIN
		--                    'Aprueba transacción generada
							SELECT @varStatus = ttxApruebaContabilidad FROM gntTipoTxn WHERE ttxId = @strTxnTipo;
							IF (@varStatus = 1) BEGIN
								if (select count(*) from cttTxn ct inner join cntTxn cn on ct.cttId = cn.txnOrigen and cn.modId='ct'and ct.modId='ct' and ct.cttTipoFondoARendir in('RN','RG'))=0  
									EXEC cnpApruebaTxn @strComprobante = @varTransaccion;
							END;
							delete from cntPosteoCn where ttxIdOri = @strPrimerValor;
		--                    ' Sale del while
							GOTO SalidaDelWhile;
						END;
					END;
				  FETCH NEXT FROM curCntPosteoCn INTO @ttxId, @ctaId, @ttxIdOri, @octId, @modId, @monId, @posPosteado, @posFechaDoc,@posTC, @posDebeC,@posHaberC, @posDescripcion,@posUsuario, @posFechaCambio, @posConFactura, @posExportadoAlFisco, @banId,@odeId, @cntNroDocumento, @cntNota, @cntImporte, @cntFechaProceso, @posTxnAnulada,@posDescripcionDetalle, @proId, @sucId, @tdoId;
				  SET @FETCHSTATUS = @@FETCH_STATUS;
			END;
			CLOSE curCntPosteoCn;
			DEALLOCATE curCntPosteoCn;
		    SalidaDelWhile:
		-- MENSAJE DE FIN DE PROCESO		
		PRINT @strNombreParamSP;
	END TRY
	BEGIN CATCH
		--PRINT ERROR_MESSAGE();
		IF LEN(ISNULL(@strMensajeError,''))=0 BEGIN
		    SET @strMensajeError=@strNombreParamSP + ' ' + ERROR_MESSAGE();
		END ;
		RAISERROR (@strMensajeError, 16, 1);
		-- MENSAJE DE ERROR DE PROCESO
		PRINT @strNombreParamSP + ' Error';		
	END CATCH;
END
