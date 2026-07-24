
CREATE PROCEDURE [dbo].[vmaGeneraAsientoVentas]
	@strvntId VARCHAR(50), --(ByVal strvntId As String,
	@booAnulaTxn BIT, --ByVal booAnulaTxn As Boolean,
	@strTipoTxnVn VARCHAR(50), --ByVal strTipoTxnVn As String,
	@strTdoId VARCHAR(50), --ByVal strTdoId As String,
	@strCliId VARCHAR(50), --ByVal strCliId As String, _
	@strMonId VARCHAR(50), --ByVal strMonId As String,
	@strPveId VARCHAR(50), --ByVal strPveId As String,
	@fchFechaDoc DATETIME, --ByVal fchFechaDoc As Date,
	@dblTc DECIMAL(24,12), --ByVal dblTc As Double, _
	@strDescripcion VARCHAR(200), --ByVal strDescripcion As String,
	@strConFacturaPos VARCHAR(1), --strConFacturaPos As String,
	@strExportadoAlFiscal VARCHAR(1), --ByVal strExportadoAlFiscal As String, _
	@flgConFactura BIT, --ByVal flgConFactura As Boolean, _
	@dblArticuloMoneda DECIMAL(24,12), --ByVal dblArticuloMoneda As Double,
	@dblDescuentoMoneda DECIMAL(24,12), --ByVal dblDescuentoMoneda As Double, _
	@dblAnticipoMoneda DECIMAL(24,12), --ByVal dblAnticipoMoneda As Double,
	@dblOtrosAnticiposMoneda DECIMAL(24,12), --ByVal dblOtrosAnticiposMoneda As Double, _
	@strTipoDescuento VARCHAR(50), --ByVal strTipoDescuento As String,
	@dblDescuentoArticulo DECIMAL(24,12), --ByVal dblDescuentoArticulo As Double,
	@dblRecargoMoneda DECIMAL(24,12), --ByVal dblRecargoMoneda As Double, _
	@dblGnpIva DECIMAL(24,12), --ByVal dblGnpIva As Double,
	@dblGnpIT DECIMAL(24,12), --ByVal dblGnpIT As Double,
	@booPveIdSinIT BIT, --ByVal booPveIdSinIT As Boolean,
	@varReferenciaDevolucion VARCHAR(50), --ByVal varReferenciaDevolucion As Variant,
	@strTxnIn VARCHAR(50)--ByVal strTxnIn As String)
	                     --WITH ENCRYPTION
AS
BEGIN
	--DEFINE OPCIONES DE EJECUCION
	SET NOCOUNT ON;
	
	--DECLARA VARIABLES
	DECLARE @strNombreParamSP VARCHAR(200);
	DECLARE @strMensajeError VARCHAR(500);
	
	DECLARE @strDetalladoConGrupos VARCHAR(1);
	DECLARE @strGeneraCAPor VARCHAR(1);
	DECLARE @strModoAsiento VARCHAR(1);
	DECLARE @varModEstado VARCHAR(1);
	DECLARE @booIntegracionCA BIT;
	DECLARE @tdoIdNoGeneraCn VARCHAR(50);
	DECLARE @strIntegracionDirectaCn VARCHAR(1); 
	DECLARE @strGeneracionContable VARCHAR(1); 
	DECLARE @strAnulaContabilidad VARCHAR(1);
	DECLARE @varModFechaFinal DATETIME;
	DECLARE @cntId_RS VARCHAR(50);
	DECLARE @varReferencia VARCHAR(50);
	DECLARE @ConFacturaAnticipo BIT;
	DECLARE @fpaId_RS VARCHAR(50);
	DECLARE @fpaReferencia_RS VARCHAR(50);
	DECLARE @fptReferenciaIngreso_RS VARCHAR(50);
	DECLARE @fptMontoMoneda_RS DECIMAL(24,12);
	DECLARE @fptDestinoIngreso_RS VARCHAR(1);
	DECLARE @artId_RS VARCHAR(50);
	DECLARE @uniId_RS VARCHAR(50);
	DECLARE @recuperacampo VARCHAR(50);
	DECLARE @pvdCantidadEntregada_RS DECIMAL(24,12);
	DECLARE @almId_RS VARCHAR(150);
	DECLARE @monId_RS VARCHAR(50);
	DECLARE @treId_RS VARCHAR(50);	
	DECLARE @txrMontoMoneda_RS DECIMAL(24,12);
	DECLARE @intCant INT;
	DECLARE @strTxnAnulada VARCHAR(1);
	DECLARE @datUltimoDiaMes DATETIME;
	DECLARE @booGeneraContabilidad BIT;
	DECLARE @dblDebe DECIMAL(24,12);
	DECLARE @dblHaber DECIMAL(24,12);
	DECLARE @strCtaid VARCHAR(50);
	DECLARE @dblTotal DECIMAL(24,12);
	DECLARE @strReferenciaConcepto VARCHAR(50);
	DECLARE @strDetallado VARCHAR(1);
	DECLARE @strAnulacionContable VARCHAR(1);
	DECLARE @varArtId VARCHAR(50);
	DECLARE @dblTotalVentas DECIMAL(24,12);
	DECLARE @vntId VARCHAR(50);
	DECLARE @cjtId_RS VARCHAR(50);
	DECLARE @strCtaCteMasDetallePorGrupo VARCHAR(1);
	DECLARE @strConcepto VARCHAR(50);
	DECLARE @flgGenerico BIT;
	DECLARE @strTipoDoc VARCHAR(50);
	DECLARE @dblPorDescuento DECIMAL(24,12);
	DECLARE @dblDescuento DECIMAL(24,12);
	DECLARE @conOtroDetalle VARCHAR(1);
	DECLARE @strOctId VARCHAR(50);
	DECLARE @dblTotalCaj DECIMAL(24,12);
	DECLARE @venId VARCHAR(50);
	DECLARE @canId VARCHAR(50);
	DECLARE @strAlmId VARCHAR(150);
	DECLARE @strProId VARCHAR(50);
	DECLARE @dblCosto DECIMAL(24,12);
	DECLARE @proId VARCHAR(50);
	DECLARE @varFPago VARCHAR(50);
	DECLARE @gstrGeneraTxnContableMonedaCentral VARCHAR(1);
	DECLARE @strMonIdC VARCHAR(50);
	DECLARE @strMonIdP VARCHAR(50);
	DECLARE @catOrigen VARCHAR(50);
	DECLARE @strconReferencia VARCHAR(1);
	DECLARE @dblDFRTotal DECIMAL(24,12);
	DECLARE @strAplicaITenTxnConDFR VARCHAR(1);
	DECLARE @booConDFR BIT;
	DECLARE @dblDFRMonto DECIMAL(24,12);
	DECLARE @varResultado2 VARCHAR(50);
	DECLARE @strConceptoDetallado VARCHAR(1);
	DECLARE @strDFRSinIT VARCHAR(1);
	DECLARE @strIntegracionContableAplicacion VARCHAR(1);
	DECLARE @dblPorcentaje DECIMAL(24,12);
	---para el poste 
	DECLARE @strproIdCn VARCHAR(50) = '' --Optional strproId, 
	DECLARE @strBanIdCn VARCHAR(50) = '' --Optional strBanId, 
	DECLARE @strNroDocumentoCn VARCHAR(50) = '' --Optional strNroDocumento, 
	DECLARE @strNotaCn VARCHAR(100) = ''
	-----Variables para cursor miRsInt------
	DECLARE @ctaId_cur VARCHAR(50);
	DECLARE @octId_cur VARCHAR(50);
	DECLARE @proId_cur VARCHAR(50);
	DECLARE @tcuImporte_cur DECIMAL(24,12);
	DECLARE @dblTotal_cur DECIMAL(24,12);
	DECLARE @grupoCtaCte VARCHAR(50) = '' ;
	--anticipo
	DECLARE @decMontoAntFac DECIMAL(24,12);
	DECLARE @strNAntFac INT
	--CALCULO DE COSTO
	DECLARE @artTipo_RS VARCHAR(50);
	DECLARE @artCalculoCosto_RS VARCHAR(50);
	DECLARE @artUsoLote_RS VARCHAR(50);
	DECLARE @lotId_RS VARCHAR(50);
	DECLARE @uniArticulo_RS VARCHAR(50);
	DECLARE @strFifo_IntId VARCHAR(50);
	DECLARE @strFifo_UniId VARCHAR(50);
	DECLARE @dblFifo_EfiSaldo DECIMAL(24,12)
	DECLARE @dblFifo_Cantidad DECIMAL(24,12)
	DECLARE @dblFifo_CantProcesar DECIMAL(24,12)
	DECLARE @dblFifo_lotId VARCHAR(50);
	DECLARE @varCalculoCostoPP VARCHAR(50);
	DECLARE @varStatus VARCHAR(50);
	DECLARE @varResultado VARCHAR(200);	
	DECLARE @dblResultado DECIMAL(24,12);			
	DECLARE @dblCantidadCONVERTida DECIMAL(24,12);
	DECLARE @intFifo_EfiId INT;
	DECLARE @intContX AS INT, @fptTipoRecargo INT
	DECLARE @strGarid VARCHAR(50);
	DECLARE @strGarid_Aux VARCHAR(50);
	DECLARE @strCjpPermiteCANconFactura VARCHAR(10);
	DECLARE @strVnpAsientoDescuentoCreditoFiscal VARCHAR(1);
	BEGIN TRY
		--VALIDA PARAMETROS
		--IF (LEN(@strCabId) = 0 OR @strCabId IS NULL) BEGIN
		--	SET @strMensajeError = @strNombreParamSP + ' ERROR: cabId debe existir';
		--	RAISERROR (@strMensajeError, 16, 1);
		--	----THROW 51000, @strMensajeError, 1;
		--END;
		SET @strGarid = '';
		SET @strGarid_Aux = '';
		SET @strDetalladoConGrupos = '';
		SET @strGeneraCAPor = '';
		SET @strModoAsiento = '';
		SET @varModEstado = '';
		SET @tdoIdNoGeneraCn = '';
		SET @strIntegracionDirectaCn = ''; 
		SET @strGeneracionContable = ''; 
		SET @strAnulaContabilidad = '';
		SET @cntId_RS = '';
		SET @varReferencia = '';
		SET @fpaId_RS = '';
		SET @fpaReferencia_RS = '';
		SET @fptReferenciaIngreso_RS = '';
		SET @fptMontoMoneda_RS = 0;
		SET @fptDestinoIngreso_RS = '';
		SET @artId_RS = '';
		SET @uniId_RS = '';
		SET @recuperacampo = '';
		SET @pvdCantidadEntregada_RS = 0;
		SET @almId_RS = '';
		SET @monId_RS = '';
		SET @treId_RS = '';	
		SET @txrMontoMoneda_RS = 0;
		SET @strTxnAnulada = '';
		SET @dblDebe = 0;
		SET @dblHaber = 0;
		SET @strCtaid = '';
		SET @dblTotal = 0;
		SET @strReferenciaConcepto = '';
		SET @strDetallado = '';
		SET @strAnulacionContable = '';
		SET @varArtId = '';
		SET @dblTotalVentas = 0;
		SET @vntId = '';
		SET @cjtId_RS = '';
		SET @strCtaCteMasDetallePorGrupo = '';
		SET @strConcepto = '';
		SET @strTipoDoc = '';
		SET @dblPorDescuento = 0;
		SET @dblDescuento = 0;
		SET @conOtroDetalle = '';
		SET @strOctId = '';
		SET @dblTotalCaj = 0;
		SET @venId = '';
		SET @canId = '';
		SET @strAlmId = '';
		SET @strProId = '';
		SET @dblCosto = 0;
		SET @proId = '';
		SET @varFPago = '';
		SET @gstrGeneraTxnContableMonedaCentral = '';
		SET @strMonIdC = '';
		SET @strMonIdP = '';
		SET @catOrigen = '';
		SET @strconReferencia = '';
		SET @strConceptoDetallado = '';
		SET @strDFRSinIT = '';
		SET @strIntegracionContableAplicacion = '';
		SET @ctaId_cur = '';
		SET @octId_cur = ''
		SET @proId_cur = '';
		SET @tcuImporte_cur = 0;
		SET @dblPorcentaje = 0;
		SET @dblTotal_cur = 0;
		--CALCULO DE COSTO
		SET @artTipo_RS = '';
		SET @artCalculoCosto_RS = '';
		SET @artUsoLote_RS = '';
		SET @lotId_RS = '';
		SET @uniArticulo_RS = '';	    
		SET @varStatus = '';		
		SET @varResultado = '';
		SET @dblCantidadCONVERTida = 0;
		SET @strCjpPermiteCANconFactura = ''
		SET @strVnpAsientoDescuentoCreditoFiscal = ''
		DECLARE @strRecargoItemsAsumido VARCHAR(50)
		
		SELECT @strCjpPermiteCANconFactura = ISNULL(cjpPermiteCANconFactura,'N') from cjtParametro 
		SELECT @varCalculoCostoPP = inpCalculoCostoPP FROM intParametro
		SELECT @strRecargoItemsAsumido = ISNULL(vnpRecargoItemsAsumido, 'N'),@strVnpAsientoDescuentoCreditoFiscal = ISNULL(vnpAsientoDescuentoCreditoFiscal,'N') FROM vntParametro 
		
		--IF (LEN(@strEstado) = 0 OR @strEstado IS NULL) BEGIN
		--	SET @strMensajeError = @strNombreParamSP + ' ERROR: cabEstado debe existir';
		--	RAISERROR (@strMensajeError, 16, 1);
		--	----THROW 51000, @strMensajeError, 1;
		--END;				
		SET @strNombreParamSP = 'vmaGeneraAsientoVentas - ' + ISNULL(@strvntId, '');
		
		SET @decMontoAntFac = (SELECT ISNULL((SELECT SUM(TA.detMonto) FROM vntTxnAnticipos AS TA INNER JOIN cjtTxn AS C ON Ta.cjtId = C.cjtId INNER JOIN iptFactura F ON F.FacReferencia = C.cjtId WHERE vntId = @strvntId AND C.cjtConFactura = 1), 0))
		
		SET @decMontoAntFac = ISNULL(@decMontoAntFac, 0)
		SET @strNAntFac = (SELECT ISNULL((SELECT COUNT(TA.detMonto) FROM vntTxnAnticipos AS TA INNER JOIN cjtTxn AS C ON Ta.cjtId = C.cjtId INNER JOIN iptFactura F ON F.FacReferencia = C.cjtId WHERE vntId = @strvntId AND C.cjtConFactura = 1), 0))
		
		SET @strAplicaITenTxnConDFR = ISNULL((SELECT gnpAplicaITenTxnConDFR FROM gntParametro WHERE 1 = 1), 'N');
		SET @booConDFR = 0;
		SET @booConDFR = ISNULL((SELECT vntConDFR FROM vntTxn WHERE vntId = @strvntId), 0);
		SET @dblDFRMonto = ISNULL((SELECT vntDFRMonto FROM vntTxn WHERE vntId = @strvntId), 0);
		SET @strGeneraCAPor = ISNULL((SELECT vnpGeneraCentroAnalisisPor FROM vntParametro WHERE 1 = 1), 'V');
		SET @strModoAsiento = ISNULL((SELECT ctpAsientoCtaCteDebito FROM cttParametro WHERE 1 = 1), 'I');
		SET @strModoAsiento = ISNULL((SELECT ctpAsientoCtaCteDebito FROM cttParametro WHERE 1 = 1), 'I')
		
		SET @booGeneraContabilidad = (SELECT ttxGeneraContabilidad FROM gntTipoTxn WHERE ttxid = @strTipoTxnVn);
		SET @booIntegracionCA = ISNULL((SELECT itgGenera FROM gntIntegracion WHERE modIdOrigen = 'vn' AND modIdDestino = 'ca'), 0);
		SET @strMonIdC = (SELECT monId FROM gntMoneda WHERE monTipo = 'C');
		SET @strMonIdP = (SELECT monId FROM gntMoneda WHERE monTipo = 'P');
		--'----fin
		SET @strIntegracionContableAplicacion = ISNULL((SELECT vnpIntegracionContableAplicacion FROM vntParametro WHERE 1 = 1), 'N');
		
		
		IF @booGeneraContabilidad = 0 BEGIN
		    --'No tiene que generar contabilidad
		    RETURN;
		END;
		IF LEN(@strTdoId) > 0 BEGIN
		    --'verificamos si el tipo de domuento es sin contabilidad
		    SET @tdoIdNoGeneraCn = ISNULL((SELECT tdoIdNoGeneraCn FROM gntTipoTxn WHERE ttxId LIKE @strTipoTxnVn), '');
		    IF LEN(@tdoIdNoGeneraCn) > 0 BEGIN
		        IF @tdoIdNoGeneraCn = @strTdoId BEGIN
		            RETURN;
		        END;
		    END;
		END;
		SELECT @strIntegracionDirectaCn = ISNULL(modIntegracionDirectaCn, 'S'), @strGeneracionContable = ISNULL(modGeneracionContable, 'A'), @strAnulaContabilidad = ISNULL(modAnulaContabilidad, 'D') FROM gntParametroModulo WHERE modId LIKE 'vn'
		
		IF @booAnulaTxn = 1 AND @strAnulaContabilidad = 'D' AND @booGeneraContabilidad = 1 AND @strTipoTxnVn <> 'PRO' BEGIN
		    --'-----iarr 29-09-2014 pedido por Javier AHossen
		    --'Busca Si  esta en la tabla de contabilidad con estado Aprobado
		    SELECT @intCant = COUNT(*) FROM cntTxn WHERE txnOrigen = @strvntId AND cntEstado = 'A'
		    
		 IF @intCant = 0 BEGIN
		        --vmaGeneraAsientoVentas = ErrMensajeMudo: gvarMensajeError = "No Se Encontro La Transacción Original En Contabilidad"
		        SET @strMensajeError = 'No Se Encontro La Transacción Original En Contabilidad';
		        RAISERROR (@strMensajeError, 16, 1);
		        ----THROW 51000, @strMensajeError, 1;
		    END; 
		    --'----------fin
		    --'solo cambia el estado de la transaccion contable
		    
		    UPDATE cntTxn
		    SET    cntEstado = 'X', cntUsuario = SYSTEM_USER, cntFechaCambio = GETDATE()
		    WHERE  txnOrigen LIKE @strvntId AND modId LIKE 'vn'
		    
		    RETURN;
		END;
		
		--verificar si no hay  forma de pago cheque
		DECLARE @intCntReg INT = 0
		
		SET @intCntReg = (SELECT COUNT(*) FROM vntFPagoTxn WHERE vntId LIKE @strvntId AND fpaId LIKE 'CHEQUE')
		
		IF @intCntReg = 0 BEGIN
		    SET @strproIdCn = @strCliId 				 
		    SET @strBanIdCn = @strPveId							 
		    SET @strNroDocumentoCn = NULL				 
		    SET @strNotaCn = NULL
		END ELSE  BEGIN
		    SET @strproIdCn = @strCliId
		    
		    DECLARE @strIngresoFpago VARCHAR(50) = ''
		    DECLARE @strBancoIngresoFpago VARCHAR(50) = NULL
		    
		    SELECT TOP 1 @strBanIdCn = fpaReferencia, @strNroDocumentoCn = fptNroDocumento, @strNotaCn = fptNota, @strBancoIngresoFpago = fptReferenciaIngreso, @strIngresoFpago = fptDestinoIngreso FROM vntFPagoTxn WHERE vntId LIKE @strvntId AND fpaId LIKE 'CHEQUE'
		    
		    IF @strTipoTxnVn IN ('VEN', 'VAF') BEGIN
		        IF @strIngresoFpago = 'B' BEGIN
		            SET @strBancoIngresoFpago = ISNULL(@strBancoIngresoFpago, '')
		        END
		        
		        SET @strBanIdCn = (SELECT banId FROM bntCuentaPropia WHERE cprId LIKE @strBancoIngresoFpago)
		        
		        SET @strBanIdCn = ISNULL(@strBanIdCn, '')
		        
		        IF LEN(@strBanIdCn) = 0 BEGIN
		            SET @strBanIdCn = @strPveId
		        END
		    END ELSE  BEGIN
		        SET @strBanIdCn = (SELECT banId FROM bntCuentaPropia WHERE cprId LIKE @strBanIdCn)
		        
		        SET @strBanIdCn = ISNULL(@strBanIdCn, '')
		        
		        IF LEN(@strBanIdCn) = 0 BEGIN
		            SET @strBanIdCn = @strPveId
		        END
		    END 
		    
		    SET @strNroDocumentoCn = ISNULL(@strNroDocumentoCn, '')
		    SET @strNotaCn = ISNULL(@strNotaCn, '')
		    
		    IF LEN(@strNroDocumentoCn) = 0 BEGIN
		        SET @strNroDocumentoCn = NULL
		    END  
		    IF LEN(@strNotaCn) = 0 BEGIN
		        SET @strNotaCn = NULL
		    END
		END 
		
		--' Algoritmo Proceso
		IF @booAnulaTxn = 1 BEGIN
		    SET @strTxnAnulada = 'S';
		END ELSE  BEGIN
		    SET @strTxnAnulada = 'N';
		END;
		IF @booAnulaTxn = 1 BEGIN
		    SET @varModEstado = (SELECT modQueFechaAnulacion FROM gntParametroModulo WHERE modId = 'vn');
		    IF @varModEstado IS NULL BEGIN
		        SET @strMensajeError = 'ERROR : NO ESTA DEFINIDA FECHA DE ANULACION';
		        RAISERROR (@strMensajeError, 16, 1);
		        ----THROW 51000, @strMensajeError, 1;
		    END;
		    IF @varModEstado = 'D' BEGIN
		        EXEC UltimoDiaDelMes @fchFechaDoc, @datUltimoDiaMes OUTPUT;
		        IF CAST(GETDATE()AS DATE) <= @datUltimoDiaMes BEGIN
		            SET @fchFechaDoc = CAST(GETDATE()AS DATE);
		        END;
		    END ELSE    
		    IF @varModEstado = 'L' BEGIN
		        SET @varModFechaFinal = (SELECT modFechaFinal FROM gntParametroModulo WHERE modId = 'vn');
		        IF @varModFechaFinal IS NULL BEGIN
		            --vmaGeneraAsientoVentas = ErrMensajeMudo: gvarMensajeError = "No Se Ha Definido La Fecha Final En Parámetros Para El Módulo"
		            SET @strMensajeError = 'No Se Ha Definido La Fecha Final En Parámetros Para El Módulo';
		            RAISERROR (@strMensajeError, 16, 1);
		            ----THROW 51000, @strMensajeError, 1;
		        END;
		        SET @fchFechaDoc = @varModFechaFinal;
		    END;
		    SET @booGeneraContabilidad = (SELECT ttxGeneraContabilidad FROM gntTipoTxn WHERE ttxid = @strTipoTxnVn);
		    IF @booGeneraContabilidad = 1 BEGIN
		        SET @varModEstado = (SELECT modAnulaContabilidad FROM gntParametroModulo WHERE modid = 'vn');
		        IF @varModEstado IS NULL BEGIN
		            SET @strMensajeError = 'No Se Ha Definido El Parámetro Anulación Contable';
		            RAISERROR (@strMensajeError, 16, 1);
		            ----THROW 51000, @strMensajeError, 1;
		        END;
		        SET @strAnulacionContable = @varModEstado;
		        SET @varFPago = ISNULL((SELECT fpaid FROM vntFPagoTxn WHERE vntid = @strvntId AND fpaid = 'HOSPEDAJE'), '')
		        
		        IF (@varFPago <> 'HOSPEDAJE') BEGIN
		            IF @strAnulacionContable = 'D' BEGIN
		                --strSQL = "Select * from cntTxn where cntEstado = 'A' and txnOrigen = '" & strvntId & "'"
		                DECLARE rsFpago CURSOR LOCAL FOR
		                	SELECT cntId FROM cntTxn WHERE cntEstado = 'A' AND txnOrigen = @strvntId
		                
		                OPEN rsFpago;
		                FETCH NEXT FROM rsFpago INTO @cntId_RS;
		                --If Not rsFpago.EOF Then
		                IF @@FETCH_STATUS = 0 BEGIN
		                    WHILE @@FETCH_STATUS = 0 BEGIN
		                        EXEC AnulaComprobante @cntId_RS, 'vn', @strMonIdC, @strMonIdP;
		                        FETCH NEXT FROM rsFpago INTO @cntId_RS;
		                    END;
		                END ELSE  BEGIN
		                    --'Busca Si no esta en la tabla de POsteo
		                    SELECT @intCant = COUNT(*) FROM cntposteocn WHERE ttxidOri = @strvntId
		                    
		                    IF @intCant > 0 BEGIN
		                        SET @strMensajeError = 'Primero Debe Realizar El Proceso de Posteo Para Anular El Comprobante Contable';
		                        RAISERROR (@strMensajeError, 16, 1);
		                        ----THROW 51000, @strMensajeError, 1;
		                    END ELSE  BEGIN
		                        --varResultado = recuperaRegistroSQL("A.artId", "vntDetTxn A INNER JOIN intArticulo B ON A.artId=B.artId", "vntId='" & strvntId & "' AND B.artTipo='I'")
		                        SET @varArtId = (SELECT A.artId FROM vntDetTxn A INNER JOIN intArticulo B ON A.artId = B.artId WHERE vntId = @strvntId AND B.artTipo = 'I'); 
		                        --If Not IsNull(varResultado) And Len(varResultado) > 0 Then
		                        IF @varArtId IS NOT NULL AND LEN(RTRIM(LTRIM(@varArtId))) > 0 BEGIN
		                            --vmaGeneraAsientoVentas = ErrMensajeMudo: gvarMensajeError = "No Se Encontro La Transacción Original En Contabilidad"
		                            SET @strMensajeError = 'No Se Encontro La Transacción Original En Contabilidad';
		                            RAISERROR (@strMensajeError, 16, 1);
		                            ----THROW 51000, @strMensajeError, 1;
		                            --Exit Function
		                            --End If
		                        END; 
		                        --End If
		                    END;
		                    --miRs.Close
		                    
		                    --Set miRs = Nothing
		                    
		                    --End If
		                END;
		                --rsFpago.Close
		                CLOSE rsFpago;
		                --Set rsFpago = Nothing
		                DEALLOCATE rsFpago;
		                --End If
		            END;
		            --End If
		        END;
		        --End If
		    END;
		    --End If
		END;
		
		SET @dblTotalVentas = 0;	
		SET @dblDebe = 0;
		SET @dblHaber = 0;		    
		
		SET @ConFacturaAnticipo = 0;
		--varResultado = recuperaRegistroSQL("vntId", "vntTxnAnticipos", "vntId='" & strvntId & "'")
		SET @vntId = (SELECT DISTINCT vntId FROM vntTxnAnticipos WHERE vntId = @strvntId) 
		--If Not IsNull(varResultado) Then
		IF @vntId IS NOT NULL BEGIN
		    --Set rsFpago = miBD.OpenRecordset("select cjtId from vntTxnAnticipos where vntId ='" & strvntId & "'", dbOpenSnapshot)
		    DECLARE rsFpago2 CURSOR LOCAL FOR
		    	SELECT cjtId FROM vntTxnAnticipos WHERE vntId = @strvntId
		    
		    OPEN rsFpago2;
		    FETCH NEXT FROM rsFpago2 INTO @cjtId_RS; 
		    --If Not rsFpago.EOF Then
		    IF @@FETCH_STATUS = 0 BEGIN
		        --rsFpago.MoveFirst
		        --Do
		        WHILE @@FETCH_STATUS = 0 AND @ConFacturaAnticipo = 0 BEGIN
		            SET @ConFacturaAnticipo = ISNULL((SELECT cjtConFactura FROM cjtTxn WHERE cjtId = @cjtId_RS), 0);
		            FETCH NEXT FROM rsFpago2 INTO @cjtId_RS;
		        END;
		    END;
		    CLOSE rsFpago2;
		    DEALLOCATE rsFpago2;
		    IF @ConFacturaAnticipo = 1 BEGIN
		        IF @flgConFactura <> @ConFacturaAnticipo BEGIN
		            SET @strMensajeError = 'La venta debe ser con factura, ya que el Anticipo es Facturado...';
		            RAISERROR (@strMensajeError, 16, 1);
		            ----THROW 51000, @strMensajeError, 1;
		        END;
		    END;
		END;		
		SET @strCtaCteMasDetallePorGrupo = ISNULL((SELECT parDetalladoConGrupos FROM cttParametro WHERE 1 = 1), 'N');
		
		--' Genera asiento contable en tabla de posteo
		SET @varModEstado = (SELECT modEstado FROM adtEmpresaModulo WHERE modId = 'vn');	
		IF @varModEstado = 'A' BEGIN
		    SET @booGeneraContabilidad = (SELECT ttxGeneraContabilidad FROM gntTipoTxn WHERE ttxid = @strTipoTxnVn);
		    IF @booGeneraContabilidad = 1 BEGIN
		        IF @strTipoTxnVn = 'VEN' OR @strTipoTxnVn = 'VAF' OR @strTipoTxnVn = 'DVE' BEGIN
		            IF (SELECT ISNULL(vnpRecargoItemsAsumido, 'N') FROM vntParametro) = 'E' BEGIN
		                DECLARE @octId VARCHAR(50);
		                DECLARE @tcuImporte DECIMAL(24,12);
		                DECLARE @proId2 VARCHAR(50);
		                DECLARE @ctaId VARCHAR(50);
		                DECLARE @strNotaFormaP VARCHAR(50);
		                DECLARE @strNroDocumento VARCHAR(50);
		                DECLARE @proId3 VARCHAR(50);
		                SELECT @strNotaFormaP = fptNota FROM vntFPagoTxn WHERE vntid = @strvntId AND fptTipoRecargo = 1
		                SELECT @strNroDocumento = vntNumero, @proId3 = proId FROM vntTxn WHERE vntid = @strvntId
		                
		                DECLARE curvntTxnCuentaRecargo CURSOR LOCAL FOR
		                	SELECT ctaId, octId, tcuImporte, proId FROM vntTxnCuentaRecargo WHERE vntid = @strvntId AND conId = 'ABOCUECOR';
		                
		                OPEN curvntTxnCuentaRecargo;
		                FETCH NEXT FROM curvntTxnCuentaRecargo INTO @ctaId,@octId,@tcuImporte,@proId2;
		                IF (@@FETCH_STATUS = 0) BEGIN
		                    WHILE @@FETCH_STATUS = 0 BEGIN
		                        IF ((SELECT ISNULL(ctaExcluyenteCF, 0) FROM cntCuenta WHERE ctaId = @ctaId) = 0) BEGIN
		                            EXEC CreaPosteo 
		                                 @tabla = 'cntPosteoCn', @ttxId = @strTipoTxnVn, 	--VEN
		                                 @intId = @strvntId, @ctaId = @ctaId, 	--
		                                 @octId = '', @posFechaDoc = @fchFechaDoc, 	--FECHA DOC
		                                 @posTC = @dblTc, 	--VENTA
		                                 @posDebeC = @tcuImporte, @posHaberC = 0, @strMonId = @strMonId, 	--VENTA
		                                 @strModId = 'vn', @posDescripcion = @strDescripcion, 	--VENTA
		                                 @strConFactura = 'N', @strExportadoAlFiscal = @strExportadoAlFiscal, 	--VENTA
		                                 @strproId = @proId3, 	--VENTA ivan ojo
		                                 @strBanId = NULL, @strNroDocumento = @strNroDocumento, 	--VENTA
		                                 @strNota = @strNotaFormaP, 	--@strNota VENTA forma de pago con chec
		                                 @dblImporte = 0, @strAnulada = 'N', @varProId = @proId2, @strMonIdC = @strMonIdC, @strMonIdP = @strMonIdP;
		 
		                            SET @dblDebe = @dblDebe + @tcuImporte;
		                        END;
		                        
		                        FETCH NEXT FROM curvntTxnCuentaRecargo INTO @ctaId,@octId,@tcuImporte,@proId2;
		                    END
		                END
		                
		                CLOSE curvntTxnCuentaRecargo;
		                DEALLOCATE curvntTxnCuentaRecargo
		            END
		            --'---------------------------FORMAS DE PAGO
		            DECLARE rsFpago3 CURSOR LOCAL FOR
		            	SELECT fpaId, fpaReferencia, fptReferenciaIngreso, fptMontoMoneda, fptDestinoIngreso, monId, fptTipoRecargo FROM vntFpagoTxn WHERE vntid = @strvntId AND (fptTipoRecargo = CASE WHEN @strRecargoItemsAsumido = 'E' THEN 1 ELSE -1 END OR fptTipoRecargo = 0)
		            
		            OPEN rsFpago3;
		            FETCH NEXT FROM rsFpago3 INTO @fpaId_RS,@fpaReferencia_RS,@fptReferenciaIngreso_RS,@fptMontoMoneda_RS,@fptDestinoIngreso_RS,@monId_RS,@fptTipoRecargo; 
		            --If Not rsFpago.EOF Then
		            IF @@FETCH_STATUS = 0 BEGIN
		                --rsFpago.MoveFirst
		                --Do
		                WHILE @@FETCH_STATUS = 0 BEGIN
		                    --If rsFpago!fpaId <> "EFECTIVO" And rsFpago!fpaId <> "DOCUMENTO" And rsFpago!fpaId <> "CHEQUE" And rsFpago!fpaId <> "TRANSFER" And (Len(Trim(rsFpago!fpaReferencia)) = 0 Or IsNull(rsFpago!fpaReferencia)) And (Len(Trim(rsFpago!fptReferenciaIngreso)) = 0 Or IsNull(rsFpago!fptReferenciaIngreso)) Then
		                    IF @fpaId_RS <> 'EFECTIVO' AND @fpaId_RS <> 'DOCUMENTO' AND @fpaId_RS <> 'CHEQUE' AND @fpaId_RS <> 'TRANSFER' AND (LEN(RTRIM(LTRIM(@fpaReferencia_RS))) = 0 OR (@fpaReferencia_RS IS NULL)) AND (LEN(RTRIM(LTRIM(@fptReferenciaIngreso_RS))) = 0 OR (@fptReferenciaIngreso_RS IS NULL)) BEGIN
		                        --vmaGeneraAsientoVentas = ErrNoExisteReferencia
		                        SET @strMensajeError = 'ERROR : NO EXISTE REFERENCIA';
		                        RAISERROR (@strMensajeError, 16, 1);
		                        ----THROW 51000, @strMensajeError, 1;
		                    END;
		                    SET @varReferencia = @fpaReferencia_RS;
		                    IF @fpaId_RS = 'CONCTACTE' BEGIN
		                        IF @strTipoTxnVn = 'VEN' OR @strTipoTxnVn = 'VAF' OR @strTipoTxnVn = 'PRO' BEGIN
		                            IF @fptTipoRecargo = 1 BEGIN
		                                SET @strConcepto = 'CUECORPAG';
		                            END ELSE  BEGIN
		                                IF @fptMontoMoneda_RS > 0 BEGIN
		                                    IF @strModoAsiento = 'I' BEGIN
		                                        SET @strConcepto = 'CUECORCOB';
		                                    END ELSE  BEGIN
		                                        SET @strConcepto = 'PRECUECOB';
		                                    END;
		                                END ELSE    
		                                IF @fptMontoMoneda_RS < 0 BEGIN
		                                    IF @strModoAsiento = 'I' BEGIN
		                                        SET @strConcepto = 'CUECORPAG';
		                                    END ELSE  BEGIN
		                                        SET @strConcepto = 'PRECUEPAG';
		                                    END;
		                                END;
		                            END
		                        END ELSE  BEGIN
		                            IF (@varReferenciaDevolucion IS NOT NULL) AND LEN(RTRIM(LTRIM(@varReferenciaDevolucion))) <> 0 BEGIN
		                                IF @strModoAsiento = 'I' BEGIN
		                                    SET @strConcepto = 'CUECORCOB';
		                                END ELSE  BEGIN
		                                    SET @strConcepto = 'PRECUECOB';
		                                END;
		                            END ELSE  BEGIN
		               IF @strModoAsiento = 'I' BEGIN
		                                    SET @strConcepto = 'CUECORPAG';
		                                END ELSE  BEGIN
		                                    SET @strConcepto = 'PRECUEPAG';
		                                END;
		                            END;
		                        END; 
		                        
		                        ------********IC
		                        IF @fptTipoRecargo IN (1, 2) BEGIN
		                            --IC 2018-06-28
		                            IF @strTipoTxnVn = 'VEN' BEGIN
		                                SET @intCntReg = (SELECT COUNT(*) FROM cntConcepto WHERE conId LIKE @strConcepto)
		                                
		                                IF @intCntReg = 0 BEGIN
		                                    SET @strMensajeError = @strNombreParamSP + ' ERROR: No existe el concepto : ''' + @strConcepto + '''';
		                                    RAISERROR (@strMensajeError, 16, 1);
		                                    --THROW 51000, @strMensajeError, 1;
		                                END
		                                
		                                SELECT @strCtaid = ctaId, @varReferencia = ISNULL(tdoid, '') FROM (SELECT c.ctaId, C.tdoid FROM cntConceptoCuenta AS cc INNER JOIN cntcuenta AS c ON cc.ctaId = c.ctaId WHERE cc.conId LIKE @strConcepto AND c.ctaId IN (SELECT ct.ctaIdProveedor FROM vntTxn AS ct WHERE ct.vntid = 
		                                                                                                                                                                                                                                                                @strvntId)
		                                                                                                   GROUP BY c.ctaId, C.tdoid)L
		                                
		                                SET @strOctId = ''
		                                
		                                IF REPLACE(@varReferencia, ' ', '') = '' BEGIN
		                                    SET @strMensajeError = @strNombreParamSP + ' ERROR: El Concepto Contable ''' + @strConcepto + ''', No se Encuentra Asociado  con la referencia ''' + ISNULL(@varReferencia, '') + ''''
		                                    
		                                    RAISERROR (@strMensajeError, 16, 1);
		                                    --THROW 51000, @strMensajeError, 1;
		                                END
		                                IF @strCtaCteMasDetallePorGrupo = 'S' BEGIN
		                                    --Por grupos de ctacte
		                                    SET @varReferencia = (SELECT gruCtaCte FROM gntDirectorio WHERE dirid = @fpaReferencia_RS)
		                                    
		                                    SET @varReferencia = ISNULL(@varReferencia, '')
		                                    
		                                    IF LEN(@varReferencia) = 0 BEGIN
		                                        ----ApruebaAsientoCompra = ErrMensajeMudo: gvarMensajeError = "El Cuenta Correntista No Tiene Asociado Un Grupo de Cuenta Corriente "
		                                        SET @strMensajeError = @strNombreParamSP + ' ERROR: El cuenta corrientista : ''' + ISNULL(@fpaReferencia_RS, '') + ''' No tiene un grupo de cuenta corriente Asignado'
		                                        
		                                        RAISERROR (@strMensajeError, 16, 1);
		                                        --THROW 51000, @strMensajeError, 1;
		                                    END
		                                END
		                            END
		                        END ELSE  BEGIN
		                            --varResultado = recuperaRegistroSQL("conOtroDetalle", "cntConcepto", "conId = '" & "CUECORCOB" & "'")
		                            SET @conOtroDetalle = (SELECT conOtroDetalle FROM cntConcepto WHERE conId = 'CUECORCOB');
		                            --If varResultado = "S" And (strConcepto = "CUECORCOB" Or strConcepto = "CUECORPAG") Then
		                            IF @conOtroDetalle = 'S' AND (@strConcepto = 'CUECORCOB' OR @strConcepto = 'CUECORPAG') BEGIN
		                                --If strCtaCteMasDetallePorGrupo = "S" Then  ' Por grupos de ctacte
		                                IF @strCtaCteMasDetallePorGrupo = 'S' BEGIN
		                                    --varReferencia = recuperaRegistroSQL("gruCtaCte", "gntDirectorio", "dirid  = '" & rsFpago!fpaReferencia & "'")
		                                    SET @varReferencia = (SELECT gruCtaCte FROM gntDirectorio WHERE dirid = @fpaReferencia_RS);
		                                    --If IsNull(varReferencia) Then
		                                    IF @varReferencia IS NULL BEGIN
		                                        --vmaGeneraAsientoVentas = ErrMensajeMudo: gvarMensajeError = "El Cuenta Correntista No Tiene Asociado Un Grupo de Cuenta Corriente "
		                                        SET @strMensajeError = 'El Cuenta Correntista No Tiene Asociado Un Grupo de Cuenta Corriente '; 
		                                        RAISERROR (@strMensajeError, 16, 1);
		                                        ----THROW 51000, @strMensajeError, 1;
		                                        --Exit Function
		                                        --End If
		                                    END;
		                                END--Else 'Por tipo de documento
		                                    ELSE  BEGIN
		                                    --varReferencia = strTdoId
		                                    SET @varReferencia = @strTdoId;
		                                    --End If
		                                END;
		                            END--Else
		                                ELSE  BEGIN
		                                --If strModoAsiento = "P" Then
		                                IF @strModoAsiento = 'P' BEGIN
		                                    --varReferencia = strTdoId
		                                    SET @varReferencia = @strTdoId;
		                                    --End If
		                                END;
		                                --End If
		                            END;
		                        END
		                    END--Case "CREDITO"
		                        ELSE    
		                    IF @fpaId_RS = 'CREDITO' BEGIN
		                        --If strTipoTxnVn = "VEN" Or strTipoTxnVn = "VAF" Or strTipoTxnVn = "PRO" Then
		                        IF @strTipoTxnVn = 'VEN' OR @strTipoTxnVn = 'VAF' OR @strTipoTxnVn = 'PRO' BEGIN
		                            --strConcepto = "CUECOB"
		                            SET @strConcepto = 'CUECOB';
		                        END--Else
		                            ELSE  BEGIN
		                            --strConcepto = "CUEPAG"
		                            SET @strConcepto = 'CUEPAG'; 
		                            --End If
		                        END;
		                    END--Case "CHEQUE", "TRANSFER" 'gap
		                        ELSE    
		                    IF @fpaId_RS IN ('CHEQUE', 'TRANSFER') BEGIN
		                        --If strTipoTxnVn = "VEN" Or strTipoTxnVn = "VAF" Or strTipoTxnVn = "PRO" Then
		                        IF @strTipoTxnVn = 'VEN' OR @strTipoTxnVn = 'VAF' OR @strTipoTxnVn = 'PRO' BEGIN
		                            --If rsFpago!fptDestinoIngreso = "B" Then
		                            IF @fptDestinoIngreso_RS = 'B' BEGIN
		                                --strConcepto = "BAN"
		                                SET @strConcepto = 'BAN';
		                                --varReferencia = rsFpago!fptReferenciaIngreso
		                                SET @varReferencia = @fptReferenciaIngreso_RS;
		       END--Else
		                                ELSE  BEGIN
		                                --strConcepto = "CAJ"
		                                SET @strConcepto = 'CAJ';
		                                --varReferencia = rsFpago!fptReferenciaIngreso
		                                SET @varReferencia = @fptReferenciaIngreso_RS;
		                                --End If
		                            END;
		                        END ELSE    
		                        IF @strTipoTxnVn = 'DVE' BEGIN
		                            --ElseIf strTipoTxnVn = "DVE" Then 'jg 24-03-2017
		                            --strConcepto = "BAN"
		                            SET @strConcepto = 'BAN';
		                            --varReferencia = rsFpago!fpaReferencia  
		                            SET @varReferencia = @fpaReferencia_RS;
		                            --Else
		                        END ELSE  BEGIN
		                            --strConcepto = "BAN"
		                            SET @strConcepto = 'BAN'; 
		                            --varReferencia = rsFpago!fptReferenciaIngreso
		                            SET @varReferencia = @fptReferenciaIngreso_RS;
		                            --End If
		                        END;
		                    END--Case "EFECTIVO"
		                        ELSE    
		                    IF @fpaId_RS = 'EFECTIVO' BEGIN
		                        --strConcepto = "CAJ"
		                        SET @strConcepto = 'CAJ';
		                    END--Case "DOCUMENTO"
		                        ELSE    
		                    IF @fpaId_RS = 'DOCUMENTO' BEGIN
		                        --strConcepto = "DOC"
		                        SET @strConcepto = 'DOC';
		                        --varReferencia = rsFpago!fpaReferencia
		                        SET @varReferencia = @fpaReferencia_RS;
		                    END--Case "HOSPEDAJE"
		                        ELSE    
		                    IF @fpaId_RS = 'HOSPEDAJE' BEGIN
		                        --If strTipoTxnVn = "VEN" Or strTipoTxnVn = "VAF" Or strTipoTxnVn = "PRO" Then
		                        IF @strTipoTxnVn = 'VEN' OR @strTipoTxnVn = 'VAF' OR @strTipoTxnVn = 'PRO' BEGIN
		                            --strConcepto = "CUECOBHOS"
		                            SET @strConcepto = 'CUECOBHOS';
		                        END--Else
		                            ELSE  BEGIN
		                            --strConcepto = "CUEPAGHOS"
		                            SET @strConcepto = 'CUEPAGHOS';
		                            --End If
		                        END;
		                        --'varReferencia = strCliId 'Comentado por PB -30-09-2014 pedido por darling
		                        --If strDetalladoConGrupos = "N" Then
		                        --								  IF @strDetalladoConGrupos = 'N' BEGIN
		                        ----varReferencia = strTdoId
		                        --									  SET @varReferencia = @strTdoId;
		                        --								  END
		                        ----Else
		                        --								  ELSE BEGIN
		                        ----varReferencia = strCliId
		                        --									  SET @varReferencia = @strCliId;
		                        ----End If
		                        --								  END;
		                        
		                        SET @strConceptoDetallado = ISNULL((SELECT conOtroDetalle FROM cntConcepto WITH (NOLOCK) WHERE conId LIKE @strConcepto), 'S')
		                        
		                        IF @strConceptoDetallado LIKE 'S' BEGIN
		                            SET @varReferencia = @strTdoId;
		                        END ELSE  BEGIN
		                            SET @varReferencia = @strCliId;
		                        END ;
		                    END--Case "TARJETA"
		                        ELSE    
		                    IF @fpaId_RS = 'TARJETA' BEGIN
		                        --If strTipoTxnVn = "VEN" Or strTipoTxnVn = "VAF" Or strTipoTxnVn = "PRO" Then
		                        IF @strTipoTxnVn = 'VEN' OR @strTipoTxnVn = 'VAF' OR @strTipoTxnVn = 'PRO' BEGIN
		                            --strConcepto = "TARCRECOB"
		                            SET @strConcepto = 'TARCRECOB';
		                        END--Else
		                            ELSE  BEGIN
		                            --strConcepto = "TARCRE"
		                            SET @strConcepto = 'TARCRE';
		                            --End If
		                        END; 
		                        --End Select
		                    END;		
		                    IF @fptTipoRecargo = 0 BEGIN
		                        --varResultado = recuperaRegistroSQL("conGenerico", "cntConcepto", "conId = '" & strConcepto & "'", , "ctaId", "octId")
		                        SELECT @flgGenerico = conGenerico, @strCtaid = ctaId, @strOctId = octId FROM cntConcepto WHERE conId = @strConcepto
		                        --If IsNull(varResultado) Then
		                        IF @@ROWCOUNT = 0 BEGIN
		                            --vmaGeneraAsientoVentas = ErrNoExisteConceptoCuenta
		                            SET @strMensajeError = 'ERROR : NO EXISTE  CONFIGURADO EL CONCEPTO ' + ISNULL(@strConcepto, '');
		                            RAISERROR (@strMensajeError, 16, 1);
		                            ----THROW 51000, @strMensajeError, 1;
		                            --Exit Function
		                            --End If
		                        END; 
		                        --flgGenerico = recuperacampo(varResultado, 1)
		                        --strCtaid = recuperacampo(varResultado, 2)
		                        --strOctId = recuperacampo(varResultado, 3)
		                        --If (IsNull(strCtaid) Or Len(Trim(strCtaid)) = 0) And flgGenerico Then
		                        IF ((@strCtaid IS NULL) OR LEN(RTRIM(LTRIM(@strCtaid))) = 0) AND @flgGenerico = 1 BEGIN
		                            --vmaGeneraAsientoVentas = ErrNoExisteConceptoCuenta
		                            SET @strMensajeError = 'ERROR : NO ESTA EXISTE LA CUENTA PARA EL CONCEPTO : ' + ISNULL(@strConcepto, '');
		                            RAISERROR (@strMensajeError, 16, 1);
		                            ----THROW 51000, @strMensajeError, 1;
		                        END;	
		                        
		                        IF @flgGenerico != 1 BEGIN
		                            --varResultado = recuperaRegistroSQL("ctaId", "cntConceptoCuenta", "conId = '" & strConcepto & "' AND ccuReferencia = '" & varReferencia & "'", , "octId")
		                            SELECT @strCtaid = ctaId, @strOctId = octId FROM cntConceptoCuenta WHERE conId = @strConcepto AND ccuReferencia = @varReferencia
		                            --If IsNull(varResultado) Then
		                            IF @@ROWCOUNT = 0 BEGIN
		                                SET @strMensajeError = 'ERROR : NO EXISTE LA CUENTA PARA EL CONCEPTO : ' + ISNULL(@strConcepto, '') + ' CON REFERENCIA : ' + ISNULL(@varReferencia, '') ;
		                                RAISERROR (@strMensajeError, 16, 1);
		                                ----THROW 51000, @strMensajeError, 1;
		                            END;	
		                            IF (@strCtaid IS NULL) OR LEN(RTRIM(LTRIM(@strCtaid))) = 0 BEGIN
		                                SET @strMensajeError = 'ERROR : NO EXISTE LA CUENTA PARA EL CONCEPTO : ' + ISNULL(@strConcepto, '') + ' CON REFERENCIA : ' + ISNULL(@varReferencia, '') ;
		                                RAISERROR (@strMensajeError, 16, 1);
		                                ----THROW 51000, @strMensajeError, 1;
		                            END;
		                        END;
		                    END
		                    
		                    SET @dblTotal = @fptMontoMoneda_RS;	
		                    SET @dblTotalCaj = @dblTotal;	
		                    IF @monId_RS <> @strMonId BEGIN
		                        IF @monId_RS = @strMonIdC BEGIN
		                            SET @dblTotal = @dblTotal / @dblTc;
		                        END ELSE  BEGIN
		                            SET @dblTotal = @dblTotal * @dblTc;
		                        END;
		                    END;
		                    SET @dblTotalVentas = @dblTotalVentas + @dblTotal;
		                    IF @booAnulaTxn != 1 BEGIN
		                        IF @strTipoTxnVn = 'VEN' OR @strTipoTxnVn = 'VAF' OR @strTipoTxnVn = 'PRO' BEGIN
		                            IF @fptTipoRecargo = 0 BEGIN
		                                IF @fptMontoMoneda_RS > 0 BEGIN
		                                    EXEC CreaPosteo 'cntPosteoCn', @strTipoTxnVn, @strvntId, @strCtaid, @strOctId, @fchFechaDoc, @dblTc, @dblTotal, 0, @strMonId, 'vn', @strDescripcion, @strConFacturaPos, @strExportadoAlFiscal, @strproIdCn, @strBanIdCn, @strNroDocumentoCn, @strNotaCn, NULL, NULL, @strTxnAnulada, 
		                                         NULL, NULL, NULL, NULL, NULL, @gstrGeneraTxnContableMonedaCentral, @strMonIdC, @strMonIdP;		
		                                    SET @dblDebe = @dblDebe + @dblTotal;
		                                END ELSE    
		                                IF @fptMontoMoneda_RS < 0 BEGIN
		                                    SET @dblTotal = ABS(@dblTotal);
		                                    EXEC CreaPosteo 'cntPosteoCn', @strTipoTxnVn, @strvntId, @strCtaid, @strOctId, @fchFechaDoc, @dblTc, 0, @dblTotal, @strMonId, 'vn', @strDescripcion, @strConFacturaPos, @strExportadoAlFiscal, @strproIdCn, @strBanIdCn, @strNroDocumentoCn, @strNotaCn, NULL, NULL, @strTxnAnulada, 
		                                         NULL, NULL, NULL, NULL, NULL, @gstrGeneraTxnContableMonedaCentral, @strMonIdC, @strMonIdP;
		                                    SET @dblHaber = @dblHaber + ABS(@dblTotal);
		                                END;
		                            END ELSE  BEGIN
		                                SET @dblTotal = ABS(@dblTotal);
		                                EXEC CreaPosteo 'cntPosteoCn', @strTipoTxnVn, @strvntId, @strCtaid, @strOctId, @fchFechaDoc, @dblTc, 0, @dblTotal, @strMonId, 'vn', @strDescripcion, @strConFacturaPos, @strExportadoAlFiscal, @strproIdCn, @strBanIdCn, @strNroDocumentoCn, @strNotaCn, NULL, NULL, @strTxnAnulada, 
		                                     NULL, NULL, NULL, NULL, NULL, @gstrGeneraTxnContableMonedaCentral, @strMonIdC, @strMonIdP;
		                                SET @dblHaber = @dblHaber + ABS(@dblTotal);
		                            END
		                        END ELSE  BEGIN
		                            EXEC CreaPosteo 'cntPosteoCn', @strTipoTxnVn, @strvntId, @strCtaid, @strOctId, @fchFechaDoc, @dblTc, 0, @dblTotal, @strMonId, 'vn', @strDescripcion, @strConFacturaPos, @strExportadoAlFiscal, @strproIdCn, @strBanIdCn, @strNroDocumentoCn, @strNotaCn, NULL, NULL, @strTxnAnulada, 
		                                 NULL, NULL, NULL, NULL, NULL, @gstrGeneraTxnContableMonedaCentral, @strMonIdC, @strMonIdP;
		                            SET @dblHaber = @dblHaber + @dblTotal;
		                        END;
		                    END ELSE  BEGIN
		                        IF @strTipoTxnVn = 'VEN' OR @strTipoTxnVn = 'VAF' OR @strTipoTxnVn = 'PRO' BEGIN
		                            IF @fptTipoRecargo = 0 BEGIN
		                                IF @fptMontoMoneda_RS > 0 BEGIN
		                                    EXEC CreaPosteo 'cntPosteoCn', @strTipoTxnVn, @strvntId, @strCtaid, @strOctId, @fchFechaDoc, @dblTc, 0, @dblTotal, @strMonId, 'vn', @strDescripcion, @strConFacturaPos, @strExportadoAlFiscal, @strproIdCn, @strBanIdCn, @strNroDocumentoCn, @strNotaCn, NULL, NULL, @strTxnAnulada, 
		                                         NULL, NULL, NULL, NULL, NULL, @gstrGeneraTxnContableMonedaCentral, @strMonIdC, @strMonIdP;	
		                                    SET @dblHaber = @dblHaber + ABS(@dblTotal);
		                                END ELSE    
		                                IF @fptMontoMoneda_RS < 0 BEGIN
		                                    SET @dblTotal = ABS(@dblTotal);
		                                    EXEC CreaPosteo 'cntPosteoCn', @strTipoTxnVn, @strvntId, @strCtaid, @strOctId, @fchFechaDoc, @dblTc, @dblTotal, 0, @strMonId, 'vn', @strDescripcion, @strConFacturaPos, @strExportadoAlFiscal, @strproIdCn, @strBanIdCn, @strNroDocumentoCn, @strNotaCn, NULL, NULL, @strTxnAnulada, 
		                                         NULL, NULL, NULL, NULL, NULL, @gstrGeneraTxnContableMonedaCentral, @strMonIdC, @strMonIdP;
		                                    SET @dblDebe = @dblDebe + ABS(@dblTotal);
		                                END;
		                            END ELSE  BEGIN
		                                EXEC CreaPosteo 'cntPosteoCn', @strTipoTxnVn, @strvntId, @strCtaid, @strOctId, @fchFechaDoc, @dblTc, 0, @dblTotal, @strMonId, 'vn', @strDescripcion, @strConFacturaPos, @strExportadoAlFiscal, @strproIdCn, @strBanIdCn, @strNroDocumentoCn, @strNotaCn, NULL, NULL, @strTxnAnulada, 
		                                     NULL, NULL, NULL, NULL, NULL, @gstrGeneraTxnContableMonedaCentral, @strMonIdC, @strMonIdP;	
		                                SET @dblHaber = @dblHaber + ABS(@dblTotal);
		                            END
		                        END ELSE  BEGIN
		                            EXEC CreaPosteo 'cntPosteoCn', @strTipoTxnVn, @strvntId, @strCtaid, @strOctId, @fchFechaDoc, @dblTc, @dblTotal, 0, @strMonId, 'vn', @strDescripcion, @strConFacturaPos, @strExportadoAlFiscal, @strproIdCn, @strBanIdCn, @strNroDocumentoCn, @strNotaCn, NULL, NULL, @strTxnAnulada, 
		                                 NULL, NULL, NULL, NULL, NULL, @gstrGeneraTxnContableMonedaCentral, @strMonIdC, @strMonIdP;
		                            SET @dblDebe = @dblDebe + ABS(@dblTotal);
		                        END;
		                    END;
		                    IF (@strConcepto = 'BAN' AND @fpaId_RS = 'CHEQUE') OR @fpaId_RS = 'TRANSFER' BEGIN
		                        --'genera ITF
		                        IF @strTipoTxnVn IN ('VEN', 'VAF') BEGIN
		                            EXEC vmaGeneraITF @dblTotal, @fptReferenciaIngreso_RS, @strTipoTxnVn, @strvntId, @fchFechaDoc, @dblTc, @strMonId, @strDescripcion, @strConFacturaPos, @strExportadoAlFiscal, @strCliId, @strPveId, @strTxnAnulada, @dblDebe OUTPUT, @dblHaber OUTPUT, @strproIdCn, @strBanIdCn, @strNroDocumentoCn, 
		                                 @strNotaCn;
		                        END ELSE  BEGIN
		                            EXEC vmaGeneraITF @dblTotal, @fpaReferencia_RS, @strTipoTxnVn, @strvntId, @fchFechaDoc, @dblTc, @strMonId, @strDescripcion, @strConFacturaPos, @strExportadoAlFiscal, @strCliId, @strPveId, @strTxnAnulada, @dblDebe OUTPUT, @dblHaber OUTPUT, @strproIdCn, @strBanIdCn, @strNroDocumentoCn, 
		                                 @strNotaCn;
		                        END 
		                        --If intStatus <> 0 Then
		                        --vmaGeneraAsientoVentas = intStatus
		                        --Exit Function
		                        --End If
		                        --End If
		                    END;
		                    --rsFpago.MoveNext
		                    FETCH NEXT FROM rsFpago3 INTO @fpaId_RS,@fpaReferencia_RS,@fptReferenciaIngreso_RS,@fptMontoMoneda_RS,@fptDestinoIngreso_RS,@monId_RS,@fptTipoRecargo; 
		                    --Loop Until rsFpago.EOF
		                END;
		                --End If
		            END;
		            --rsFpago.Close
		            CLOSE rsFpago3; 
		            --Set rsFpago = Nothing
		            DEALLOCATE rsFpago3;
		            --'-------------------------COSMER------------SOlo Por ALmacen
		            
		            SET @strConcepto = 'COSMER';	
		            SELECT @flgGenerico = conGenerico, @strCtaid = ctaId, @strOctId = octId FROM cntConcepto WHERE conId = @strConcepto
		            
		            IF @@ROWCOUNT = 0 BEGIN
		                SET @strMensajeError = 'No Existe el datos para el concepto COSMER';
		                RAISERROR (@strMensajeError, 16, 1);
		                ----THROW 51000, @strMensajeError, 1;
		            END;
		            IF ((@strCtaid IS NULL) OR LEN(RTRIM(LTRIM(@strCtaid))) = 0) AND @flgGenerico = 1 BEGIN
		                SET @strMensajeError = 'No Existe el datos para el concepto COSMER';
		                RAISERROR (@strMensajeError, 16, 1);
		                ----THROW 51000, @strMensajeError, 1;
		            END;
		            
		            IF @strGeneraCAPor = 'V' AND @booIntegracionCA = 1 BEGIN
		                SET @venId = (SELECT venId FROM vntTxn WHERE vntId LIKE @strvntId);
		                SET @canId = (SELECT canId FROM gntDirectorio WHERE dirid = @venId);
		                IF @canId IS NULL BEGIN
		                    SET @strMensajeError = 'El Vendededor No Tiene Asociado Un Centro de Análisis';
		                    RAISERROR (@strMensajeError, 16, 1);
		                    ----THROW 51000, @strMensajeError, 1;
		                END;
		            END ELSE  BEGIN
		                IF @strGeneraCAPor = 'P' AND @booIntegracionCA = 1 BEGIN
		                    SET @canId = (SELECT canId FROM gntPuntoVenta WHERE pveId = @strPveId);
		                    IF @canId IS NULL BEGIN
		                        SET @strMensajeError = 'El Punto de Venta ' + @strPveId + ' No Tiene Asociado Un Centro de Análisis';
		                        RAISERROR (@strMensajeError, 16, 1);
		                        ----THROW 51000, @strMensajeError, 1;
		                    END;
		                END;
		            END;
		            SET @strOctId = ISNULL(@canId, '')
		            
		            IF @booIntegracionCA = 1 BEGIN
		                SET @strProId = ISNULL((SELECT proId FROM gntPuntoVenta WHERE pveId = @strPveId), '');
		            END ELSE  BEGIN
		                SET @strProId = '';
		            END;
		            
					--31/01/2018 MODIFICACION SOLICITADA POR YOVANA
					SELECT @conOtroDetalle = conOtroDetalle, @StrconReferencia = conReferencia FROM cntConcepto WHERE conId = 'COSMER';
					IF (@conOtroDetalle = 'S' AND @StrconReferencia = 'S') BEGIN
						SET @dblTotal = 0;
						DECLARE miRsDet2 CURSOR LOCAL FOR
		                    SELECT d.artId, d.uniId, d.pvdCantidadEntregada, artTipo, artCalculoCosto, artUsoLote, lotId, a.uniId AS uniArticulo, a.garid,pvdDescripcion 
							FROM vntDetTxn d, intArticulo a WHERE d.artId = a.artId AND vntId LIKE @strvntId AND ISNULL(pvdConSolicitud, 'N')LIKE 'N' AND 
		                        	pvdCantidadEntregada > 0 ORDER BY a.garid
		                        
		                OPEN miRsDet2;
		                FETCH NEXT FROM miRsDet2 INTO @artId_RS,@uniId_RS,@pvdCantidadEntregada_RS,@artTipo_RS,@artCalculoCosto_RS,@artUsoLote_RS,@lotId_RS,@uniArticulo_RS, @strGarid,@strAlmId;	
		                WHILE @@FETCH_STATUS = 0 BEGIN							
							IF @pvdCantidadEntregada_RS > 0 BEGIN
		                        --'Valida existencia de la unidad
		                        IF @uniId_RS IS NULL OR LEN(@uniId_RS) = 0 BEGIN
		                            SET @strMensajeError = @strNombreParamSP + 'No Existe Unidad';
		                            RAISERROR (@strMensajeError, 16, 1);
		                        END
		                        --'Valida existencia de artículo
		                        IF @artId_RS IS NULL OR LEN(@artId_RS) = 0 BEGIN
		                            SET @strMensajeError = @strNombreParamSP + 'No Existe Articulo';
		                            RAISERROR (@strMensajeError, 16, 1);
		                        END
		                        IF @artCalculoCosto_RS = 'P' BEGIN
		                            EXEC CalcularCosto @strAlmId, @artId_RS, @uniId_RS, @strMonId, @dblTc, @pvdCantidadEntregada_RS, @strTxnIn, @dblCosto OUTPUT,@datAFecha = @fchFechaDoc;
		                        END ELSE    
		                        IF @artCalculoCosto_RS <> 'F' BEGIN
		                            --'emmfifo todo el esle add
		                            --varResultado = inpCalculaCostoArticulo(@strAlmId, @artId_RS, @artTipo_RS, @dblTc, @artCalculoCosto_RS, , fchFechaDoc, varCalculoCostoPP)
		                            EXEC inpCalculaCostoArticulo @varAlmId = @strAlmId, @strArtId = @artId_RS, @strArtTipo = @artTipo_RS, @dblTC = @dblTc, @varCostoTipo = @artCalculoCosto_RS, @varAFecha = @fchFechaDoc, @varCalculoCostoPP = @varCalculoCostoPP, @inpCalculaCostoArticulo = @varResultado OUTPUT; 
		                            IF (@strMonId = @strMonIdC) BEGIN
		                                --dblCostoTemporal = Val(recuperacampo(varResultado, 1))
		                                EXEC recuperacampo 
		                                        @strResultado = @varResultado, @intNroCampo = 1, @strCampoActual = @varStatus OUTPUT;
		                                SET @dblCosto = CAST(@varStatus AS DECIMAL(24,12));
		                                --End If
		                            END;                                
		                            IF (@strMonId = @strMonIdP) BEGIN
		                                --dblCostoTemporal = Val(recuperacampo(varResultado, 2))
		                                EXEC recuperacampo 
		                                        @strResultado = @varResultado, @intNroCampo = 2, @strCampoActual = @varStatus OUTPUT;
		                                SET @dblCosto = CAST(@varStatus AS DECIMAL(24,12));
		                                --End If
		                            END;		                                    
		                            --'Convierte Costo si unidades son distintas
		                            IF @uniId_RS <> @uniArticulo_RS BEGIN
		                                EXEC ConvierteEquivalencia 
		                                        @strUnidadDe = @uniId_RS, @strUnidadA = @uniArticulo_RS, @dblvalor = 1, @dblCantidadCONVERTida = @dblResultado OUTPUT;
		                                --If varResultado < 0 Then
		                                IF (@dblResultado < 0) BEGIN
		                                    --vnpGeneraAsientoVentasTxn = varResultado: gvarMensajeError = "Artículo: " & rsFpago!artId & "; Equivalencia: " & rsFpago![uniId] & " ---> " & rsFpago!uniArticulo
		                                    --Exit Function
		                                    SET @strMensajeError = @strNombreParamSP + ' ERROR: Artículo: ' + @artId_RS + '; Equivalencia: ' + @uniId_RS + ' ---> ' + @uniArticulo_RS;
		                                    RAISERROR (@strMensajeError, 16, 1);
		                                    ----THROW 51000, @strMensajeError, 1;
		                                    --End If
		                                END;
		                                --dblCantidadCONVERTida = varResultado
		                                SET @dblCantidadCONVERTida = @dblResultado;
		                                --dblCostoTemporal = dblCostoTemporal * dblCantidadCONVERTida
		                                SET @dblCosto = @dblCosto * @dblCantidadCONVERTida;
		                            END ELSE   
		                            IF @artUsoLote_RS <> 'O' BEGIN
		                                --'emm todo el else add para lote
		                                SET @dblFifo_CantProcesar = @pvdCantidadEntregada_RS
		                                SET @intContX = 0;
		                                WHILE @dblFifo_CantProcesar <= 0 OR @intContX = 0 BEGIN
		                                    SET @intContX = @intContX + 1
		                                    EXEC inpCalculaCostoArticulo 
		                                            @varAlmId = @strAlmId, @strArtId = @artId_RS, @strArtTipo = @artTipo_RS, @dblTC = @dblTc, @varCostoTipo = @artCalculoCosto_RS, @varAFecha = @fchFechaDoc, @varCalculoCostoPP = @varCalculoCostoPP, @inpCalculaCostoArticulo = @varResultado OUTPUT;  
		                                    EXEC recuperacampo @strResultado = @varResultado, @intNroCampo = 7, @strCampoActual = @varStatus OUTPUT
		                                            
		                                    IF @varStatus <> 'N' BEGIN
		                                        SET @strMensajeError = @strNombreParamSP + 'No Existe Detalle';
		                                        RAISERROR (@strMensajeError, 16, 1);
		                                    END
		                                            
		                                    IF (@strMonId = @strMonIdC) BEGIN
		                                        --dblCostoTemporal = Val(recuperacampo(varResultado, 1))
		                                        EXEC recuperacampo 
		                                                @strResultado = @varResultado, @intNroCampo = 1, @strCampoActual = @varStatus OUTPUT;
		                                        SET @dblCosto = CAST(@varStatus AS DECIMAL(24,12));
		                                        --End If
		                                    END;                                
		                                    IF (@strMonId = @strMonIdP) BEGIN
		                                        --dblCostoTemporal = Val(recuperacampo(varResultado, 2))
		                                        EXEC recuperacampo 
		                                                @strResultado = @varResultado, @intNroCampo = 2, @strCampoActual = @varStatus OUTPUT;
		                                        SET @dblCosto = CAST(@varStatus AS DECIMAL(24,12));
		                                        --End If
		                                    END;       
		                                    EXEC recuperacampo @strResultado = @varResultado, @intNroCampo = 3, @strCampoActual = @varStatus OUTPUT; 
		                                    SET @intFifo_EfiId = CAST(@varStatus AS INT);
		                                    EXEC recuperacampo @strResultado = @varResultado, @intNroCampo = 4, @strCampoActual = @varStatus OUTPUT;
		                                    SET @strFifo_IntId = @varStatus
		                                            
		                                    EXEC recuperacampo @strResultado = @varResultado, @intNroCampo = 5, @strCampoActual = @varStatus OUTPUT;
		                                    SET @strFifo_UniId = @varStatus
		                                            
		                                    EXEC recuperacampo @strResultado = @varResultado, @intNroCampo = 6, @strCampoActual = @varStatus OUTPUT;
		                                    SET @dblFifo_EfiSaldo = CAST(@varStatus AS DECIMAL(24,12));
		                                            
		                                    IF @dblFifo_EfiSaldo >= @dblFifo_CantProcesar BEGIN
		                                        SET @dblFifo_Cantidad = @dblFifo_CantProcesar
		                                        SET @dblFifo_EfiSaldo = @dblFifo_EfiSaldo - @dblFifo_CantProcesar
		                                    END ELSE  BEGIN
		                                        SET @dblFifo_Cantidad = @dblFifo_EfiSaldo
		                                        SET @dblFifo_EfiSaldo = 0
		                                    END
		                                            
		                                    SET @dblFifo_CantProcesar = @dblFifo_CantProcesar - @dblFifo_Cantidad
		                                            
		                                    --'Convierte Costo si unidades son distintas
		                                    IF @strFifo_UniId <> @uniArticulo_RS BEGIN
		                                        --varResultado = ConvierteEquivalencia(@strFifo_UniId, @uniArticulo_RS, 1)
		                                        EXEC ConvierteEquivalencia 
		                                                @strUnidadDe = @strFifo_UniId, @strUnidadA = @uniArticulo_RS, @dblvalor = 1, @dblCantidadCONVERTida = @varResultado OUTPUT;
		                                        IF @varResultado < 0 BEGIN
		                                            --vmaGeneraAsientoVentas = varResultado: gvarMensajeError = "Artículo: " & miRsDet!artId & "; Equivalencia: " & strFifo_UniId & " ---> " & miRsDet!uniArticulo
		                                            --Exit FUNCTION                                                                                                
		                                            SET @strMensajeError = @strNombreParamSP + ' ERROR: Artículo: ' + @artId_RS + '; Equivalencia: ' + @strFifo_UniId + ' ---> ' + @uniArticulo_RS;
		                                            RAISERROR (@strMensajeError, 16, 1);
		                                        END
		                                                
		                                        SET @dblCantidadConvertida = @varResultado
		                                        SET @dblCosto = @dblCosto * @dblCantidadConvertida
		                                    END
		                                END
		                            END ELSE --'*************************LOTES*****************************
		                                BEGIN
		                                SET @dblFifo_CantProcesar = @pvdCantidadEntregada_RS
		                                SET @intContX = 0
		                                        
		                                WHILE @dblFifo_CantProcesar <= 0 OR @intContX = 0 BEGIN
		                                    SET @intContX = @intContX + 1
		                                    --'dblCostoC & ";" & dblCostoP & ";" & lotId & ";" & eloCantidad
		                                    --varResultado = inpGetCostoArticuloLote(CStr(stralmId), @artId_RS)
		                                    EXEC inpGetCostoArticuloLote 
		                                            @stralmId, @artId_RS, NULL, @varResultado OUTPUT;
		                                            
		                                    IF @varResultado = '' OR @varResultado IS NULL BEGIN
		                                        --vmaGeneraAsientoVentas = ErrMensajeMudo
		                                        --gvarMensajeError = "El articulo " & miRsDet!artId & " no tiene la cantidad requerida en existencia..."                                                                                                                                   
		                                        SET @strMensajeError = @strNombreParamSP + ' El articulo ' + @artId_RS + ' no tiene la cantidad requerida en existencia...';
		                                        RAISERROR (@strMensajeError, 16, 1);
		                                        --Exit FUNCTION
		                                    END                                      
		                                    IF (@strMonId = @strMonIdC) BEGIN
		                                        --dblCostoTemporal = Val(recuperacampo(varResultado, 1))
		                                        EXEC recuperacampo 
		                                                @strResultado = @varResultado, @intNroCampo = 1, @strCampoActual = @varStatus OUTPUT;
		                                        SET @dblCosto = CAST(@varStatus AS DECIMAL(24,12));
		                                        --End If
		                                    END;                                
		                                    IF (@strMonId = @strMonIdP) BEGIN
		                                        --dblCostoTemporal = Val(recuperacampo(varResultado, 2))
		                                        EXEC recuperacampo 
		                                                @strResultado = @varResultado, @intNroCampo = 2, @strCampoActual = @varStatus OUTPUT;
		                                        SET @dblCosto = CAST(@varStatus AS DECIMAL(24,12));
		                                        --End If
		                                    END; 
		                                    --dblFifo_lotId = recuperacampo(varResultado, 3)   
		                                    EXEC recuperacampo @strResultado = @varResultado, @intNroCampo = 3, @strCampoActual = @varStatus OUTPUT; 
		                                    SET @dblFifo_lotId = @varStatus;
		                                            
		                                    --'strFifo_IntId = recuperacampo(varResultado, 4)
		                                    SET @strFifo_UniId = @uniId_RS
		                                    --dblFifo_EfiSaldo = CDbl(recuperacampo(varResultado, 4))
		                                    EXEC recuperacampo @strResultado = @varResultado, @intNroCampo = 4, @strCampoActual = @varStatus OUTPUT; 
		                                    SET @dblFifo_EfiSaldo = CAST(@varStatus AS DECIMAL(24,12));
		                                            
		                                    IF @dblFifo_EfiSaldo >= @dblFifo_CantProcesar BEGIN
		                                        SET @dblFifo_Cantidad = @dblFifo_CantProcesar
		                                        SET @dblFifo_EfiSaldo = @dblFifo_EfiSaldo - @dblFifo_CantProcesar
		                                    END ELSE  BEGIN
		                                        SET @dblFifo_Cantidad = @dblFifo_EfiSaldo
		                                        SET @dblFifo_EfiSaldo = 0
		                                    END
		                                            
		                                    SET @dblFifo_CantProcesar = @dblFifo_CantProcesar - @dblFifo_Cantidad
		                                            
		                                    --'Convierte Costo si unidades son distintas
		                                    IF @strFifo_UniId <> @uniArticulo_RS BEGIN
		                                        --varResultado = ConvierteEquivalencia(@strFifo_UniId, @uniArticulo_RS, 1)
		                                        EXEC ConvierteEquivalencia 
		                                                @strUnidadDe = @strFifo_UniId, @strUnidadA = @uniArticulo_RS, @dblvalor = 1, @dblCantidadCONVERTida = @varResultado OUTPUT;
		                                        IF @varResultado < 0 BEGIN
		                                            --vmaGeneraAsientoVentas = varResultado: gvarMensajeError = "Artículo: " & @artId_RS & "; Equivalencia: " & strFifo_UniId & " ---> " & miRsDet!uniArticulo
		                                            --Exit FUNCTION                                                                                                                             
		                                            SET @strMensajeError = @strNombreParamSP + ' ERROR: Artículo: ' + @artId_RS + '; Equivalencia: ' + @strFifo_UniId + ' ---> ' + @uniArticulo_RS;
		                                            RAISERROR (@strMensajeError, 16, 1);
		                                        END
		                                                
		                                        SET @dblCantidadConvertida = @varResultado
		                                        SET @dblCosto = @dblCosto * @dblCantidadConvertida
		                                    END
		                                END
		                            END
		                        END
		                    END		                            
		                    SET @dblTotal = @dblTotal + @dblCosto * @pvdCantidadEntregada_RS;
							SET @strGarid_Aux = @strGarid;
		                    FETCH NEXT FROM miRsDet2 INTO @artId_RS,@uniId_RS,@pvdCantidadEntregada_RS,@artTipo_RS,@artCalculoCosto_RS,@artUsoLote_RS,@lotId_RS,@uniArticulo_RS, @strGarid,@strAlmId;
							IF (@strGarid_Aux <> @strGarid) or @@FETCH_STATUS <> 0 BEGIN
								
								IF @dblTotal > 0 BEGIN
									
									select @strCtaid = ctaId from cntconceptocuenta where conid ='COSMER' AND ccuReferencia =@strGarid_Aux;
									IF @strCtaid = '' OR @strCtaid IS NULL BEGIN
		                                SET @strMensajeError = @strNombreParamSP + ' Para el conepto COMER: Más detallado Si - Con referencia Si, no se encuentra la ctaId...';
		                                RAISERROR (@strMensajeError, 16, 1);
		                            END
									IF @booAnulaTxn != 1 BEGIN
										IF @strTipoTxnVn <> 'DVE' BEGIN	
											EXEC CreaPosteo 'cntPosteoCn', @strTipoTxnVn, @strvntId, @strCtaid, @strOctId, @fchFechaDoc, @dblTc, @dblTotal, 0, @strMonId, 'vn', 
															@strDescripcion, @strConFacturaPos, @strExportadoAlFiscal, @strproIdCn, @strBanIdCn, @strNroDocumentoCn, @strNotaCn, NULL, NULL, @strTxnAnulada,
															NULL,@strProId,NULL,NULL,NULL,@gstrGeneraTxnContableMonedaCentral,@strMonIdC,@strMonIdP;	
											SET @dblDebe = @dblDebe + @dblTotal;
										END	    
										ELSE BEGIN	
											EXEC CreaPosteo 'cntPosteoCn', @strTipoTxnVn, @strvntId, @strCtaid, @strOctId, @fchFechaDoc, @dblTc, 0, @dblTotal, @strMonId, 'vn', 
															@strDescripcion, @strConFacturaPos, @strExportadoAlFiscal, @strproIdCn, @strBanIdCn, @strNroDocumentoCn, @strNotaCn, NULL, NULL, @strTxnAnulada,
															NULL,@strProId,NULL,NULL,NULL,@gstrGeneraTxnContableMonedaCentral,@strMonIdC,@strMonIdP;	
											SET @dblHaber = @dblHaber + @dblTotal;	
										END;
									END   
									ELSE BEGIN
										IF @strTipoTxnVn <> 'DVE' BEGIN	
											EXEC CreaPosteo 'cntPosteoCn', @strTipoTxnVn, @strvntId, @strCtaid, @strOctId, @fchFechaDoc, @dblTc, 0, @dblTotal, @strMonId, 'vn', 
															@strDescripcion, @strConFacturaPos, @strExportadoAlFiscal, @strproIdCn, @strBanIdCn, @strNroDocumentoCn, @strNotaCn, NULL, NULL, @strTxnAnulada,
															NULL,@strProId,NULL,NULL,NULL,@gstrGeneraTxnContableMonedaCentral,@strMonIdC,@strMonIdP;
											SET @dblHaber = @dblHaber + @dblTotal;
										END	    
										ELSE BEGIN	
											EXEC CreaPosteo 'cntPosteoCn', @strTipoTxnVn, @strvntId, @strCtaid, @strOctId, @fchFechaDoc, @dblTc, @dblTotal, 0, @strMonId, 'vn', 
															@strDescripcion, @strConFacturaPos, @strExportadoAlFiscal, @strproIdCn, @strBanIdCn, @strNroDocumentoCn, @strNotaCn, NULL, NULL, @strTxnAnulada,
															NULL,@strProId,NULL,NULL,NULL,@gstrGeneraTxnContableMonedaCentral,@strMonIdC,@strMonIdP;
											SET @dblDebe = @dblDebe + @dblTotal;
										END;
									END;
								END;
								SET @dblTotal = 0 ;
							END							
		                END;
		                CLOSE miRsDet2;
		                DEALLOCATE miRsDet2;					
					END ELSE BEGIN
					
		            IF @flgGenerico = 1 BEGIN
		                DECLARE miRs2 CURSOR LOCAL FOR
		                	SELECT DISTINCT pvdDescripcion FROM vntDetTxn AS V, intArticulo AS A WHERE vntId LIKE @strvntId AND ISNULL(pvdConSolicitud, 'N') LIKE 'N' AND pvdCantidadEntregada > 0 AND V.artId = A.artId AND A.artTipo = 'I' ORDER BY pvdDescripcion
		                
		                OPEN miRs2;
		                FETCH NEXT FROM miRs2 INTO @almId_RS;	
		                SET @dblTotal = 0;
		                IF @@FETCH_STATUS = 0 BEGIN
		                    WHILE @@FETCH_STATUS = 0 BEGIN
		                        IF LEN(ISNULL(@almId_RS, '')) = 0 BEGIN
		                            SET @strMensajeError = @strNombreParamSP + 'No Existe el almacen para el concepto COSMER';
		                            RAISERROR (@strMensajeError, 16, 1);
		                            ----THROW 51000, @strMensajeError, 1;
		                        END;
		                        SET @strAlmId = @almId_RS;
		                        
		                        DECLARE miRsDet CURSOR LOCAL FOR
		                        	--SELECT artId,uniId,pvdCantidadEntregada FROM vntDetTxn WHERE vntId LIKE @strvntId AND  ISNULL(pvdConSolicitud,'N')  LIKE 'N' AND
		               	--	pvdDescripcion LIKE @strAlmId AND pvdCantidadEntregada > 0 ORDER By pvdDescripcion
		                        	SELECT d.artId, d.uniId, d.pvdCantidadEntregada, artTipo, artCalculoCosto, artUsoLote, lotId, a.uniId AS uniArticulo FROM vntDetTxn d, intArticulo a WHERE d.artId = a.artId AND vntId LIKE @strvntId AND ISNULL(pvdConSolicitud, 'N')LIKE 'N' AND pvdDescripcion LIKE @strAlmId AND 
		                        	       pvdCantidadEntregada > 0 ORDER BY pvdDescripcion
		                        
		                        OPEN miRsDet;
		                        FETCH NEXT FROM miRsDet INTO @artId_RS,@uniId_RS,@pvdCantidadEntregada_RS,@artTipo_RS,@artCalculoCosto_RS,@artUsoLote_RS,@lotId_RS,@uniArticulo_RS;		
		                        WHILE @@FETCH_STATUS = 0 BEGIN
		                            --EXEC CalcularCosto @strAlmId, @artId_RS, @uniId_RS, @strMonId, @dblTc, @pvdCantidadEntregada_RS, @strTxnIn,@dblCosto OUTPUT;
		                            
		                            IF @pvdCantidadEntregada_RS > 0 BEGIN
		                                --'Valida existencia de la unidad
		                                IF @uniId_RS IS NULL OR LEN(@uniId_RS) = 0 BEGIN
		                                    SET @strMensajeError = @strNombreParamSP + 'No Existe Unidad';
		                                    RAISERROR (@strMensajeError, 16, 1);
		                                END
		                                --'Valida existencia de artículo
		                                IF @artId_RS IS NULL OR LEN(@artId_RS) = 0 BEGIN
		                                    SET @strMensajeError = @strNombreParamSP + 'No Existe Articulo';
		                                    RAISERROR (@strMensajeError, 16, 1);
		                                END
		                                IF @artCalculoCosto_RS = 'P' BEGIN
		                                    EXEC CalcularCosto @strAlmId, @artId_RS, @uniId_RS, @strMonId, @dblTc, @pvdCantidadEntregada_RS, @strTxnIn, @dblCosto OUTPUT,@datAFecha = @fchFechaDoc;
		                                END ELSE    
		                                IF @artCalculoCosto_RS <> 'F' BEGIN
		                                    --'emmfifo todo el esle add
		                                    --varResultado = inpCalculaCostoArticulo(@strAlmId, @artId_RS, @artTipo_RS, @dblTc, @artCalculoCosto_RS, , fchFechaDoc, varCalculoCostoPP)
		                                    EXEC inpCalculaCostoArticulo 
		                                         @varAlmId = @strAlmId, @strArtId = @artId_RS, @strArtTipo = @artTipo_RS, @dblTC = @dblTc, @varCostoTipo = @artCalculoCosto_RS, @varAFecha = @fchFechaDoc, @varCalculoCostoPP = @varCalculoCostoPP, @inpCalculaCostoArticulo = @varResultado OUTPUT; 
		                                    
		                                    IF (@strMonId = @strMonIdC) BEGIN
		                                        --dblCostoTemporal = Val(recuperacampo(varResultado, 1))
		                                        EXEC recuperacampo 
		                                             @strResultado = @varResultado, @intNroCampo = 1, @strCampoActual = @varStatus OUTPUT;
		                                        SET @dblCosto = CAST(@varStatus AS DECIMAL(24,12));
		                                        --End If
		                                    END;                                
		                                    IF (@strMonId = @strMonIdP) BEGIN
		                                        --dblCostoTemporal = Val(recuperacampo(varResultado, 2))
		                                        EXEC recuperacampo 
		                                             @strResultado = @varResultado, @intNroCampo = 2, @strCampoActual = @varStatus OUTPUT;
		                                        SET @dblCosto = CAST(@varStatus AS DECIMAL(24,12));
		                                        --End If
		                                    END;
		            
		                                    --'Convierte Costo si unidades son distintas
		                                    IF @uniId_RS <> @uniArticulo_RS BEGIN
		                                        EXEC ConvierteEquivalencia 
		                                             @strUnidadDe = @uniId_RS, @strUnidadA = @uniArticulo_RS, @dblvalor = 1, @dblCantidadCONVERTida = @dblResultado OUTPUT;
		                                        --If varResultado < 0 Then
		                                        IF (@dblResultado < 0) BEGIN
		                                            --vnpGeneraAsientoVentasTxn = varResultado: gvarMensajeError = "Artículo: " & rsFpago!artId & "; Equivalencia: " & rsFpago![uniId] & " ---> " & rsFpago!uniArticulo
		                                            --Exit Function
		                                            SET @strMensajeError = @strNombreParamSP + ' ERROR: Artículo: ' + @artId_RS + '; Equivalencia: ' + @uniId_RS + ' ---> ' + @uniArticulo_RS;
		                                            RAISERROR (@strMensajeError, 16, 1);
		                                            ----THROW 51000, @strMensajeError, 1;
		                                            --End If
		                                        END;
		                                        --dblCantidadCONVERTida = varResultado
		                                        SET @dblCantidadCONVERTida = @dblResultado;
		                                        --dblCostoTemporal = dblCostoTemporal * dblCantidadCONVERTida
		                                        SET @dblCosto = @dblCosto * @dblCantidadCONVERTida;
		                                    END ELSE   
		                                    IF @artUsoLote_RS <> 'O' BEGIN
		                                        --'emm todo el else add para lote
		                                        SET @dblFifo_CantProcesar = @pvdCantidadEntregada_RS
		                                        SET @intContX = 0;
		                                        WHILE @dblFifo_CantProcesar <= 0 OR @intContX = 0 BEGIN
		                                            SET @intContX = @intContX + 1
		                                            --'dblCostoC & ";" & dblCostoP & ";" & intEfiId & ";" & strIntId & ";" & strUniId & ";" & dblEfiSaldo
		                                            --varResultado = inpCalculaCostoArticulo(stralmId, miRsDet!artId, miRsDet!artTipo, dblTC, miRsDet!artCalculoCosto, , fchFechaDoc, varCalculoCostoPP)
		                                            EXEC inpCalculaCostoArticulo 
		                                                 @varAlmId = @strAlmId, @strArtId = @artId_RS, @strArtTipo = @artTipo_RS, @dblTC = @dblTc, @varCostoTipo = @artCalculoCosto_RS, @varAFecha = @fchFechaDoc, @varCalculoCostoPP = @varCalculoCostoPP, @inpCalculaCostoArticulo = @varResultado OUTPUT;  
		                                            EXEC recuperacampo @strResultado = @varResultado, @intNroCampo = 7, @strCampoActual = @varStatus OUTPUT
		                                            
		                                            IF @varStatus <> 'N' BEGIN
		                                                SET @strMensajeError = @strNombreParamSP + 'No Existe Detalle';
		                                                RAISERROR (@strMensajeError, 16, 1);
		                                            END
		                                            
		                                            IF (@strMonId = @strMonIdC) BEGIN
		                                                --dblCostoTemporal = Val(recuperacampo(varResultado, 1))
		                                                EXEC recuperacampo 
		                                                     @strResultado = @varResultado, @intNroCampo = 1, @strCampoActual = @varStatus OUTPUT;
		                                                SET @dblCosto = CAST(@varStatus AS DECIMAL(24,12));
		                                       --End If
		                                            END;                                
		                                            IF (@strMonId = @strMonIdP) BEGIN
		                                                --dblCostoTemporal = Val(recuperacampo(varResultado, 2))
		                                                EXEC recuperacampo 
		                                                     @strResultado = @varResultado, @intNroCampo = 2, @strCampoActual = @varStatus OUTPUT;
		                                                SET @dblCosto = CAST(@varStatus AS DECIMAL(24,12));
		                                                --End If
		                                            END;       
		                                            EXEC recuperacampo @strResultado = @varResultado, @intNroCampo = 3, @strCampoActual = @varStatus OUTPUT; 
		                                            SET @intFifo_EfiId = CAST(@varStatus AS INT);
		                                            EXEC recuperacampo @strResultado = @varResultado, @intNroCampo = 4, @strCampoActual = @varStatus OUTPUT;
		                                            SET @strFifo_IntId = @varStatus
		                                            
		                                            EXEC recuperacampo @strResultado = @varResultado, @intNroCampo = 5, @strCampoActual = @varStatus OUTPUT;
		                                            SET @strFifo_UniId = @varStatus
		                                            
		                                            EXEC recuperacampo @strResultado = @varResultado, @intNroCampo = 6, @strCampoActual = @varStatus OUTPUT;
		                                            SET @dblFifo_EfiSaldo = CAST(@varStatus AS DECIMAL(24,12));
		                                            
		                                            IF @dblFifo_EfiSaldo >= @dblFifo_CantProcesar BEGIN
		                                                SET @dblFifo_Cantidad = @dblFifo_CantProcesar
		                                                SET @dblFifo_EfiSaldo = @dblFifo_EfiSaldo - @dblFifo_CantProcesar
		                                            END ELSE  BEGIN
		                                                SET @dblFifo_Cantidad = @dblFifo_EfiSaldo
		                                                SET @dblFifo_EfiSaldo = 0
		                                            END
		                                            
		                                            SET @dblFifo_CantProcesar = @dblFifo_CantProcesar - @dblFifo_Cantidad
		                                            
		                                            --'Convierte Costo si unidades son distintas
		                                            IF @strFifo_UniId <> @uniArticulo_RS BEGIN
		                                                --varResultado = ConvierteEquivalencia(@strFifo_UniId, @uniArticulo_RS, 1)
		                                                EXEC ConvierteEquivalencia 
		                                                     @strUnidadDe = @strFifo_UniId, @strUnidadA = @uniArticulo_RS, @dblvalor = 1, @dblCantidadCONVERTida = @varResultado OUTPUT;
		                                                IF @varResultado < 0 BEGIN
		                                                    --vmaGeneraAsientoVentas = varResultado: gvarMensajeError = "Artículo: " & miRsDet!artId & "; Equivalencia: " & strFifo_UniId & " ---> " & miRsDet!uniArticulo
		                                                    --Exit FUNCTION                                                                                                
		                                                    SET @strMensajeError = @strNombreParamSP + ' ERROR: Artículo: ' + @artId_RS + '; Equivalencia: ' + @strFifo_UniId + ' ---> ' + @uniArticulo_RS;
		                                                    RAISERROR (@strMensajeError, 16, 1);
		                                             END
		                                                
		                                                SET @dblCantidadConvertida = @varResultado
		                                                SET @dblCosto = @dblCosto * @dblCantidadConvertida
		                                            END
		                                        END
		                                    END ELSE --'*************************LOTES*****************************
		                                        BEGIN
		                                        SET @dblFifo_CantProcesar = @pvdCantidadEntregada_RS
		                                        SET @intContX = 0
		                                        
		                                        WHILE @dblFifo_CantProcesar <= 0 OR @intContX = 0 BEGIN
		                                            SET @intContX = @intContX + 1
		                                            --'dblCostoC & ";" & dblCostoP & ";" & lotId & ";" & eloCantidad
		                                            --varResultado = inpGetCostoArticuloLote(CStr(stralmId), @artId_RS)
		                                            EXEC inpGetCostoArticuloLote 
		                                                 @stralmId, @artId_RS, NULL, @varResultado OUTPUT;
		                                            
		                                            IF @varResultado = '' OR @varResultado IS NULL BEGIN
		                                                --vmaGeneraAsientoVentas = ErrMensajeMudo
		                                                --gvarMensajeError = "El articulo " & miRsDet!artId & " no tiene la cantidad requerida en existencia..."                                                                                                                                   
		                                                SET @strMensajeError = @strNombreParamSP + ' El articulo ' + @artId_RS + ' no tiene la cantidad requerida en existencia...';
		                                                RAISERROR (@strMensajeError, 16, 1);
		                                                --Exit FUNCTION
		                                            END                                      
		                                            IF (@strMonId = @strMonIdC) BEGIN
		                                                --dblCostoTemporal = Val(recuperacampo(varResultado, 1))
		                                                EXEC recuperacampo 
		                                                     @strResultado = @varResultado, @intNroCampo = 1, @strCampoActual = @varStatus OUTPUT;
		                                                SET @dblCosto = CAST(@varStatus AS DECIMAL(24,12));
		                                                --End If
		                                            END;                                
		                                            IF (@strMonId = @strMonIdP) BEGIN
		                                                --dblCostoTemporal = Val(recuperacampo(varResultado, 2))
		                                                EXEC recuperacampo 
		                                                     @strResultado = @varResultado, @intNroCampo = 2, @strCampoActual = @varStatus OUTPUT;
		                                                SET @dblCosto = CAST(@varStatus AS DECIMAL(24,12));
		                                                --End If
		                                            END; 
		                                            --dblFifo_lotId = recuperacampo(varResultado, 3)   
		                                            EXEC recuperacampo @strResultado = @varResultado, @intNroCampo = 3, @strCampoActual = @varStatus OUTPUT; 
		                                            SET @dblFifo_lotId = @varStatus;
		                                            
		                                            --'strFifo_IntId = recuperacampo(varResultado, 4)
		                                            SET @strFifo_UniId = @uniId_RS
		                                            --dblFifo_EfiSaldo = CDbl(recuperacampo(varResultado, 4))
		                                            EXEC recuperacampo @strResultado = @varResultado, @intNroCampo = 4, @strCampoActual = @varStatus OUTPUT; 
		                                            SET @dblFifo_EfiSaldo = CAST(@varStatus AS DECIMAL(24,12));
		                                            
		                                            IF @dblFifo_EfiSaldo >= @dblFifo_CantProcesar BEGIN
		                                                SET @dblFifo_Cantidad = @dblFifo_CantProcesar
		                                                SET @dblFifo_EfiSaldo = @dblFifo_EfiSaldo - @dblFifo_CantProcesar
		                                            END ELSE  BEGIN
		                                                SET @dblFifo_Cantidad = @dblFifo_EfiSaldo
		                                                SET @dblFifo_EfiSaldo = 0
		                                            END
		                                            
		                                            SET @dblFifo_CantProcesar = @dblFifo_CantProcesar - @dblFifo_Cantidad
		                                            
		                                            --'Convierte Costo si unidades son distintas
		                                            IF @strFifo_UniId <> @uniArticulo_RS BEGIN
		                                                --varResultado = ConvierteEquivalencia(@strFifo_UniId, @uniArticulo_RS, 1)
		                                                EXEC ConvierteEquivalencia 
		                                                     @strUnidadDe = @strFifo_UniId, @strUnidadA = @uniArticulo_RS, @dblvalor = 1, @dblCantidadCONVERTida = @varResultado OUTPUT;
		                                                IF @varResultado < 0 BEGIN
		                                                    --vmaGeneraAsientoVentas = varResultado: gvarMensajeError = "Artículo: " & @artId_RS & "; Equivalencia: " & strFifo_UniId & " ---> " & miRsDet!uniArticulo
		                                                    --Exit FUNCTION                                                                                                                             
		                                                    SET @strMensajeError = @strNombreParamSP + ' ERROR: Artículo: ' + @artId_RS + '; Equivalencia: ' + @strFifo_UniId + ' ---> ' + @uniArticulo_RS;
		                                                    RAISERROR (@strMensajeError, 16, 1);
		                                                END
		                                                
		                                                SET @dblCantidadConvertida = @varResultado
		                                                SET @dblCosto = @dblCosto * @dblCantidadConvertida
		                                            END
		                                        END
		                                    END
		                                END
		                            END --'ic-2018-01-31
		                            
		                            
		                            SET @dblTotal = @dblTotal + @dblCosto * @pvdCantidadEntregada_RS;
		                            FETCH NEXT FROM miRsDet INTO @artId_RS,@uniId_RS,@pvdCantidadEntregada_RS,@artTipo_RS,@artCalculoCosto_RS,@artUsoLote_RS,@lotId_RS,@uniArticulo_RS;
		                        END; 
		                        CLOSE miRsDet;
		                        DEALLOCATE miRsDet;
		                        FETCH NEXT FROM miRs2 INTO @almId_RS;
		                    END;	
		                    
		                    IF @dblTotal > 0 BEGIN
		                        --IF @strIntegracionContableAplicacion = 'S' AND @strNAntFac=0 BEGIN 
		                        IF @strIntegracionContableAplicacion = 'S' BEGIN
		                            --22/10/2018 MODIFICACION SOLICITADA POR MONICA VILLARROEL
		                            DECLARE miRsInt CURSOR LOCAL FOR
		                            	SELECT ctaId, octId, proId, tcuImporte FROM vntTxnCuenta WHERE vntId LIKE @strVntId AND conid = 'VENNET'
		                            
		                            OPEN miRsInt;
		                            FETCH NEXT FROM miRsInt INTO @ctaId_cur,@octId_cur,@proId_cur,@tcuImporte_cur;
		                            IF @@FETCH_STATUS = 0 BEGIN
		                                WHILE @@FETCH_STATUS = 0 BEGIN
		                                    SET @dblPorcentaje = @tcuImporte_cur / (@dblArticuloMoneda -@dblAnticipoMoneda); --23/10/2018 MODIFICADO
		                                    SET @dblTotal_cur = @dblTotal * @dblPorcentaje;
		                                    SET @strOctId = ISNULL(@octId_cur, '');
		                                    SET @strProId = ISNULL(@proId_cur, '');
		                                    IF @booAnulaTxn != 1 BEGIN
		                                        IF @strTipoTxnVn <> 'DVE' BEGIN
		                                            EXEC CreaPosteo 'cntPosteoCn', @strTipoTxnVn, @strvntId, @strCtaid, @strOctId, @fchFechaDoc, @dblTc, @dblTotal_cur, 0, @strMonId, 'vn', @strDescripcion, @strConFacturaPos, @strExportadoAlFiscal, @strproIdCn, @strBanIdCn, @strNroDocumentoCn, @strNotaCn, NULL, 
		                                                 NULL, @strTxnAnulada, NULL, @strProId, NULL, NULL, NULL, @gstrGeneraTxnContableMonedaCentral, @strMonIdC, @strMonIdP;	
		                                            SET @dblDebe = @dblDebe + @dblTotal_cur;
		                                        END ELSE  BEGIN
		                                            EXEC CreaPosteo 'cntPosteoCn', @strTipoTxnVn, @strvntId, @strCtaid, @strOctId, @fchFechaDoc, @dblTc, 0, @dblTotal_cur, @strMonId, 'vn', @strDescripcion, @strConFacturaPos, @strExportadoAlFiscal, @strproIdCn, @strBanIdCn, @strNroDocumentoCn, @strNotaCn, NULL, 
		                                                 NULL, @strTxnAnulada, NULL, @strProId, NULL, NULL, NULL, @gstrGeneraTxnContableMonedaCentral, @strMonIdC, @strMonIdP;
		                                            SET @dblHaber = @dblHaber + @dblTotal_cur;
		                                        END;
		                                    END ELSE  BEGIN
		                                        IF @strTipoTxnVn <> 'DVE' BEGIN
		                                            EXEC CreaPosteo 'cntPosteoCn', @strTipoTxnVn, @strvntId, @strCtaid, @strOctId, @fchFechaDoc, @dblTc, 0, @dblTotal_cur, @strMonId, 'vn', @strDescripcion, @strConFacturaPos, @strExportadoAlFiscal, @strproIdCn, @strBanIdCn, @strNroDocumentoCn, @strNotaCn, NULL, 
		                                                 NULL, @strTxnAnulada, NULL, @strProId, NULL, NULL, NULL, @gstrGeneraTxnContableMonedaCentral, @strMonIdC, @strMonIdP;
		                                            SET @dblHaber = @dblHaber + @dblTotal_cur;
		                                        END ELSE  BEGIN
		                                            EXEC CreaPosteo 'cntPosteoCn', @strTipoTxnVn, @strvntId, @strCtaid, @strOctId, @fchFechaDoc, @dblTc, @dblTotal_cur, 0, @strMonId, 'vn', @strDescripcion, @strConFacturaPos, @strExportadoAlFiscal, @strproIdCn, @strBanIdCn, @strNroDocumentoCn, @strNotaCn, NULL, 
		                                                 NULL, @strTxnAnulada, NULL, @strProId, NULL, NULL, NULL, @gstrGeneraTxnContableMonedaCentral, @strMonIdC, @strMonIdP;	
		                                            SET @dblDebe = @dblDebe + @dblTotal_cur;
		                                        END;
		                                    END;
		                                    FETCH NEXT FROM miRsInt INTO @ctaId_cur,@octId_cur,@proId_cur,@tcuImporte_cur;
		                                END;
		                            END;
		                   CLOSE miRsInt;
		                            DEALLOCATE miRsInt;
		                        END; ELSE  BEGIN
		                        IF @booAnulaTxn != 1 BEGIN
		                            IF @strTipoTxnVn <> 'DVE' BEGIN
		                                SET @strProId = ISNULL(@strProId, '');
		                                EXEC CreaPosteo 'cntPosteoCn', @strTipoTxnVn, @strvntId, @strCtaid, @strOctId, @fchFechaDoc, @dblTc, @dblTotal, 0, @strMonId, 'vn', @strDescripcion, @strConFacturaPos, @strExportadoAlFiscal, @strproIdCn, @strBanIdCn, @strNroDocumentoCn, @strNotaCn, NULL, NULL, @strTxnAnulada, 
		                                     NULL, @strProId, NULL, NULL, NULL, @gstrGeneraTxnContableMonedaCentral, @strMonIdC, @strMonIdP;	
		                                SET @dblDebe = @dblDebe + @dblTotal;
		                            END ELSE  BEGIN
		                                SET @strProId = ISNULL(@strProId, '');
		                                EXEC CreaPosteo 'cntPosteoCn', @strTipoTxnVn, @strvntId, @strCtaid, @strOctId, @fchFechaDoc, @dblTc, 0, @dblTotal, @strMonId, 'vn', @strDescripcion, @strConFacturaPos, @strExportadoAlFiscal, @strproIdCn, @strBanIdCn, @strNroDocumentoCn, @strNotaCn, NULL, NULL, @strTxnAnulada, 
		                                     NULL, @strProId, NULL, NULL, NULL, @gstrGeneraTxnContableMonedaCentral, @strMonIdC, @strMonIdP;
		                                SET @dblHaber = @dblHaber + @dblTotal;
		                            END;
		                        END ELSE  BEGIN
		                            IF @strTipoTxnVn <> 'DVE' BEGIN
		                                SET @strProId = ISNULL(@strProId, '');
		                                EXEC CreaPosteo 'cntPosteoCn', @strTipoTxnVn, @strvntId, @strCtaid, @strOctId, @fchFechaDoc, @dblTc, 0, @dblTotal, @strMonId, 'vn', @strDescripcion, @strConFacturaPos, @strExportadoAlFiscal, @strproIdCn, @strBanIdCn, @strNroDocumentoCn, @strNotaCn, NULL, NULL, @strTxnAnulada, 
		                                     NULL, @strProId, NULL, NULL, NULL, @gstrGeneraTxnContableMonedaCentral, @strMonIdC, @strMonIdP;
		                                SET @dblHaber = @dblHaber + @dblTotal;
		                            END ELSE  BEGIN
		                                SET @strProId = ISNULL(@strProId, '');
		                                EXEC CreaPosteo 'cntPosteoCn', @strTipoTxnVn, @strvntId, @strCtaid, @strOctId, @fchFechaDoc, @dblTc, @dblTotal, 0, @strMonId, 'vn', @strDescripcion, @strConFacturaPos, @strExportadoAlFiscal, @strproIdCn, @strBanIdCn, @strNroDocumentoCn, @strNotaCn, NULL, NULL, @strTxnAnulada, 
		                                     NULL, @strProId, NULL, NULL, NULL, @gstrGeneraTxnContableMonedaCentral, @strMonIdC, @strMonIdP;	
		                                SET @dblDebe = @dblDebe + @dblTotal;
		                            END;
		                        END;
		                    END;
		                END; 
		                CLOSE miRs2
		                DEALLOCATE miRs2;
		            END;
		        END;
		        
		        IF @flgGenerico != 1 BEGIN
		            DECLARE miRs3 CURSOR LOCAL FOR
		            	SELECT DISTINCT pvdDescripcion FROM vntDetTxn WHERE vntId LIKE @strvntId AND ISNULL(pvdConSolicitud, 'N') LIKE 'N' AND pvdCantidadEntregada > 0 ORDER BY pvdDescripcion
		            
		            OPEN miRs3;
		            FETCH NEXT FROM miRs3 INTO @almId_RS;
		            IF @@FETCH_STATUS = 0 BEGIN
		                SET @dblTotal = 0;
		                WHILE @@FETCH_STATUS = 0 BEGIN
		                    SET @dblTotal = 0;
		                    SET @strAlmId = @almId_RS
		                    
		                    IF ISNULL(@strAlmId, '') != '' BEGIN
		                        --'--------buscar la cuenta--------------------
		                        SET @strCtaid = (SELECT ctaId FROM cntConceptoCuenta WHERE conId LIKE @strConcepto AND ccuReferencia LIKE @almId_RS);
		                      IF LEN(ISNULL(@strCtaid, '')) = 0 BEGIN
		                            SET @strMensajeError = 'No existe la cuenta contable asociada al concepto ' + @strConcepto + ' con referencia  ' + @strAlmId;
		                            RAISERROR (@strMensajeError, 16, 1);
		                            ----THROW 51000, @strMensajeError, 1;
		                        END;
		                        DECLARE miRsDet2 CURSOR LOCAL FOR
		                        	--SELECT artId,uniId, pvdCantidadEntregada FROM vntDetTxn WHERE vntId LIKE @strvntId AND ISNULL(pvdConSolicitud,'N')  LIKE 'N'
		                        	--AND pvdDescripcion LIKE @strAlmId AND pvdCantidadEntregada > 0	ORDER BY pvdDescripcion
		                        	SELECT d.artId, d.uniId, d.pvdCantidadEntregada, artTipo, artCalculoCosto, artUsoLote, lotId, a.uniId AS uniArticulo FROM vntDetTxn d, intArticulo a WHERE d.artId = a.artId AND vntId LIKE @strvntId AND ISNULL(pvdConSolicitud, 'N')LIKE 'N' AND pvdDescripcion LIKE @strAlmId AND 
		                        	       pvdCantidadEntregada > 0 ORDER BY pvdDescripcion
		                        
		                        OPEN miRsDet2;
		                        FETCH NEXT FROM miRsDet2 INTO @artId_RS,@uniId_RS,@pvdCantidadEntregada_RS,@artTipo_RS,@artCalculoCosto_RS,@artUsoLote_RS,@lotId_RS,@uniArticulo_RS;	
		                        WHILE @@FETCH_STATUS = 0 BEGIN
		                            --EXEC CalcularCosto @strAlmId, @artId_RS, @uniId_RS, @strMonId, @dblTc, @pvdCantidadEntregada_RS, @strTxnIn,@dblCosto OUTPUT;
		                            IF @pvdCantidadEntregada_RS > 0 BEGIN
		                                --'Valida existencia de la unidad
		                                IF @uniId_RS IS NULL OR LEN(@uniId_RS) = 0 BEGIN
		                                    SET @strMensajeError = @strNombreParamSP + 'No Existe Unidad';
		                                    RAISERROR (@strMensajeError, 16, 1);
		                                END
		                                --'Valida existencia de artículo
		                                IF @artId_RS IS NULL OR LEN(@artId_RS) = 0 BEGIN
		                                    SET @strMensajeError = @strNombreParamSP + 'No Existe Articulo';
		                                    RAISERROR (@strMensajeError, 16, 1);
		                                END
		                                IF @artCalculoCosto_RS = 'P' BEGIN
		                                    EXEC CalcularCosto @strAlmId, @artId_RS, @uniId_RS, @strMonId, @dblTc, @pvdCantidadEntregada_RS, @strTxnIn, @dblCosto OUTPUT,@datAFecha = @fchFechaDoc;
		                                END ELSE    
		                                IF @artCalculoCosto_RS <> 'F' BEGIN
		                                    --'emmfifo todo el esle add
		                                    --varResultado = inpCalculaCostoArticulo(@strAlmId, @artId_RS, @artTipo_RS, @dblTc, @artCalculoCosto_RS, , fchFechaDoc, varCalculoCostoPP)
		                                    EXEC inpCalculaCostoArticulo 
		                                         @varAlmId = @strAlmId, @strArtId = @artId_RS, @strArtTipo = @artTipo_RS, @dblTC = @dblTc, @varCostoTipo = @artCalculoCosto_RS, @varAFecha = @fchFechaDoc, @varCalculoCostoPP = @varCalculoCostoPP, @inpCalculaCostoArticulo = @varResultado OUTPUT; 
		                                    
		                                    IF (@strMonId = @strMonIdC) BEGIN
		                                        --dblCostoTemporal = Val(recuperacampo(varResultado, 1))
		                                        EXEC recuperacampo 
		                                             @strResultado = @varResultado, @intNroCampo = 1, @strCampoActual = @varStatus OUTPUT;
		                                        SET @dblCosto = CAST(@varStatus AS DECIMAL(24,12));
		                                        --End If
		                                    END;                                
		                                    IF (@strMonId = @strMonIdP) BEGIN
		                                        --dblCostoTemporal = Val(recuperacampo(varResultado, 2))
		                                        EXEC recuperacampo 
		                                             @strResultado = @varResultado, @intNroCampo = 2, @strCampoActual = @varStatus OUTPUT;
		                                        SET @dblCosto = CAST(@varStatus AS DECIMAL(24,12));
		                                        --End If
		                                    END;
		                                    
		                                    --'Convierte Costo si unidades son distintas
		                                    IF @uniId_RS <> @uniArticulo_RS BEGIN
		                                        EXEC ConvierteEquivalencia 
		                                             @strUnidadDe = @uniId_RS, @strUnidadA = @uniArticulo_RS, @dblvalor = 1, @dblCantidadCONVERTida = @dblResultado OUTPUT;
		                                        --If varResultado < 0 Then
		                                        IF (@dblResultado < 0) BEGIN
		                                            --vnpGeneraAsientoVentasTxn = varResultado: gvarMensajeError = "Artículo: " & rsFpago!artId & "; Equivalencia: " & rsFpago![uniId] & " ---> " & rsFpago!uniArticulo
		                                            --Exit Function
		                                            SET @strMensajeError = @strNombreParamSP + ' ERROR: Artículo: ' + @artId_RS + '; Equivalencia: ' + @uniId_RS + ' ---> ' + @uniArticulo_RS;
		                                            RAISERROR (@strMensajeError, 16, 1);
		                                            ----THROW 51000, @strMensajeError, 1;
		                                            --End If
		                                        END;
		                                        --dblCantidadCONVERTida = varResultado
		                                        SET @dblCantidadCONVERTida = @dblResultado;
		                                        --dblCostoTemporal = dblCostoTemporal * dblCantidadCONVERTida
		                                        SET @dblCosto = @dblCosto * @dblCantidadCONVERTida;
		                                    END ELSE   
		                                    IF @artUsoLote_RS <> 'O' BEGIN
		                                        --'emm todo el else add para lote
		                                        SET @dblFifo_CantProcesar = @pvdCantidadEntregada_RS
		                                        SET @intContX = 0;
		                                        WHILE @dblFifo_CantProcesar <= 0 OR @intContX = 0 BEGIN
		                                            SET @intContX = @intContX + 1
		                                            --'dblCostoC & ";" & dblCostoP & ";" & intEfiId & ";" & strIntId & ";" & strUniId & ";" & dblEfiSaldo
		                                            --varResultado = inpCalculaCostoArticulo(stralmId, miRsDet!artId, miRsDet!artTipo, dblTC, miRsDet!artCalculoCosto, , fchFechaDoc, varCalculoCostoPP)
		                                            EXEC inpCalculaCostoArticulo 
		                                                 @varAlmId = @strAlmId, @strArtId = @artId_RS, @strArtTipo = @artTipo_RS, @dblTC = @dblTc, @varCostoTipo = @artCalculoCosto_RS, @varAFecha = @fchFechaDoc, @varCalculoCostoPP = @varCalculoCostoPP, @inpCalculaCostoArticulo = @varResultado OUTPUT;  
		                                            EXEC recuperacampo @strResultado = @varResultado, @intNroCampo = 7, @strCampoActual = @varStatus OUTPUT
		                                            
		                                            IF @varStatus <> 'N' BEGIN
		                                                SET @strMensajeError = @strNombreParamSP + 'No Existe Detalle';
		                                                RAISERROR (@strMensajeError, 16, 1);
		                   END
		                                            
		                                            IF (@strMonId = @strMonIdC) BEGIN
		                                                --dblCostoTemporal = Val(recuperacampo(varResultado, 1))
		                                                EXEC recuperacampo 
		                                                     @strResultado = @varResultado, @intNroCampo = 1, @strCampoActual = @varStatus OUTPUT;
		                                                SET @dblCosto = CAST(@varStatus AS DECIMAL(24,12));
		                                                --End If
		                                            END;                                
		                                            IF (@strMonId = @strMonIdP) BEGIN
		                                                --dblCostoTemporal = Val(recuperacampo(varResultado, 2))
		                                                EXEC recuperacampo 
		                                                     @strResultado = @varResultado, @intNroCampo = 2, @strCampoActual = @varStatus OUTPUT;
		                                                SET @dblCosto = CAST(@varStatus AS DECIMAL(24,12));
		                                                --End If
		                                            END;       
		                                            EXEC recuperacampo @strResultado = @varResultado, @intNroCampo = 3, @strCampoActual = @varStatus OUTPUT; 
		                                            SET @intFifo_EfiId = CAST(@varStatus AS INT);
		                                            EXEC recuperacampo @strResultado = @varResultado, @intNroCampo = 4, @strCampoActual = @varStatus OUTPUT;
		                                            SET @strFifo_IntId = @varStatus
		                                            
		                                            EXEC recuperacampo @strResultado = @varResultado, @intNroCampo = 5, @strCampoActual = @varStatus OUTPUT;
		                                            SET @strFifo_UniId = @varStatus
		                                            
		                                            EXEC recuperacampo @strResultado = @varResultado, @intNroCampo = 6, @strCampoActual = @varStatus OUTPUT;
		                                            SET @dblFifo_EfiSaldo = CAST(@varStatus AS DECIMAL(24,12));
		                                            
		                                            IF @dblFifo_EfiSaldo >= @dblFifo_CantProcesar BEGIN
		                                                SET @dblFifo_Cantidad = @dblFifo_CantProcesar
		                                                SET @dblFifo_EfiSaldo = @dblFifo_EfiSaldo - @dblFifo_CantProcesar
		                                            END ELSE  BEGIN
		                                                SET @dblFifo_Cantidad = @dblFifo_EfiSaldo
		                                                SET @dblFifo_EfiSaldo = 0
		                                            END
		                                            
		                                            SET @dblFifo_CantProcesar = @dblFifo_CantProcesar - @dblFifo_Cantidad
		                                            
		                                            --'Convierte Costo si unidades son distintas
		                                            IF @strFifo_UniId <> @uniArticulo_RS BEGIN
		                                                --varResultado = ConvierteEquivalencia(@strFifo_UniId, @uniArticulo_RS, 1)
		                                                EXEC ConvierteEquivalencia 
		                                                     @strUnidadDe = @strFifo_UniId, @strUnidadA = @uniArticulo_RS, @dblvalor = 1, @dblCantidadCONVERTida = @varResultado OUTPUT;
		                                                IF @varResultado < 0 BEGIN
		                                                    --vmaGeneraAsientoVentas = varResultado: gvarMensajeError = "Artículo: " & miRsDet!artId & "; Equivalencia: " & strFifo_UniId & " ---> " & miRsDet!uniArticulo
		                                                    --Exit FUNCTION                                                                                                
		                                                    SET @strMensajeError = @strNombreParamSP + ' ERROR: Artículo: ' + @artId_RS + '; Equivalencia: ' + @strFifo_UniId + ' ---> ' + @uniArticulo_RS;
		                                                    RAISERROR (@strMensajeError, 16, 1);
		                                                END
		                                                
		                                                SET @dblCantidadConvertida = @varResultado
		                                                SET @dblCosto = @dblCosto * @dblCantidadConvertida
		                                            END
		                                        END
		                                    END ELSE --'*************************LOTES*****************************
		                                        BEGIN
		                                        SET @dblFifo_CantProcesar = @pvdCantidadEntregada_RS
		                                        SET @intContX = 0
		                                        
		                                        WHILE @dblFifo_CantProcesar <= 0 OR @intContX = 0 BEGIN
		                                            SET @intContX = @intContX + 1
		                                            --'dblCostoC & ";" & dblCostoP & ";" & lotId & ";" & eloCantidad
		                                            --varResultado = inpGetCostoArticuloLote(CStr(stralmId), @artId_RS)
		                                            EXEC inpGetCostoArticuloLote 
		                                                 @stralmId, @artId_RS, NULL, @varResultado OUTPUT;
		                                            
		                                            IF @varResultado = '' OR @varResultado IS NULL BEGIN
		                                                --vmaGeneraAsientoVentas = ErrMensajeMudo
		                                                --gvarMensajeError = "El articulo " & miRsDet!artId & " no tiene la cantidad requerida en existencia..."                                                                                                                                   
		                                                SET @strMensajeError = @strNombreParamSP + ' El articulo ' + @artId_RS + ' no tiene la cantidad requerida en existencia...';
		                                                RAISERROR (@strMensajeError, 16, 1);
		                                                --Exit FUNCTION
		                                            END                                      
		                                            IF (@strMonId = @strMonIdC) BEGIN
		                                                --dblCostoTemporal = Val(recuperacampo(varResultado, 1))
		                                                EXEC recuperacampo 
		                                                     @strResultado = @varResultado, @intNroCampo = 1, @strCampoActual = @varStatus OUTPUT;
		                                                SET @dblCosto = CAST(@varStatus AS DECIMAL(24,12));
		                                                --End If
		                                            END;                                
		                                            IF (@strMonId = @strMonIdP) BEGIN
		                                                --dblCostoTemporal = Val(recuperacampo(varResultado, 2))
		                                                EXEC recuperacampo 
		                                                     @strResultado = @varResultado, @intNroCampo = 2, @strCampoActual = @varStatus OUTPUT;
		                                                SET @dblCosto = CAST(@varStatus AS DECIMAL(24,12));
		                                                --End If
		                                            END; 
		                                            --dblFifo_lotId = recuperacampo(varResultado, 3)   
		                                            EXEC recuperacampo @strResultado = @varResultado, @intNroCampo = 3, @strCampoActual = @varStatus OUTPUT; 
		                                            SET @dblFifo_lotId = @varStatus;
		                                            
		                                            --'strFifo_IntId = recuperacampo(varResultado, 4)
		                                            SET @strFifo_UniId = @uniId_RS
		                                            --dblFifo_EfiSaldo = CDbl(recuperacampo(varResultado, 4))
		                                            EXEC recuperacampo @strResultado = @varResultado, @intNroCampo = 4, @strCampoActual = @varStatus OUTPUT; 
		                                            SET @dblFifo_EfiSaldo = CAST(@varStatus AS DECIMAL(24,12));
		                                            
		                                            IF @dblFifo_EfiSaldo >= @dblFifo_CantProcesar BEGIN
		                                                SET @dblFifo_Cantidad = @dblFifo_CantProcesar
		                                                SET @dblFifo_EfiSaldo = @dblFifo_EfiSaldo - @dblFifo_CantProcesar
		                                            END ELSE  BEGIN
		                                                SET @dblFifo_Cantidad = @dblFifo_EfiSaldo
		                                                SET @dblFifo_EfiSaldo = 0
		                                            END
		                                            
		                                            SET @dblFifo_CantProcesar = @dblFifo_CantProcesar - @dblFifo_Cantidad
		                                            
		                                            --'Convierte Costo si unidades son distintas
		                                            IF @strFifo_UniId <> @uniArticulo_RS BEGIN
		                                                --varResultado = ConvierteEquivalencia(@strFifo_UniId, @uniArticulo_RS, 1)
		                                                EXEC ConvierteEquivalencia 
		                                                     @strUnidadDe = @strFifo_UniId, @strUnidadA = @uniArticulo_RS, @dblvalor = 1, @dblCantidadCONVERTida = @varResultado OUTPUT;
		                                                IF @varResultado < 0 BEGIN
		                                                    --vmaGeneraAsientoVentas = varResultado: gvarMensajeError = "Artículo: " & @artId_RS & "; Equivalencia: " & strFifo_UniId & " ---> " & miRsDet!uniArticulo
		                                                    --Exit FUNCTION                                                                                                                             
		                                                    SET @strMensajeError = @strNombreParamSP + ' ERROR: Artículo: ' + @artId_RS + '; Equivalencia: ' + @strFifo_UniId + ' ---> ' + @uniArticulo_RS;
		                                                    RAISERROR (@strMensajeError, 16, 1);
		                                                END
		                                                
		                                                SET @dblCantidadConvertida = @varResultado
		                                                SET @dblCosto = @dblCosto * @dblCantidadConvertida
		                                            END
		                                        END
		                                    END
		                                END
		                            END --'ic-2018-01-31		                            
		                            
		                            SET @dblTotal = @dblTotal + @dblCosto * @pvdCantidadEntregada_RS;
		                            FETCH NEXT FROM miRsDet2 INTO @artId_RS,@uniId_RS,@pvdCantidadEntregada_RS,@artTipo_RS,@artCalculoCosto_RS,@artUsoLote_RS,@lotId_RS,@uniArticulo_RS;
		                        END;
		                        CLOSE miRsDet2;
		                        DEALLOCATE miRsDet2;
		                        IF @dblTotal > 0 BEGIN
		                            DECLARE cur_vntTxnCuenta CURSOR LOCAL FOR
		                            	SELECT ctaId, octId, proId, tcuImporte FROM vntTxnCuenta WHERE vntId LIKE @strvntId AND octid IS NOT NULL AND conid = 'VENNET'
		                            
		                            OPEN cur_vntTxnCuenta;
		                            FETCH NEXT FROM cur_vntTxnCuenta INTO @ctaId_cur,@octId_cur,@proId_cur,@tcuImporte_cur ;
		                            IF @@FETCH_STATUS = 0 BEGIN
		                                DECLARE @dblTotalIngresos DECIMAL(24,12) = 0;
		                                DECLARE @dblTotalAux DECIMAL(24,12) = 0;
		                                SELECT @dblTotalIngresos = SUM(tcuImporte) FROM vntTxnCuenta WHERE vntId LIKE @strvntId AND octid IS NOT NULL AND conid = 'VENNET'
		                                
		                                WHILE @@FETCH_STATUS = 0 BEGIN
		                                    SET @dblTotalAux = @dblTotal * @tcuImporte_cur / @dblTotalIngresos
		                                    
		                                    IF @booAnulaTxn != 1 BEGIN
		                                        IF @strTipoTxnVn <> 'DVE' BEGIN
		                                            EXEC CreaPosteo 'cntPosteoCn', @strTipoTxnVn, @strvntId, @strCtaid, @octId_cur, @fchFechaDoc, @dblTc, @dblTotalAux, 0, @strMonId, 'vn', @strDescripcion, @strConFacturaPos, @strExportadoAlFiscal, @strproIdCn, @strBanIdCn, @strNroDocumentoCn, @strNotaCn, NULL, 
		                                                 NULL, @strTxnAnulada, NULL, @proId_cur, NULL, NULL, NULL, @gstrGeneraTxnContableMonedaCentral, @strMonIdC, @strMonIdP;	
		                                            SET @dblDebe = @dblDebe + @dblTotalAux;
		                                        END ELSE  BEGIN
		                                            EXEC CreaPosteo 'cntPosteoCn', @strTipoTxnVn, @strvntId, @strCtaid, @octId_cur, @fchFechaDoc, @dblTc, 0, @dblTotalAux, @strMonId, 'vn', @strDescripcion, @strConFacturaPos, @strExportadoAlFiscal, @strproIdCn, @strBanIdCn, @strNroDocumentoCn, @strNotaCn, NULL, 
		                                                 NULL, @strTxnAnulada, NULL, @proId_cur, NULL, NULL, NULL, @gstrGeneraTxnContableMonedaCentral, @strMonIdC, @strMonIdP;	
		                                            SET @dblHaber = @dblHaber + @dblTotalAux;
		                                        END;
		                                    END ELSE  BEGIN
		                                        IF @strTipoTxnVn <> 'DVE' BEGIN
		                                            EXEC CreaPosteo 'cntPosteoCn', @strTipoTxnVn, @strvntId, @strCtaid, @octId_cur, @fchFechaDoc, @dblTc, 0, @dblTotalAux, @strMonId, 'vn', @strDescripcion, @strConFacturaPos, @strExportadoAlFiscal, @strproIdCn, @strBanIdCn, @strNroDocumentoCn, @strNotaCn, NULL, 
		                                                 NULL, @strTxnAnulada, NULL, @proId_cur, NULL, NULL, NULL, @gstrGeneraTxnContableMonedaCentral, @strMonIdC, @strMonIdP;
		                                            SET @dblHaber = @dblHaber + @dblTotalAux;
		                                        END ELSE  BEGIN
		                                            EXEC CreaPosteo 'cntPosteoCn', @strTipoTxnVn, @strvntId, @strCtaid, @octId_cur, @fchFechaDoc, @dblTc, @dblTotalAux, 0, @strMonId, 'vn', @strDescripcion, @strConFacturaPos, @strExportadoAlFiscal, @strproIdCn, @strBanIdCn, @strNroDocumentoCn, @strNotaCn, NULL, 
		                                                 NULL, @strTxnAnulada, NULL, @proId_cur, NULL, NULL, NULL, @gstrGeneraTxnContableMonedaCentral, @strMonIdC, @strMonIdP;
		                                       SET @dblDebe = @dblDebe + @dblTotalAux;
		                                        END;
		                                    END;
		                                    FETCH NEXT FROM cur_vntTxnCuenta INTO @ctaId_cur,@octId_cur,@proId_cur,@tcuImporte_cur ;
		                                END		                                
		                                CLOSE cur_vntTxnCuenta; 
		                                DEALLOCATE cur_vntTxnCuenta;
		                            END ELSE  BEGIN
		                                IF @booAnulaTxn != 1 BEGIN
		                                    IF @strTipoTxnVn <> 'DVE' BEGIN
		                                        EXEC CreaPosteo 'cntPosteoCn', @strTipoTxnVn, @strvntId, @strCtaid, @strOctId, @fchFechaDoc, @dblTc, @dblTotal, 0, @strMonId, 'vn', @strDescripcion, @strConFacturaPos, @strExportadoAlFiscal, @strproIdCn, @strBanIdCn, @strNroDocumentoCn, @strNotaCn, NULL, NULL, @strTxnAnulada, 
		                                             NULL, NULL, NULL, NULL, NULL, @gstrGeneraTxnContableMonedaCentral, @strMonIdC, @strMonIdP;	
		                                        SET @dblDebe = @dblDebe + @dblTotal;
		                                    END ELSE  BEGIN
		                                        EXEC CreaPosteo 'cntPosteoCn', @strTipoTxnVn, @strvntId, @strCtaid, @strOctId, @fchFechaDoc, @dblTc, 0, @dblTotal, @strMonId, 'vn', @strDescripcion, @strConFacturaPos, @strExportadoAlFiscal, @strproIdCn, @strBanIdCn, @strNroDocumentoCn, @strNotaCn, NULL, NULL, @strTxnAnulada, 
		                                             NULL, NULL, NULL, NULL, NULL, @gstrGeneraTxnContableMonedaCentral, @strMonIdC, @strMonIdP;	
		                                        SET @dblHaber = @dblHaber + @dblTotal;
		                                    END;
		                                END ELSE  BEGIN
		                                    IF @strTipoTxnVn <> 'DVE' BEGIN
		                                        EXEC CreaPosteo 'cntPosteoCn', @strTipoTxnVn, @strvntId, @strCtaid, @strOctId, @fchFechaDoc, @dblTc, 0, @dblTotal, @strMonId, 'vn', @strDescripcion, @strConFacturaPos, @strExportadoAlFiscal, @strproIdCn, @strBanIdCn, @strNroDocumentoCn, @strNotaCn, NULL, NULL, @strTxnAnulada, 
		                                             NULL, NULL, NULL, NULL, NULL, @gstrGeneraTxnContableMonedaCentral, @strMonIdC, @strMonIdP;
		                                        SET @dblHaber = @dblHaber + @dblTotal;
		                                    END ELSE  BEGIN
		                                        EXEC CreaPosteo 'cntPosteoCn', @strTipoTxnVn, @strvntId, @strCtaid, @strOctId, @fchFechaDoc, @dblTc, @dblTotal, 0, @strMonId, 'vn', @strDescripcion, @strConFacturaPos, @strExportadoAlFiscal, @strproIdCn, @strBanIdCn, @strNroDocumentoCn, @strNotaCn, NULL, NULL, @strTxnAnulada, 
		                                             NULL, NULL, NULL, NULL, NULL, @gstrGeneraTxnContableMonedaCentral, @strMonIdC, @strMonIdP;
		                                        SET @dblDebe = @dblDebe + @dblTotal;
		                                    END;
		                                END;
		                            END
		                        END;
		                    END;
		                    FETCH NEXT FROM miRs3 INTO @almId_RS;
		                END; 
		                CLOSE miRs3; 
		                DEALLOCATE miRs3;
		            END;
		        END;
				
				END
		        --'-------------------------ALM--------------------------
		        --strConcepto = "ALM"
		        SET @strConcepto = 'ALM';
		        --varResultado = recuperaRegistroSQL("conGenerico", "cntConcepto", "conId = '" & strConcepto & "'", , "ctaId", "octId")
		        SELECT @flgGenerico = conGenerico, @strCtaid = ctaId, @strOctId = octId FROM cntConcepto WHERE conId = @strConcepto
		        
		        --If IsNull(varResultado) Then
		        IF @@ROWCOUNT = 0 BEGIN
		     --vmaGeneraAsientoVentas = ErrMensajeMudo
		            --gvarMensajeError = "No Existe el datos para el concepto ALM"
		            SET @strMensajeError = 'No Existe el datos para el concepto ALM';
		            RAISERROR (@strMensajeError, 16, 1);
		            ----THROW 51000, @strMensajeError, 1;
		            --Exit Function
		            --End If
		        END;
		        --flgGenerico = recuperacampo(varResultado, 1)
		        --strCtaid = recuperacampo(varResultado, 2)
		        --strOctId = recuperacampo(varResultado, 3)
		        --If (IsNull(strCtaid) Or Len(Trim(strCtaid)) = 0) And flgGenerico Then
		        IF ((@strCtaid IS NULL) OR LEN(RTRIM(LTRIM(@strCtaid))) = 0) AND @flgGenerico = 1 BEGIN
		            --vmaGeneraAsientoVentas = ErrMensajeMudo
		            --gvarMensajeError = "No Existe el datos para el concepto ALM"
		            SET @strMensajeError = 'No Existe el datos para el concepto ALM';
		            RAISERROR (@strMensajeError, 16, 1);
		            ----THROW 51000, @strMensajeError, 1;
		            --Exit Function
		            --End If
		        END;
		        --If Not flgGenerico Then
		        IF @flgGenerico != 1 BEGIN
		            --strSQL = "select distinct pvdDescripcion as AlmId  from vntDetTxn  where vntId like '@vntId' and  isnull(pvdConSolicitud,'N')  like 'N' and pvdCantidadEntregada >0 "
		            --strSQL = strSQL & " order by pvdDescripcion"
		            --strSQL = Replace(strSQL, "@vntId", strvntId)
		            DECLARE miRs4 CURSOR LOCAL FOR
		            	SELECT DISTINCT pvdDescripcion FROM vntDetTxn WHERE vntId LIKE @strvntId AND ISNULL(pvdConSolicitud, 'N') LIKE 'N' AND pvdCantidadEntregada > 0 ORDER BY pvdDescripcion
		            --Set miRs = miBD.OpenRecordset(strSQL, dbOpenSnapshot)
		            OPEN miRs4;
		            FETCH NEXT FROM miRs4 INTO @almId_RS;
		            --If Not miRs.EOF Then
		            IF @@FETCH_STATUS = 0 BEGIN
		                --dblTotal = 0
		                SET @dblTotal = 0;
		                --While Not miRs.EOF
		                WHILE @@FETCH_STATUS = 0 BEGIN
		                    --dblTotal = 0
		                    SET @dblTotal = 0; 
		                    --strAlmId = miRs!almId
		                    SET @strAlmId = @almId_RS;
		                    --'PAT 24-03-14
		                    --If Not Nz(strAlmId, "") = "" Then
		                    IF ISNULL(@strAlmId, '') <> '' BEGIN
		                        --'Fin
		                        --'--------buscar la cuenta--------------------
		                        --varResultado = recuperaRegistroSQL("ctaId", "cntConceptoCuenta", "conId like '" & strConcepto & "' and ccuReferencia like '" & strAlmId & "'")
		                        SET @strCtaid = (SELECT ctaId FROM cntConceptoCuenta WHERE conId LIKE @strConcepto AND ccuReferencia LIKE @strAlmId);	
		                        IF LEN(ISNULL(@strCtaid, '')) = 0 BEGIN
		                            --vmaGeneraAsientoVentas = ErrMensajeMudo
		                            --gvarMensajeError = "No existe la cuenta contable asociada al concepto " & strConcepto & " con referencia  " & strAlmId
		                            SET @strMensajeError = 'No existe la cuenta contable asociada al concepto ' + @strConcepto + ' con referencia  ' + @strAlmId; 
		                            RAISERROR (@strMensajeError, 16, 1);
		                            ----THROW 51000, @strMensajeError, 1;
		                        END;
		                        --'--------------------------------------------
		                        
		                        DECLARE miRsDet3 CURSOR LOCAL FOR
		                        	--SELECT artId,uniId,pvdCantidadEntregada FROM vntDetTxn WHERE vntId LIKE @strvntId AND ISNULL(pvdConSolicitud,'N')LIKE 'N'
		                        	--AND pvdDescripcion LIKE @strAlmId AND pvdCantidadEntregada > 0 	
		                        	SELECT d.artId, d.uniId, d.pvdCantidadEntregada, artTipo, artCalculoCosto, artUsoLote, lotId, a.uniId AS uniArticulo FROM vntDetTxn d, intArticulo a WHERE d.artId = a.artId AND vntId LIKE @strvntId AND ISNULL(pvdConSolicitud, 'N')LIKE 'N' AND pvdDescripcion LIKE @strAlmId AND 
		                        	       pvdCantidadEntregada > 0 ORDER BY pvdDescripcion
		                        --Set miRsDet = miBD.OpenRecordset(strSQL, dbOpenSnapshot)
		                        OPEN miRsDet3;
		                        FETCH NEXT FROM miRsDet3 INTO @artId_RS,@uniId_RS,@pvdCantidadEntregada_RS,@artTipo_RS,@artCalculoCosto_RS,@artUsoLote_RS,@lotId_RS,@uniArticulo_RS; 
		                        --While Not miRsDet.EOF
		                        WHILE @@FETCH_STATUS = 0 BEGIN
		                            --strResultado = CalcularCosto(strAlmId, miRsDet!artId, miRsDet!uniId, strMonId, dblTc, miRsDet!pvdCantidadEntregada, strTxnIn)
		                            --ic 2018/01/31----EXEC CalcularCosto @strAlmId, @artId_RS, @uniId_RS, @strMonId, @dblTc, @pvdCantidadEntregada_RS, @strTxnIn,@dblCosto OUTPUT;
		                            --If CInt(recuperacampo(strResultado, 1)) <> 0 Then
		                            --gvarMensajeError = recuperacampo(strResultado, 3)
		                            --vmaGeneraAsientoVentas = ErrMensajeMudo
		                            --Exit Function
		                            --End If
		                            --dblCosto = CDbl(recuperacampo(strResultado, 2))
		                            
		                            
		                            
		                            IF @pvdCantidadEntregada_RS > 0 BEGIN
		                                --'Valida existencia de la unidad
		                                IF @uniId_RS IS NULL OR LEN(@uniId_RS) = 0 BEGIN
		                                    SET @strMensajeError = @strNombreParamSP + 'No Existe Unidad';
		                                    RAISERROR (@strMensajeError, 16, 1);
		                                END
		                                --'Valida existencia de artículo
		                                IF @artId_RS IS NULL OR LEN(@artId_RS) = 0 BEGIN
		                                    SET @strMensajeError = @strNombreParamSP + 'No Existe Articulo';
		                                    RAISERROR (@strMensajeError, 16, 1);
		                                END
		                                IF @artCalculoCosto_RS = 'P' BEGIN
		                                    EXEC CalcularCosto @strAlmId, @artId_RS, @uniId_RS, @strMonId, @dblTc, @pvdCantidadEntregada_RS, @strTxnIn, @dblCosto OUTPUT,@datAFecha = @fchFechaDoc;
		                                END ELSE    
		                                IF @artCalculoCosto_RS <> 'F' BEGIN
		                                    --'emmfifo todo el esle add
		                                    --varResultado = inpCalculaCostoArticulo(@strAlmId, @artId_RS, @artTipo_RS, @dblTc, @artCalculoCosto_RS, , fchFechaDoc, varCalculoCostoPP)
		                                    EXEC inpCalculaCostoArticulo 
		                                         @varAlmId = @strAlmId, @strArtId = @artId_RS, @strArtTipo = @artTipo_RS, @dblTC = @dblTc, @varCostoTipo = @artCalculoCosto_RS, @varAFecha = @fchFechaDoc, @varCalculoCostoPP = @varCalculoCostoPP, @inpCalculaCostoArticulo = @varResultado OUTPUT; 
		                                    
		                                    IF (@strMonId = @strMonIdC) BEGIN
		                                        --dblCostoTemporal = Val(recuperacampo(varResultado, 1))
		                                        EXEC recuperacampo 
		                                             @strResultado = @varResultado, @intNroCampo = 1, @strCampoActual = @varStatus OUTPUT;
		                                        SET @dblCosto = CAST(@varStatus AS DECIMAL(24,12));
		                                        --End If
		                                    END;                                
		                             IF (@strMonId = @strMonIdP) BEGIN
		                                        --dblCostoTemporal = Val(recuperacampo(varResultado, 2))
		                                        EXEC recuperacampo 
		                                             @strResultado = @varResultado, @intNroCampo = 2, @strCampoActual = @varStatus OUTPUT;
		                                        SET @dblCosto = CAST(@varStatus AS DECIMAL(24,12));
		                                        --End If
		                                    END;
		                                    
		                                    --'Convierte Costo si unidades son distintas
		                                    IF @uniId_RS <> @uniArticulo_RS BEGIN
		                                        EXEC ConvierteEquivalencia 
		                                             @strUnidadDe = @uniId_RS, @strUnidadA = @uniArticulo_RS, @dblvalor = 1, @dblCantidadCONVERTida = @dblResultado OUTPUT;
		                                        --If varResultado < 0 Then
		                                        IF (@dblResultado < 0) BEGIN
		                                            --vnpGeneraAsientoVentasTxn = varResultado: gvarMensajeError = "Artículo: " & rsFpago!artId & "; Equivalencia: " & rsFpago![uniId] & " ---> " & rsFpago!uniArticulo
		                                            --Exit Function
		                                            SET @strMensajeError = @strNombreParamSP + ' ERROR: Artículo: ' + @artId_RS + '; Equivalencia: ' + @uniId_RS + ' ---> ' + @uniArticulo_RS;
		                                            RAISERROR (@strMensajeError, 16, 1);
		                                            ----THROW 51000, @strMensajeError, 1;
		                                            --End If
		                                        END;
		                                        --dblCantidadCONVERTida = varResultado
		                                        SET @dblCantidadCONVERTida = @dblResultado;
		                                        --dblCostoTemporal = dblCostoTemporal * dblCantidadCONVERTida
		                                        SET @dblCosto = @dblCosto * @dblCantidadCONVERTida;
		                                    END ELSE   
		                                    IF @artUsoLote_RS <> 'O' BEGIN
		                                        --'emm todo el else add para lote
		                                        SET @dblFifo_CantProcesar = @pvdCantidadEntregada_RS
		                                        SET @intContX = 0;
		                                        WHILE @dblFifo_CantProcesar <= 0 OR @intContX = 0 BEGIN
		                                            SET @intContX = @intContX + 1
		                                            --'dblCostoC & ";" & dblCostoP & ";" & intEfiId & ";" & strIntId & ";" & strUniId & ";" & dblEfiSaldo
		                                            --varResultado = inpCalculaCostoArticulo(stralmId, miRsDet!artId, miRsDet!artTipo, dblTC, miRsDet!artCalculoCosto, , fchFechaDoc, varCalculoCostoPP)
		                                            EXEC inpCalculaCostoArticulo 
		                                                 @varAlmId = @strAlmId, @strArtId = @artId_RS, @strArtTipo = @artTipo_RS, @dblTC = @dblTc, @varCostoTipo = @artCalculoCosto_RS, @varAFecha = @fchFechaDoc, @varCalculoCostoPP = @varCalculoCostoPP, @inpCalculaCostoArticulo = @varResultado OUTPUT;  
		                                            EXEC recuperacampo @strResultado = @varResultado, @intNroCampo = 7, @strCampoActual = @varStatus OUTPUT
		                                            
		                                            IF @varStatus <> 'N' BEGIN
		                                                SET @strMensajeError = @strNombreParamSP + 'No Existe Detalle';
		                                                RAISERROR (@strMensajeError, 16, 1);
		         END
		                                            
		                                            IF (@strMonId = @strMonIdC) BEGIN
		                                                --dblCostoTemporal = Val(recuperacampo(varResultado, 1))
		                                                EXEC recuperacampo 
		                                                     @strResultado = @varResultado, @intNroCampo = 1, @strCampoActual = @varStatus OUTPUT;
		                                                SET @dblCosto = CAST(@varStatus AS DECIMAL(24,12));
		                                                --End If
		                                            END;                                
		                                            IF (@strMonId = @strMonIdP) BEGIN
		                                                --dblCostoTemporal = Val(recuperacampo(varResultado, 2))
		                                                EXEC recuperacampo 
		                                                     @strResultado = @varResultado, @intNroCampo = 2, @strCampoActual = @varStatus OUTPUT;
		                                                SET @dblCosto = CAST(@varStatus AS DECIMAL(24,12));
		                                                --End If
		                                            END;       
		                                            EXEC recuperacampo @strResultado = @varResultado, @intNroCampo = 3, @strCampoActual = @varStatus OUTPUT; 
		                                            SET @intFifo_EfiId = CAST(@varStatus AS INT);
		                                            EXEC recuperacampo @strResultado = @varResultado, @intNroCampo = 4, @strCampoActual = @varStatus OUTPUT;
		                                            SET @strFifo_IntId = @varStatus
		                                            
		                                            EXEC recuperacampo @strResultado = @varResultado, @intNroCampo = 5, @strCampoActual = @varStatus OUTPUT;
		                                            SET @strFifo_UniId = @varStatus
		                                            
		                                            EXEC recuperacampo @strResultado = @varResultado, @intNroCampo = 6, @strCampoActual = @varStatus OUTPUT;
		                                            SET @dblFifo_EfiSaldo = CAST(@varStatus AS DECIMAL(24,12));
		                                            
		                                            IF @dblFifo_EfiSaldo >= @dblFifo_CantProcesar BEGIN
		                                                SET @dblFifo_Cantidad = @dblFifo_CantProcesar
		                                                SET @dblFifo_EfiSaldo = @dblFifo_EfiSaldo - @dblFifo_CantProcesar
		                                            END ELSE  BEGIN
		                                                SET @dblFifo_Cantidad = @dblFifo_EfiSaldo
		                                                SET @dblFifo_EfiSaldo = 0
		                                            END
		                                            
		                                            SET @dblFifo_CantProcesar = @dblFifo_CantProcesar - @dblFifo_Cantidad
		                                            
		                                            --'Convierte Costo si unidades son distintas
		                                            IF @strFifo_UniId <> @uniArticulo_RS BEGIN
		                                                --varResultado = ConvierteEquivalencia(@strFifo_UniId, @uniArticulo_RS, 1)
		                                                EXEC ConvierteEquivalencia 
		                                                     @strUnidadDe = @strFifo_UniId, @strUnidadA = @uniArticulo_RS, @dblvalor = 1, @dblCantidadCONVERTida = @varResultado OUTPUT;
		                                                IF @varResultado < 0 BEGIN
		                                                    --vmaGeneraAsientoVentas = varResultado: gvarMensajeError = "Artículo: " & miRsDet!artId & "; Equivalencia: " & strFifo_UniId & " ---> " & miRsDet!uniArticulo
		                                                    --Exit FUNCTION                                                                                                
		                                                    SET @strMensajeError = @strNombreParamSP + ' ERROR: Artículo: ' + @artId_RS + '; Equivalencia: ' + @strFifo_UniId + ' ---> ' + @uniArticulo_RS;
		                                                    RAISERROR (@strMensajeError, 16, 1);
		                                                END
		                                                
		                                                SET @dblCantidadConvertida = @varResultado
		                                                SET @dblCosto = @dblCosto * @dblCantidadConvertida
		                                            END
		                                        END
		                                    END ELSE --'*************************LOTES*****************************
		                                        BEGIN
		                                        SET @dblFifo_CantProcesar = @pvdCantidadEntregada_RS
		                                        SET @intContX = 0
		                                        
		                                        WHILE @dblFifo_CantProcesar <= 0 OR @intContX = 0 BEGIN
		                                            SET @intContX = @intContX + 1
		                                            --'dblCostoC & ";" & dblCostoP & ";" & lotId & ";" & eloCantidad
		                                            --varResultado = inpGetCostoArticuloLote(CStr(stralmId), @artId_RS)
		                                            EXEC inpGetCostoArticuloLote 
		                                                 @stralmId, @artId_RS, NULL, @varResultado OUTPUT;
		                                            
		                                            IF @varResultado = '' OR @varResultado IS NULL BEGIN
		                                                --vmaGeneraAsientoVentas = ErrMensajeMudo
		                                                --gvarMensajeError = "El articulo " & miRsDet!artId & " no tiene la cantidad requerida en existencia..."                                                                                                                                   
		                                                SET @strMensajeError = @strNombreParamSP + ' El articulo ' + @artId_RS + ' no tiene la cantidad requerida en existencia...';
		                                                RAISERROR (@strMensajeError, 16, 1);
		                                                --Exit FUNCTION
		                                            END                                      
		                                            IF (@strMonId = @strMonIdC) BEGIN
		                                                --dblCostoTemporal = Val(recuperacampo(varResultado, 1))
		                                                EXEC recuperacampo 
		                                                     @strResultado = @varResultado, @intNroCampo = 1, @strCampoActual = @varStatus OUTPUT;
		                                                SET @dblCosto = CAST(@varStatus AS DECIMAL(24,12));
		                                                --End If
		                                            END;                                
		                                            IF (@strMonId = @strMonIdP) BEGIN
		                                                --dblCostoTemporal = Val(recuperacampo(varResultado, 2))
		                                                EXEC recuperacampo 
		                                                     @strResultado = @varResultado, @intNroCampo = 2, @strCampoActual = @varStatus OUTPUT;
		                                                SET @dblCosto = CAST(@varStatus AS DECIMAL(24,12));
		                                                --End If
		                                            END; 
		                                            --dblFifo_lotId = recuperacampo(varResultado, 3)   
		                                            EXEC recuperacampo @strResultado = @varResultado, @intNroCampo = 3, @strCampoActual = @varStatus OUTPUT; 
		                                            SET @dblFifo_lotId = @varStatus;
		                                            
		                                            --'strFifo_IntId = recuperacampo(varResultado, 4)
		                                            SET @strFifo_UniId = @uniId_RS
		                                            --dblFifo_EfiSaldo = CDbl(recuperacampo(varResultado, 4))
		                                            EXEC recuperacampo @strResultado = @varResultado, @intNroCampo = 4, @strCampoActual = @varStatus OUTPUT; 
		                                            SET @dblFifo_EfiSaldo = CAST(@varStatus AS DECIMAL(24,12));
		                                            
		                                            IF @dblFifo_EfiSaldo >= @dblFifo_CantProcesar BEGIN
		                                                SET @dblFifo_Cantidad = @dblFifo_CantProcesar
		                                                SET @dblFifo_EfiSaldo = @dblFifo_EfiSaldo - @dblFifo_CantProcesar
		                                            END ELSE  BEGIN
		                                                SET @dblFifo_Cantidad = @dblFifo_EfiSaldo
		                                                SET @dblFifo_EfiSaldo = 0
		                                            END
		                                            
		                                            SET @dblFifo_CantProcesar = @dblFifo_CantProcesar - @dblFifo_Cantidad
		                                            
		                                            --'Convierte Costo si unidades son distintas
		                                            IF @strFifo_UniId <> @uniArticulo_RS BEGIN
		                                                --varResultado = ConvierteEquivalencia(@strFifo_UniId, @uniArticulo_RS, 1)
		                                                EXEC ConvierteEquivalencia 
		                                                     @strUnidadDe = @strFifo_UniId, @strUnidadA = @uniArticulo_RS, @dblvalor = 1, @dblCantidadCONVERTida = @varResultado OUTPUT;
		                                                IF @varResultado < 0 BEGIN
		                                                    --vmaGeneraAsientoVentas = varResultado: gvarMensajeError = "Artículo: " & @artId_RS & "; Equivalencia: " & strFifo_UniId & " ---> " & miRsDet!uniArticulo
		                                                    --Exit FUNCTION                                                                                                                             
		                                                    SET @strMensajeError = @strNombreParamSP + ' ERROR: Artículo: ' + @artId_RS + '; Equivalencia: ' + @strFifo_UniId + ' ---> ' + @uniArticulo_RS;
		                                                    RAISERROR (@strMensajeError, 16, 1);
		                                                END
		                                                
		                                                SET @dblCantidadConvertida = @varResultado
		                                                SET @dblCosto = @dblCosto * @dblCantidadConvertida
		                                            END
		                                        END
		                                    END
		                                END
		                            END --'ic-2018-01-31
		                                --dblTotal = dblTotal + dblCosto * miRsDet!pvdCantidadEntregada
		                            SET @dblTotal = @dblTotal + @dblCosto * @pvdCantidadEntregada_RS;
		             --miRsDet.MoveNext
		                            FETCH NEXT FROM miRsDet3 INTO @artId_RS,@uniId_RS,@pvdCantidadEntregada_RS,@artTipo_RS,@artCalculoCosto_RS,@artUsoLote_RS,@lotId_RS,@uniArticulo_RS; 
		                            --Wend
		                        END;
		                        --miRsDet.Close
		                        CLOSE miRsDet3;
		                        --Set miRsDet = Nothing
		                        DEALLOCATE miRsDet3; 
		                        --If dblTotal > 0 Then
		                        IF @dblTotal > 0 BEGIN
		                            --If Not booAnulaTxn Then
		                            IF @booAnulaTxn != 1 BEGIN
		                                --If strTipoTxnVn <> "DVE" Then
		                                IF @strTipoTxnVn <> 'DVE' BEGIN
		                                    --intStatus = CreaPosteo("cntPosteoCn", strTipoTxnVn, strvntId, strCtaid, strOctId, fchFechaDoc, dblTc, 0, dblTotal, strMonId, "vn", strDescripcion, strConFacturaPos, strExportadoAlFiscal, strCliId, strPveId, , , , , strTxnAnulada)
		                                    EXEC CreaPosteo 'cntPosteoCn', @strTipoTxnVn, @strvntId, @strCtaid, @strOctId, @fchFechaDoc, @dblTc, 0, @dblTotal, @strMonId, 'vn', @strDescripcion, @strConFacturaPos, @strExportadoAlFiscal, @strproIdCn, @strBanIdCn, @strNroDocumentoCn, @strNotaCn, NULL, NULL, @strTxnAnulada, 
		                                         NULL, NULL, NULL, NULL, NULL, @gstrGeneraTxnContableMonedaCentral, @strMonIdC, @strMonIdP;
		                                    --dblHaber = dblHaber + dblTotal
		                                    SET @dblHaber = @dblHaber + @dblTotal;
		                                END--Else
		                                    ELSE  BEGIN
		                                    --intStatus = CreaPosteo("cntPosteoCn", strTipoTxnVn, strvntId, strCtaid, strOctId, fchFechaDoc, dblTc, dblTotal, 0, strMonId, "vn", strDescripcion, strConFacturaPos, strExportadoAlFiscal, strCliId, strPveId, , , , , strTxnAnulada)
		                                    EXEC CreaPosteo 'cntPosteoCn', @strTipoTxnVn, @strvntId, @strCtaid, @strOctId, @fchFechaDoc, @dblTc, @dblTotal, 0, @strMonId, 'vn', @strDescripcion, @strConFacturaPos, @strExportadoAlFiscal, @strproIdCn, @strBanIdCn, @strNroDocumentoCn, @strNotaCn, NULL, NULL, @strTxnAnulada, 
		                                         NULL, NULL, NULL, NULL, NULL, @gstrGeneraTxnContableMonedaCentral, @strMonIdC, @strMonIdP;
		                                    --dblDebe = dblDebe + dblTotal
		                                    SET @dblDebe = @dblDebe + @dblTotal;
		                                    --End If
		                                END;
		                            END--Else
		                                ELSE  BEGIN
		                                --If strTipoTxnVn <> "DVE" Then
		                                IF @strTipoTxnVn <> 'DVE' BEGIN
		                                    --intStatus = CreaPosteo("cntPosteoCn", strTipoTxnVn, strvntId, strCtaid, strOctId, fchFechaDoc, dblTc, dblTotal, 0, strMonId, "vn", strDescripcion, strConFacturaPos, strExportadoAlFiscal, strCliId, strPveId, , , , , strTxnAnulada)
		                                    EXEC CreaPosteo 'cntPosteoCn', @strTipoTxnVn, @strvntId, @strCtaid, @strOctId, @fchFechaDoc, @dblTc, @dblTotal, 0, @strMonId, 'vn', @strDescripcion, @strConFacturaPos, @strExportadoAlFiscal, @strproIdCn, @strBanIdCn, @strNroDocumentoCn, @strNotaCn, NULL, NULL, @strTxnAnulada, 
		                                         NULL, NULL, NULL, NULL, NULL, @gstrGeneraTxnContableMonedaCentral, @strMonIdC, @strMonIdP; 
		                                    --dblDebe = dblDebe + dblTotal
		                                    SET @dblDebe = @dblDebe + @dblTotal;
		                                END--Else
		                                    ELSE  BEGIN
		                                    --intStatus = CreaPosteo("cntPosteoCn", strTipoTxnVn, strvntId, strCtaid, strOctId, fchFechaDoc, dblTc, 0, dblTotal, strMonId, "vn", strDescripcion, strConFacturaPos, strExportadoAlFiscal, strCliId, strPveId, , , , , strTxnAnulada)
		                                    EXEC CreaPosteo 'cntPosteoCn', @strTipoTxnVn, @strvntId, @strCtaid, @strOctId, @fchFechaDoc, @dblTc, 0, @dblTotal, @strMonId, 'vn', @strDescripcion, @strConFacturaPos, @strExportadoAlFiscal, @strproIdCn, @strBanIdCn, @strNroDocumentoCn, @strNotaCn, NULL, NULL, @strTxnAnulada, 
		                                         NULL, NULL, NULL, NULL, NULL, @gstrGeneraTxnContableMonedaCentral, @strMonIdC, @strMonIdP;
		                                    --dblHaber = dblHaber + dblTotal
		                                    SET @dblHaber = @dblHaber + @dblTotal;
		                                    --End If
		                                END;
		                                --End If
		                            END; 
		                            --If intStatus Then
		                            --vmaGeneraAsientoVentas = ErrMensajeMudo
		                            --gvarMensajeError = "Error al Crear el asiento para  el Concepto " & strConcepto & " Con referencia " & strAlmId
		                            --Exit Function
		                            --End If
		                            --End If
		                        END; 
		                        --'PAT 24-03-14
		                        --End If
		                    END; 
		                    --'Fin
		                    --miRs.MoveNext
		                    FETCH NEXT FROM miRs4 INTO @almId_RS; 
		                    --Wend
		                END;
		                --miRs.Close
		                CLOSE miRs4;
		                --Set miRs = Nothing
		                DEALLOCATE miRs4; 
		                --End If
		            END; 
		            --End If
		        END; 
		        --'-------------------------DESVEN-------------
		        
		        
		        --If dblDescuentoMoneda <> 0 And strTipoTxnVn <> "PRO" Then
		        IF @dblDescuentoMoneda <> 0 AND @strTipoTxnVn <> 'PRO' BEGIN
		            --strConcepto = "DESVEN"
		            SET @strConcepto = 'DESVEN'; 
		            --varResultado = recuperaRegistroSQL("conGenerico", "cntConcepto", "conId = '" & strConcepto & "'", , "ctaId", "octId")
		            SELECT @flgGenerico = conGenerico, @strCtaid = ctaId, @strOctId = octId FROM cntConcepto WHERE conId = @strConcepto
		            --If IsNull(varResultado) Then
		            IF @@ROWCOUNT = 0 BEGIN
		                --vmaGeneraAsientoVentas = ErrMensajeMudo
		                --gvarMensajeError = "No existe configurada la  cuenta para el concepto " & strConcepto
		                SET @strMensajeError = 'No existe configurada la  cuenta para el concepto ' + @strConcepto;
		                RAISERROR (@strMensajeError, 16, 1);
		                ----THROW 51000, @strMensajeError, 1;
		            END;
		            
		            IF ((@strCtaid IS NULL) OR LEN(RTRIM(LTRIM(@strCtaid))) = 0) AND @flgGenerico = 1 BEGIN
		                --vmaGeneraAsientoVentas = ErrNoExisteConceptoCuenta
		                SET @strMensajeError = 'ERROR : No Existe la cuenta para el concepto ' + @strConcepto ; 
		                RAISERROR (@strMensajeError, 16, 1);
		                ----THROW 51000, @strMensajeError, 1;
		            END;
		            --'------Inicio -DJ-18-08-2014
		            --If strGeneraCAPor = "V" And booIntegracionCA Then    'If strGeneraCAPor = "V" Then  'Comentado por iarr 09-09-2014
		            IF @strGeneraCAPor = 'V' AND @booIntegracionCA = 1 BEGIN
		                --varResultado2 = recuperaRegistroSQL("venId", "vntTxn", "vntId like '" & strvntId & "'")
		                SET @venId = (SELECT venId FROM vntTxn WHERE vntId LIKE @strvntId);
		                --varResultado2 = recuperaRegistroSQL("canId", "gntDirectorio", "dirid = '" & varResultado2 & "'")
		                SET @canId = (SELECT canId FROM gntDirectorio WHERE dirid = @venId);
		                
		                IF @canId IS NULL BEGIN
		                    --gvarMensajeError = "El Vendededor No Tiene Asociado Un Centro de Análisis"
		                    SET @strMensajeError = 'El Vendededor No Tiene Asociado Un Centro de Análisis'; 
		                    RAISERROR (@strMensajeError, 16, 1);
		                    ----THROW 51000, @strMensajeError, 1;
		                END;
		            END ELSE  BEGIN
		                IF @strGeneraCAPor = 'P' AND @booIntegracionCA = 1 BEGIN
		                    SET @canId = (SELECT canId FROM gntPuntoVenta WHERE pveId = @strPveId);	
		                    IF @canId IS NULL BEGIN
		                        SET @strMensajeError = 'El Punto de Venta No Tiene Asociado Un Centro de Análisis';
		                        RAISERROR (@strMensajeError, 16, 1);
		                        ----THROW 51000, @strMensajeError, 1;
		                    END;
		                END;
		            END;
		            SET @strOctId = ISNULL(@canId, '');
		            IF @booIntegracionCA = 1 BEGIN
		                SET @strProId = ISNULL((SELECT proId FROM gntPuntoVenta WHERE pveId = @strPveId), '');
		            END ELSE  BEGIN
		                SET @strProId = '';
		            END;
		            --'--------Fi
		            IF @flgGenerico != 1 BEGIN
		                SELECT @conOtroDetalle = conOtroDetalle, @StrconReferencia = conReferencia FROM cntConcepto WHERE conId = 'DESVEN';
		                IF (@@ROWCOUNT = 0) BEGIN
		                    SET @strMensajeError = @strNombreParamSP + ' ERROR: No existe el concepto DESVEN';
		                    RAISERROR (@strMensajeError, 16, 1);
		                    ----THROW 51000, @strMensajeError, 1;
		                END
		                
		                IF @conOtroDetalle = 'S' AND @StrconReferencia = 'S' BEGIN
		                    EXEC BuscaCuenta 'DESVEN', @strTdoId, @strCtaid OUTPUT, @strOctId OUTPUT;
		                END ELSE  BEGIN
		                    EXEC BuscaCuenta 'DESVEN', @strPveId, @strCtaid OUTPUT, @strOctId OUTPUT;
		                END
		                --		                     'FIN
		            END;		            

		            IF @booConDFR = 1 BEGIN
						SET @dblTotal = @dblDescuentoMoneda;
		            END ELSE BEGIN
						IF @strVnpAsientoDescuentoCreditoFiscal = 'S' AND @flgConFactura = 1  BEGIN
							SET @dblTotal = @dblDescuentoMoneda * (1 - @dblGnpIva); --31/08/2018 MODIFICACION CALCULO DE DESCUENTO SOLICITADO POR YOVANA ORELLANA
						END ELSE BEGIN
							SET @dblTotal = @dblDescuentoMoneda;
						END 
		            END
		             
					--28/09/2018 MODIFICACION MONICA VILLARROEL
					--IF @strIntegracionContableAplicacion = 'S' AND @strNAntFac=0 BEGIN
		            IF @strIntegracionContableAplicacion = 'S' BEGIN
		                --22/10/2018 MODIFICACION SOLICITADA POR MONICA VILLARROEL
		                DECLARE miRsInt CURSOR LOCAL FOR
		                	SELECT ctaId, octId, proId, tcuImporte FROM vntTxnCuenta WHERE vntId LIKE @strVntId AND conid = 'VENNET'
		                
		                OPEN miRsInt;
		                FETCH NEXT FROM miRsInt INTO @ctaId_cur,@octId_cur,@proId_cur,@tcuImporte_cur;
		                IF @@FETCH_STATUS = 0 BEGIN
		                    WHILE @@FETCH_STATUS = 0 BEGIN
		                        SET @dblPorcentaje = @tcuImporte_cur / @dblArticuloMoneda;
		                        SET @dblTotal_cur = @dblTotal * @dblPorcentaje;
		                        SET @strOctId = ISNULL(@octId_cur, '');
		                        SET @strProId = ISNULL(@proId_cur, '');
		                        
		                        IF @booAnulaTxn != 1 BEGIN
		                            IF @strTipoTxnVn = 'VEN' OR @strTipoTxnVn = 'VAF' BEGIN
		                                EXEC CreaPosteo 'cntPosteoCn', @strTipoTxnVn, @strvntId, @strCtaid, @strOctId, @fchFechaDoc, @dblTc, @dblTotal_cur, 0, @strMonId, 'vn', @strDescripcion, @strConFacturaPos, @strExportadoAlFiscal, @strproIdCn, @strBanIdCn, @strNroDocumentoCn, @strNotaCn, NULL, NULL, @strTxnAnulada, 
		                                     NULL, @strProId, NULL, NULL, NULL, @gstrGeneraTxnContableMonedaCentral, @strMonIdC, @strMonIdP;
		                                SET @dblDebe = @dblDebe + @dblTotal_cur;
		                            END ELSE  BEGIN
		                                EXEC CreaPosteo 'cntPosteoCn', @strTipoTxnVn, @strvntId, @strCtaid, @strOctId, @fchFechaDoc, @dblTc, 0, @dblTotal_cur, @strMonId, 'vn', @strDescripcion, @strConFacturaPos, @strExportadoAlFiscal, @strproIdCn, @strBanIdCn, @strNroDocumentoCn, @strNotaCn, NULL, NULL, @strTxnAnulada, 
		                                     NULL, @strProId, NULL, NULL, NULL, @gstrGeneraTxnContableMonedaCentral, @strMonIdC, @strMonIdP;
		                                SET @dblHaber = @dblHaber + @dblTotal_cur;
		                            END;
		                        END ELSE  BEGIN
		                            IF @strTipoTxnVn = 'VEN' OR @strTipoTxnVn = 'VAF' BEGIN
		                                EXEC CreaPosteo 'cntPosteoCn', @strTipoTxnVn, @strvntId, @strCtaid, @strOctId, @fchFechaDoc, @dblTc, 0, @dblTotal_cur, @strMonId, 'vn', @strDescripcion, @strConFacturaPos, @strExportadoAlFiscal, @strproIdCn, @strBanIdCn, @strNroDocumentoCn, @strNotaCn, NULL, NULL, @strTxnAnulada, 
		                                     NULL, @strProId, NULL, NULL, NULL, @gstrGeneraTxnContableMonedaCentral, @strMonIdC, @strMonIdP;
		                                SET @dblHaber = @dblHaber + @dblTotal_cur;
		                            END ELSE  BEGIN
		                                EXEC CreaPosteo 'cntPosteoCn', @strTipoTxnVn, @strvntId, @strCtaid, @strOctId, @fchFechaDoc, @dblTc, @dblTotal_cur, 0, @strMonId, 'vn', @strDescripcion, @strConFacturaPos, @strExportadoAlFiscal, @strproIdCn, @strBanIdCn, @strNroDocumentoCn, @strNotaCn, NULL, NULL, @strTxnAnulada, 
		                                     NULL, @strProId, NULL, NULL, NULL, @gstrGeneraTxnContableMonedaCentral, @strMonIdC, @strMonIdP;
		                                SET @dblDebe = @dblDebe + @dblTotal_cur;
		                            END;
		                        END;
		                        FETCH NEXT FROM miRsInt INTO @ctaId_cur,@octId_cur,@proId_cur,@tcuImporte_cur;
		                    END;
		                END
		                
		                CLOSE miRsInt;
		                DEALLOCATE miRsInt;
		            END ELSE  BEGIN
		                IF @booAnulaTxn != 1 BEGIN
		                    IF @strTipoTxnVn = 'VEN' OR @strTipoTxnVn = 'VAF' BEGIN
		                        --intStatus = CreaPosteo("cntPosteoCn", strTipoTxnVn, strvntId, strCtaid, strOctId, fchFechaDoc, dblTc, dblTotal, 0, strMonId, "vn", strDescripcion, strConFacturaPos, strExportadoAlFiscal, strCliId, strPveId, , , , , strTxnAnulada, , strProId)
		                        EXEC CreaPosteo 'cntPosteoCn', @strTipoTxnVn, @strvntId, @strCtaid, @strOctId, @fchFechaDoc, @dblTc, @dblTotal, 0, @strMonId, 'vn', @strDescripcion, @strConFacturaPos, @strExportadoAlFiscal, @strproIdCn, @strBanIdCn, @strNroDocumentoCn, @strNotaCn, NULL, NULL, @strTxnAnulada, 
		                             NULL, @strProId, NULL, NULL, NULL, @gstrGeneraTxnContableMonedaCentral, @strMonIdC, @strMonIdP;
		                        SET @dblDebe = @dblDebe + @dblTotal;
		                    END ELSE  BEGIN
		                        --intStatus = CreaPosteo("cntPosteoCn", strTipoTxnVn, strvntId, strCtaid, strOctId, fchFechaDoc, dblTc, 0, dblTotal, strMonId, "vn", strDescripcion, strConFacturaPos, strExportadoAlFiscal, strCliId, strPveId, , , , , strTxnAnulada, , strProId)
		                        EXEC CreaPosteo 'cntPosteoCn', @strTipoTxnVn, @strvntId, @strCtaid, @strOctId, @fchFechaDoc, @dblTc, 0, @dblTotal, @strMonId, 'vn', @strDescripcion, @strConFacturaPos, @strExportadoAlFiscal, @strproIdCn, @strBanIdCn, @strNroDocumentoCn, @strNotaCn, NULL, NULL, @strTxnAnulada, 
		                             NULL, @strProId, NULL, NULL, NULL, @gstrGeneraTxnContableMonedaCentral, @strMonIdC, @strMonIdP;
		                        SET @dblHaber = @dblHaber + @dblTotal;
		                        --End If
		                    END;
		                END ELSE  BEGIN
		                    IF @strTipoTxnVn = 'VEN' OR @strTipoTxnVn = 'VAF' BEGIN
		                        EXEC CreaPosteo 'cntPosteoCn', @strTipoTxnVn, @strvntId, @strCtaid, @strOctId, @fchFechaDoc, @dblTc, 0, @dblTotal, @strMonId, 'vn', @strDescripcion, @strConFacturaPos, @strExportadoAlFiscal, @strproIdCn, @strBanIdCn, @strNroDocumentoCn, @strNotaCn, NULL, NULL, @strTxnAnulada, 
		                             NULL, @strProId, NULL, NULL, NULL, @gstrGeneraTxnContableMonedaCentral, @strMonIdC, @strMonIdP;
		                        SET @dblHaber = @dblHaber + @dblTotal;
		                    END--Else
		                        ELSE  BEGIN
		                        --intStatus = CreaPosteo("cntPosteoCn", strTipoTxnVn, strvntId, strCtaid, strOctId, fchFechaDoc, dblTc, dblTotal, 0, strMonId, "vn", strDescripcion, strConFacturaPos, strExportadoAlFiscal, strCliId, strPveId, , , , , strTxnAnulada, , strProId)
		                        EXEC CreaPosteo 'cntPosteoCn', @strTipoTxnVn, @strvntId, @strCtaid, @strOctId, @fchFechaDoc, @dblTc, @dblTotal, 0, @strMonId, 'vn', @strDescripcion, @strConFacturaPos, @strExportadoAlFiscal, @strproIdCn, @strBanIdCn, @strNroDocumentoCn, @strNotaCn, NULL, NULL, @strTxnAnulada, 
		                             NULL, @strProId, NULL, NULL, NULL, @gstrGeneraTxnContableMonedaCentral, @strMonIdC, @strMonIdP;
		                        SET @dblDebe = @dblDebe + @dblTotal;
		                    END;
		                END;
		            END;
		            --End If
		        END;
		        --' Asiento (Debe) para Descuento Por Articulo
		        IF @dblDescuentoArticulo <> 0 AND @strTipoTxnVn <> 'PRO' BEGIN
		            SET @strConcepto = 'DESVEN'; 
		            SELECT @flgGenerico = conGenerico, @strCtaid = ctaId, @strOctId = octId, @conOtroDetalle = conOtroDetalle, @strconReferencia = conReferencia FROM cntConcepto WHERE conId = 'DESVEN'
		            
		            IF @@ROWCOUNT = 0 BEGIN
		                SET @strMensajeError = 'No existe configurada la  cuenta para el concepto DESVEN'; 
		                RAISERROR (@strMensajeError, 16, 1);
		                ----THROW 51000, @strMensajeError, 1;
		            END;
		            IF ((@strCtaid IS NULL) OR LEN(RTRIM(LTRIM(@strCtaid))) = 0) AND @flgGenerico = 1 BEGIN
		                SET @strMensajeError = 'No existe configurada la  cuenta para el concepto DESVEN'; 
		                RAISERROR (@strMensajeError, 16, 1);
		                ----THROW 51000, @strMensajeError, 1;
		            END;
		            --'------Inicio -DJ-18-08-2014
		            --If strGeneraCAPor = "V" And booIntegracionCA Then        'If strGeneraCAPor = "V" Then  'Comentado por iarr 09-09-2014
		            IF @strGeneraCAPor = 'V' AND @booIntegracionCA = 1 BEGIN
		                --varResultado2 = recuperaRegistroSQL("venId", "vntTxn", "vntId like '" & strvntId & "'")
		                SET @venId = (SELECT venId FROM vntTxn WHERE vntId LIKE @strvntId);
		                --varResultado2 = recuperaRegistroSQL("canId", "gntDirectorio", "dirid = '" & varResultado2 & "'")
		                SET @canId = (SELECT canId FROM gntDirectorio WHERE dirid = @venId);
		                --If IsNull(varResultado2) Then
		                IF @canId IS NULL BEGIN
		                    --gvarMensajeError = "El Vendededor No Tiene Asociado Un Centro de Análisis"
		                    SET @strMensajeError = 'El Vendededor No Tiene Asociado Un Centro de Análisis';
		                    RAISERROR (@strMensajeError, 16, 1);
		 ----THROW 51000, @strMensajeError, 1;
		                END;
		            END ELSE  BEGIN
		                IF @strGeneraCAPor = 'P' AND @booIntegracionCA = 1 BEGIN
		                    SET @canId = (SELECT canId FROM gntPuntoVenta WHERE pveId = @strPveId);														
		                    
		                    IF @canId IS NULL BEGIN
		                        --gvarMensajeError = "El Punto de Venta No Tiene Asociado Un Centro de Análisis"
		                        SET @strMensajeError = 'El Punto de Venta ' + @strPveId + ' No Tiene Asociado Un Centro de Análisis'; 
		                        RAISERROR (@strMensajeError, 16, 1);
		                        ----THROW 51000, @strMensajeError, 1;
		                    END;
		                END;
		            END;
		            SET @strOctId = ISNULL(@canId, '');		
		            IF @booIntegracionCA = 1 BEGIN
		                --strProId = Nz(recuperaRegistroSQL("proId", "gntPuntoVenta", "pveId='" & strPveId & "'"), "")
		                SET @strProId = ISNULL((SELECT proId FROM gntPuntoVenta WHERE pveId = @strPveId), '');
		            END ELSE  BEGIN
		                SET @strProId = '';
		            END;
		            --'----fin --
		            IF @flgGenerico != 1 BEGIN
		                --									'DC 20-01-2017
		                IF @conOtroDetalle = 'S' AND @strconReferencia = 'S' BEGIN
		                    --										varResultado = recuperaRegistroSQL("ctaId", "cntConceptoCuenta", "conId = 'DESVEN' AND ccuReferencia = '" & strPveId & "'", , "octId")
		                    SELECT @strCtaid = ctaId FROM cntConceptoCuenta WHERE conId = 'DESVEN' AND ccuReferencia = @strTdoId
		                    
		                    IF @@ROWCOUNT = 0 BEGIN
		                        SET @strMensajeError = 'ERROR : NO EXISTE EL CONCEPTO  DESVEN  CON REFERENCIA ' + ISNULL(@strTdoId, '');
		                        RAISERROR (@strMensajeError, 16, 1);
		                        ----THROW 51000, @strMensajeError, 1;
		                    END;
		                    IF (@strCtaid IS NULL) OR LEN(RTRIM(LTRIM(@strCtaid))) = 0 BEGIN
		                        SET @strMensajeError = 'No existe configurada la  cuenta para el concepto ' + @strConcepto; 
		                        RAISERROR (@strMensajeError, 16, 1);
		                        ----THROW 51000, @strMensajeError, 1;
		                    END;
		                END ELSE  BEGIN
		                    --										varResultado = recuperaRegistroSQL("ctaId", "cntConceptoCuenta", "conId = 'DESVEN' AND ccuReferencia = '" & strPveId & "'", , "octId")
		                    SELECT @strCtaid = ctaId FROM cntConceptoCuenta WHERE conId = 'DESVEN' AND ccuReferencia = @strPveId
		                    --										If IsNull(varResultado) Then
		                    IF @@ROWCOUNT = 0 BEGIN
		                        --											vmaGeneraAsientoVentas = ErrNoExisteConceptoCuenta
		                        SET @strMensajeError = 'ERROR : NO EXISTE EL CONCEPTO  DESVEN  CON REFERENCIA ' + ISNULL(@strPveId, '');
		                        RAISERROR (@strMensajeError, 16, 1);
		                        ----THROW 51000, @strMensajeError, 1;
		                    END;
		                    
		                    IF (@strCtaid IS NULL) OR LEN(RTRIM(LTRIM(@strCtaid))) = 0 BEGIN
		                        SET @strMensajeError = 'No existe configurada la  cuenta para el concepto ' + @strConcepto; 
		                        RAISERROR (@strMensajeError, 16, 1);
		                        ----THROW 51000, @strMensajeError, 1;
		                    END;
		                END
		            END;

		            IF @booConDFR = 1 BEGIN
						SET @dblTotal = @dblDescuentoArticulo;
		            END ELSE BEGIN
						IF @strVnpAsientoDescuentoCreditoFiscal = 'S' AND @flgConFactura = 1  BEGIN
							SET @dblTotal = @dblDescuentoArticulo * (1 - @dblGnpIva); --31/08/2018 MODIFICACION CALCULO DE DESCUENTO SOLICITADO POR YOVANA ORELLANA
						END ELSE BEGIN
							SET @dblTotal = @dblDescuentoArticulo;
						END 
		            END		                  
		            IF @booAnulaTxn != 1 BEGIN
		                --If strTipoTxnVn = "VEN" Or strTipoTxnVn = "VAF" Then
		                IF @strTipoTxnVn = 'VEN' OR @strTipoTxnVn = 'VAF' BEGIN
		                    --intStatus = CreaPosteo("cntPosteoCn", strTipoTxnVn, strvntId, strCtaid, strOctId, fchFechaDoc, dblTc, dblTotal, 0, strMonId, "vn", strDescripcion, strConFacturaPos, strExportadoAlFiscal, strCliId, strPveId, , , , , strTxnAnulada, , strProId)
		                    EXEC CreaPosteo 'cntPosteoCn', @strTipoTxnVn, @strvntId, @strCtaid, @strOctId, @fchFechaDoc, @dblTc, @dblTotal, 0, @strMonId, 'vn', @strDescripcion, @strConFacturaPos, @strExportadoAlFiscal, @strproIdCn, @strBanIdCn, @strNroDocumentoCn, @strNotaCn, NULL, NULL, @strTxnAnulada, NULL, 
		                         @strProId, NULL, NULL, NULL, @gstrGeneraTxnContableMonedaCentral, @strMonIdC, @strMonIdP;
		                    --dblDebe = dblDebe + dblTotal
		                    SET @dblDebe = @dblDebe + @dblTotal;
		                END--Else
		                    ELSE  BEGIN
		                    --intStatus = CreaPosteo("cntPosteoCn", strTipoTxnVn, strvntId, strCtaid, strOctId, fchFechaDoc, dblTc, 0, dblTotal, strMonId, "vn", strDescripcion, strConFacturaPos, strExportadoAlFiscal, strCliId, strPveId, , , , , strTxnAnulada, , strProId)
		                    EXEC CreaPosteo 'cntPosteoCn', @strTipoTxnVn, @strvntId, @strCtaid, @strOctId, @fchFechaDoc, @dblTc, 0, @dblTotal, @strMonId, 'vn', @strDescripcion, @strConFacturaPos, @strExportadoAlFiscal, @strproIdCn, @strBanIdCn, @strNroDocumentoCn, @strNotaCn, NULL, NULL, @strTxnAnulada, NULL, 
		                         @strProId, NULL, NULL, NULL, @gstrGeneraTxnContableMonedaCentral, @strMonIdC, @strMonIdP;
		                    SET @dblHaber = @dblHaber + @dblTotal;
		                END;
		            END ELSE  BEGIN
		                IF @strTipoTxnVn = 'VEN' OR @strTipoTxnVn = 'VAF' BEGIN
		                    --intStatus = CreaPosteo("cntPosteoCn", strTipoTxnVn, strvntId, strCtaid, strOctId, fchFechaDoc, dblTc, 0, dblTotal, strMonId, "vn", strDescripcion, strConFacturaPos, strExportadoAlFiscal, strCliId, strPveId, , , , , strTxnAnulada)
		                    EXEC CreaPosteo 'cntPosteoCn', @strTipoTxnVn, @strvntId, @strCtaid, @strOctId, @fchFechaDoc, @dblTc, 0, @dblTotal, @strMonId, 'vn', @strDescripcion, @strConFacturaPos, @strExportadoAlFiscal, @strproIdCn, @strBanIdCn, @strNroDocumentoCn, @strNotaCn, NULL, NULL, @strTxnAnulada, NULL, 
		                         NULL, NULL, NULL, NULL, @gstrGeneraTxnContableMonedaCentral, @strMonIdC, @strMonIdP;
		                    --dblHaber = dblHaber + dblTotal
		                    SET @dblHaber = @dblHaber + @dblTotal;
		                END--Else
		                    ELSE  BEGIN
		                    --intStatus = CreaPosteo("cntPosteoCn", strTipoTxnVn, strvntId, strCtaid, strOctId, fchFechaDoc, dblTc, dblTotal, 0, strMonId, "vn", strDescripcion, strConFacturaPos, strExportadoAlFiscal, strCliId, strPveId, , , , , strTxnAnulada)
		                    EXEC CreaPosteo 'cntPosteoCn', @strTipoTxnVn, @strvntId, @strCtaid, @strOctId, @fchFechaDoc, @dblTc, @dblTotal, 0, @strMonId, 'vn', @strDescripcion, @strConFacturaPos, @strExportadoAlFiscal, @strproIdCn, @strBanIdCn, @strNroDocumentoCn, @strNotaCn, NULL, NULL, @strTxnAnulada, NULL, 
		                         NULL, NULL, NULL, NULL, @gstrGeneraTxnContableMonedaCentral, @strMonIdC, @strMonIdP; 
		                    --dblDebe = dblDebe + dblTotal
		                    SET @dblDebe = @dblDebe + @dblTotal;
		                    --End If
		                END;
		                --If intStatus <> 0 Then
		                --vmaGeneraAsientoVentas = intStatus
		                --Exit Function
		                --End If
		                --End If
		            END;
		 --End If
		        END;
		        --'------------------------RECVEN---------------
		        --If dblRecargoMoneda <> 0 And strTipoTxnVn <> "PRO" Then
		        
		        IF @dblRecargoMoneda <> 0 AND @strTipoTxnVn <> 'PRO' BEGIN
		            --strConcepto = "RECVEN"
		            SET @strConcepto = 'RECVEN';
		            --varResultado = recuperaRegistroSQL("conGenerico", "cntConcepto", "conId = '" & strConcepto & "'", , "ctaId", "octId")
		            SELECT @flgGenerico = conGenerico, @strCtaid = ctaId, @strOctId = octId FROM cntConcepto WHERE conId = @strConcepto
		            
		            --If IsNull(varResultado) Then
		            IF @@ROWCOUNT = 0 BEGIN
		                --vmaGeneraAsientoVentas = ErrMensajeMudo
		                --gvarMensajeError = "No existe configurada la  cuenta para el concepto " & strConcepto
		                SET @strMensajeError = 'No existe configurada la  cuenta para el concepto ' + @strConcepto; 
		                RAISERROR (@strMensajeError, 16, 1);
		                ----THROW 51000, @strMensajeError, 1;
		                --Exit Function
		                --End If
		            END;
				    IF @strGeneraCAPor = 'P'  BEGIN
					  SELECT @strOctId = canId,@strProId = proId FROM gntPuntoVenta WHERE pveId = @strPveId;
					  IF @strOctId IS NULL BEGIN
						  SET @strMensajeError = 'El Punto de Venta ' + @strPveId + ' No Tiene Asociado Un Centro de Análisis';
						  RAISERROR (@strMensajeError, 16, 1);
					  END;
				    END;
		            --flgGenerico = recuperacampo(varResultado, 1)
		            --strCtaid = recuperacampo(varResultado, 2)
		            --strOctId = recuperacampo(varResultado, 3)
		            --If (IsNull(strCtaid) Or Len(Trim(strCtaid)) = 0) And flgGenerico Then
		            IF ((@strCtaid IS NULL) OR LEN(RTRIM(LTRIM(@strCtaid))) = 0) AND @flgGenerico = 1 BEGIN
		                --vmaGeneraAsientoVentas = ErrMensajeMudo
		                --gvarMensajeError = "No existe configurada la  cuenta para el concepto " & strConcepto
		                SET @strMensajeError = 'No existe configurada la  cuenta para el concepto ' + @strConcepto;
		                RAISERROR (@strMensajeError, 16, 1);
		                ----THROW 51000, @strMensajeError, 1;
		                --Exit Function
		                --End If
		            END;
		            --If Not flgGenerico Then
		            IF @flgGenerico != 1 BEGIN
		                DECLARE rsFpago4 CURSOR LOCAL FOR
		                	SELECT treId, txrMontoMoneda FROM vntTxnRecargo WHERE vntid = @strvntId 
		                --Set rsFpago = miBD.OpenRecordset("select treId, txrMontoMoneda from vntTxnRecargo where vntid = '" & strvntId & "'", dbOpenSnapshot)
		                OPEN rsFpago4;
		                FETCH NEXT FROM rsFpago4 INTO @treId_RS,@txrMontoMoneda_RS;
		                --If Not rsFpago.EOF Then
		                IF @@FETCH_STATUS = 0 BEGIN
		                    --rsFpago.MoveFirst
		                    --Do
		                    WHILE @@FETCH_STATUS = 0 BEGIN
		                        SET @dblPorDescuento = @txrMontoMoneda_RS / (@dblArticuloMoneda - @dblDescuentoArticulo + @dblRecargoMoneda);	
		                        SET @dblDescuento = @dblPorDescuento * @dblDescuentoMoneda;
		                        SELECT @strCtaid = ctaId, @strOctId = octId FROM cntConceptoCuenta WHERE conId = @strConcepto AND ccuReferencia = @treId_RS
		                        
		                        IF @@ROWCOUNT = 0 BEGIN
		                            SET @strMensajeError = 'No existe configurada la  cuenta para el concepto ' + @strConcepto + 'con Referencia ' + @treId_RS;
		                            RAISERROR (@strMensajeError, 16, 1);
		                            ----THROW 51000, @strMensajeError, 1;
		                        END;	
		                        IF (@strCtaid IS NULL) OR LEN(RTRIM(LTRIM(@strCtaid))) = 0 BEGIN
		                            SET @strMensajeError = 'No existe configurada la  cuenta para el concepto ' + @strConcepto + 'con Referencia ' + @treId_RS;
		                            RAISERROR (@strMensajeError, 16, 1);
		                            ----THROW 51000, @strMensajeError, 1;
		                        END;	
		                        IF @flgConFactura = 1 BEGIN
		                            SET @dblTotal = @txrMontoMoneda_RS - @dblDescuento;	
		                            SET @dblTotal = @dblTotal * (1 - @dblGnpIva);
		                            SET @dblTotal = @dblTotal + @dblDescuento;
		                        END ELSE  BEGIN
		                            SET @dblTotal = @txrMontoMoneda_RS - @dblDescuento;
		                        END;
		                        IF @booAnulaTxn != 1 BEGIN
		                            IF @strTipoTxnVn = 'VEN' OR @strTipoTxnVn = 'VAF' BEGIN
		                                EXEC CreaPosteo 'cntPosteoCn', @strTipoTxnVn, @strvntId, @strCtaid, @strOctId, @fchFechaDoc, @dblTc, 0, @dblTotal, @strMonId, 'vn', @strDescripcion, @strConFacturaPos, @strExportadoAlFiscal, @strproIdCn, @strBanIdCn, @strNroDocumentoCn, @strNotaCn, NULL, NULL, @strTxnAnulada, 
		                                     NULL, @strProId, NULL, NULL, NULL, @gstrGeneraTxnContableMonedaCentral, @strMonIdC, @strMonIdP;
		                                SET @dblHaber = @dblHaber + @dblTotal;
		                            END--Else
		                                ELSE  BEGIN
		                                --intStatus = CreaPosteo("cntPosteoCn", strTipoTxnVn, strvntId, strCtaid, strOctId, fchFechaDoc, dblTc, dblTotal, 0, strMonId, "vn", strDescripcion, strConFacturaPos, strExportadoAlFiscal, strCliId, strPveId, , , , , strTxnAnulada)
		                                EXEC CreaPosteo 'cntPosteoCn', @strTipoTxnVn, @strvntId, @strCtaid, @strOctId, @fchFechaDoc, @dblTc, @dblTotal, 0, @strMonId, 'vn', @strDescripcion, @strConFacturaPos, @strExportadoAlFiscal, @strproIdCn, @strBanIdCn, @strNroDocumentoCn, @strNotaCn, NULL, NULL, @strTxnAnulada, 
		                                     NULL, @strProId, NULL, NULL, NULL, @gstrGeneraTxnContableMonedaCentral, @strMonIdC, @strMonIdP;
		                                --dblDebe = dblDebe + dblTotal
		                                SET @dblDebe = @dblDebe + @dblTotal; 
		                                --End If
		                            END;
		                        END--Else
		                            ELSE  BEGIN
		                            --If strTipoTxnVn = "VEN" Or strTipoTxnVn = "VAF" Then
		                            IF @strTipoTxnVn = 'VEN' OR @strTipoTxnVn = 'VAF' BEGIN
		                                --intStatus = CreaPosteo("cntPosteoCn", strTipoTxnVn, strvntId, strCtaid, strOctId, fchFechaDoc, dblTc, dblTotal, 0, strMonId, "vn", strDescripcion, strConFacturaPos, strExportadoAlFiscal, strCliId, strPveId, , , , , strTxnAnulada)
		                                EXEC CreaPosteo 'cntPosteoCn', @strTipoTxnVn, @strvntId, @strCtaid, @strOctId, @fchFechaDoc, @dblTc, @dblTotal, 0, @strMonId, 'vn', @strDescripcion, @strConFacturaPos, @strExportadoAlFiscal, @strproIdCn, @strBanIdCn, @strNroDocumentoCn, @strNotaCn, NULL, NULL, @strTxnAnulada, 
		                                     NULL, @strProId, NULL, NULL, NULL, @gstrGeneraTxnContableMonedaCentral, @strMonIdC, @strMonIdP;
		                                --dblDebe = dblDebe + dblTotal
		                                SET @dblDebe = @dblDebe + @dblTotal;
		                            END--Else
		                                ELSE  BEGIN
		                                --intStatus = CreaPosteo("cntPosteoCn", strTipoTxnVn, strvntId, strCtaid, strOctId, fchFechaDoc, dblTc, 0, dblTotal, strMonId, "vn", strDescripcion, strConFacturaPos, strExportadoAlFiscal, strCliId, strPveId, , , , , strTxnAnulada)
		                                EXEC CreaPosteo 'cntPosteoCn', @strTipoTxnVn, @strvntId, @strCtaid, @strOctId, @fchFechaDoc, @dblTc, 0, @dblTotal, @strMonId, 'vn', @strDescripcion, @strConFacturaPos, @strExportadoAlFiscal, @strproIdCn, @strBanIdCn, @strNroDocumentoCn, @strNotaCn, NULL, NULL, @strTxnAnulada, 
		                                     NULL, @strProId, NULL, NULL, NULL, @gstrGeneraTxnContableMonedaCentral, @strMonIdC, @strMonIdP;
		                                --dblHaber = dblHaber + dblTotal
		                                SET @dblHaber = @dblHaber + @dblTotal;
		                                --End If
		                            END;
		                            --End If
		                        END;		
		                        
		                        FETCH NEXT FROM rsFpago4 INTO @treId_RS,@txrMontoMoneda_RS;
		                        --Loop Until rsFpago.EOF
		                    END;
		                    --End If
		                END; 
		                --rsFpago.Close
		                CLOSE rsFpago4;
		                --Set rsFpago = Nothing
		                DEALLOCATE rsFpago4;
		            END--Else
		                ELSE  BEGIN
		                --dblPorDescuento = dblRecargoMoneda / (dblArticuloMoneda - dblDescuentoArticulo + dblRecargoMoneda)
		                SET @dblPorDescuento = @dblRecargoMoneda / (@dblArticuloMoneda - @dblDescuentoArticulo + @dblRecargoMoneda); 
		                --dblDescuento = dblPorDescuento * dblDescuentoMoneda
		                SET @dblDescuento = @dblPorDescuento * @dblDescuentoMoneda; 
		                --If flgConFactura Then
		                IF @flgConFactura = 1 BEGIN
		                    --dblTotal = dblRecargoMoneda - dblDescuento
		                    SET @dblTotal = @dblRecargoMoneda - @dblDescuento; 
		                    --dblTotal = dblTotal * (1 - dblGnpIva)
		                    SET @dblTotal = @dblTotal * (1 - @dblGnpIva); 
		                    --dblTotal = dblTotal + dblDescuento
		                    SET @dblTotal = @dblTotal + @dblDescuento;
		                END--Else
		                    ELSE  BEGIN
		                    --dblTotal = dblRecargoMoneda - dblDescuento
		                    SET @dblTotal = @dblRecargoMoneda - @dblDescuento; 
		                    --End If
		                END; 
		                --If Not booAnulaTxn Then
		                IF @booAnulaTxn != 1 BEGIN
		                    --If strTipoTxnVn = "VEN" Or strTipoTxnVn = "VAF" Then
		                    IF @strTipoTxnVn = 'VEN' OR @strTipoTxnVn = 'VAF' BEGIN
		                        --intStatus = CreaPosteo("cntPosteoCn", strTipoTxnVn, strvntId, strCtaid, strOctId, fchFechaDoc, dblTc, 0, dblTotal, strMonId, "vn", strDescripcion, strConFacturaPos, strExportadoAlFiscal, strCliId, strPveId, , , , , strTxnAnulada)
		                        EXEC CreaPosteo 'cntPosteoCn', @strTipoTxnVn, @strvntId, @strCtaid, @strOctId, @fchFechaDoc, @dblTc, 0, @dblTotal, @strMonId, 'vn', @strDescripcion, @strConFacturaPos, @strExportadoAlFiscal, @strproIdCn, @strBanIdCn, @strNroDocumentoCn, @strNotaCn, NULL, NULL, @strTxnAnulada, 
		                             NULL, @strProId, NULL, NULL, NULL, @gstrGeneraTxnContableMonedaCentral, @strMonIdC, @strMonIdP;
		                        --dblHaber = dblHaber + dblTotal
		                        SET @dblHaber = @dblHaber + @dblTotal;
		                    END--Else
		                        ELSE  BEGIN
		                        --intStatus = CreaPosteo("cntPosteoCn", strTipoTxnVn, strvntId, strCtaid, strOctId, fchFechaDoc, dblTc, dblTotal, 0, strMonId, "vn", strDescripcion, strConFacturaPos, strExportadoAlFiscal, strCliId, strPveId, , , , , strTxnAnulada)
		                        EXEC CreaPosteo 'cntPosteoCn', @strTipoTxnVn, @strvntId, @strCtaid, @strOctId, @fchFechaDoc, @dblTc, @dblTotal, 0, @strMonId, 'vn', @strDescripcion, @strConFacturaPos, @strExportadoAlFiscal, @strproIdCn, @strBanIdCn, @strNroDocumentoCn, @strNotaCn, NULL, NULL, @strTxnAnulada, 
		                             NULL, @strProId, NULL, NULL, NULL, @gstrGeneraTxnContableMonedaCentral, @strMonIdC, @strMonIdP; 
		                        --dblDebe = dblDebe + dblTotal
		                        SET @dblDebe = @dblDebe + @dblTotal; 
		                        --End If
		                    END;
		                END--Else
		                    ELSE  BEGIN
		                    --If strTipoTxnVn = "VEN" Or strTipoTxnVn = "VAF" Then
		                    IF @strTipoTxnVn = 'VEN' OR @strTipoTxnVn = 'VAF' BEGIN
		                        --intStatus = CreaPosteo("cntPosteoCn", strTipoTxnVn, strvntId, strCtaid, strOctId, fchFechaDoc, dblTc, dblTotal, 0, strMonId, "vn", strDescripcion, strConFacturaPos, strExportadoAlFiscal, strCliId, strPveId, , , , , strTxnAnulada)
		                        EXEC CreaPosteo 'cntPosteoCn', @strTipoTxnVn, @strvntId, @strCtaid, @strOctId, @fchFechaDoc, @dblTc, @dblTotal, 0, @strMonId, 'vn', @strDescripcion, @strConFacturaPos, @strExportadoAlFiscal, @strproIdCn, @strBanIdCn, @strNroDocumentoCn, @strNotaCn, NULL, NULL, @strTxnAnulada, 
		                             NULL, @strProId, NULL, NULL, NULL, @gstrGeneraTxnContableMonedaCentral, @strMonIdC, @strMonIdP; 
		                        --dblDebe = dblDebe + dblTotal
		                        SET @dblDebe = @dblDebe + @dblTotal;
		                    END--Else
		                        ELSE  BEGIN
		                        --intStatus = CreaPosteo("cntPosteoCn", strTipoTxnVn, strvntId, strCtaid, strOctId, fchFechaDoc, dblTc, 0, dblTotal, strMonId, "vn", strDescripcion, strConFacturaPos, strExportadoAlFiscal, strCliId, strPveId, , , , , strTxnAnulada)
		                        EXEC CreaPosteo 'cntPosteoCn', @strTipoTxnVn, @strvntId, @strCtaid, @strOctId, @fchFechaDoc, @dblTc, 0, @dblTotal, @strMonId, 'vn', @strDescripcion, @strConFacturaPos, @strExportadoAlFiscal, @strproIdCn, @strBanIdCn, @strNroDocumentoCn, @strNotaCn, NULL, NULL, @strTxnAnulada, 
		                             NULL, @strProId, NULL, NULL, NULL, @gstrGeneraTxnContableMonedaCentral, @strMonIdC, @strMonIdP;
		                        --dblHaber = dblHaber + dblTotal
		                        SET @dblHaber = @dblHaber + @dblTotal;
		                        --End If
		                    END;
		                    --End If
		                END; 
		                --If intStatus <> 0 Then
		                --vmaGeneraAsientoVentas = intStatus
		                --Exit Function
		                --End If
		                --End If
		            END;
		            --End If
		        END; 
		        --'------------------------IVAGAS---------------Progarmado cuando es Generico
		        --If flgConFactura Then
		        IF @flgConFactura = 1 BEGIN
		            --strConcepto = "IVAGAS"
		            SET @strConcepto = 'IVAGAS'; 
		            --varResultado = recuperaRegistroSQL("conGenerico", "cntConcepto", "conId = '" & strConcepto & "'", , "ctaId", "octId")
		            SELECT @flgGenerico = conGenerico, @strCtaid = ctaId, @strOctId = octId FROM cntConcepto WHERE conId = @strConcepto
		            
		            --If IsNull(varResultado) Then
		            IF @@ROWCOUNT = 0 BEGIN
		                --vmaGeneraAsientoVentas = ErrMensajeMudo
		                --gvarMensajeError = "No existe configurada la  cuenta para el concepto " & strConcepto
		                SET @strMensajeError = 'No existe configurada la  cuenta para el concepto ' + @strConcepto;
		                RAISERROR (@strMensajeError, 16, 1);
		                ----THROW 51000, @strMensajeError, 1;
		                --Exit Function
		                --End If
		            END;
		            IF ((@strCtaid IS NULL) OR LEN(RTRIM(LTRIM(@strCtaid))) = 0) AND @flgGenerico = 1 BEGIN
		                SET @strMensajeError = 'No existe configurada la  cuenta para el concepto ' + @strConcepto; 
		                RAISERROR (@strMensajeError, 16, 1);
		                ----THROW 51000, @strMensajeError, 1;
		            END;
		     --SET @dblTotal = @dblArticuloMoneda - @dblDescuentoArticulo - @dblDescuentoMoneda + @dblRecargoMoneda;
		            IF @strCjpPermiteCANconFactura = 'S' BEGIN
						SET @dblTotal = @dblArticuloMoneda - @dblAnticipoMoneda --31/08/2018 MODIFICACION CALCULO SOLICITADO POR YOVANA ORELLANA
					END ELSE BEGIN
						SET @dblTotal = @dblArticuloMoneda 
		            END		            
		            IF @booConDFR = 1 BEGIN
		                SET @dblTotal = @dblTotal - @dblDFRMonto
		            END;
		            --obarrientos correccion no se tomaba encuenta el recargo 2019-07-03
					IF @strRecargoItemsAsumido = 'C' AND @dblRecargoMoneda>0 BEGIN
						SET @dblTotal = @dblTotal + @dblRecargoMoneda
					END		             
		            --set @dblTotal=@dblTotal- @decMontoAntFac 
		            IF @booConDFR = 0 BEGIN
						IF @strVnpAsientoDescuentoCreditoFiscal = 'S' BEGIN
							SET @dblTotal = @dblTotal * @dblGnpIva;	
						END ELSE BEGIN
							SET @dblTotal = (@dblTotal - @dblDescuentoMoneda) * @dblGnpIva;	 
						END
					END ELSE BEGIN
						SET @dblTotal = 0;
		            END
		            IF @dblTotal > 0 BEGIN
		                IF @booAnulaTxn != 1 BEGIN
		                    IF @strTipoTxnVn <> 'DVE' BEGIN
		                        EXEC CreaPosteo 'cntPosteoCn', @strTipoTxnVn, @strvntId, @strCtaid, @strOctId, @fchFechaDoc, @dblTc, 0, @dblTotal, @strMonId, 'vn', @strDescripcion, @strConFacturaPos, @strExportadoAlFiscal, @strproIdCn, @strBanIdCn, @strNroDocumentoCn, @strNotaCn, NULL, NULL, @strTxnAnulada, 
		                             NULL, NULL, NULL, NULL, NULL, @gstrGeneraTxnContableMonedaCentral, @strMonIdC, @strMonIdP;
		                        SET @dblHaber = @dblHaber + @dblTotal;
		                    END ELSE  BEGIN
		                        --intStatus = CreaPosteo("cntPosteoCn", strTipoTxnVn, strvntId, strCtaid, strOctId, fchFechaDoc, dblTc, dblTotal, 0, strMonId, "vn", strDescripcion, strConFacturaPos, strExportadoAlFiscal, strCliId, strPveId, , , , , strTxnAnulada)
		                        EXEC CreaPosteo 'cntPosteoCn', @strTipoTxnVn, @strvntId, @strCtaid, @strOctId, @fchFechaDoc, @dblTc, @dblTotal, 0, @strMonId, 'vn', @strDescripcion, @strConFacturaPos, @strExportadoAlFiscal, @strproIdCn, @strBanIdCn, @strNroDocumentoCn, @strNotaCn, NULL, NULL, @strTxnAnulada, 
		                             NULL, NULL, NULL, NULL, NULL, @gstrGeneraTxnContableMonedaCentral, @strMonIdC, @strMonIdP;
		                        SET @dblDebe = @dblDebe + @dblTotal;
		                        --End If
		                    END;
		                END--Else
		                    ELSE  BEGIN
		                    --If strTipoTxnVn <> "DVE" Then
		                    IF @strTipoTxnVn <> 'DVE' BEGIN
		                        --intStatus = CreaPosteo("cntPosteoCn", strTipoTxnVn, strvntId, strCtaid, strOctId, fchFechaDoc, dblTc, dblTotal, 0, strMonId, "vn", strDescripcion, strConFacturaPos, strExportadoAlFiscal, strCliId, strPveId, , , , , strTxnAnulada)
		                        EXEC CreaPosteo 'cntPosteoCn', @strTipoTxnVn, @strvntId, @strCtaid, @strOctId, @fchFechaDoc, @dblTc, @dblTotal, 0, @strMonId, 'vn', @strDescripcion, @strConFacturaPos, @strExportadoAlFiscal, @strproIdCn, @strBanIdCn, @strNroDocumentoCn, @strNotaCn, NULL, NULL, @strTxnAnulada, 
		                             NULL, NULL, NULL, NULL, NULL, @gstrGeneraTxnContableMonedaCentral, @strMonIdC, @strMonIdP; 
		                        --dblDebe = dblDebe + dblTotal
		                        SET @dblDebe = @dblDebe + @dblTotal;
		                    END--Else
		                        ELSE  BEGIN
		                        --intStatus = CreaPosteo("cntPosteoCn", strTipoTxnVn, strvntId, strCtaid, strOctId, fchFechaDoc, dblTc, 0, dblTotal, strMonId, "vn", strDescripcion, strConFacturaPos, strExportadoAlFiscal, strCliId, strPveId, , , , , strTxnAnulada)
		                        EXEC CreaPosteo 'cntPosteoCn', @strTipoTxnVn, @strvntId, @strCtaid, @strOctId, @fchFechaDoc, @dblTc, 0, @dblTotal, @strMonId, 'vn', @strDescripcion, @strConFacturaPos, @strExportadoAlFiscal, @strproIdCn, @strBanIdCn, @strNroDocumentoCn, @strNotaCn, NULL, NULL, @strTxnAnulada, 
		                             NULL, NULL, NULL, NULL, NULL, @gstrGeneraTxnContableMonedaCentral, @strMonIdC, @strMonIdP; 
		                        --dblHaber = dblHaber + dblTotal
		                        SET @dblHaber = @dblHaber + @dblTotal;
		                        --End If
		                    END;
		                END;
		            END;
		            
		            
		            --			'PB -27-02-2015 -----IVAGASREG -------
		            IF @booConDFR = 1 BEGIN
		                SET @strConcepto = 'IVAGASREG'
		                
		                SELECT @flgGenerico = conGenerico, @strCtaid = ctaId, @strOctId = octId FROM cntConcepto WHERE conId = @strConcepto
		                
		                IF @@ROWCOUNT = 0 BEGIN
		                    SET @strMensajeError = 'No existe configurada la  cuenta para el concepto ' + @strConcepto; 
		                    RAISERROR (@strMensajeError, 16, 1);
		                    ----THROW 51000, @strMensajeError, 1;
		                END;
		                IF (@strCtaid IS NULL OR LEN(RTRIM(LTRIM(@strCtaid))) = 0) AND @flgGenerico = 1 BEGIN
		                    SET @strMensajeError = 'No existe configurada la  cuenta para el concepto ' + @strConcepto; 
		                    RAISERROR (@strMensajeError, 16, 1);
		                    ----THROW 51000, @strMensajeError, 1;
		                END;
		                SET @dblDFRTotal = @dblDFRMonto * @dblGnpIva;
		                IF @dblDFRTotal > 0 BEGIN
		                    IF @booAnulaTxn = 0 BEGIN
		                        IF @strTipoTxnVn <> 'DVE' BEGIN
		                            EXEC CreaPosteo 'cntPosteoCn', @strTipoTxnVn, @strvntId, @strCtaid, @strOctId, @fchFechaDoc, @dblTC, 0, @dblDFRTotal, @strMonId, 'vn', @strDescripcion, @strConFacturaPos, @strExportadoAlFiscal, @strproIdCn, @strBanIdCn, @strNroDocumentoCn, @strNotaCn, NULL, NULL, @strTxnAnulada, 
		                                 NULL, NULL, NULL, NULL, NULL, @gstrGeneraTxnContableMonedaCentral, @strMonIdC, @strMonIdP;
		                            SET @dblHaber = @dblHaber + @dblDFRTotal;
		                        END ELSE  BEGIN
		                            EXEC CreaPosteo 'cntPosteoCn', @strTipoTxnVn, @strvntId, @strCtaid, @strOctId, @fchFechaDoc, @dblTC, @dblDFRTotal, 0, @strMonId, 'vn', @strDescripcion, @strConFacturaPos, @strExportadoAlFiscal, @strproIdCn, @strBanIdCn, @strNroDocumentoCn, @strNotaCn, NULL, NULL, @strTxnAnulada, 
		                                 NULL, NULL, NULL, NULL, NULL, @gstrGeneraTxnContableMonedaCentral, @strMonIdC, @strMonIdP;
		                            SET @dblDebe = @dblDebe + @dblDFRTotal
		                        END;
		                    END ELSE  BEGIN
		                        IF @strTipoTxnVn <> 'DVE' BEGIN
		                            EXEC CreaPosteo 'cntPosteoCn', @strTipoTxnVn, @strvntId, @strCtaid, @strOctId, @fchFechaDoc, @dblTC, @dblDFRTotal, 0, @strMonId, 'vn', @strDescripcion, @strConFacturaPos, @strExportadoAlFiscal, @strproIdCn, @strBanIdCn, @strNroDocumentoCn, @strNotaCn, NULL, NULL, @strTxnAnulada, 
		                                 NULL, NULL, NULL, NULL, NULL, @gstrGeneraTxnContableMonedaCentral, @strMonIdC, @strMonIdP;
		                            --dblDebe = dblDebe + dblDFRTotal
		                            SET @dblDebe = @dblDebe + @dblDFRTotal;
		                        END ELSE  BEGIN
		                            EXEC CreaPosteo 'cntPosteoCn', @strvntId, @strTipoTxnVn, @strvntId, @strCtaid, @strOctId, @fchFechaDoc, @dblTC, 0, @dblDFRTotal, @strMonId, 'vn', @strDescripcion, @strConFacturaPos, @strExportadoAlFiscal, @strproIdCn, @strBanIdCn, @strNroDocumentoCn, @strNotaCn, NULL, NULL, 
		                                 @strTxnAnulada, NULL, NULL, NULL, NULL, NULL, @gstrGeneraTxnContableMonedaCentral, @strMonIdC, @strMonIdP;
		                            SET @dblHaber = @dblHaber + @dblDFRTotal;
		                        END
		                    END;
		                END;
		            END;
		        END;
		        --'----------------------IMPTRA-------------------
		        
		        IF @flgConFactura = 1 BEGIN
		            SET @strConcepto = 'IMPTRA';
		            SELECT @flgGenerico = conGenerico, @strCtaid = ctaId, @strOctId = octId FROM cntConcepto WHERE conId = @strConcepto
		            
		            IF @@ROWCOUNT = 0 BEGIN
		                SET @strMensajeError = 'No existe configurada la  cuenta para el concepto ' + @strConcepto;
		                RAISERROR (@strMensajeError, 16, 1);
		                ----THROW 51000, @strMensajeError, 1;
		            END;
		            IF @strGeneraCAPor = 'V' AND @booIntegracionCA = 1 BEGIN
		                SET @varResultado2 = (SELECT venId FROM vntTxn WHERE vntId LIKE @strvntId)
		                
		                SET @varResultado2 = (SELECT canId FROM gntDirectorio WHERE dirid LIKE @varResultado2)
		                
		                IF @varResultado2 IS NULL BEGIN
		                    --		gvarMensajeError = "El Vendededor No Tiene Asociado Un Centro de Análisis"
		                    SET @strMensajeError = 'El Vendededor No Tiene Asociado Un Centro de Análisis ' + @strConcepto;
		                    RAISERROR (@strMensajeError, 16, 1);
		                    ----THROW 51000, @strMensajeError, 1;
		                END;
		            END ELSE  BEGIN
		                IF @strGeneraCAPor = 'P' AND @booIntegracionCA = 1 BEGIN
		                    SET @varResultado2 = (SELECT canId FROM gntPuntoVenta WHERE pveId = @strPveId)
		                    
		                    IF @varResultado2 IS NULL BEGIN
		                        SET @strMensajeError = 'El Punto de Venta No Tiene Asociado Un Centro de Análisis ' + @strPveId;
		                        RAISERROR (@strMensajeError, 16, 1);
		                        ----THROW 51000, @strMensajeError, 1;
		                    END
		                END;
		            END;
		            SET @strOctId = ISNULL(@varResultado2, '');
		            IF @booIntegracionCA = 1 BEGIN
		                SET @strProId = (SELECT proId FROM gntPuntoVenta WHERE pveId = @strPveId)
		            END
		            IF ((@strCtaid IS NULL) OR LEN(RTRIM(LTRIM(@strCtaid))) = 0) AND @flgGenerico = 1 BEGIN
		                SET @strMensajeError = 'No existe configurada la  cuenta para el concepto ' + @strConcepto; 
		                RAISERROR (@strMensajeError, 16, 1);
		                ----THROW 51000, @strMensajeError, 1;
		            END;
		            IF @flgGenerico = 0 BEGIN
		                SET @strCtaid = '';
		                SET @strOctId = '';
		                SELECT @strCtaid = ctaId, @strOctId = octId FROM cntConceptoCuenta WHERE conId = @strConcepto AND ccuReferencia = @strPveId
		                
		                IF LEN(ISNULL(@strCtaid, '')) = 0 BEGIN
		                    SET @strMensajeError = 'No existe configurada la cuenta para el Punto Venta  ' + @strPveId; 
		                    RAISERROR (@strMensajeError, 16, 1);
		                    ----THROW 51000, @strMensajeError, 1;
		                END;
		            END;
		            
		            --SET @dblTotal = @dblArticuloMoneda - @dblDescuentoArticulo - @dblDescuentoMoneda + @dblRecargoMoneda;
		            --SET @dblTotal = @dblArticuloMoneda - @dblAnticipoMoneda --31/08/2018 MODIFICACION CALCULO SOLICITADO POR YOVANA ORELLANA
		            IF @strCjpPermiteCANconFactura = 'S' BEGIN
						SET @dblTotal = @dblArticuloMoneda - @dblAnticipoMoneda - @dblDescuentoMoneda - @dblDescuentoArticulo --25/09/2018 MODIFICACION CALCULO SOLICITADO POR MONICA VILLARROEL						
		            END ELSE BEGIN
						SET @dblTotal = @dblArticuloMoneda - @dblDescuentoMoneda - @dblDescuentoArticulo --25/09/2018 MODIFICACION CALCULO SOLICITADO POR MONICA VILLARROEL						
		            END
		            
		            IF @booConDFR = 1 AND @strAplicaITenTxnConDFR = 'N' BEGIN
		                SET @dblTotal = @dblTotal - @dblDFRMonto;
		            END;
		            --obarrientos correccion no se tomaba encuenta el recargo 2019-07-03
					IF @strRecargoItemsAsumido = 'C' AND @dblRecargoMoneda>0 BEGIN
						SET @dblTotal = @dblTotal + @dblRecargoMoneda
					END		 
		            --set @dblTotal=@dblTotal -@decMontoAntFac
		            SET @dblTotal = @dblTotal * @dblGnpIT;
		            IF @dblTotal > 0 BEGIN
		                --IF @strIntegracionContableAplicacion = 'S' AND @strNAntFac=0 BEGIN
		                IF @strIntegracionContableAplicacion = 'S' BEGIN
		                    --22/10/2018 MODIFICACION SOLICITADA POR MONICA VILLARROEL
		                    DECLARE miRsInt CURSOR LOCAL FOR
		                    	SELECT ctaId, octId, proId, tcuImporte FROM vntTxnCuenta WHERE vntId LIKE @strVntId AND conid = 'VENNET'
		                    
		                    OPEN miRsInt;
		                    FETCH NEXT FROM miRsInt INTO @ctaId_cur,@octId_cur,@proId_cur,@tcuImporte_cur;
		                    IF @@FETCH_STATUS = 0 BEGIN
		                        WHILE @@FETCH_STATUS = 0 BEGIN
		                            SET @dblPorcentaje = @tcuImporte_cur / (@dblArticuloMoneda - @dblAnticipoMoneda);
		                            SET @dblTotal_cur = @dblTotal * @dblPorcentaje;
		                            SET @strOctId = ISNULL(@octId_cur, '');
		                            SET @strProId = ISNULL(@proId_cur, '');
		                            IF @booAnulaTxn != 1 BEGIN
		                                IF @strTipoTxnVn <> 'DVE' BEGIN
		                                    SET @strProId = ISNULL(@strProId, '');
		                                    EXEC CreaPosteo 'cntPosteoCn', @strTipoTxnVn, @strvntId, @strCtaid, @strOctId, @fchFechaDoc, @dblTc, @dblTotal_cur, 0, @strMonId, 'vn', @strDescripcion, @strConFacturaPos, @strExportadoAlFiscal, @strproIdCn, @strBanIdCn, @strNroDocumentoCn, @strNotaCn, NULL, NULL, @strTxnAnulada, 
		                                         NULL, @strProId, NULL, NULL, NULL, @gstrGeneraTxnContableMonedaCentral, @strMonIdC, @strMonIdP;
		                                    SET @dblDebe = @dblDebe + @dblTotal_cur;
		                                END ELSE  BEGIN
		                                    SET @strProId = ISNULL(@strProId, '');
		                                    EXEC CreaPosteo 'cntPosteoCn', @strTipoTxnVn, @strvntId, @strCtaid, @strOctId, @fchFechaDoc, @dblTc, 0, @dblTotal_cur, @strMonId, 'vn', @strDescripcion, @strConFacturaPos, @strExportadoAlFiscal, @strproIdCn, @strBanIdCn, @strNroDocumentoCn, @strNotaCn, NULL, NULL, @strTxnAnulada, 
		                                         NULL, @strProId, NULL, NULL, NULL, @gstrGeneraTxnContableMonedaCentral, @strMonIdC, @strMonIdP;
		                                    SET @dblHaber = @dblHaber + @dblTotal_cur;
		                                END;
		                            END ELSE  BEGIN
		                                IF @strTipoTxnVn <> 'DVE' BEGIN
		                                    SET @strProId = ISNULL(@strProId, '');
		                                    EXEC CreaPosteo 'cntPosteoCn', @strTipoTxnVn, @strvntId, @strCtaid, @strOctId, @fchFechaDoc, @dblTc, 0, @dblTotal_cur, @strMonId, 'vn', @strDescripcion, @strConFacturaPos, @strExportadoAlFiscal, @strproIdCn, @strBanIdCn, @strNroDocumentoCn, @strNotaCn, NULL, NULL, @strTxnAnulada, 
		                                         NULL, @strProId, NULL, NULL, NULL, @gstrGeneraTxnContableMonedaCentral, @strMonIdC, @strMonIdP;
		                                    SET @dblHaber = @dblHaber + @dblTotal_cur;
		                                END ELSE  BEGIN
		                                    SET @strProId = ISNULL(@strProId, '');
		                                    EXEC CreaPosteo 'cntPosteoCn', @strTipoTxnVn, @strvntId, @strCtaid, @strOctId, @fchFechaDoc, @dblTc, @dblTotal_cur, 0, @strMonId, 'vn', @strDescripcion, @strConFacturaPos, @strExportadoAlFiscal, @strproIdCn, @strBanIdCn, @strNroDocumentoCn, @strNotaCn, NULL, NULL, @strTxnAnulada, 
		                                         NULL, @strProId, NULL, NULL, NULL, @gstrGeneraTxnContableMonedaCentral, @strMonIdC, @strMonIdP;
		                                    SET @dblDebe = @dblDebe + @dblTotal_cur;
		                                END;
		                            END;
		                            FETCH NEXT FROM miRsInt INTO @ctaId_cur,@octId_cur,@proId_cur,@tcuImporte_cur;
		                        END;
		                    END;
		                    CLOSE miRsInt;
		                    DEALLOCATE miRsInt;
		                END; ELSE  BEGIN
		                --If Not booAnulaTxn Then
		                IF @booAnulaTxn != 1 BEGIN
		                    --If strTipoTxnVn <> "DVE" Then
		                    IF @strTipoTxnVn <> 'DVE' BEGIN
		                        --'intStatus = CreaPosteo("cntPosteoCn", strTipoTxnVn, strvntId, strCtaId, strOctId, fchFechaDoc, dblTc, dblTotal, 0, strMonId, "vn", strDescripcion, strConFacturaPos, strExportadoAlFiscal, strCliId, strPveId, , , , , strTxnAnulada) DESP + PAT 28-7-14
		                        --intStatus = CreaPosteo("cntPosteoCn", strTipoTxnVn, strvntId, strCtaid, strOctId, fchFechaDoc, dblTc, dblTotal, 0, strMonId, "vn", strDescripcion, strConFacturaPos, strExportadoAlFiscal, strCliId, strPveId, , , , , strTxnAnulada, , Nz(strProId, ""))
		                        SET @strProId = ISNULL(@strProId, '');
		                        EXEC CreaPosteo 'cntPosteoCn', @strTipoTxnVn, @strvntId, @strCtaid, @strOctId, @fchFechaDoc, @dblTc, @dblTotal, 0, @strMonId, 'vn', @strDescripcion, @strConFacturaPos, @strExportadoAlFiscal, @strproIdCn, @strBanIdCn, @strNroDocumentoCn, @strNotaCn, NULL, NULL, @strTxnAnulada, 
		                             NULL, @strProId, NULL, NULL, NULL, @gstrGeneraTxnContableMonedaCentral, @strMonIdC, @strMonIdP;
		                        --dblDebe = dblDebe + dblTotal
		                        SET @dblDebe = @dblDebe + @dblTotal;
		                    END--Else
		                        ELSE  BEGIN
		                        SET @strProId = ISNULL(@strProId, '');
		                        EXEC CreaPosteo 'cntPosteoCn', @strTipoTxnVn, @strvntId, @strCtaid, @strOctId, @fchFechaDoc, @dblTc, 0, @dblTotal, @strMonId, 'vn', @strDescripcion, @strConFacturaPos, @strExportadoAlFiscal, @strproIdCn, @strBanIdCn, @strNroDocumentoCn, @strNotaCn, NULL, NULL, @strTxnAnulada, 
		                             NULL, @strProId, NULL, NULL, NULL, @gstrGeneraTxnContableMonedaCentral, @strMonIdC, @strMonIdP; 
		                        SET @dblHaber = @dblHaber + @dblTotal;
		                    END;
		                END ELSE  BEGIN
		                    IF @strTipoTxnVn <> 'DVE' BEGIN
		                        SET @strProId = ISNULL(@strProId, '');
		                        EXEC CreaPosteo 'cntPosteoCn', @strTipoTxnVn, @strvntId, @strCtaid, @strOctId, @fchFechaDoc, @dblTc, 0, @dblTotal, @strMonId, 'vn', @strDescripcion, @strConFacturaPos, @strExportadoAlFiscal, @strproIdCn, @strBanIdCn, @strNroDocumentoCn, @strNotaCn, NULL, NULL, @strTxnAnulada, 
		                             NULL, @strProId, NULL, NULL, NULL, @gstrGeneraTxnContableMonedaCentral, @strMonIdC, @strMonIdP;
		                        SET @dblHaber = @dblHaber + @dblTotal;
		                    END ELSE  BEGIN
		                        SET @strProId = ISNULL(@strProId, '');
		                        EXEC CreaPosteo 'cntPosteoCn', @strTipoTxnVn, @strvntId, @strCtaid, @strOctId, @fchFechaDoc, @dblTc, @dblTotal, 0, @strMonId, 'vn', @strDescripcion, @strConFacturaPos, @strExportadoAlFiscal, @strproIdCn, @strBanIdCn, @strNroDocumentoCn, @strNotaCn, NULL, NULL, @strTxnAnulada, 
		                             NULL, @strProId, NULL, NULL, NULL, @gstrGeneraTxnContableMonedaCentral, @strMonIdC, @strMonIdP;
		                        SET @dblDebe = @dblDebe + @dblTotal;
		                    END;
		                END;
		            END;
		        END;
		        
		        --'PB -27-02-2015 --------IMPTRAREG -----
		        SELECT @strDFRSinIT = ISNULL(ippDfrSinIT, 'N') FROM iptParametro --03-01-2016 PEDIDO POR JAVIER Y SILVANA
		        IF @booConDFR = 1 AND @strAplicaITenTxnConDFR = 'N' AND @strDFRSinIT = 'N' BEGIN
		            SET @strConcepto = 'IMPTRAREG';
		            SELECT @flgGenerico = conGenerico, @strCtaid = ctaId, @strOctId = octId FROM cntConcepto WHERE conId = @strConcepto
		            
		            IF @@ROWCOUNT = 0 BEGIN
		                SET @strMensajeError = 'No existe configurada la  cuenta para el concepto ' + @strConcepto; 
		                RAISERROR (@strMensajeError, 16, 1);
		                ----THROW 51000, @strMensajeError, 1;
		            END;
		            IF @strGeneraCAPor = 'V' AND @booIntegracionCA = 1 BEGIN
		                SET @varResultado2 = (SELECT venId FROM vntTxn WHERE vntId LIKE @strvntId);
		                SET @varResultado2 = (SELECT canId FROM gntDirectorio WHERE dirid = @varResultado2);
		                IF @varResultado2 IS NULL BEGIN
		                    SET @strMensajeError = 'El Vendededor No Tiene Asociado Un Centro de Análisis'; 
		                    RAISERROR (@strMensajeError, 16, 1);
		                    ----THROW 51000, @strMensajeError, 1;
		                END;
		            END ELSE  BEGIN
		                --If strGeneraCAPor = "P" And booIntegracionCA Then  'If strGeneraCAPor = "P" Then  'Comentado por iarr 09-09-2014
		                IF @strGeneraCAPor = 'P' AND @booIntegracionCA = 1 BEGIN
		                    --varResultado2 = recuperaRegistroSQL("canId", "gntPuntoVenta", "pveId='" & strPveId & "'")
		                    SET @varResultado2 = (SELECT canId FROM gntPuntoVenta WHERE pveId = @strPveId);
		                    --If IsNull(varResultado) Then
		                    IF @varResultado2 IS NULL BEGIN
		                        --gvarMensajeError = "El Punto de Venta No Tiene Asociado Un Centro de Análisis"
		                        --vmaGeneraAsientoVentas = ErrMensajeMudo
		                        SET @strMensajeError = 'El Punto de Venta No Tiene Asociado Un Centro de Análisis'; 
		                        RAISERROR (@strMensajeError, 16, 1);
		                        ----THROW 51000, @strMensajeError, 1;
		                        --Exit Function
		                        --End If
		                    END;
		                    --End If
		                END;
		                --End If
		            END;
		            --strOctId = Nz(varResultado2, "")
		            SET @strOctId = ISNULL(@varResultado2, '');
		            --'---------------------------------
		            --If (IsNull(strCtaid) Or Len(Trim(strCtaid)) = 0) And flgGenerico Then
		            IF (@strCtaid IS NULL OR LEN(RTRIM(LTRIM(@strCtaid))) = 0) AND @flgGenerico = 1 BEGIN
		                --vmaGeneraAsientoVentas = ErrMensajeMudo
		                --gvarMensajeError = "No existe configurada la  cuenta para el concepto " & strConcepto
		                SET @strMensajeError = 'No existe configurada la  cuenta para el concepto ' + @strConcepto; 
		                RAISERROR (@strMensajeError, 16, 1);
		                ----THROW 51000, @strMensajeError, 1;
		                --Exit Function
		                --End If
		            END;
		            --dblDFRTotal = dblDFRMonto * dblGnpIT
		            SET @dblDFRTotal = @dblDFRMonto * @dblGnpIT
		            --If dblDFRTotal > 0 Then
		            IF @dblDFRTotal > 0 BEGIN
		                --If Not booAnulaTxn Then
		                IF @booAnulaTxn = 0 BEGIN
		                    --If strTipoTxnVn <> "DVE" Then
		            IF @strTipoTxnVn <> 'DVE' BEGIN
		                        --'intStatus = CreaPosteo("cntPosteoCn", strTipoTxnVn, strvntId, strCtaId, strOctId, fchFechaDoc, dblTc, dblTotal, 0, strMonId, "vn", strDescripcion, strConFacturaPos, strExportadoAlFiscal, strCliId, strPveId, , , , , strTxnAnulada) DESP + PAT 28-7-14
		                        --intStatus = CreaPosteo("cntPosteoCn", strTipoTxnVn, strvntId, strCtaid, strOctId, fchFechaDoc, dblTC, dblDFRTotal, 0, strMonId, "vn", strDescripcion, strConFacturaPos, strExportadoAlFiscal, strCliId, strPveId, , , , , strTxnAnulada, , Nz(strProId, ""))
		                        SET @strProId = ISNULL(@strProId, '');
		                        EXEC CreaPosteo 'cntPosteoCn', @strTipoTxnVn, @strvntId, @strCtaid, @strOctId, @fchFechaDoc, @dblTC, @dblDFRTotal, 0, @strMonId, 'vn', @strDescripcion, @strConFacturaPos, @strExportadoAlFiscal, @strproIdCn, @strBanIdCn, @strNroDocumentoCn, @strNotaCn, NULL, NULL, @strTxnAnulada, 
		                             NULL, @strProId, NULL, NULL, NULL, @gstrGeneraTxnContableMonedaCentral, @strMonIdC, @strMonIdP;
		                        --dblDebe = dblDebe + dblDFRTotal
		                        SET @dblDebe = @dblDebe + @dblDFRTotal;
		                    END--Else
		                        ELSE  BEGIN
		                        --'intStatus = CreaPosteo("cntPosteoCn", strTipoTxnVn, strvntId, strCtaId, strOctId, fchFechaDoc, dblTc, 0, dblTotal, strMonId, "vn", strDescripcion, strConFacturaPos, strExportadoAlFiscal, strCliId, strPveId, , , , , strTxnAnulada) 'DESP + PAT 28-7-14
		                        --intStatus = CreaPosteo("cntPosteoCn", strTipoTxnVn, strvntId, strCtaid, strOctId, fchFechaDoc, dblTC, 0, dblDFRTotal, strMonId, "vn", strDescripcion, strConFacturaPos, strExportadoAlFiscal, strCliId, strPveId, , , , , strTxnAnulada, , Nz(strProId, ""))
		                        SET @strProId = ISNULL(@strProId, '');
		                        EXEC CreaPosteo 'cntPosteoCn', @strTipoTxnVn, @strvntId, @strCtaid, @strOctId, @fchFechaDoc, @dblTC, 0, @dblDFRTotal, @strMonId, 'vn', @strDescripcion, @strConFacturaPos, @strExportadoAlFiscal, @strproIdCn, @strBanIdCn, @strNroDocumentoCn, @strNotaCn, NULL, NULL, @strTxnAnulada, 
		                             NULL, @strProId, NULL, NULL, NULL, @gstrGeneraTxnContableMonedaCentral, @strMonIdC, @strMonIdP;
		                        --dblHaber = dblHaber + dblDFRTotal
		                        SET @dblDebe = @dblDebe + @dblDFRTotal;
		                        --End If
		                    END;
		                END--Else
		                    ELSE  BEGIN
		                    --If strTipoTxnVn <> "DVE" Then
		                    IF @strTipoTxnVn <> 'DVE' BEGIN
		                        --'intStatus = CreaPosteo("cntPosteoCn", strTipoTxnVn, strvntId, strCtaId, strOctId, fchFechaDoc, dblTc, 0, dblTotal, strMonId, "vn", strDescripcion, strConFacturaPos, strExportadoAlFiscal, strCliId, strPveId, , , , , strTxnAnulada) 'DESP + PAT 28-7-14
		                        --intStatus = CreaPosteo("cntPosteoCn", strTipoTxnVn, strvntId, strCtaid, strOctId, fchFechaDoc, dblTC, 0, dblDFRTotal, strMonId, "vn", strDescripcion, strConFacturaPos, strExportadoAlFiscal, strCliId, strPveId, , , , , strTxnAnulada, , Nz(strProId, ""))
		                        SET @strProId = ISNULL(@strProId, '');
		                        EXEC CreaPosteo 'cntPosteoCn', @strTipoTxnVn, @strvntId, @strCtaid, @strOctId, @fchFechaDoc, @dblTC, 0, @dblDFRTotal, @strMonId, 'vn', @strDescripcion, @strConFacturaPos, @strExportadoAlFiscal, @strproIdCn, @strBanIdCn, @strNroDocumentoCn, @strNotaCn, NULL, NULL, @strTxnAnulada, 
		                             NULL, @strProId, NULL, NULL, NULL, @gstrGeneraTxnContableMonedaCentral, @strMonIdC, @strMonIdP;
		                        --dblHaber = dblHaber + dblDFRTotal
		                        SET @dblHaber = @dblHaber + @dblDFRTotal;
		                    END--Else
		                        ELSE BEGIN
		                        --'intStatus = CreaPosteo("cntPosteoCn", strTipoTxnVn, strvntId, strCtaId, strOctId, fchFechaDoc, dblTc, dblTotal, 0, strMonId, "vn", strDescripcion, strConFacturaPos, strExportadoAlFiscal, strCliId, strPveId, , , , , strTxnAnulada) 'DESP + PAT 28-7-14
		                        --intStatus = CreaPosteo("cntPosteoCn", strTipoTxnVn, strvntId, strCtaid, strOctId, fchFechaDoc, dblTC, dblDFRTotal, 0, strMonId, "vn", strDescripcion, strConFacturaPos, strExportadoAlFiscal, strCliId, strPveId, , , , , strTxnAnulada, , Nz(strProId, ""))
		                        SET @strProId = ISNULL(@strProId, '');
		                        EXEC CreaPosteo 'cntPosteoCn', @strTipoTxnVn, @strvntId, @strCtaid, @strOctId, @fchFechaDoc, @dblTC, @dblDFRTotal, 0, @strMonId, 'vn', @strDescripcion, @strConFacturaPos, @strExportadoAlFiscal, @strproIdCn, @strBanIdCn, @strNroDocumentoCn, @strNotaCn, NULL, NULL, @strTxnAnulada, 
		                             NULL, @strProId, NULL, NULL, NULL, @gstrGeneraTxnContableMonedaCentral, @strMonIdC, @strMonIdP;
		                        --dblDebe = dblDebe + dblDFRTotal
		                        SET @dblDebe = @dblDebe + @dblDFRTotal;
		                        --End If
		                    END;
		                    --End If
		                END;
		                --If intStatus <> 0 Then
		                --vmaGeneraAsientoVentas = intStatus
		                --Exit Function
		                --End If
		                --End If
		            END; 
		            --End If
		        END;
		        --'PB -27-02-2015
		        
		        
		        
		        
		        --End If
		    END;
		    
		    --'-----------------------IMPTRAPAG -----------
		    --If flgConFactura Then
		    IF @flgConFactura = 1 BEGIN
		        --strConcepto = "IMPTRAPAG"
		        SET @strConcepto = 'IMPTRAPAG'; 
		        --varResultado = recuperaRegistroSQL("conGenerico", "cntConcepto", "conId = '" & strConcepto & "'", , "ctaId", "octId")
		        SELECT @flgGenerico = conGenerico, @strCtaid = ctaId, @strOctId = octId FROM cntConcepto WHERE conId = @strConcepto
		        
		        --If IsNull(varResultado) Then
		        IF @@ROWCOUNT = 0 BEGIN
		            --vmaGeneraAsientoVentas = ErrMensajeMudo
		            --gvarMensajeError = "No existe configurada la  cuenta para el concepto " & strConcepto
		            SET @strMensajeError = 'No existe configurada la  cuenta para el concepto ' + @strConcepto;
		            RAISERROR (@strMensajeError, 16, 1);
		            ----THROW 51000, @strMensajeError, 1;
		            --Exit Function
		            --End If
		        END; 
		        --flgGenerico = recuperacampo(varResultado, 1)
		        --strCtaid = recuperacampo(varResultado, 2)
		        --strOctId = recuperacampo(varResultado, 3)
		        --If (IsNull(strCtaid) Or Len(Trim(strCtaid)) = 0) And flgGenerico Then
		        IF ((@strCtaid IS NULL) OR LEN(RTRIM(LTRIM(@strCtaid))) = 0) AND @flgGenerico = 1 BEGIN
		            --vmaGeneraAsientoVentas = ErrMensajeMudo
		            --gvarMensajeError = "No existe configurada la  cuenta para el concepto " & strConcepto
		            SET @strMensajeError = 'No existe configurada la  cuenta para el concepto ' + @strConcepto;
		            RAISERROR (@strMensajeError, 16, 1);
		            ----THROW 51000, @strMensajeError, 1;
		            --Exit Function
		            --End If
		        END; 
		        --dblTotal = dblArticuloMoneda - dblDescuentoArticulo - dblDescuentoMoneda + dblRecargoMoneda
		        --SET @dblTotal = @dblArticuloMoneda - @dblDescuentoArticulo - @dblDescuentoMoneda + @dblRecargoMoneda;
		        --SET @dblTotal = @dblArticuloMoneda - @dblAnticipoMoneda --31/08/2018 MODIFICACION CALCULO 
		        IF @strCjpPermiteCANconFactura = 'S' BEGIN
					SET @dblTotal = @dblArticuloMoneda - @dblAnticipoMoneda - @dblDescuentoMoneda - @dblDescuentoArticulo --25/09/2018 MODIFICACION CALCULO SOLICITADO POR MONICA VILLARROEL
				END ELSE BEGIN
					SET @dblTotal = @dblArticuloMoneda  - @dblDescuentoMoneda - @dblDescuentoArticulo --25/09/2018 MODIFICACION CALCULO SOLICITADO POR MONICA VILLARROEL									
		        END                                                                                                      --'dj-12-03-2015
		                                                                                                              --If booConDFR Then
		        IF @booConDFR = 1 BEGIN
		            --dblTotal = dblTotal - dblDFRMonto
		            SET @dblTotal = @dblTotal - @dblDFRMonto;
		            --End If
		        END;
		        --'fin
	            --obarrientos correccion no se tomaba encuenta el recargo 2019-07-03
				IF @strRecargoItemsAsumido = 'C' AND @dblRecargoMoneda>0 BEGIN
					SET @dblTotal = @dblTotal + @dblRecargoMoneda
				END		 		        
		        
		        --dblTotal = dblTotal * dblGnpIT
		        --set @dblTotal=@dblTotal -@decMontoAntFac
		        SET @dblTotal = @dblTotal * @dblGnpIT; 
		        --If dblTotal > 0 Then
		        IF @dblTotal > 0 BEGIN
		            --If Not booAnulaTxn Then
		            IF @booAnulaTxn != 1 BEGIN
		                --If strTipoTxnVn <> "DVE" Then
		                IF @strTipoTxnVn <> 'DVE' BEGIN
		                    --intStatus = CreaPosteo("cntPosteoCn", strTipoTxnVn, strvntId, strCtaid, strOctId, fchFechaDoc, dblTc, 0, dblTotal, strMonId, "vn", strDescripcion, strConFacturaPos, strExportadoAlFiscal, strCliId, strPveId, , , , , strTxnAnulada)
		                    EXEC CreaPosteo 'cntPosteoCn', @strTipoTxnVn, @strvntId, @strCtaid, @strOctId, @fchFechaDoc, @dblTc, 0, @dblTotal, @strMonId, 'vn', @strDescripcion, @strConFacturaPos, @strExportadoAlFiscal, @strproIdCn, @strBanIdCn, @strNroDocumentoCn, @strNotaCn, NULL, NULL, @strTxnAnulada, NULL, 
		                         NULL, NULL, NULL, NULL, @gstrGeneraTxnContableMonedaCentral, @strMonIdC, @strMonIdP;
		                    --dblHaber = dblHaber + dblTotal
		                    SET @dblHaber = @dblHaber + @dblTotal;
		                END--Else
		                    ELSE  BEGIN
		                    --intStatus = CreaPosteo("cntPosteoCn", strTipoTxnVn, strvntId, strCtaid, strOctId, fchFechaDoc, dblTc, dblTotal, 0, strMonId, "vn", strDescripcion, strConFacturaPos, strExportadoAlFiscal, strCliId, strPveId, , , , , strTxnAnulada)
		                    EXEC CreaPosteo 'cntPosteoCn', @strTipoTxnVn, @strvntId, @strCtaid, @strOctId, @fchFechaDoc, @dblTc, @dblTotal, 0, @strMonId, 'vn', @strDescripcion, @strConFacturaPos, @strExportadoAlFiscal, @strproIdCn, @strBanIdCn, @strNroDocumentoCn, @strNotaCn, NULL, NULL, @strTxnAnulada, NULL, 
		                         NULL, NULL, NULL, NULL, @gstrGeneraTxnContableMonedaCentral, @strMonIdC, @strMonIdP;
		                    --dblDebe = dblDebe + dblTotal
		                    SET @dblDebe = @dblDebe + @dblTotal;
		                    --End If
		                END;
		            END--Else
		                ELSE  BEGIN
		                --If strTipoTxnVn <> "DVE" Then
		                IF @strTipoTxnVn <> 'DVE' BEGIN
		                    --intStatus = CreaPosteo("cntPosteoCn", strTipoTxnVn, strvntId, strCtaid, strOctId, fchFechaDoc, dblTc, dblTotal, 0, strMonId, "vn", strDescripcion, strConFacturaPos, strExportadoAlFiscal, strCliId, strPveId, , , , , strTxnAnulada)
		                    EXEC CreaPosteo 'cntPosteoCn', @strTipoTxnVn, @strvntId, @strCtaid, @strOctId, @fchFechaDoc, @dblTc, @dblTotal, 0, @strMonId, 'vn', @strDescripcion, @strConFacturaPos, @strExportadoAlFiscal, @strproIdCn, @strBanIdCn, @strNroDocumentoCn, @strNotaCn, NULL, NULL, @strTxnAnulada, NULL, 
		                         NULL, NULL, NULL, NULL, @gstrGeneraTxnContableMonedaCentral, @strMonIdC, @strMonIdP;
		                    SET @dblDebe = @dblDebe + @dblTotal;
		                END ELSE  BEGIN
		                    --intStatus = CreaPosteo("cntPosteoCn", strTipoTxnVn, strvntId, strCtaid, strOctId, fchFechaDoc, dblTc, 0, dblTotal, strMonId, "vn", strDescripcion, strConFacturaPos, strExportadoAlFiscal, strCliId, strPveId, , , , , strTxnAnulada)
		                    EXEC CreaPosteo 'cntPosteoCn', @strTipoTxnVn, @strvntId, @strCtaid, @strOctId, @fchFechaDoc, @dblTc, 0, @dblTotal, @strMonId, 'vn', @strDescripcion, @strConFacturaPos, @strExportadoAlFiscal, @strproIdCn, @strBanIdCn, @strNroDocumentoCn, @strNotaCn, NULL, NULL, @strTxnAnulada, NULL, 
		                         NULL, NULL, NULL, NULL, @gstrGeneraTxnContableMonedaCentral, @strMonIdC, @strMonIdP;
		                    SET @dblHaber = @dblHaber + @dblTotal;
		                END;
		            END;
		        END; 
		        
		        --'---------------DJ-12-03-2015---concepto IMTRAPAGR
		        IF @booConDFR = 1 AND @strDFRSinIT = 'N' BEGIN
		            --strConcepto = "IMPTRAPAGR"
		            SET @strConcepto = 'IMPTRAPAGR'; 
		            --varResultado = recuperaRegistroSQL("conGenerico", "cntConcepto", "conId = '" & strConcepto & "'", , "ctaId", "octId")
		            SELECT @flgGenerico = conGenerico, @strCtaid = ctaId, @strOctId = octId FROM cntConcepto WHERE conId = @strConcepto
		            --If IsNull(varResultado) Then
		            IF @@ROWCOUNT = 0 BEGIN
		                --vmaGeneraAsientoVentas = ErrMensajeMudo
		                --gvarMensajeError = "No existe configurada la  cuenta para el concepto " & strConcepto
		                SET @strMensajeError = 'No existe configurada la  cuenta para el concepto ' + @strConcepto;
		                RAISERROR (@strMensajeError, 16, 1);
		                ----THROW 51000, @strMensajeError, 1;
		                --Exit Function
		                --End If
		            END;
		            IF ((@strCtaid IS NULL) OR LEN(RTRIM(LTRIM(@strCtaid))) = 0) AND @flgGenerico = 1 BEGIN
		                SET @strMensajeError = 'No existe configurada la  cuenta para el concepto ' + @strConcepto;
		                RAISERROR (@strMensajeError, 16, 1);
		                ----THROW 51000, @strMensajeError, 1;
		            END;
		            SET @dblTotal = @dblDFRMonto * @dblGnpIT;
		            IF @dblTotal > 0 BEGIN
		                IF @booAnulaTxn = 0 BEGIN
		                    IF @strTipoTxnVn <> 'DVE' BEGIN
		                        --intStatus = CreaPosteo("cntPosteoCn", strTipoTxnVn, strvntId, strCtaid, strOctId, fchFechaDoc, dblTC, 0, dblTotal, strMonId, "vn", strDescripcion, strConFacturaPos, strExportadoAlFiscal, strCliId, strPveId, , , , , strTxnAnulada)
		                        EXEC CreaPosteo 'cntPosteoCn', @strTipoTxnVn, @strvntId, @strCtaid, @strOctId, @fchFechaDoc, @dblTC, 0, @dblTotal, @strMonId, 'vn', @strDescripcion, @strConFacturaPos, @strExportadoAlFiscal, @strproIdCn, @strBanIdCn, @strNroDocumentoCn, @strNotaCn, NULL, NULL, @strTxnAnulada, 
		                             NULL, NULL, NULL, NULL, NULL, @gstrGeneraTxnContableMonedaCentral, @strMonIdC, @strMonIdP;
		                        SET @dblHaber = @dblHaber + @dblTotal
		                    END ELSE  BEGIN
		                        --intStatus = CreaPosteo("cntPosteoCn", strTipoTxnVn, strvntId, strCtaid, strOctId, fchFechaDoc, dblTC, dblTotal, 0, strMonId, "vn", strDescripcion, strConFacturaPos, strExportadoAlFiscal, strCliId, strPveId, , , , , strTxnAnulada)
		                        EXEC CreaPosteo 'cntPosteoCn', @strTipoTxnVn, @strvntId, @strCtaid, @strOctId, @fchFechaDoc, @dblTC, @dblTotal, 0, @strMonId, 'vn', @strDescripcion, @strConFacturaPos, @strExportadoAlFiscal, @strproIdCn, @strBanIdCn, @strNroDocumentoCn, @strNotaCn, NULL, NULL, @strTxnAnulada, 
		                             NULL, NULL, NULL, NULL, NULL, @gstrGeneraTxnContableMonedaCentral, @strMonIdC, @strMonIdP;
		                        SET @dblDebe = @dblDebe + @dblTotal;
		                    END;
		                END--Else
		                    ELSE  BEGIN
		                    IF @strTipoTxnVn <> 'DVE' BEGIN
		                        --intStatus = CreaPosteo("cntPosteoCn", strTipoTxnVn, strvntId, strCtaid, strOctId, fchFechaDoc, dblTC, dblTotal, 0, strMonId, "vn", strDescripcion, strConFacturaPos, strExportadoAlFiscal, strCliId, strPveId, , , , , strTxnAnulada)
		                        EXEC CreaPosteo 'cntPosteoCn', @strTipoTxnVn, @strvntId, @strCtaid, @strOctId, @fchFechaDoc, @dblTC, @dblTotal, 0, @strMonId, 'vn', @strDescripcion, @strConFacturaPos, @strExportadoAlFiscal, @strproIdCn, @strBanIdCn, @strNroDocumentoCn, @strNotaCn, NULL, NULL, @strTxnAnulada, 
		                             NULL, NULL, NULL, NULL, NULL, @gstrGeneraTxnContableMonedaCentral, @strMonIdC, @strMonIdP; 	
		                        SET @dblDebe = @dblDebe + @dblTotal;
		                    END ELSE  BEGIN
		                        --intStatus = CreaPosteo("cntPosteoCn", strTipoTxnVn, strvntId, strCtaid, strOctId, fchFechaDoc, dblTC, 0, dblTotal, strMonId, "vn", strDescripcion, strConFacturaPos, strExportadoAlFiscal, strCliId, strPveId, , , , , strTxnAnulada)
		                        EXEC CreaPosteo 'cntPosteoCn', @strTipoTxnVn, @strvntId, @strCtaid, @strOctId, @fchFechaDoc, @dblTC, 0, @dblTotal, @strMonId, 'vn', @strDescripcion, @strConFacturaPos, @strExportadoAlFiscal, @strproIdCn, @strBanIdCn, @strNroDocumentoCn, @strNotaCn, NULL, NULL, @strTxnAnulada, 
		                             NULL, NULL, NULL, NULL, NULL, @gstrGeneraTxnContableMonedaCentral, @strMonIdC, @strMonIdP;
		                        SET @dblHaber = @dblHaber + @dblTotal;
		                    END;
		                END;
		            END;
		        END;
		    END;
		    -------------------------CREFIS -----------31/08/2018 CODIGO ADICIONADO SOLICITADO POR YOVANA ORELLANA
		    IF @flgConFactura = 1 BEGIN				
		        SET @strConcepto = 'CREFIS';	
		        SELECT @flgGenerico = conGenerico, @strCtaid = ctaId, @strOctId = octId FROM cntConcepto WHERE conId = @strConcepto
		        
		        IF @@ROWCOUNT = 0 BEGIN
		            SET @strMensajeError = 'No existe configurada la  cuenta para el concepto ' + @strConcepto;
		            RAISERROR (@strMensajeError, 16, 1);
		            ----THROW 51000, @strMensajeError, 1;
		        END;	
		        IF ((@strCtaid IS NULL) OR LEN(RTRIM(LTRIM(@strCtaid))) = 0) AND @flgGenerico = 1 BEGIN
		            SET @strMensajeError = 'No existe configurada la  cuenta para el concepto ' + @strConcepto;
		            RAISERROR (@strMensajeError, 16, 1);
		            ----THROW 51000, @strMensajeError, 1;
		        END;	
		        IF @strVnpAsientoDescuentoCreditoFiscal = 'S' AND @booConDFR = 0 BEGIN
					SET @dblTotal = (@dblDescuentoMoneda + @dblDescuentoArticulo) * @dblGnpIva;
				END ELSE BEGIN
					SET @dblTotal = 0;
		        END
		        IF @dblTotal > 0 BEGIN
		            IF @booAnulaTxn != 1 BEGIN
		                IF @strTipoTxnVn <> 'DVE' BEGIN
		                    EXEC CreaPosteo 'cntPosteoCn', @strTipoTxnVn, @strvntId, @strCtaid, @strOctId, @fchFechaDoc, @dblTc, @dblTotal, 0, @strMonId, 'vn', @strDescripcion, @strConFacturaPos, @strExportadoAlFiscal, @strproIdCn, @strBanIdCn, @strNroDocumentoCn, @strNotaCn, NULL, NULL, @strTxnAnulada, NULL, 
		                         NULL, NULL, NULL, NULL, @gstrGeneraTxnContableMonedaCentral, @strMonIdC, @strMonIdP;
		                    SET @dblDebe = @dblDebe + @dblTotal;
		                END ELSE  BEGIN
		                    EXEC CreaPosteo 'cntPosteoCn', @strTipoTxnVn, @strvntId, @strCtaid, @strOctId, @fchFechaDoc, @dblTc, 0, @dblTotal, @strMonId, 'vn', @strDescripcion, @strConFacturaPos, @strExportadoAlFiscal, @strproIdCn, @strBanIdCn, @strNroDocumentoCn, @strNotaCn, NULL, NULL, @strTxnAnulada, NULL, 
		                         NULL, NULL, NULL, NULL, @gstrGeneraTxnContableMonedaCentral, @strMonIdC, @strMonIdP;
		                    SET @dblHaber = @dblHaber + @dblTotal;
		                END;
		            END ELSE  BEGIN
		                IF @strTipoTxnVn <> 'DVE' BEGIN
		                    EXEC CreaPosteo 'cntPosteoCn', @strTipoTxnVn, @strvntId, @strCtaid, @strOctId, @fchFechaDoc, @dblTc, 0, @dblTotal, @strMonId, 'vn', @strDescripcion, @strConFacturaPos, @strExportadoAlFiscal, @strproIdCn, @strBanIdCn, @strNroDocumentoCn, @strNotaCn, NULL, NULL, @strTxnAnulada, NULL, 
		                         NULL, NULL, NULL, NULL, @gstrGeneraTxnContableMonedaCentral, @strMonIdC, @strMonIdP;
		                    SET @dblHaber = @dblHaber + @dblTotal;
		                END ELSE  BEGIN
		                    EXEC CreaPosteo 'cntPosteoCn', @strTipoTxnVn, @strvntId, @strCtaid, @strOctId, @fchFechaDoc, @dblTc, @dblTotal, 0, @strMonId, 'vn', @strDescripcion, @strConFacturaPos, @strExportadoAlFiscal, @strproIdCn, @strBanIdCn, @strNroDocumentoCn, @strNotaCn, NULL, NULL, @strTxnAnulada, NULL, 
		                         NULL, NULL, NULL, NULL, @gstrGeneraTxnContableMonedaCentral, @strMonIdC, @strMonIdP;
		                    SET @dblDebe = @dblDebe + @dblTotal;
		                END;
		            END;
		        END
		    END;
		    --'--------------------VENNET------------------POR GRUPO DE ARTICULO
		    
		    EXEC vmaGeneraVENNET @strvntId, @strTipoTxnVn, @fchFechaDoc, @dblTc, @strMonId, @strDescripcion, @strExportadoAlFiscal, @strCliId, @booAnulaTxn, @strTxnAnulada, @flgConFactura, @strConFacturaPos, @dblArticuloMoneda, @dblDescuentoArticulo, @dblRecargoMoneda, @dblGnpIva, @dblDebe OUTPUT, @dblHaber 
		         OUTPUT, @strTdoId, @dblDescuentoMoneda, @strPveId, @strproIdCn, @strBanIdCn, @strNroDocumentoCn, @strNotaCn ;
		    --'-----------------------ANTICIPO------------
		    IF @dblAnticipoMoneda > 0 AND @strTipoTxnVn <> 'PRO' AND @strNAntFac = 0 BEGIN
				IF @strCjpPermiteCANconFactura = 'S' BEGIN
					SET @dblTotal = 0
				END ELSE BEGIN
					SET @dblTotal = (SELECT SUM(CASE WHEN cjtTxn.monid = @strMonId THEN cjtTxn.cjtMontoEfectivoMoneda ELSE CASE WHEN cjtTxn.monid = @strMonIdP THEN cjtTxn.cjtMontoEfectivoMoneda * cjtTcMcMp ELSE cjtTxn.cjtMontoEfectivoMoneda/ cjtTcMcMp END END) 
					FROM cjtTxn INNER JOIN vntTxnAnticipos ON vntTxnAnticipos.cjtId = cjtTxn.cjtId WHERE vntTxnAnticipos.vntid = @strvntId)					
				END
				IF @dblTotal>0 BEGIN
					SET @strConcepto = 'ANTOTR';	
				END ELSE BEGIN
					SET @strConcepto = 'ANTVEN';
					SET @dblTotal = (@dblAnticipoMoneda -@decMontoAntFac) + (@decMontoAntFac * (1 - @dblGnpIva));	
				END
				--' Asiento (Debe) para Anticipos
				SELECT @flgGenerico = conGenerico, @strCtaid = ctaId, @strOctId = octId FROM cntConcepto WHERE conId = @strConcepto
		        
				IF @@ROWCOUNT = 0 BEGIN
					SET @strMensajeError = 'No Existe  informacion para el concepto' + @strConcepto; 
					RAISERROR (@strMensajeError, 16, 1);
					----THROW 51000, @strMensajeError, 1;
				END;
				IF ((@strCtaid IS NULL) OR LEN(RTRIM(LTRIM(@strCtaid))) = 0) AND @flgGenerico = 1 BEGIN
					SET @strMensajeError = 'No Existe  la cuenta  para el concepto' + @strConcepto;
					RAISERROR (@strMensajeError, 16, 1);
					----THROW 51000, @strMensajeError, 1;
				END;
				IF @flgGenerico != 1 BEGIN
					SELECT @strDetallado = ISNULL(conReferencia, 'N'), @strconReferencia = ISNULL(conOtroDetalle, 'N') FROM cntConcepto WHERE conId = 'ANTVEN'
		            
					IF @strDetallado = 'N' BEGIN
						--'Por DIrectotio
						SET @strReferenciaConcepto = @strCliId;
					END ELSE    
					IF @strDetallado = 'S' BEGIN
						--'por Grupo de Cuenta corrientista a
		                DECLARE @parDetalladoC VARCHAR(5)
						select @parDetalladoC = parDetalladoConGrupos from cttParametro
						-- erick
						IF @parDetalladoC = 'S'
							BEGIN
								SET @grupoCtaCte = (SELECT gructaCte FROM gntDirectorio WHERE dirId LIKE @strCliId)		                
								SET @strReferenciaConcepto = ISNULL(@grupoCtaCte, '')		                
								PRINT 'por Grupo de Cuenta corrientista a';
							END
						ELSE
							BEGIN		
							-- erick
							SELECT @dblTotal = SUM(vntTxnAnticipos.detMonto) 
							FROM vntTxnAnticipos WHERE vntTxnAnticipos.vntid = @strvntId

								SELECT @strTdoId = tdoid-- tipo documento
								FROM cjtTxn INNER JOIN vntTxnAnticipos ON vntTxnAnticipos.cjtId = cjtTxn.cjtId WHERE vntTxnAnticipos.vntid = @strvntId						
								
								-- obteniendo la cuenta y la referencia											
								SELECT @strCtaid = ctaId, @strReferenciaConcepto = ccuReferencia
								FROM cntConceptoCuenta
								WHERE ccuReferencia = @strTdoId and conid = 'ANTOTR'	
							END			
					END;
		            
					IF LEN(@strReferenciaConcepto) = 0 BEGIN
						SET @strMensajeError = 'ERROR : No existe configurada el concepto ' + ISNULL(@strConcepto, '') + ' con referencia ' + ISNULL(@strReferenciaConcepto, ''); 
						RAISERROR (@strMensajeError, 16, 1);
						----THROW 51000, @strMensajeError, 1;
					END;	
					SELECT @strCtaid = ctaId, @strOctId = octId FROM cntConceptoCuenta WHERE conId = 'ANTVEN' AND ccuReferencia = @strReferenciaConcepto
		            
					IF @@ROWCOUNT = 0 BEGIN
						SET @strMensajeError = 'ERROR : NO Esta configurada el concepto  ANTVEN con referencia ' + ISNULL(@strReferenciaConcepto, ''); 
						RAISERROR (@strMensajeError, 16, 1);
						----THROW 51000, @strMensajeError, 1;
					END;
					IF (@strCtaid IS NULL) OR LEN(RTRIM(LTRIM(@strCtaid))) = 0 BEGIN
						SET @strMensajeError = 'ERROR : NO Esta configurada el concepto  ANTVEN con referencia ' + ISNULL(@strReferenciaConcepto, ''); 
						RAISERROR (@strMensajeError, 16, 1);
						----THROW 51000, @strMensajeError, 1;
					END;
				END;		        


		        IF @booAnulaTxn != 1 BEGIN
		            EXEC CreaPosteo 'cntPosteoCn', @strTipoTxnVn, @strvntId, @strCtaid, @strOctId, @fchFechaDoc, @dblTc, @dblTotal, 0, @strMonId, 'vn', @strDescripcion, @strConFacturaPos, @strExportadoAlFiscal, @strproIdCn, @strBanIdCn, @strNroDocumentoCn, @strNotaCn, NULL, NULL, 'N', NULL, NULL, NULL, NULL, 
		                 NULL, @gstrGeneraTxnContableMonedaCentral, @strMonIdC, @strMonIdP;
		            SET @dblDebe = @dblDebe + @dblTotal;
		        END ELSE  BEGIN
		            EXEC CreaPosteo 'cntPosteoCn', @strTipoTxnVn, @strvntId, @strCtaid, @strOctId, @fchFechaDoc, @dblTc, 0, @dblTotal, @strMonId, 'vn', @strDescripcion, @strConFacturaPos, @strExportadoAlFiscal, @strproIdCn, @strBanIdCn, @strNroDocumentoCn, @strNotaCn, NULL, NULL, 'S', NULL, NULL, NULL, NULL, 
		                 NULL, @gstrGeneraTxnContableMonedaCentral, @strMonIdC, @strMonIdP;
		            SET @dblHaber = @dblHaber + @dblTotal;
		        END;
		    END;
		END--'-----------------------Fin-----------------
		    ELSE  BEGIN
		    --'----------------Haber------Almacen Origen------------------------
		    
		    EXEC vmaGeneraInverarioParaPRO @strvntId, @strTipoTxnVn, @fchFechaDoc, @dblTc, @strMonId, @strDescripcion, @strConFacturaPos, @strExportadoAlFiscal, @strCliId, @strPveId, @strTxnAnulada, @booAnulaTxn, @dblHaber OUTPUT, @dblDebe OUTPUT, 'O', @strproIdCn, @strBanIdCn, @strNroDocumentoCn, @strNotaCn ;
		    --'-------------------Para el Debe- Almacen Destino----------------------------------------------------------
		    EXEC vmaGeneraInverarioParaPRO @strvntId, @strTipoTxnVn, @fchFechaDoc, @dblTc, @strMonId, @strDescripcion, @strConFacturaPos, @strExportadoAlFiscal, @strCliId, @strPveId, @strTxnAnulada, @booAnulaTxn, @dblHaber OUTPUT, @dblDebe OUTPUT, 'D', @strproIdCn, @strBanIdCn, @strNroDocumentoCn, @strNotaCn;
		END;
	END  ;
END; 
--'--------------Control si cuadra el documento
IF ABS(@dblDebe - @dblHaber) > 0.005 BEGIN   
	select ctanombre,c.* from cntPosteoCn c inner join cntcuenta cu on cu.ctaid= c.ctaid where ttxIdOri =@strvntId;
	SET @strMensajeError = @strNombreParamSP + ' ERROR: No Cuadra Documento(Debe: ' + CAST(ISNULL(@dblDebe, 0) AS VARCHAR) + ' -- Haber: ' + CAST(ISNULL(@dblHaber, 0) AS VARCHAR) +')';
    RAISERROR (@strMensajeError, 16, 1);
    ----THROW 51000, @strMensajeError, 1;
END;	
SET @booGeneraContabilidad = (SELECT ttxGeneraContabilidad FROM gntTipoTxn WHERE ttxid = @strTipoTxnVn);	
IF @booGeneraContabilidad = 1 AND @booAnulaTxn != 1 AND @dblDebe > 0 AND @dblHaber > 0 AND @strGeneracionContable = 'A' BEGIN
    EXEC cnpGeneraCreaUnaTxnAutomatica 'Txn Generada En Ventas', 'vn', @strvntId;
END; 
--Exit Function
--Errores:
--vmaGeneraAsientoVentas = Err.Number
--End Function

--MENSAJE DE FIN DE PROCESO		
PRINT @strNombreParamSP;
END TRY

BEGIN CATCH
	IF LEN(ISNULL(@strMensajeError, '')) = 0 BEGIN
	    SET @strMensajeError = @strNombreParamSP + ' ' + ERROR_MESSAGE();
	END ;
	RAISERROR (@strMensajeError, 16, 1);
	----THROW;
	
	--MENSAJE DE ERROR DE PROCESO
	PRINT @strNombreParamSP + ' Error';
END CATCH;
END
