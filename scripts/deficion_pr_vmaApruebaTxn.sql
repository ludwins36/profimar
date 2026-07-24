USE [dbTest]
GO
/****** Object:  StoredProcedure [dbo].[vmaApruebaTxn]    Script Date: 13/06/2026 7:43:03 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[vmaApruebaTxn]
	@strvntId VARCHAR(50),
	@strPveIdFacturacion VARCHAR(50)='',--Optional strPveIdFacturacion As String = "", 
	@lngNumeroFacturaManual BIGINT=-1--Optional lngNumeroFacturaManual As Long = -1
--WITH ENCRYPTION 
AS
BEGIN
	-- DEFINE OPCIONES DE EJECUCION
	SET NOCOUNT ON;

	-- DECLARA VARIABLES
	
	DECLARE @strNombreParamSP VARCHAR(200);
	DECLARE @strMensajeError VARCHAR(500);
	DECLARE @strEstado VARCHAR(1);
	DECLARE @strMonId VARCHAR(50);
	DECLARE @dblTotalMoneda DECIMAL(24,12);
	DECLARE @strTipoTxnVn VARCHAR(50);
	DECLARE @strCliId VARCHAR(50);
	DECLARE @strPveId VARCHAR(50);
	DECLARE @fchFechaDoc DATETIME;
	DECLARE @dblTC DECIMAL(24,12);
	DECLARE @dblDescuentoMoneda DECIMAL(24,12);
	DECLARE @dblRecargoMoneda DECIMAL(24,12);
    DECLARE @flgConFactura BIT;
    DECLARE @strVenId VARCHAR(50);
    DECLARE @dblArticuloMoneda DECIMAL(24,12);
    DECLARE @varDescripcion VARCHAR(300);
    DECLARE @strTdoId VARCHAR(50);
    DECLARE @strModId VARCHAR(2);
    DECLARE @dblAnticipoMoneda DECIMAL(24,12);
    DECLARE @varTdoId VARCHAR(50);
    DECLARE @strExportadoAlFiscal VARCHAR(1);
    DECLARE @varRespId VARCHAR(50);
    DECLARE @varReferenciaDevolucion VARCHAR(50);
    DECLARE @dblDescuentoArticulo DECIMAL(24,12);
    DECLARE @varSucId VARCHAR(50);
    DECLARE @intCntRegistros int ;
    DECLARE @booExistenciaMenor BIT;
    DECLARE @artId_cur VARCHAR(50);
    DECLARE @pvdDescripcion_cur  VARCHAR(300);
    DECLARE @pvdCantidadEntregada_cur DECIMAL(24,12);
    DECLARE @uniId_cur VARCHAR(50);
    DECLARE @strTipoArticulo VARCHAR(1);
    DECLARE @dblExistenciaPorArticulo  DECIMAL(24,12);
	DECLARE @booPveIdSinIT BIT;
	DECLARE @strArtIdNegativo VARCHAR(50);
	DECLARE @strArtIdFracionado VARCHAR(50);
	DECLARE @strArtId VARCHAR(50);
	DECLARE @dblDIferencias DECIMAL(24,12);
	DECLARE @flgGeneraCtaCte BIT ;
	DECLARE @dblGnpIva DECIMAL(24,12);
	DECLARE @dblGnpIT DECIMAL(24,12);
	DECLARE @booItgIn BIT;
    DECLARE @booItgCc BIT; 
	DECLARE @booItgCj BIT;
    DECLARE @booItgCt BIT;
    DECLARE @booItgBn BIT ; 
	DECLARE @booItSl BIT;
	DECLARE @booItgIp BIT;
	DECLARE @booItgCn BIT;
	DECLARE @strDescripcion VARCHAR(200);
	DECLARE @strCajId VARCHAR(50);
	DECLARE @strRespId VARCHAR(50);
	DECLARE @strTipoDocumentoSoloCosto VARCHAR(50);
	DECLARE @dblOtrosAnticiposMoneda DECIMAL(24,12);
	DECLARE @strFpagoDefault VARCHAR(50);
	DECLARE @dirNroDiasCliente INT;
	DECLARE @fchFechaReferencia DATETIME;
	DECLARE @strMonIdC VARCHAR(50);
	DECLARE @modQueFechaAprobacion VARCHAR(1);
	DECLARE @intVerdadero INT;
	DECLARE @strConFacturaPos VARCHAR(1);
	DECLARE @strpveIdSinITDelParametro  VARCHAR(50);	
	DECLARE @canId_RS VARCHAR(50);
    DECLARE @ttxId_RS VARCHAR(50);
    DECLARE @tdoId_RS VARCHAR(50);
    DECLARE @proId_RS VARCHAR(50);
    DECLARE @tcaImporteMoneda_RS DECIMAL(24,12);
    DECLARE @TotalDetalle_RS DECIMAL(24,12);
    DECLARE @fptMontoMoneda_RS DECIMAL(24,12);
    DECLARE @monId_RS VARCHAR(50);	
    DECLARE @strvntIdRelacionConDevoluciones  VARCHAR(50);
	DECLARE @dblMontoC DECIMAL(24,12);	
    DECLARE @dblMontoP DECIMAL(24,12);	
    DECLARE @strpveSinIT VARCHAR(1);
    DECLARE @strSucId VARCHAR(50);
    DECLARE @itgGenera_RS BIT;
    DECLARE @modIdDestino_RS VARCHAR(50);
    DECLARE @strMonIdP VARCHAR(50);
    DECLARE @intConFactura BIT;
    DECLARE @intFalso INT;
    DECLARE @intDiasAño INT;
    DECLARE @tdoIdNoGeneraCn VARCHAR(50);
    DECLARE @flgIntegra BIT;
    DECLARE @strIntegracionIngresosAplicacion VARCHAR(1);
    DECLARE @vnpIntegracionContableAplicacion VARCHAR(1);
    DECLARE @strProidValidacion VARCHAR(50);
    DECLARE @strProIdPveId VARCHAR(50);
    DECLARE @strCaIdValidacion VARCHAR(50);
    DECLARE @proId VARCHAR(50);
    DECLARE @caId VARCHAR(50); 
    DECLARE @dblTcMoMp DECIMAL(24,12);
    DECLARE @dblTcMcMp DECIMAL(24,12);
    DECLARE @vnpCargarComponentesDetalleVenta VARCHAR(1); 
    DECLARE @dblPorcDescuentoArticulo DECIMAL(24,12);
    DECLARE @booAsientoPrevision BIT;
    DECLARE @modEstado VARCHAR(1); 
    DECLARE @strTipoTxnCa VARCHAR(50); 
    DECLARE @strOrigenCa VARCHAR(50); 
    DECLARE @strDestinoCa VARCHAR(50); 
    DECLARE @dblPorDescuento DECIMAL(24,12);
    DECLARE @dblTotal DECIMAL(24,12);
    DECLARE @strTxnIdCa VARCHAR(50);
    DECLARE @modIdDestino VARCHAR(50);
    DECLARE @strCaIdPveId VARCHAR(50);
    DECLARE @strtdoIdPveId VARCHAR(50);
    DECLARE @strConF VARCHAR(1);
    DECLARE @booAnulaTxn BIT;
    DECLARE @vntCorrelativoTxn VARCHAR(50);
    DECLARE @strTipoDescuento VARCHAR(50);
    DECLARE @varObligaSucursal VARCHAR(1);
    DECLARE @strCorrelativoActivado VARCHAR(1);
    DECLARE @strCorrelativoDigitoPor VARCHAR(1);
    DECLARE @strCorrelativoPor VARCHAR(1);
    DECLARE @strCorrelativoTipoPor VARCHAR(1);
    DECLARE @strTxnIn VARCHAR(50);
    DECLARE @strEntidadRelacion VARCHAR(50);
    DECLARE @sucId VARCHAR(50);
    DECLARE @strDigitoInicial VARCHAR(1);
    DECLARE @strNuevoCorrelativo VARCHAR(50);
    DECLARE @intCorrelativoDigitoCantidad INT;
    DECLARE @strSoloCostoArticulo VARCHAR(1);
    DECLARE	@strGeneraFacturaAlAprobar VARCHAR(1);
    DECLARE @booConDFR BIT;
    DECLARE @dblDFRMonto DECIMAL(24,12);
    DECLARE @strGnpValidaNitMontoMinimo VARCHAR(1);
    DECLARE @dblGnpMontoMinimoValidaNit DECIMAL(24,12);
    DECLARE @dblMontoFacturaEnBs DECIMAL(24,12);
    DECLARE @strVntRazonSocial VARCHAR(50);
    DECLARE @strVntRuc VARCHAR(50);
   declare @strArtIdVENConSOl VARCHAR(50)=''
	declare @strArtIdCantEntrEnVEN VARCHAR(50)=''
    --Dim strValidaBancarizacion As String 'dj25102015
    DECLARE @strValidaBancarizacion VARCHAR(50); 
    --Dim strValidaPorcentajeAntiEnPro As String 'dj25102015
    DECLARE @strValidaPorcentajeAntiEnPro VARCHAR(50);
    --Dim dblPorcAnticipoEnPro As Double 'dj25102015
	DECLARE @dblPorcAnticipoEnPro DECIMAL(24,12);
    --Dim dblMontoLimBancarizacion As Double 'dj25102015
    DECLARE @dblMontoLimBancarizacion DECIMAL(24,12);
    --Dim dblMontoVentasNetas As Double 'dj25102015
    DECLARE @dblMontoVentasNetas DECIMAL(24,12);
    --Dim intCntReg As Integer 'dj25102015
    DECLARE @intCntReg INT;
    --Dim dblMontoFPagoPro As Double 'dj25102015
    DECLARE @dblMontoFPagoPro DECIMAL(24,12);
    --Dim dblMontoBaseVenta As Double 'dj25102015
    DECLARE @dblMontoBaseVenta DECIMAL(24,12);
    --Dim dblPorcentajeFpago As Double 'dj25102015
    DECLARE @dblPorcentajeFpago DECIMAL(24,12);
    
    declare @strmdeId VARCHAR(50)='' --dj20161216
	declare @strObligaMotivoDevolucion VARCHAR(1)
	declare @strActualizaFechaActual VARCHAR(1)--20161219
	declare @datFechaActual datetime 
	--Comisiones INI
	DECLARE @dblMontoComision DECIMAL(24,12)
	DECLARE @varStatus VARCHAR(50)
	DECLARE @dblResultado DECIMAL(24,12)
	DECLARE @intResultado INT
	DECLARE @dblPorcentajeGeneral DECIMAL(24,12)
	DECLARE @dblPorcentajeComision DECIMAL(24,12)
	DECLARE @dblNumeroCuotas DECIMAL(24,12)
	DECLARE @varResultado VARCHAR(500)
	DECLARE @strTipoComision VARCHAR(50)
	DECLARE @strComisionMomento VARCHAR(50)
	DECLARE @varOrigenComision VARCHAR(50)
	DECLARE @varAlmId VARCHAR(50)
	DECLARE @booResultado BIT
	DECLARE @strValidaExistenciaEnPro VARCHAR(50)
	--Comisiones FIN
		
    DECLARE @boovntDevolucionNDC BIT;
    BEGIN TRY
		-- VALIDA PARAMETROS
		--IF (LEN(@strCabId) = 0 OR @strCabId IS NULL) BEGIN
		--	SET @strMensajeError = @strNombreParamSP + ' ERROR: cabId debe existir';
		--	RAISERROR (@strMensajeError, 16, 1);
		--	---- THROW 51000, @strMensajeError, 1;
		--END;
		SET @intVerdadero = 1;
		SET @strEstado  = '';
		SET @strMonId  = '';
		SET @dblTotalMoneda  = 0;
		SET @strTipoTxnVn  = '';
		SET @strCliId  = '';
		SET @strPveId  = '';
		SET @dblTC  = 0;
		SET @dblDescuentoMoneda  = 0;
		SET @dblRecargoMoneda  = 0;
		SET @strVenId  = '';
		SET @dblArticuloMoneda  = 0;
		SET @varDescripcion  = '';
		SET @strTdoId  = '';
		SET @strModId  = '';
		SET @dblAnticipoMoneda  = 0;
		SET @varTdoId  = '';
		SET @strExportadoAlFiscal  = '';
		SET @varRespId  = '';
		SET @varReferenciaDevolucion  = '';
		SET @dblDescuentoArticulo  = 0;
		SET @varSucId  = '';
		SET @artId_cur  = '';
		SET @pvdDescripcion_cur   = '';
		SET @pvdCantidadEntregada_cur  = 0;
		SET @uniId_cur  = '';
		SET @strTipoArticulo  = '';
		SET @dblExistenciaPorArticulo   = 0;
		SET @strArtIdNegativo  = '';
		SET @strArtIdFracionado  = '';
		SET @strArtId  = '';
		SET @dblDIferencias  = 0;
		SET @dblGnpIva  = 0;
		SET @dblGnpIT  = 0;
		SET @strDescripcion  = '';
		SET @strCajId  = '';
		SET @strRespId  = '';
		SET @strTipoDocumentoSoloCosto  = '';
		SET @dblOtrosAnticiposMoneda  = 0;
		SET @strFpagoDefault  = '';
		SET @strMonIdC  = '';
		SET @modQueFechaAprobacion  = '';
		SET @strConFacturaPos  = '';
		SET @strpveIdSinITDelParametro   = '';	
		SET @canId_RS  = '';
		SET @ttxId_RS  = '';
		SET @tdoId_RS  = '';
		SET @proId_RS  = '';
		SET @tcaImporteMoneda_RS  = 0;
		SET @TotalDetalle_RS  = 0;
		SET @fptMontoMoneda_RS  = 0;
		SET @monId_RS  = '';	
		SET @strvntIdRelacionConDevoluciones   = '';
		SET @dblMontoC  = 0;	
		SET @dblMontoP  = 0;	
		SET @strpveSinIT  = '';
		SET @strSucId  = '';
		SET @modIdDestino_RS  = '';
		SET @strMonIdP  = '';
		SET @tdoIdNoGeneraCn  = '';
		SET @strIntegracionIngresosAplicacion  = '';
		SET @vnpIntegracionContableAplicacion  = '';
		SET @strProidValidacion  = '';
		SET @strProIdPveId  = '';
		SET @strCaIdValidacion  = '';
		SET @proId  = '';
		SET @caId  = ''; 
		SET @dblTcMoMp  = 0;
		SET @dblTcMcMp  = 0;
		SET @vnpCargarComponentesDetalleVenta  = ''; 
		SET @dblPorcDescuentoArticulo  = 0;
		SET @modEstado  = ''; 
		SET @strTipoTxnCa  = ''; 
		SET @strOrigenCa  = ''; 
		SET @strDestinoCa  = ''; 
		SET @dblPorDescuento  = 0;
		SET @dblTotal  = 0;
		SET @strTxnIdCa  = '';
		SET @modIdDestino  = '';
		SET @strCaIdPveId  = '';
		SET @strtdoIdPveId  = '';
		SET @strConF  = '';
		SET @vntCorrelativoTxn  = '';
		SET @strTipoDescuento  = '';
		SET @varObligaSucursal  = '';
		SET @strCorrelativoActivado  = '';
		SET @strCorrelativoDigitoPor  = '';
		SET @strCorrelativoPor  = '';
		SET @strCorrelativoTipoPor  = '';
		SET @strTxnIn  = '';
		SET @strEntidadRelacion  = '';
		SET @sucId  = '';
		SET @strDigitoInicial  = '';
		SET @strNuevoCorrelativo  = '';
		SET @strSoloCostoArticulo  = '';
		SET @dblDFRMonto =0;
		SET @strGnpValidaNitMontoMinimo = '';
		SET @dblGnpMontoMinimoValidaNit = 0;
		SET @dblMontoFacturaEnBs = 0;
		SET @strVntRazonSocial = '';
		SET @strVntRuc = '';
		DECLARE @strFPagoMonto0 VARCHAR(50);
		SET @strFPagoMonto0 ='';
		DECLARE @intNroFPago INT;
		SET @intNroFPago=0;
		
		declare  @pvePermitirVENConSol VARCHAR(1) =''
		declare @vnpValidarCantEntrEnVEN VARCHAR(1) =''
		--IF (LEN(@strEstado) = 0 OR @strEstado IS NULL) BEGIN
		--	SET @strMensajeError = @strNombreParamSP + ' ERROR: cabEstado debe existir';
		--	RAISERROR (@strMensajeError, 16, 1);
		--	---- THROW 51000, @strMensajeError, 1;
		--END;				
	DECLARE @CAD VARCHAR(50),@dblRecargo2s DECIMAL(24,12),@dblRecargo3s DECIMAL(24,12),@dblRecargo4s DECIMAL(24,12)
    select @CAD=ISNULL(vnpRecargoItemsAsumido,'N') from vntParametro
    If @CAD = 'E' BEGIN
       select @dblRecargo2s=ISNULL(sum(pvdRecargo),0) from vntDetTxn where vntId=@strvntId
       select @dblRecargo3s=ISNULL(sum(tcuImporte),0) from vntTxnCuentaRecargo where vntId=@strvntId
       SELECT @dblRecargo4s=ISNULL(SUM(CASE WHEN f.monid=c.monid THEN f.fptMontoMoneda WHEN f.monid='DOL' THEN F.fptMontoMoneda*C.vntTC 
            ELSE F.fptMontoMoneda/C.vntTC END),0)FROM vntFPagoTxn f INNER JOIN vntTxn AS c ON c.vntId=f.vntId WHERE FPTTIPORECARGO=1 AND C.vntId=@strvntId
       If @dblRecargo2s <> @dblRecargo3s BEGIN            
			SET @strMensajeError = @strNombreParamSP + ' Error no cuadra recargo con los montos de aplicación de recargo..';
			RAISERROR (@strMensajeError, 16, 1);
       END
       Else If @dblRecargo4s <> @dblRecargo2s BEGIN     
			SET @strMensajeError = @strNombreParamSP + ' Error no cuadra recargo con los montos de de forma de pago de recargo..';
			RAISERROR (@strMensajeError, 16, 1);
       END
       Else If(SELECT ISNULL(ctaIdProveedor,'')from vntTxn where vntId=@strvntId) = '' AND @dblRecargo2s<>0 BEGIN
			SET @strMensajeError = @strNombreParamSP + ' Error no ingreso la cta Proveedor, en Aplicacion Recargo..';
			RAISERROR (@strMensajeError, 16, 1);
       End  
    END;
			SET @strNombreParamSP = 'vmaApruebaTxn - ' + ISNULL(@strvntId,'');
		-- PROCESOS, TRANSACCIONALES SI EL QUE LLAMA INICIO TXN
		--Function vmaApruebaTxn(strvntId As String) As Integer
			  set @pvePermitirVENConSol= ( select top 1 pvePermitirVENConSol  from   gntPuntoVenta as P inner join gntDirectorioLogin as D  on P.dirId=D.dirId where logUsuario=SYSTEM_USER)
			  set @pvePermitirVENConSol=ISNULL(@pvePermitirVENConSol,'N')
			  set @vnpValidarCantEntrEnVEN = (select top 1 vnpValidarCantEntrEnVEN from vntParametro)
			  set @vnpValidarCantEntrEnVEN=isnull(@vnpValidarCantEntrEnVEN,'N')
			  
			  -- dj20161219
				set @strActualizaFechaActual=(select top 1  vnpActualizaFechaActual from vntParametro with (nolock))
				set @strActualizaFechaActual=ISNULL(@strActualizaFechaActual,'N')
				set @datFechaActual=GETDATE()
			  --dj20161216
			  set @strObligaMotivoDevolucion=(select top 1 vnpObligaMotivoDevolucion from vntParametro)
			  set @strObligaMotivoDevolucion=ISNULL( @strObligaMotivoDevolucion,'N')
		
			  SET @strGeneraFacturaAlAprobar = ISNULL((SELECT vnpGeneraFacturaAlAprobar FROM vntParametro WHERE 1 = 1),'N');
		
			  SET @strValidaBancarizacion = (SELECT vnpValidarBancarizacion FROM vntParametro WHERE 1 = 1)
			  SET @strValidaPorcentajeAntiEnPro = (SELECT isnull(vnpValidarPorcAnticipoEnPRO,'N') FROM vntParametro WHERE 1=1) 
			  SET @dblPorcAnticipoEnPro = (SELECT vnpPorcAnticipoEnPRO FROM vntParametro WHERE 1 = 1)
	
			  EXEC CargarMonedaCentral @strMonIdC OUTPUT;
		      EXEC CargarMonedaParalela @strMonIdP OUTPUT;
		      SET @booAsientoPrevision = 0;
		      SELECT @strEstado = vntEstado , @strMonId = monId , @dblTotalMoneda = vntTotalMoneda ,
					 @strTipoTxnVn = ttxid , @strCliId = cliId, @strPveId = pveId , @fchFechaDoc = vntFechaDoc ,
					 @dblTC = vntTC , @dblDescuentoMoneda = vntDescuentoMoneda , @dblRecargoMoneda = vntRecargoMoneda , 
					 @flgConFactura = vntconFactura , @strVenId = venId , @dblArticuloMoneda = vntArticuloMoneda , 
					 @varDescripcion = vntDescripcion, @strTdoId = tdoId, @strModId = modId , 
					 @dblAnticipoMoneda = isnull(vntAnticipoMoneda,0), 			 					 
					 @dblOtrosAnticiposMoneda = isnull(vntOtrosAnticipos,0),					 
					 @varTdoId = tdoId, 
					 @strExportadoAlFiscal = vntExportadoAlFiscal , @varRespId = respId , 
					 @varReferenciaDevolucion = vntReferencia , @dblDescuentoArticulo = vntDescuentoArticulo, 
					 @varSucId = sucId,  @dblDFRMonto=vntDFRMonto, @booConDFR=vntConDFR,@strmdeId=mdeId,@boovntDevolucionNDC=vntDevolucionNDC
		      FROM vntTxn WHERE vntId LIKE @strvntId
			  
		      IF @@ROWCOUNT = 0 BEGIN
					SET @strMensajeError = @strNombreParamSP + ' ERROR: No existe la transaccion en el sistema con el codigo mencionado';
					RAISERROR (@strMensajeError, 16, 1);
					---- THROW 51000, @strMensajeError, 1;
		      END ;
		
			  IF @strEstado <> 'R' BEGIN	
				  SET @strMensajeError = @strNombreParamSP + ' ERROR: NO ESTA EN REVISION';
				  RAISERROR (@strMensajeError, 16, 1);
				  ---- THROW 51000, @strMensajeError, 1;
			  END;
			  ---dj20161216---------
			  if @strObligaMotivoDevolucion like 'S' and @strTipoTxnVn like 'DVE' begin
				if LEN(isnull(@strmdeId,''))=0  begin
					SET @strMensajeError = @strNombreParamSP + ' ERROR: Debe Ingresar el motivo de la devolucion';
					RAISERROR (@strMensajeError, 16, 1);
					-- THROW 51000, @strMensajeError, 1;
				end
			  end 
			  ---ic20200619 YOBANA---------
			  if isnull(@boovntDevolucionNDC,0)=0 and @strTipoTxnVn like 'DVE' begin
				if (SELECT CASE WHEN vntConDFR=1 AND(vntNroFactura >0) THEN 1 ELSE 0 END FROM vntTxn WHERE vntid=@varReferenciaDevolucion)=1  begin
					SET @strMensajeError = @strNombreParamSP + ' ERROR: La Venta tiene facturas regularizadas en Impuestos. Y no aprueba la Devolución';
					RAISERROR (@strMensajeError, 16, 1);
					-- THROW 51000, @strMensajeError, 1;
				end
			  end 
			  ----------------------
			  if @strActualizaFechaActual like 'S' begin
					  ---validar --dj20161219----------------------------
					  declare @intDifereciaFecha int
					  set @intDifereciaFecha= DATEDIFF(day,@fchFechaDoc,@datFechaActual)
					  if @intDifereciaFecha<>0 begin
						  ---actualizar la fecha  a la actual
						  declare @datFechaTxn date
						  set @datFechaTxn=@fchFechaDoc
						  set  @fchFechaDoc=CAST( @datFechaActual as date)
						  ------------------------------------
						  update vntTxn set vntFechaDoc=@fchFechaDoc where vntId like @strvntId
						  update vntFPagoTxn  set fpaFechaReferencia=  DATEADD(DAY,DATEDIFF(day,@datFechaTxn,@datFechaActual),fpaFechaReferencia) from vntFPagoTxn where vntId like @strvntId and DATEDIFF(day,fpaFechaReferencia,@datFechaActual)<>0
					  end 
			  
			  end
		
			  IF LEN(ISNULL(@varSucId,''))=0 BEGIN
				  SET @varSucId=ISNULL( (SELECT sucId FROM gntPuntoVenta WHERE pveId LIKE  ISNULL(@strPveId,'')),'');
			  END;
		
		--    'Validar que el Precio No sea Cero dj-07-05-2014
			  SET @intCntRegistros= (SELECT COUNT(*) FROM vntDetTxn WHERE vntId LIKE  @strvntId   and  pvdPrecioMoneda=0);
			  IF @intCntRegistros >0 BEGIN
				  SET @strMensajeError = @strNombreParamSP + ' ERROR: Existen articulos con Precio 0 ,Revise el detalle de la transaccion';
				  RAISERROR (@strMensajeError, 16, 1);
				  ---- THROW 51000, @strMensajeError, 1;
			  END ;
			  
			  --validar transacciones de ventas  con solicitud
			  if @pvePermitirVENConSol='N'  begin
					if @strTipoTxnVn='VEN' begin
						
						set @strArtIdVENConSOl=( select top 1 isnull(codBarra,artId) from vntDetTxn as D where vntId=@strvntId and isnull(pvdConSolicitud,'N')='S')
						set @strArtIdVENConSOl=ISNULL(@strArtIdVENConSOl,'')
						if len(@strArtIdVENConSOl)> 0 begin
							SET @strMensajeError = @strNombreParamSP + ' ERROR: El articulo con codigo ' +  @strArtIdVENConSOl + ' esta con solicitud'
							RAISERROR (@strMensajeError, 16, 1);
							-- THROW 51000, @strMensajeError, 1;
						end 
					end 
			  end 
			  
			  ---validar cantidad entregada en cero
			  
			  if @vnpValidarCantEntrEnVEN='S' and @strTipoTxnVn='VEN' begin
				
				set @strArtIdCantEntrEnVEN= (SELECT TOP 1 ISNULL(vntDetTxn.codBarra, vntDetTxn.artId) FROM vntDetTxn LEFT JOIN intArticulo ON vntDetTxn.artId=intArticulo.artId   WHERE vntDetTxn.vntId LIKE @strvntId  AND intArticulo.artTipo <>'S' AND isnull(vntDetTxn.pvdCantidadEntregada,0)=0)
				set @strArtIdCantEntrEnVEN=ISNULL(@strArtIdCantEntrEnVEN,'')
				if len(@strArtIdCantEntrEnVEN)> 0   begin
					SET @strMensajeError = @strNombreParamSP + ' ERROR: El articulo con codigo ' +  @strArtIdCantEntrEnVEN + ' tiene  una cantidad Entregada en 0'
					RAISERROR (@strMensajeError, 16, 1);
					-- THROW 51000, @strMensajeError, 1;
				end 
			  end 
			  	EXECUTE	vmaValidarAlmacenConSolicitud 
														@strTipoTxn =@strTipoTxnVn,
														@strVntId=@strTipoTxnVn
				  -----DJ20161223---
			    EXECUTE vmaValidaAnticipoEnSolicitudes 
														@vntId =@strvntId,
														@monId =@strMonId,
														@vntTc =@dblTC,
														@ttxId =@strTipoTxnVn,
														@pveId =@strPveId,
														@cliente =@strCliId										
		--    'Validacion de cantidad  Vendida sea >=0 solicitado por sanddra esscalante dj-07-2014
			IF (@strTipoTxnVn = 'PRO' AND (select vnpValidaExistenciaEnProforma from vntparametro ) = 'S')
			BEGIN
			  SET @strArtIdNegativo=ISNULL((SELECT  TOP 1 artId  FROM vntDetTxn WHERE  vntId like  @strvntId AND pvdCantidadVendida <=0),'');
			  IF LEN(@strArtIdNegativo)>0 BEGIN
		--        vmaApruebaTxn = ErrMensajeMudo
				  SET @strMensajeError = @strNombreParamSP + ' ERROR : El Articulo con codigo ' + @strArtIdNegativo +' Tiene una Cantidad Vendida Negativa';
				  RAISERROR (@strMensajeError, 16, 1);
				  ---- THROW 51000, @strMensajeError, 1;
			  END ;
			END
			IF (@strTipoTxnVn = 'VEN')
			BEGIN
			  SET @strArtIdNegativo=ISNULL((SELECT  TOP 1 artId  FROM vntDetTxn WHERE  vntId like  @strvntId AND pvdCantidadVendida <=0),'');
			  IF LEN(@strArtIdNegativo)>0 BEGIN
		--        vmaApruebaTxn = ErrMensajeMudo
				  SET @strMensajeError = @strNombreParamSP + ' ERROR : El Articulo con codigo ' + @strArtIdNegativo +' Tiene una Cantidad Vendida Negativa';
				  RAISERROR (@strMensajeError, 16, 1);
				  ---- THROW 51000, @strMensajeError, 1;
			  END ;
			END
		--    'Validacion de Cantidad Fraccionada -----dj-13-10-2014
		--    '--Cantidad vendida
			  SET @strArtIdFracionado=ISNULL(( select TOP 1 D.artId from vntDetTxn  as D  inner join intArticulo as A on A.artId = D.artId WHERE vntId LIKE @strvntId  AND A.artFraccionado LIKE 'N' and ABS(pvdCantidadVendida - CAST(pvdCantidadVendida as bigint)) >0.001),'');
			  IF LEN(@strArtIdFracionado) >0 BEGIN
		--        vmaApruebaTxn = ErrMensajeMudo
				  SET @strMensajeError = @strNombreParamSP + ' ERROR : El articulo  con codigo ' + @strArtIdFracionado +' No puede ser Fraccionado';
				  RAISERROR (@strMensajeError, 16, 1);
				  ---- THROW 51000, @strMensajeError, 1;
			  END ;
		
			  SET @strArtId=ISNULL((SELECT D.artId FROM vntDetTxn  AS D  inner join intArticulo AS A ON A.artId = D.artId WHERE vntId LIKE @strvntId AND A.artFraccionado LIKE 'N' AND ABS(pvdCantidadEntregada - CAST(pvdCantidadEntregada as bigint)) >0.001),'');
		--    If Len(Nz(varResultado, "")) > 0 Then
		      IF LEN(@strArtId)>0 BEGIN
				  SET @strMensajeError = @strNombreParamSP + 'ERROR : El articulo  con codigo ' + @strArtId +' No dispone de saldo para entregar';
				  RAISERROR (@strMensajeError, 16, 1);
				  ---- THROW 51000, @strMensajeError, 1;
			  END;
		
		     ----------------------------------------------------------------------------------
		     
		     IF @strTipoTxnVn in ('VEN','VAF')  BEGIN
				 DECLARE @strArtIdSinExi VARCHAR(50)='';
				 DECLARE @decCantidadExi DECIMAL(24,12);
				 declare @pveGeneraSolVentaSinExistencia VARCHAR(1)=''
				 SET @decCantidadExi =0
				 
				 
				 set @pveGeneraSolVentaSinExistencia=(SELECT pveGeneraSolVentaSinExistencia FROM gntPuntoVenta where  pveId like @strPveId)
				 IF @pveGeneraSolVentaSinExistencia LIKE 'N' BEGIN
					 SELECT @strArtIdSinExi=artId,@decCantidadExi=Saldo FROM 
											(
												SELECT TOP 1 ALM,T.artId,(isnull(E.exiExistencia,0) - Cantidad) as Saldo  FROM 
												(
													select ALM,A.artId,dbo.infConvierteEquivalencia(D.uniId,A.uniId,CantidaEntrega) as Cantidad from (
																		SELECT pvdDescripcion as ALM ,D.artId,D.uniId ,sum(D.pvdCantidadVendida) as CantidaEntrega  FROM vntDetTxn as d WHERE vntId like  @strVntId and  pvdCantidadVendida > 0 and pvdConSolicitud like 'N'
																		group by  pvdDescripcion,D.artId,D.uniId
																   ) AS D inner join intArticulo  as A on D.artId=A.artId   where A.artTipo <>'S'
												) AS T LEFT JOIN intExistencia AS E on T.ALM=E.almId and T.artId=E.artId where  (isnull(E.exiExistencia,0) - Cantidad) <0 
											) AS tt
					IF @@ROWCOUNT > 0 BEGIN
						SET @strMensajeError = @strNombreParamSP + 'ERROR : el punto de venta no puede  vender articulos sin existencia por ejm ' + ISNULL(@strArtIdSinExi,'');
						RAISERROR (@strMensajeError, 16, 1);
						-- THROW 51000, @strMensajeError, 1;
					END;
				END;
			 END ;
		     -----------------------------------------------------------------------------------

		--    'PAT 02-05-14 Valida que las cantidad Entregada sea menor a la Existencia del Articulo
		
			  SET  @booExistenciaMenor = 0;
		
		      IF @strTipoTxnVn = 'VEN' Or @strTipoTxnVn = 'PRO' Or @strTipoTxnVn = 'VAF' BEGIN
	
                  set @strValidaExistenciaEnPro = (SELECT isnull(vnpValidarExistenciaEnProforma,'N') FROM vntParametro)
                  If @strTipoTxnVn <> 'PRO' begin
                       set @strValidaExistenciaEnPro = 'S'
                  End 
             IF @strValidaExistenciaEnPro='S' BEGIN 
				  DECLARE cur_ValidarExistencia CURSOR LOCAL  FOR SELECT artId,pvdDescripcion ,pvdCantidadEntregada,uniId 
																  FROM vntDetTxn 
																  WHERE vntId LIKE @strvntId and pvdCantidadEntregada > 0 ;
				  OPEN  cur_ValidarExistencia;
				  FETCH NEXT FROM cur_ValidarExistencia  INTO @artId_cur,@pvdDescripcion_cur ,@pvdCantidadEntregada_cur,@uniId_cur ;
		
				  WHILE @@FETCH_STATUS = 0 BEGIN
					  SET @strTipoArticulo= ISNULL((SELECT TOP 1 artTipo FROM intarticulo WHERE artId LIKE @artId_cur),'');
		
					  IF @strTipoArticulo ='I' BEGIN
						  SET @pvdDescripcion_cur = ISNULL(@pvdDescripcion_cur,'');	
						  EXECUTE vmaExitencia @strPveId , @pvdDescripcion_cur , @artId_cur , @uniId_cur , @dblExistenciaPorArticulo OUTPUT 
		
						  IF  CAST ( ISNULL(@pvdCantidadEntregada_cur,0) AS DECIMAL(24,12))> @dblExistenciaPorArticulo BEGIN
		
							  SET @booExistenciaMenor = 1;
		
					      END;
		
					  END;
		
					  FETCH NEXT FROM cur_ValidarExistencia  INTO @artId_cur,@pvdDescripcion_cur ,@pvdCantidadEntregada_cur,@uniId_cur ;
				  END;
		
				  CLOSE cur_ValidarExistencia;
				  DEALLOCATE cur_ValidarExistencia;
		END
				  IF @booExistenciaMenor = 1 BEGIN
				     SET @strMensajeError = @strNombreParamSP + ' ERROR : Existen artículos con cantidades entregadas mayores a la existencia en almacen';
					 RAISERROR (@strMensajeError, 16, 1);
					  ---- THROW 51000, @strMensajeError, 1;
				  END;
		
		      END;
		--    No Puede aprobar Txn Venta con Forma Pago 0 PB -22-10-2015 ini
			SELECT  @intNroFPago= COUNT(*) FROM vntFPagoTxn WHERE vntId LIKE @strvntId;
			IF @intNroFPago>0 BEGIN
				SELECT @strFPagoMonto0=vntId FROM vntFPagoTxn  WHERE vntId LIKE @strvntId AND  fptMontoMoneda =0;
				IF len(@strFPagoMonto0) > 0 BEGIN
				   	SET @strMensajeError = @strNombreParamSP + 'Cancelado: No Puede Tener un Monto 0 en la Forma de Pago...';
					RAISERROR (@strMensajeError, 16, 1);
					---- THROW 51000, @strMensajeError, 1;                   	
				END;
			END;

		--    'Valida que la txn no tenga cantidades en cero
		
		      SET @strArtId = ISNULL((SELECT TOP 1  artId FROM vntDetTxn WHERE vntId LIKE @strvntId  AND pvdCantidadVendida = 0 ),'')
		
			  IF LEN(@strArtId)>0 BEGIN 
		
				  SET @strMensajeError = @strNombreParamSP + ' ERROR : Existen detalles con cantidad vendida en cero... Artículo: ' + @strArtId;
				  RAISERROR (@strMensajeError, 16, 1);
				  ---- THROW 51000, @strMensajeError, 1;
			  END 
		
			   
		--    'Verifica que no tenga txns relacionadas en impuestos
		
		      SET @intCntRegistros=(SELECT COUNT(refId) As NroRegistros FROM iptFactura, iptDetTxn WHERE iptFactura.facId = iptDetTxn.facId AND facEstado <> 'X' AND refId = @strvntId)
		
			  IF @intCntRegistros>0 BEGIN
	
				  SET @strMensajeError = @strNombreParamSP + ' ERROR : Tiene una factura relacionada en el modulo de imopuestos ';
				  RAISERROR (@strMensajeError, 16, 1);
				  ---- THROW 51000, @strMensajeError, 1;
			  END ;
	
			  SET @dblDIferencias = @dblTotalMoneda - (@dblArticuloMoneda + @dblRecargoMoneda - @dblDescuentoMoneda - @dblDescuentoArticulo - @dblAnticipoMoneda)
	
			  IF ABS(@dblDIferencias) > 0.02 BEGIN
				  SET @strMensajeError = @strNombreParamSP + ' ERROR :Los Montos totales no cuadran  ';
				  RAISERROR (@strMensajeError, 16, 1);
				  ---- THROW 51000, @strMensajeError, 1;
			  END;
	
		 
		    

		--    'Valida que exista el vendedor
	
			  IF LEN(IsNull(@strVenId,'')) = 0 BEGIN
			      SET @strMensajeError = @strNombreParamSP + ' ERROR :No existe el vendedor en la transaccion ';
				  RAISERROR (@strMensajeError, 16, 1);
				  ---- THROW 51000, @strMensajeError, 1;
			  END ;
	
			  IF LEN(ISNULL(@varDescripcion,'')) = 0 BEGIN
				  SET  @strDescripcion = ' TXN GENERADA EN VENTAS ' + @strvntId;
	
			  END ELSE BEGIN
				  SET @strDescripcion = @varDescripcion;
			  END; 
		
		--    'Punto de Venta Sin IT
		
			  SET @booPveIdSinIT = 0;
		
		      SET  @strpveIdSinITDelParametro=(SELECT TOP 1   pveIdSinIT FROM vntParametro );
			  IF NOT @strpveIdSinITDelParametro IS NULL  BEGIN
				  SELECT @strpveIdSinITDelParametro=REPLACE(@strpveIdSinITDelParametro,'*','%')
	
			      IF LEN(IsNull(@strpveIdSinITDelParametro,''))>0 AND @strPveId LIKE @strpveIdSinITDelParametro BEGIN
	
					  SET @booPveIdSinIT = 1;
				  END;

			  END ELSE BEGIN

				   SET @strpveSinIT= ISNULL((SELECT pveSinIT FROM 	gntPuntoVenta WHERE pveId LIKE  @strPveId),'N');

				  IF  @strpveSinIT ='S' BEGIN
				      SET @booPveIdSinIT = 1;
				  END ;
		       END ;
	
			  
		--    'Recupera datos punto de venta
	
		      SELECT @strCajId = cajId ,@strSucId = sucId FROM gntPuntoVenta WHERE  pveId LIKE @strPveId
	
		      IF @@ROWCOUNT = 0  BEGIN
				 SET @strMensajeError = @strNombreParamSP + ' ERROR :No esta configurado la caja para el punto de venta :' + @strPveId;
				  RAISERROR (@strMensajeError, 16, 1);
				  ---- THROW 51000, @strMensajeError, 1;
			  END;
		

			  IF LEN(IsNull(@varRespId,''))=0 BEGIN
				  SET @strMensajeError = @strNombreParamSP + ' ERROR :No Existe el responsable en la transaccion';
				  RAISERROR (@strMensajeError, 16, 1);
				  ---- THROW 51000, @strMensajeError, 1;
		 
			  END ELSE BEGIN
		 
				  SET  @strRespId = @varRespId;
			  END ;
		 
			  SET @flgGeneraCtaCte=1
		 
			   IF @strSoloCostoArticulo ='S' AND LEN(@strTipoDocumentoSoloCosto)>0 BEGIN
		 
				  IF @strTipoDocumentoSoloCosto = @strTdoId  BEGIN
		 
				      SET @flgGeneraCtaCte = 0
				  END;
		 
			  END;
		 
			  
		 
			  IF  @strTipoTxnVn = 'DVE' AND @strModId = 'vn'   BEGIN
		 
				  IF LEN(ISNULL(@varReferenciaDevolucion,'')) > 0 BEGIN
					  SET @strvntIdRelacionConDevoluciones = (SELECT  TOP 1 vntId  FROM vntDetTxn
																				  WHERE  vntId = @strvntId 
																				  AND artId NOT IN (SELECT artId FROM vntDetTxn WHERE vntId  LIKE  @varReferenciaDevolucion )
															 );

				      IF LEN(ISNULL(@strvntIdRelacionConDevoluciones,''))>0 BEGIN

						  SET @strMensajeError = @strNombreParamSP + ' ERROR :Existen artículo en la devolución que no están en la venta original...';
						  RAISERROR (@strMensajeError, 16, 1);
						  ---- THROW 51000, @strMensajeError, 1;
				      END ;

				  END;

			  END;

			  SELECT TOP 1 @dblGnpIva=gnpIVA,@dblGnpIT=gnpIT,@intDiasAño = gnpDiasAno  FROM gntparametro;
			  IF @@ROWCOUNT = 0 BEGIN	
				  SET @strMensajeError = @strNombreParamSP + ' ERROR :No esta configurado el IVA  en los parametros  generales';
				  RAISERROR (@strMensajeError, 16, 1);
				  ---- THROW 51000, @strMensajeError, 1;
			  END ;
		--    'Verifica que la txn tenga monto

			  if @dblTotalMoneda <= 0 And ((@dblAnticipoMoneda + @dblOtrosAnticiposMoneda + @dblDescuentoArticulo + @dblDescuentoMoneda) < (@dblArticuloMoneda + @dblRecargoMoneda)) BEGIN
	
				  SET @strMensajeError = @strNombreParamSP + ' ERROR :El TOtal Moneda no cuadra con los anticipos , descuentos , articulo moneda  y recargos';
				  RAISERROR (@strMensajeError, 16, 1);
				  ---- THROW 51000, @strMensajeError, 1;
			  END ;
		
		--    'verifica  la integracion  de    los otros modulos
		
			  SET @booItgIn = 0;
			  SET @booItgCc = 0;
			  SET @booItgCj = 0
	
			  SET @booItgCt = 0;  
			  SET @booItgBn = 0;
			  SET @booItSl = 0;
			  SET @booItgIp = 0;
			  SET @booItgCn =0;
			  DECLARE rsFpago CURSOR LOCAL FOR SELECT itgGenera,modIdDestino FROM gntIntegracion WHERE modIdOrigen = 'vn' AND itgGenera = 1		  
			  OPEN rsFpago;
			  FETCH NEXT FROM rsFpago INTO @itgGenera_RS,@modIdDestino_RS;		
				IF @@FETCH_STATUS = 0 BEGIN		
				   WHILE @@FETCH_STATUS = 0 BEGIN			
					   IF @itgGenera_RS = 1 BEGIN 									
						  IF @modIdDestino_RS = 'in' BEGIN
							 SET @booItgIn = 1;
						  END	 
						  ELSE IF @modIdDestino_RS = 'sl' BEGIN
							  SET @booItSl = 1;
						  END	  
						  ELSE IF @modIdDestino_RS = 'cj' BEGIN
							 SET @booItgCj = 1;
						  END	 
						  ELSE IF @modIdDestino_RS = 'ct' BEGIN
							 SET @booItgCt = 1;
						  END	 
						  ELSE IF @modIdDestino_RS = 'bn' BEGIN
							 SET @booItgBn = 1;	
						  END			  
						  ELSE IF @modIdDestino_RS = 'ip' BEGIN
							 SET @booItgIp = 1;
						  END		  
						  ELSE IF @modIdDestino_RS = 'cn' BEGIN
							 SET @booItgCn = 1;
						  END
						  ELSE IF @modIdDestino_RS = 'cc' BEGIN
							 SET @booItgCn = 1;
						  END						  
					   END;	
					   FETCH NEXT FROM rsFpago INTO @itgGenera_RS,@modIdDestino_RS;
				   END;
				END   
				ELSE BEGIN
				   SET @strMensajeError = 'ERROR : NO ESTA DEFINIDA LA INTEGRACION';
				   RAISERROR (@strMensajeError, 16, 1);
				   ---- THROW 51000, @strMensajeError, 1;
				END;

				CLOSE rsFpago;
				DEALLOCATE rsFpago;
			  
			  DECLARE rsFpago2 CURSOR LOCAL FOR SELECT fptMontoMoneda,monId FROM vntFpagoTxn WHERE vntId = @strvntId AND isnull(fptTipoRecargo,0)=0
			  OPEN rsFpago2;
			  FETCH NEXT FROM rsFpago2 INTO @fptMontoMoneda_RS,@monId_RS;		
			  IF @@FETCH_STATUS <> 0 AND @dblTotalMoneda <> 0 BEGIN	
		--        'Si no tiene formas de pago, ingresa una en efectivo por el total
				  IF @strTipoTxnVn != 'PRO' BEGIN
					  SET @strFpagoDefault = (SELECT fpaid FROM gntPuntoVenta WHERE pveid LIKE @strPveId);
					  IF @strFpagoDefault = 'CONCTACTE' BEGIN
						  SET @dirNroDiasCliente = ISNULL((SELECT dirNroDiasCliente FROM gntDirectorio WHERE dirId = @strCliId),0);	
						  SET @fchFechaReferencia = DATEADD(DAY, @dirNroDiasCliente, @fchFechaDoc);
					  END	  
					  ELSE BEGIN
						  SET @fchFechaReferencia = @fchFechaDoc;
		              END;

					  IF @strFpagoDefault = 'CONCTACTE' BEGIN
						  INSERT INTO vntFPagoTxn (vntId, monId, fpaId, fpaReferencia, fpaFechaReferencia, fptMontoMoneda, fptUsuario, fptFechaCambio) VALUES
						  (@strvntId ,@strMonId ,@strFpagoDefault,@strCliId,@fchFechaReferencia,@dblTotalMoneda,SYSTEM_USER,GETDATE());	
					  END	  
		 
					  ELSE BEGIN
						  INSERT INTO vntFPagoTxn (vntId, monId, fpaId, fpaReferencia, fpaFechaReferencia, fptMontoMoneda, fptUsuario, fptFechaCambio) VALUES
						  (@strvntId ,@strMonId ,@strFpagoDefault,@strCajId,@fchFechaReferencia,@dblTotalMoneda,SYSTEM_USER,GETDATE());
					  END;

					  IF @@ERROR <> 0 BEGIN  	
						  SET @strMensajeError = 'ERROR EN GRABACION';	
						  RAISERROR (@strMensajeError, 16, 1);
						  ---- THROW 51000, @strMensajeError, 1;

					  END;

				  END;
			  END	  

			  ELSE BEGIN

				  SET @dblMontoC = 0;

				  SET @dblMontoP = 0;	
				  IF @@FETCH_STATUS = 0 BEGIN

					  WHILE @@FETCH_STATUS = 0 BEGIN

						  IF @monId_RS = @strMonIdC BEGIN

							  SET @dblMontoC = @dblMontoC + @fptMontoMoneda_RS;
							  SET @dblMontoP = @dblMontoP + (@fptMontoMoneda_RS / @dblTC);
						  END	  

						  ELSE BEGIN	

							  SET @dblMontoP = @dblMontoP + @fptMontoMoneda_RS;
							  SET @dblMontoC = @dblMontoC + (@fptMontoMoneda_RS * @dblTC);
						  END;

						  FETCH NEXT FROM rsFpago2 INTO @fptMontoMoneda_RS,@monId_RS;	

					  END;

					  CLOSE rsFpago2;

				  END;

				  DEALLOCATE rsFpago2;		

				 IF @strTipoTxnVn <> 'PRO' BEGIN

					  IF @strMonId = @strMonIdC AND @dblTotalMoneda <> @dblMontoC BEGIN
						   IF ABS(@dblTotalMoneda - @dblMontoC) > 0.02 BEGIN	
							  SET @strMensajeError = 'ERROR : MONTO DE TRANSACCION NO IGUALA A FORMA DE PAGO';
							  RAISERROR (@strMensajeError, 16, 1);
							  ---- THROW 51000, @strMensajeError, 1;
						   END;

					  END;

					  IF @strMonId = @strMonIdP AND @dblTotalMoneda <> @dblMontoP BEGIN

						  IF ABS(@dblTotalMoneda - @dblMontoP) > 0.02 BEGIN
							  SET @strMensajeError = 'ERROR : MONTO DE TRANSACCION NO IGUALA A FORMA DE PAGO';
							  RAISERROR (@strMensajeError, 16, 1);
							  ---- THROW 51000, @strMensajeError, 1;

						  END;

					  END;

				  END;

			  END;	 
			 -- 'jg 02-05-2017

				select @strGnpValidaNitMontoMinimo=gnpValidaNitMontoMinimo,@dblGnpMontoMinimoValidaNit=gnpMontoMinimoValidaNit from gntParametro;
				select @strVntRazonSocial=vntRazonSocial,@strVntRuc=vntRUC from vntTxn where vntId=@strvntId;
				IF @flgConFactura <> 0 AND @strGnpValidaNitMontoMinimo='S' BEGIN
				
					select @dblMontoFacturaEnBs=ISNULL(SUM((CASE WHEN a.monId='DOL' THEN a.fptMontoMoneda*a.vntTc ELSE a.fptMontoMoneda END)),0) from (select fpt.monId, sum(fpt.fptMontoMoneda) as fptMontoMoneda,c.vntTc from vntFPagoTxn as fpt inner join vntTxn as c on c.vntId=fpt.vntId where c.vntId=@strvntId group by fpt.monId,c.vntTc)AS a;
					IF @dblGnpMontoMinimoValidaNit <= @dblMontoFacturaEnBs AND (@strVntRazonSocial = 's/n' Or @strVntRazonSocial = 'sn' Or Len(ISNULL(@strVntRazonSocial, '')) = 0 Or @strVntRuc = '0') And @strTipoTxnVn = 'VEN' BEGIN
				 
						SET @strMensajeError = 'ERROR : Debe ingresar nit y razon social';
						RAISERROR (@strMensajeError, 16, 1);
 
					END;
 
				END;
				--'fin jg
	 

			   --verificar  saldo  en cuentas corrientes en proforma segun parametro
			 execute  vmaVerificaSaldoCtaCteEnPRO 
												 @vntId =@strvntId,
												 @ttxId=@strTipoTxnVn,
												 @strCtacte  =@strCliId,
												 @strMonId  =@strMonId,
												 @dblTc =@dblTC,
												 @strMonIdC  =@strMonIdC,
												 @strMonIdP =@strMonIdP
			  
			  
		      DECLARE rsFpago3 CURSOR LOCAL FOR SELECT SUM(txrMontoMoneda) 
												FROM vntTxnRecargo WHERE vntid = @strvntId    
			  OPEN rsFpago3;
			  FETCH NEXT FROM rsFpago3 INTO @TotalDetalle_RS; 	
			  IF @@FETCH_STATUS = 0 BEGIN	

				 IF @dblRecargoMoneda <> @TotalDetalle_RS BEGIN 

					IF ABS(@dblRecargoMoneda - @TotalDetalle_RS) > 0.02 BEGIN 

					  SET @strMensajeError = 'ERROR : MONTO RECARGO NO IGUAL A MONTO RECARGO Detalle';
					  RAISERROR (@strMensajeError, 16, 1);
					  ---- THROW 51000, @strMensajeError, 1;

					END;

				 END;

			  END;

			  CLOSE rsFpago3;

			  DEALLOCATE rsFpago3;
		--    'Verifica que el Monto Coincida con Monto de Detalles
		
			  SET @TotalDetalle_RS = (SELECT SUM(pvdPrecioMoneda * pvdCantidadVendida)
													FROM vntDetTxn WHERE vntid = @strvntId)
			 
		
			  IF @@ROWCOUNT > 0 BEGIN	
				 IF @dblArticuloMoneda <> @TotalDetalle_RS BEGIN
					If Not (@dblArticuloMoneda > 0 And @TotalDetalle_RS = 0) BEGIN
						  IF ABS(@dblArticuloMoneda - @TotalDetalle_RS) > 0.02 BEGIN
							  SET @strMensajeError = 'ERROR : MONTO NO IGUAL A MONTO DETALLE ARTICULOS';							  
							  RAISERROR (@strMensajeError, 16, 1);
							  ---- THROW 51000, @strMensajeError, 1;
						  END;	
					END;
				 END	
		
		         ELSE BEGIN 
					If (@dblTotalMoneda <> (@TotalDetalle_RS + @dblRecargoMoneda - @dblDescuentoMoneda - @dblDescuentoArticulo - @dblAnticipoMoneda)) BEGIN
		
					   SET @dblDIferencias = @dblTotalMoneda - (@TotalDetalle_RS + @dblRecargoMoneda - @dblDescuentoMoneda - @dblDescuentoArticulo - @dblAnticipoMoneda);
					  IF ABS(@dblDIferencias) > 0.02 BEGIN
 
						  IF @dblDIferencias < 0 BEGIN
		 
							  SET @strMensajeError = 'ERROR : MONTO TOTAL';
							  RAISERROR (@strMensajeError, 16, 1);
							  ---- THROW 51000, @strMensajeError, 1;
 
						  END						  
		 
						  ELSE BEGIN
							  IF @strTipoTxnVn <> 'PRO' BEGIN
								  SET @strMensajeError = 'ERROR : MONTO TOTAL';
								  RAISERROR (@strMensajeError, 16, 1);
								  ---- THROW 51000, @strMensajeError, 1;
							  END;
						  END;
	 
					  END;
		 
					END;
		 
				 END;
		 
			  END;
		 
		--    'Verifica que el Monto Coincida con Monto de Detalles
		
			  SET @TotalDetalle_RS = (SELECT SUM(pvdPrecioMoneda * pvdCantidadVendida) FROM vntDetTxn WHERE vntid = @strvntId);	

			  IF @@ROWCOUNT > 0 BEGIN	
				 IF @dblArticuloMoneda <> @TotalDetalle_RS BEGIN

					IF NOT (@dblArticuloMoneda > 0 AND @TotalDetalle_RS = 0) BEGIN
						  IF ABS(@dblArticuloMoneda - @TotalDetalle_RS) > 0.02 BEGIN
							  SET @strMensajeError = 'ERROR : MONTO NO IGUAL MONTO DETALLE ARTICULOS';
							  RAISERROR (@strMensajeError, 16, 1);
							  ---- THROW 51000, @strMensajeError, 1;
		
						  END;
		
					END;
				 END	
		
				 ELSE BEGIN
		
					If @dblTotalMoneda <> (@TotalDetalle_RS + @dblRecargoMoneda - @dblDescuentoMoneda - @dblDescuentoArticulo - @dblAnticipoMoneda - @dblOtrosAnticiposMoneda) BEGIN	
		
						 SET @dblDIferencias = @dblTotalMoneda - (@TotalDetalle_RS + @dblRecargoMoneda - @dblDescuentoMoneda - @dblDescuentoArticulo - @dblAnticipoMoneda - @dblOtrosAnticiposMoneda);
		
					  IF ABS(@dblDIferencias) > 0.02 BEGIN
		
						  IF @dblDIferencias < 0 BEGIN
		
							  SET @strMensajeError = 'ERROR : MONTO TOTAL'; 
							  RAISERROR (@strMensajeError, 16, 1);
							  ---- THROW 51000, @strMensajeError, 1;
		
						  END
		
						  ELSE BEGIN
		
							  IF @strTipoTxnVn <> 'PRO' BEGIN
		
								  SET @strMensajeError = 'ERROR : MONTO TOTAL'; 
								  RAISERROR (@strMensajeError, 16, 1);
								  ---- THROW 51000, @strMensajeError, 1;
		
							  END;	
		--                End If
						  END;
		--            End If
					  END;
		--          End If
					END;
		--       End If
				 END;
		--    End If
			  END;

			  SET @modQueFechaAprobacion = (SELECT modQueFechaAprobacion FROM gntParametroModulo WHERE modId = 'vn');	

			  IF @modQueFechaAprobacion IS NULL BEGIN	
		--        vmaApruebaTxn = ErrNoEstaDefinidaFechaAprobacion
				  SET @strMensajeError = 'ERROR : NO ESTA DEFINIDA FECHA DE APROBACION';
				  RAISERROR (@strMensajeError, 16, 1);
				  ---- THROW 51000, @strMensajeError, 1;
		--        Exit Function
		--    End If
			  END;	
		--    If varModEstado = "D" Then
			  IF @modQueFechaAprobacion = 'D' BEGIN
		--        fchFechaDoc = Date
				  SET @fchFechaDoc = GETDATE();
		--    End If
			  END;	
		--    If flgConFactura Then
			  IF @flgConFactura = 1 BEGIN	
		--        intConFactura = intVerdadero
				  SET @intConFactura = @intVerdadero;
		--        strConFacturaPos = "S"
				  SET @strConFacturaPos = 'S';
			  END	  
		--    Else	
			  ELSE BEGIN	
		--        intConFactura = intFalso
				  SET @intConFactura = @intFalso;
		--        strConFacturaPos = "N"
				  SET @strConFacturaPos = 'N';
		--    End If
			  END;
		--    '  crea transacciones a los distintos Modulos Apartir de la Forma de pago
		--     intStatus = vmaGeneraFpagoTxn(strvntId, strTipoTxnVn, dblTC, strRespId, fchFechaDoc, intDiasAño, strDescripcion, strExportadoAlFiscal, strSucId, strCliId, intConFactura, strCajId, flgGeneraCtaCte, varReferenciaDevolucion, varTdoId)
			  EXEC vmaGeneraFpagoTxn @strvntId, @strTipoTxnVn, @dblTC, @strRespId, @fchFechaDoc, @intDiasAño, @strDescripcion, @strExportadoAlFiscal, 
									@strSucId, @strCliId, @intConFactura, @strCajId, @flgGeneraCtaCte, @varReferenciaDevolucion, @varTdoId;	
		--    If intStatus <> 0 Then
		--        vmaApruebaTxn = intStatus
		--        Exit Function
		--    End If
		
		
		
		--'verificar bancarizacion dj25102015
		--	If strTipoTxnVn = "VEN" And strValidaBancarizacion = "S" Then
			If @strTipoTxnVn = 'VEN' And @strValidaBancarizacion = 'S' BEGIN		
		--		dblMontoLimBancarizacion = Nz(recuperaVariant("select top 1 ippMontoABancarizar from iptParametro "), 0)
				SET @dblMontoLimBancarizacion = (SELECT top 1 ISNULL(ippMontoABancarizar,0) FROM iptParametro)
		--		strSql = "SELECT sum(case when monId like  @monId then ventaNeta  else  case when monId like 'DOL' then ventaNeta *vntTC  else case when vntTC <>0 then ventaNeta / CAST( vnttc as decimal(24,12)) else 0 end end end )as ventaNetaMoneda  FROM"
		--		strSql = strSql & "            ("
		--		strSql = strSql & "                select  (isnull(vntArticuloMoneda,0) + ISNULL( vntRecargoMoneda,0)- isnull(vntDescuentoArticulo,0) - ISNULL( vntDescuentoMoneda,0)) as ventaNeta,monId,vntTC from vntTxn where vntId like @vntTxn"
		--		strSql = strSql & "            ) as T "
		--		strSql = Replace(strSql, "@vntTxn", "'" & strVntId & "'")
		--		strSql = Replace(strSql, "@monId", "'" & strMonIdC & "'")
		--		dblMontoVentasNetas = Nz(recuperaVariant(strSql), 0)
				SET @dblMontoVentasNetas = (SELECT sum(case when monId like  @strMonIdC then ventaNeta  else  
													   case when monId like 'DOL' then ventaNeta *vntTC  else 
													   case when vntTC <>0 then ventaNeta / CAST( vnttc as decimal(24,12)) else 0 end end end )as ventaNetaMoneda  
				                            FROM(
				                            	 select  (isnull(vntArticuloMoneda,0) + ISNULL( vntRecargoMoneda,0)- isnull(vntDescuentoArticulo,0) - ISNULL( vntDescuentoMoneda,0)) as ventaNeta,monId,vntTC 
				                            	 from vntTxn where vntId like @strVntId
				                            	 ) as T 
											)
		--		If dblMontoVentasNetas >= dblMontoLimBancarizacion Then
				If @dblMontoVentasNetas >= @dblMontoLimBancarizacion BEGIN	
		--			' validar bancarizacion
		--			strSql = ""
		--			strSql = " select COUNT(*) from vntFPagoTxn   where vntId like @vntId and  fpaId  not in ('CHEQUE','TRANSFER')"
		--			strSql = Replace(strSql, "@vntId", "'" & strVntId & "'")
		--			intCntReg = recuperaVariant(strSql)
					SET @intCntReg =(select COUNT(*) from vntFPagoTxn   where vntId like @strVntId and fpaId not in ('CHEQUE','TRANSFER'))
		--			If intCntReg > 0 Then
					IF @intCntReg > 0 BEGIN	
		--				gvarMensajeError = "El monto de la transaccion supera  el monto Limite de Bacarizacion : " & dblMontoLimBancarizacion & " BS , esta transaccion tiene que efectuacer con forma de pago cheque o transferencia"
		--				vmaApruebaTxn = ErrMensajeMudo
						SET @strMensajeError = 'El monto de la transaccion supera  el monto Limite de Bacarizacion : ' + CAST(@dblMontoLimBancarizacion AS VARCHAR) + ' BS , esta transaccion tiene que efectuacer con forma de pago cheque o transferencia';
					    RAISERROR (@strMensajeError, 16, 1);
					    ---- THROW 51000, @strMensajeError, 1;
		--				Exit Function
		--			End If
					END
		--		End If
				END
		--	End If
			END
		--	If strTipoTxnVn = "PRO" And strValidaPorcentajeAntiEnPro = "S" Then
			If @strTipoTxnVn = 'PRO' And @strValidaPorcentajeAntiEnPro = 'S' BEGIN	
		--		strSql = "SELECT count(pvdDestino) FROM vntDetTxn WHERE vntId LIKE @vntId and len(ISNULL(pvdDestino,'')) >0"
		--		strSql = Replace(strSql, "@vntId", "'" & strVntId & "'")
		--		intCntReg = Nz(recuperaVariant(strSql), 0)
				SET @intCntReg = (SELECT count(pvdDestino) FROM vntDetTxn WHERE vntId LIKE @strVntId and len(ISNULL(pvdDestino,'')) >0)
		--		If intCntReg >= 0 Then
				If @intCntReg >= 0 BEGIN	
		--			' validar el porcentaje de pagos   en la forma de pago
		--			strSql = ""
		--			strSql = "select SUM( case when VF.monId like @monId then VF.fptMontoMoneda else case  when vf.monId  like 'DOL' then  VF.fptMontoMoneda * vntTC else case when  vnttc   <>0 then  VF.fptMontoMoneda / CAST( vntTC as decimal(24,12)) else 0 end end end ) as monto from vntTxn as V inner join vntFPagoTxn as VF on V.vntId =vf.vntId where V.vntId like @vntId "
		--			strSql = Replace(strSql, "@monId", "'" & strMonId & "'")
		--			strSql = Replace(strSql, "@vntId", "'" & strVntId & "'")
		--			dblMontoFPagoPro = Nz(recuperaVariant(strSql), 0)
					SET @dblMontoFPagoPro = (select SUM( case when VF.monId like @strMonId then VF.fptMontoMoneda else case  when vf.monId  like 'DOL' then  VF.fptMontoMoneda * vntTC else case when  vnttc   <>0 then  VF.fptMontoMoneda / CAST( vntTC as decimal(24,12)) else 0 end end end ) as monto from vntTxn as V inner join vntFPagoTxn as VF on V.vntId =vf.vntId where V.vntId like @strVntId)
		--			dblMontoBaseVenta = (dblArticuloMoneda + dblRecargoMoneda) - (dblDescuentoMoneda + dblDescuentoArticulo)
					SET @dblMontoBaseVenta = (@dblArticuloMoneda + @dblRecargoMoneda) - (@dblDescuentoMoneda + @dblDescuentoArticulo)
		--			dblPorcentajeFpago = 0
					SET @dblPorcentajeFpago = 0
		--			If dblMontoBaseVenta <> 0 Then
					If @dblMontoBaseVenta <> 0 BEGIN	
		--				dblPorcentajeFpago = dblMontoFPagoPro / dblMontoBaseVenta
						SET @dblPorcentajeFpago = @dblMontoFPagoPro / @dblMontoBaseVenta
		--				If dblPorcentajeFpago < dblPorcAnticipoEnPro Then
		--				If @dblPorcentajeFpago < @dblPorcAnticipoEnPro BEGIN	
		----					gvarMensajeError = "El Porcentaje Actual de su forma de pago es : " & Round((dblPorcentajeFpago * 100), 2) & " % , tiene que ser mayor o igual al porcentaje permitido : " & dblPorcAnticipoEnPro & " %"
		----					vmaApruebaTxn = ErrMensajeMudo
		--					SET @strMensajeError = 'El Porcentaje Actual de su forma de pago es : ' + Round((@dblPorcentajeFpago * 100), 2) + ' % , tiene que ser mayor o igual al porcentaje permitido : ' + @dblPorcAnticipoEnPro + ' %';
		--					RAISERROR (@strMensajeError, 16, 1);
		--					---- THROW 51000, @strMensajeError, 1;
		----					Exit Function
		----				End If
		--				END
		--			End If
					END
		--		End If
		        END
		--	End If
			END
		--	'fin dj25102015
		
		
		
		
		--    'PAT 07-05-14 Crea Componenentes en el Detalle segun Parametro
		--    If strTipoTxnVn = "VEN" Then
			  IF @strTipoTxnVn = 'VEN' BEGIN	
		--        If Nz(recuperaRegistroSQL("vnpCargarComponentesDetalleVenta", "vntParametro", "1=1"), "N") = "S" Then
				  SET @vnpCargarComponentesDetalleVenta = ISNULL((SELECT vnpCargarComponentesDetalleVenta FROM vntParametro WHERE 1 = 1),'N');
				  If  @vnpCargarComponentesDetalleVenta = 'S' BEGIN
		--            intStatus = CrearComponentesPorArticulo(strvntId)
					  EXEC CrearComponentesPorArticulo @strvntId;
		--            If intStatus <> 0 Then
		--                vmaApruebaTxn = intStatus
		--                Exit Function
		--            End If
		--        End If
				  END;
		--    End If
			  END;	
		--    'Fin PAT
		
		--     'Genera Txn en Centro de Análisis si txn es del módulo 'PAT 07-05-14---------------------------------
		 
			  IF LEN(@strTdoId) > 0 BEGIN	
		--        'verificamos si el tipo de domuento es sin contabilidad
		 
				  SET @tdoIdNoGeneraCn = ISNULL((SELECT tdoIdNoGeneraCn FROM gntTipoTxn WHERE ttxId LIKE @strTipoTxnVn),'');
 
				  IF LEN(@tdoIdNoGeneraCn) = 0 BEGIN
		 
					  IF @tdoIdNoGeneraCn = @strTdoId BEGIN
		 
					  GOTO SINCENTROANALISIS
		--            End If
					  END;
		--        End If
				  END;
		--    End If
			  END;	

			  IF @strModId = 'VN' AND @strTipoTxnVn <> 'PRO' BEGIN	

		          SET @vnpIntegracionContableAplicacion = ISNULL((SELECT vnpIntegracionContableAplicacion FROM vntParametro WHERE 1 = 1),'N');
		
				  IF @vnpIntegracionContableAplicacion = 'S' BEGIN

					  SET @strIntegracionIngresosAplicacion = 'S';
				  END	  

				  ELSE BEGIN

					  SET @strIntegracionIngresosAplicacion = 'N';

				  END;
		--        'Verifica si está habilitada la integración in --> ca
		
				  SET @flgIntegra = ISNULL((SELECT itggenera FROM gntIntegracion WHERE modIdOrigen = 'vn' and modIdDestino = 'ca'),0);

				  IF @flgIntegra = 1 BEGIN
		--             '---Inicio dj-08-01-2014- Validacion de Centro de Analisis y el proyecto
		
						SELECT @strProidValidacion = proId , 
							   @strCaIdValidacion = canId	
						FROM gntPuntoVenta
						WHERE pveId LIKE @strPveId

						IF @@ROWCOUNT = 0 BEGIN
		
						  SET @strMensajeError = 'No esta configurado el centro de analisis y proyecto para el punto de venta ' + @strPveId;
						  RAISERROR (@strMensajeError, 16, 1);
						  ---- THROW 51000, @strMensajeError, 1;

						END;

						IF LEN(@strProidValidacion) = 0 BEGIN
	
							  SET @strMensajeError = 'No esta configurado el proyecto para el punto de venta ' + @strPveId;
							  RAISERROR (@strMensajeError, 16, 1);
							  ---- THROW 51000, @strMensajeError, 1;

						END;

						IF LEN(@strCaIdValidacion) = 0 BEGIN
		
							  SET @strMensajeError = 'No esta configurado el centro de analisis para el punto de venta ' + @strPveId;
							  RAISERROR (@strMensajeError, 16, 1);
							  ---- THROW 51000, @strMensajeError, 1;
 
						END;
		
						SET @proId = (SELECT proId FROM catProyecto WHERE proId LIKE @strProidValidacion);
 
						IF @proId IS NULL BEGIN
		
						  	  SET @strMensajeError = 'El proyecto ' + isnull(@strProidValidacion,'') + '  que tiene configurado en el punto de Venta ' + @strPveId + ' No es valido ';	
							  RAISERROR (@strMensajeError, 16, 1);
							  ---- THROW 51000, @strMensajeError, 1;
 
		                END;
		
						SET @caId = (SELECT canId FROM catCentroAnalisis WHERE canId LIKE @strCaIdValidacion);
	 
						IF @caId IS NULL BEGIN
		
							  SET @strMensajeError = 'El centro de analisis ' + @strCaIdValidacion + '  que tiene configurado en el punto de Venta ' + @strPveId + ' No es valido ';
							  RAISERROR (@strMensajeError, 16, 1);
							  ---- THROW 51000, @strMensajeError, 1;
	 
						END;
		--             '--------------fin-------
	 
					  IF @strMonId = @strMonIdC BEGIN
	 
						  SET @dblTcMoMp = @dblTC;
	 
						  SET @dblTcMcMp = @dblTC;
		 
					  END;
	 
					  IF @strMonId = @strMonIdP BEGIN	
		 
						  SET @dblTcMoMp = 1;
	 
						  SET @dblTcMcMp = @dblTC;
 
		              END;          
	 
					  IF @dblArticuloMoneda = 0 BEGIN
							SET @dblPorcDescuentoArticulo = @dblDescuentoArticulo;                          	
					  END
					  ELSE BEGIN
					       	SET @dblPorcDescuentoArticulo = @dblDescuentoArticulo / @dblArticuloMoneda;
					  END
		--             'Genera centro de analisis automatico
 
					  IF @booAsientoPrevision != 1 BEGIN
	
						  EXEC vnpCreaCentroAnalisisAutomatico @strvntId, @strTipoTxnVn, @strTdoId, @strVenId, @dblPorcDescuentoArticulo, @dblPorDescuento, @strPveId, @dblDescuentoMoneda, @dblTotalMoneda, @dblDescuentoArticulo, @dblRecargoMoneda, 
															@dblArticuloMoneda, @fchFechaDoc, @dblTC, @strMonId, @strIntegracionIngresosAplicacion, @flgConFactura, @dblGnpIva, @dblGnpIT, @booPveIdSinIT,1, @dblAnticipoMoneda;	

					  END;
		--            'Si está habilitado CA genera txn

					  SET @modEstado = (SELECT modEstado FROM adtEmpresaModulo WHERE modId = 'ca');	

					  IF @modEstado = 'A' BEGIN
		--                 'Recorre tabla xxtTxnCa

						   
			  
						   DECLARE rsCasTxn CURSOR LOCAL FOR SELECT canId,ttxId,tdoId,proId,tcaImporteMoneda 
															 FROM vntTxnCa 
															 WHERE vntId = @strvntId	
						   OPEN rsCasTxn;
						   FETCH NEXT FROM rsCasTxn INTO @canId_RS,@ttxId_RS,@tdoId_RS,@proId_RS,@tcaImporteMoneda_RS;

						   IF @@FETCH_STATUS = 0 BEGIN

							  WHILE @@FETCH_STATUS = 0 BEGIN
		--                        'Define tipo de txn a generar, Origen y Destino de la Txn
	
									 IF @strTipoTxnVn = 'DVE' BEGIN
	
										 SET @strTipoTxnCa = 'ECA';
	
										 SET @strOrigenCa = @canId_RS;
	
										 SET @strDestinoCa = @strCliId;
									 END	 
	
									 ELSE IF @strTipoTxnVn = 'PRO' OR @strTipoTxnVn = 'VEN' OR @strTipoTxnVn = 'VAF' BEGIN

										 SET @strTipoTxnCa = 'ICA';
		
										 SET @strOrigenCa = @strCliId;
		
										 SET @strDestinoCa = @canId_RS;
		
									 END;
	
								  IF LEN(ISNULL(@ttxId_RS,'')) > 0 BEGIN
	
									  SET @strTipoTxnCa = @ttxId_RS;	
	
									  IF @strTipoTxnCa = 'ECA' BEGIN
	
										 SET @strOrigenCa = @canId_RS;
	
										 SET @strDestinoCa = @strCliId;
									  END	 

									  ELSE BEGIN	
	
										 SET @strOrigenCa = @strCliId;
	
										 SET @strDestinoCa = @canId_RS;
		
									  END;
		
								  END;

								  SET @dblMontoC = @tcaImporteMoneda_RS;	
		
								  IF (@strTipoTxnCa = 'ICA' AND @strTipoTxnVn = 'VEN') OR (@strTipoTxnCa = 'ECA' AND @strTipoTxnVn = 'DVE') BEGIN
		--                            'Ajusta Montos si es con factura
 
									  IF @strConFacturaPos = 'S' BEGIN
 
										  IF @dblDescuentoMoneda <> 0 BEGIN
		
											  SET @dblTotal = @dblMontoC - (@dblMontoC * @dblPorDescuento);
		
											  SET @dblTotal = (@dblGnpIva * @dblMontoC) - (@dblTotal * @dblGnpIva);
		
											  SET @dblTotal = ((1 - @dblGnpIva) * @dblMontoC) + @dblTotal;
		
											  SET @dblTotal = @dblTotal + (@dblPorcDescuentoArticulo * @dblMontoC * @dblGnpIva);
										  END	  

										  ELSE BEGIN	
		
											  SET @dblTotal = ((1 - @dblGnpIva) * @dblMontoC) + (@dblPorcDescuentoArticulo * @dblMontoC * @dblGnpIva);
 
										  END;	
		
										  SET @dblMontoC = @dblTotal;
		
									  END;
		--                        End If
								  END;
		--                        'Crea Transaccion
		--                        If dblMontoC > 0 Then ' Crea y Aprueba la TXN si tiene monto > 0
								  IF @dblMontoC > 0 BEGIN		
	
									   EXEC capCreaEncabezado @strTipoTxnCa, @strMonId, @strvntId, 'vn', @fchFechaDoc, @dblTcMcMp, @dblTcMoMp, 
															@strDescripcion, @strOrigenCa, @strDestinoCa, @tdoId_RS, @strRespId, @dblMontoC, NULL, @proId_RS, @strExportadoAlFiscal,@strTxnIdCa OUTPUT;
		 
									   EXEC capApruebaTxn @strTxnIdCa;	
	 
								  END;	
	 
								  FETCH NEXT FROM rsCasTxn INTO @canId_RS,@ttxId_RS,@tdoId_RS,@proId_RS,@tcaImporteMoneda_RS;
	 
							  END;
						  	
	 
						  END;
						  CLOSE rsCasTxn;	
						  DEALLOCATE rsCasTxn;
 
					  END;
	 
				  END;
		 
			  END;
			  
		--    'Fin PAT 07-05-14------------------------------------------------------------------------------
		    
		--SINCENTROANALISIS:
		  SINCENTROANALISIS:	
		--    '-------------------Solicitudes ------------------son generadas unicamente por Proformas
		--    If booItSl Then ' si esta habilitado el modulo
			  IF @booItSl = 1 BEGIN	
		
				  IF @strTipoTxnVn = 'PRO' BEGIN
		--            'si el modulo se integra con solicitudes

					  SET @modIdDestino = (SELECT modIdDestino FROM gntIntegracion WHERE modIdOrigen LIKE 'vn' AND modIdDestino LIKE 'sl');

					  IF LEN(@modIdDestino) > 0 BEGIN
	
							  SET @modEstado = (SELECT modEstado FROM adtEmpresaModulo WHERE modId like 'sl'); 
		--                   If varResultado = "A" Then ' si el Modulo Esta Habilitado
							 IF @modEstado = 'A' BEGIN

							   SELECT @strCaIdPveId = ISNULL(canId,'') , 
									  @strtdoIdPveId = ISNULL(tdoId,'') , 
									  @strProIdPveId = ISNULL(proId,'')
							   FROM gntPuntoVenta
							   WHERE pveId LIKE @strPveId
 
							   IF LEN(@strCaIdPveId) = 0 BEGIN

								  SET @strMensajeError = 'No existe el Centro de Analisis para el Punto de venta  con codigo ' + @strPveId;
								  RAISERROR (@strMensajeError, 16, 1);
								  ---- THROW 51000, @strMensajeError, 1;
 
							   END;	 
 
							   IF LEN(@strtdoIdPveId) = 0 BEGIN
	 
								  SET @strMensajeError = 'No existe el tipo de documento para el Punto de venta  con codigo ' + @strPveId;	
								  RAISERROR (@strMensajeError, 16, 1);
								  ---- THROW 51000, @strMensajeError, 1;
 
							   END;
	 
							   IF LEN(@strProIdPveId) = 0 BEGIN
		
								  SET @strMensajeError = 'No existe el proyecto para el Punto de venta  con codigo ' + @strPveId;	
								  RAISERROR (@strMensajeError, 16, 1);
								  ---- THROW 51000, @strMensajeError, 1;
	 
 
							   END;
		
							   IF @flgConFactura = 1 BEGIN
									SET @strConF = 'S';
							   END
							   ELSE BEGIN
									SET @strConF = 'N';
							   END;
							   EXEC vmaGeneraSolicitudes @strvntId, @dblTC, @strRespId, @fchFechaDoc, @strDescripcion, @strExportadoAlFiscal, @strCliId, 
														 @strtdoIdPveId, @strCaIdPveId, @strVenId, @strMonId, @strConF, @strProIdPveId;
	
							 END;
	
					  END;
		
				  END;					
		
			  END;
		--    '--------------------
		--    ' genera Inventario
		--    If booItgIn Then	
			  IF @booItgIn = 1 BEGIN	
		--        intStatus = vmaGeneraInventario(strvntId, strTipoTxnVn, strCliId, strMonId, fchFechaDoc, dblTC, strDescripcion, strExportadoAlFiscal, strRespId)
				  EXEC vmaGeneraInventario @strvntId, @strTipoTxnVn, @strCliId, @strMonId, @fchFechaDoc, @dblTC, @strDescripcion, @strExportadoAlFiscal, @strRespId;
		--        If intStatus <> 0 Then
		--            vmaApruebaTxn = intStatus
		--            Exit Function
		--        End If
		--    End If
		      END;
		--------------------------------------------Comisiones---------------------------------INI
		SET @dblMontoComision = 0;
		--    'Pago de Comisión a Vendedores		
		SELECT @varStatus = vnpComisionActiva,@dblResultado= vnpPorcentajeEfectivo,@intResultado= vnpNumeroCuotas FROM vntParametro WHERE 1=1;		
		IF (@varStatus = 'S' AND @strTipoTxnVn = 'VEN') BEGIN		
			SET @dblPorcentajeGeneral = 0;		
			SET @dblPorcentajeComision = 0;		
			IF (@dblResultado IS NOT NULL) BEGIN		
				SET @dblPorcentajeGeneral = @dblResultado;	
			END;		
			IF (@intResultado IS NOT NULL) BEGIN
				SET @dblNumeroCuotas = @intResultado;
			END ELSE BEGIN	
				SET @strMensajeError = @strNombreParamSP + ' ERROR: Falta El Parámetro Número de Cuotas Para Comisión En Ventas';
				RAISERROR (@strMensajeError, 16, 1);
				---- THROW 51000, @strMensajeError, 1;		
			END;
		--        ' Recupera Porcentaje comision Vendedor		
			SELECT @dblResultado= dirComisionVendedor,@varStatus= dirTipoComision,@varResultado= DirComisionMomento FROM gntDirectorio WHERE dirid = @strvenId;		
			IF (@varStatus IS NOT NULL AND LEN(LTRIM(RTRIM(@varStatus)))<>0) BEGIN		
				SET @strTipoComision = @varStatus		
			END ELSE BEGIN		
				SET @strMensajeError = @strNombreParamSP + ' ERROR: No Esta Definido El Tipo de Comisión Para El Vendedor';
				RAISERROR (@strMensajeError, 16, 1);
				---- THROW 51000, @strMensajeError, 1;		
			END;		
			IF (@varResultado IS NOT NULL AND LEN(LTRIM(RTRIM(@varResultado)))<>0) BEGIN		
				SET @strComisionMomento = @varResultado;		
			END ELSE BEGIN		
				SET @strComisionMomento = 'C';	
			END;
		--        'Verifica Comisión momento
			IF (@strTipoComision = 'V') BEGIN --'Si tiene comision el empleado
				IF (@dblResultado IS NOT NULL) BEGIN	
					SET @dblPorcentajeComision = @dblResultado;--'si tiene porcentaje de comision
				END;
			END;		
			IF (@strTipoComision = 'G') BEGIN--General		
				SET @dblPorcentajeComision = @dblPorcentajeGeneral;
			END;		
			IF (@strTipoComision = 'C' OR @strTipoComision = 'D' OR @strTipoComision = 'T') BEGIN--Cliente,Grupo Vendedor,Grupo Cliente		
				IF (@strTipoComision = 'C') BEGIN		
					SET @varOrigenComision = @strCliId;		
				END ELSE BEGIN
				IF (@strTipoComision = 'D') BEGIN			
					SELECT @varOrigenComision =gruVendedor FROM gntDirectorio WHERE dirid = @strvenId;		
				END ELSE BEGIN
				IF (@strTipoComision = 'T') BEGIN		
					SELECT @varOrigenComision =gruCliente FROM gntDirectorio WHERE dirid = @strCliId;		
				END;
				END;
				END;		
				SELECT @dblResultado = ComPorcentaje FROM vntComision WHERE comOrigen = @varOrigenComision;		
				IF (@dblResultado IS NOT NULL) BEGIN		
					SET @dblPorcentajeComision = @dblResultado;		
				END;
			END;		
			IF (@strTipoComision = 'U') BEGIN--Utilidades sobre las ventas		
				EXEC vnpPorcentajeComisionDeUtilidades 
					@strVntId = @strVntId,
					@dblTotalMoneda = @dblTotalMoneda,
					@strMonId = @strMonId,
					@dblTc = @dblTc,
					@stralmId = @varAlmId,
					@datFecha = @fchFechaDoc,
					@vnpPorcentajeComisionDeUtilidades = @dblPorcentajeComision OUTPUT;
			END;
			--comentado, 20171205 por que no existe  la funcion que   johnni hizo esta modificacion		
			IF (@strTipoComision = 'P') BEGIN		
				--IF @strComisionMomento <> 'C' BEGIN 		
					exec vnpPorcentajeProductos @strVntId, @dblTotalMoneda, @strMonId, @dblTc, @dblPorcentajeComision OUTPUT;
				--END 
			END 		
			--erick
			IF (@strTipoComision = 'X') BEGIN 		
				DECLARE @strAnticiposM decimal(18, 12) = 0
				SELECT @strAnticiposM = vntAnticipoMoneda FROM vntTxn WHERE vntid = @strvntId 
				SET @dblTotalMoneda =  @dblTotalMoneda + @strAnticiposM
				IF ((select COUNT(*) from vntFPagoTxn where vntid = @strvntId and fpaid = 'CONCTACTE') = 0)
					EXEC vnpPorcentajeProductoVendedor 
						@strVntId = @strVntId,
						@dblTotalMoneda = @dblTotalMoneda,
						@strMonId = @strMonId,
						@dblTc = @dblTc,
						@strvenId = @strvenId,						
						@dblPorcentajeProductoVendedor = @dblPorcentajeComision OUTPUT;
				ELSE
					SET @dblPorcentajeComision = 0
			END;		
		--            Case "R" 'Reglas
		--                If Not vnpPorcentajeReglasPorGrupo(strVntId, dblTotalMoneda, dblDescuentoMoneda, strMonId, dblTc, strCliId, flgConFactura, dblPorcentajeComision) Then
		--                    vnpApruebaTxn = ErrMensajeMudo: gvarMensajeError = "Aprobación Cancelada...."
		--                    Exit Function
		--                End If
		--         End Select
		    		
			IF (@dblPorcentajeComision > 0) BEGIN		
				SET @dblMontoComision = (@dblTotalMoneda + @dblAnticipoMoneda + @dblOtrosAnticiposMoneda) * @dblPorcentajeComision;
		--            'Recupera monto Pagado Al contado		
				IF (@strComisionMomento = 'C') BEGIN		
					DECLARE curVntFpagoTxn CURSOR LOCAL FOR
					select MonId,fptMontoMoneda from vntFpagoTxn where fpaid <> 'CONCTACTE' and fpaid <> 'HOSPEDAJE' and fpaid <> 'CREDITO' and fpaid <> 'DOCUMENTO' and vntId = @strVntId;		
				END ELSE BEGIN
				IF (@strComisionMomento = 'V') BEGIN
					DECLARE curVntFpagoTxn CURSOR LOCAL FOR
					select MonId,fptMontoMoneda from vntFpagoTxn where vntId = @strVntId;		
				END;
				END;		
				SET @booResultado = 0;		
				OPEN curVntFpagoTxn;
				FETCH NEXT FROM curVntFpagoTxn INTO @monId_RS,@fptMontoMoneda_RS;	
				
				/*--- ERICK
				IF @monId_RS is null
					begin
						DECLARE @strTotalAnticipos DECIMAL(18, 12) = 0							
						SELECT , @monId_RS = monid from vntTxn where vntid = @strVntId
					end*/
					/*
				DECLARE @strTotalAnticipos DECIMAL(18, 12) = 0							
				SELECT @monId_RS = monid, @strTotalAnticipos = vntanticipomoneda from vntTxn where vntid = @strVntId	*/
						
				IF (@@ROWCOUNT>0) BEGIN
					SET @dblTotal = 0;
					WHILE @@FETCH_STATUS = 0 BEGIN
						IF (@strMonId = @monId_RS) BEGIN		
							SET @dblTotal = @dblTotal + @fptMontoMoneda_RS;		
						END ELSE BEGIN		
							IF (@strMonId = @strMonIdC) BEGIN		
								SET @dblTotal = @dblTotal + (@fptMontoMoneda_RS * @dblTc);	
							END ELSE BEGIN		
								SET @dblTotal = @dblTotal + (@fptMontoMoneda_RS / @dblTc);
							END;
						END;
						FETCH NEXT FROM curVntFpagoTxn INTO @monId_RS,@fptMontoMoneda_RS;
					END;
					SET @booResultado = 1;
				END;
				CLOSE curVntFpagoTxn;
				DEALLOCATE curVntFpagoTxn;
		--            'Verifica PAgos en Efectivos		
				IF ((@dblTotal + @dblAnticipoMoneda + @dblOtrosAnticiposMoneda)>0) BEGIN
		--                'Genera Comisión al vendedor		
					IF (@strComisionMomento = 'V')
						BEGIN
							SET @dblTotal = (@dblTotal + @dblAnticipoMoneda + @dblOtrosAnticiposMoneda) * @dblPorcentajeComision;
							EXEC vnpCreaComisionTxn  
								@strTxnId = @strVntId,
								@strMonId = @strMonId,
								@datFecha = @fchFechaDoc,
								@dblPorcentaje = @dblPorcentajeComision,
								@dblMonto = @dblTotal,
								@strRefId = @strVntId,
								@varSltId = NULL,
								@dblTc = @dblTc;	
						END 
						ELSE 
						
							BEGIN		
								IF (@booResultado =1 AND @strComisionMomento = 'C')
									BEGIN	
										IF 	@dblTotal = 0
											SET @dblTotal = (@dblTotal + @dblAnticipoMoneda) * @dblPorcentajeComision;		
										ELSE
											SET @dblTotal = @dblTotal * @dblPorcentajeComision;		

									END;
							ELSE
								-- ERICK: SI EL PAGO SOLO ES CON ANTICIPO
								SET @dblTotal = @dblAnticipoMoneda  * @dblPorcentajeComision;		
							END

							EXEC vnpCreaComisionTxn 
								@strTxnId = @strVntId,
								@strMonId = @strMonId,
								@datFecha = @fchFechaDoc,
								@dblPorcentaje = @dblPorcentajeComision,
								@dblMonto = @dblTotal,
								@strRefId = @strVntId,
								@varSltId = NULL,
								@dblTc = @dblTc;			

				END;
		--            'Actualiza Porcentaje en ventas
				update vntTxn SET vntPorcentajeComision = @dblPorcentajeComision
				, vntNumeroCuotasComision = @dblNumeroCuotas
				, vntComisionMoneda = @dblMontoComision
				, vntComisionMomento = @strComisionMomento
				WHERE vntId = @strVntId;
			END;
		END;
		--    ' Comisión por anticipo a vendedor		
		SET @dblMontoComision = 0;
		--    'Pago de Comisión a Vendedores	
		SELECT @varStatus= comisionPorAnticipo, @dblResultado= vnpPorcentajeEfectivo,@intResultado = vnpNumeroCuotas FROM vntParametro WHERE 1=1;
		--	Si Esta Activa El Pago de Comisiones
		IF (@varStatus = 'S' AND @strTipoTxnVn = 'VEN') BEGIN		
			SET @dblPorcentajeGeneral = 0;		
			SET @dblPorcentajeComision = 0;
			IF (@dblResultado IS NOT NULL) BEGIN
				SET @dblPorcentajeGeneral = @dblResultado;
			END;
			IF (@intResultado IS NOT NULL) BEGIN
				SET @dblNumeroCuotas = @intResultado;
			END ELSE BEGIN
				SET @strMensajeError = @strNombreParamSP + ' ERROR: Falta El Parámetro Número de Cuotas Para Comisión En Ventas';
				RAISERROR (@strMensajeError, 16, 1);
				---- THROW 51000, @strMensajeError, 1;
			END;
		--        'Recupera Porcentaje comision Vendedor
			SELECT @dblResultado= dirComisionVendedor,@varStatus= dirTipoComision,@varResultado= DirComisionMomento FROM gntDirectorio WHERE dirid = @strvenId;
			IF (@varStatus IS NOT NULL AND LEN(LTRIM(RTRIM(@varStatus)))<>0) BEGIN
				SET @strTipoComision = @varStatus;
			END ELSE BEGIN
				SET @strMensajeError = @strNombreParamSP + ' ERROR: No Esta Definido El Tipo de Comisión Para El Vendedor';
				RAISERROR (@strMensajeError, 16, 1);
				---- THROW 51000, @strMensajeError, 1;
			END;		
			IF (@strTipoComision ='V') BEGIN
				IF (@dblResultado IS NOT NULL) BEGIN
					SET @dblPorcentajeComision = @dblResultado;
				END;
			END;		
			IF (@strTipoComision = 'G') BEGIN		
				SET @dblPorcentajeComision = @dblPorcentajeGeneral;
			END;	
			IF (@dblPorcentajeComision > 0) BEGIN
		--            'Genera Comisión al vendedor
				SET @dblTotal = (@dblAnticipoMoneda + @dblOtrosAnticiposMoneda) * @dblPorcentajeComision;		
				EXEC vnpCreaComisionTxn 
					@strTxnId = @strVntId,
					@strMonId = @strMonId,
					@datFecha = @fchFechaDoc,
					@dblPorcentaje = @dblPorcentajeComision,
					@dblMonto = @dblTotal,
					@strRefId = @strVntId,
					@varSltId = NULL,
					@dblTc = @dblTc;
			END;
		END;	
		--------------------------------------------Comisiones---------------------------------FIN
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		--    'genera Asiento

			  SET @strMonId = RTRIM(LTRIM(@strMonId));
 
			  SET @booAnulaTxn = 0;
 
			  IF @booItgCn =1 
			  BEGIN         
		
				EXEC vmaGeneraAsientoVentas @strvntId, @booAnulaTxn, @strTipoTxnVn, @strTdoId, @strCliId, @strMonId, @strPveId, @fchFechaDoc, @dblTC, @strDescripcion, @strConFacturaPos, 
										@strExportadoAlFiscal, @flgConFactura, @dblArticuloMoneda, @dblDescuentoMoneda, @dblAnticipoMoneda, @dblOtrosAnticiposMoneda, 
										@strTipoDescuento, @dblDescuentoArticulo, @dblRecargoMoneda, @dblGnpIva, @dblGnpIT, @booPveIdSinIT, @varReferenciaDevolucion, @strTxnIn;
			  END;						
 
		--    'cambia del Estado En Revision al Estado Aprobado
	 
		      UPDATE vntTxn SET vntEstado = 'A', vntFechaCambio = @fchFechaDoc, vntUsuario = SYSTEM_USER, vntTxnCerrada = 'C', vntFechaAprobacion = GETDATE(), vntUsuarioAprobacion = SYSTEM_USER
			  WHERE vntId LIKE @strvntId
		    
		 
		  IF (@booItgIp = 1) AND (@strGeneraFacturaAlAprobar = 'S') AND @flgConFactura = 1 BEGIN	
		 
			If @strTipoTxnVn = 'VEN' BEGIN 
		 
				IF (@booConDFR =1) BEGIN
			 
						IF (@dblTotalMoneda - @dblDFRMonto) <> 0 BEGIN
							EXEC vmaGeneraFacturaApartirVenta @strVntId, @strTipoTxnVn, 
								@strPveIdFacturacion, @fchFechaDoc, @strrespId, @strMonId, @dblTc, @strVenId, @lngNumeroFacturaManual;
						END;
				     	
				END
				ELSE BEGIN
				    --'verifico si el modulo esta habilitado'
					
					EXEC vmaGeneraFacturaApartirVenta @strVntId, @strTipoTxnVn, 
					@strPveIdFacturacion, @fchFechaDoc, @strrespId, @strMonId, @dblTc, @strVenId, @lngNumeroFacturaManual;
				END;
		
 
		--	End If
			END;
		--End If
		  END;    
		       
		  IF (@booItgIp = 1)  AND @flgConFactura = 1  and  @strTipoTxnVn = 'DVE'  BEGIN
			--Anula facturas de las ventas relacionadas
			 if len(isnull(@varReferenciaDevolucion,''))> 0 begin
				--recuperar la factura
				declare @facIdRefDev VARCHAR(50)
				set @facIdRefDev=( select top 1 facId from iptFactura where FacReferencia like @varReferenciaDevolucion and ttxId like 'FVE' and facEstado like 'A')
				set @facIdRefDev=ISNULL(@facIdRefDev,'')
				if len(@facIdRefDev)> 0 begin
					execute ippAnulaTxn 
								@strTxnId =@facIdRefDev,				--strTxnId As String, 
								@varModLlamante ='vn'
				end
			 end  
		  end 
		       
		--    'Cambia el estado de la Transacción 'PAT 02-05-2014
		--    'Carga valores parametro gntParametroModulo
 
		      SET @vntCorrelativoTxn = ISNULL((SELECT vntCorrelativoTxn FROM vntTxn WHERE vntId = @strvntId),'');
		
		      IF @vntCorrelativoTxn = '' BEGIN
		
				
				SELECT @varObligaSucursal = modObligaSucursal , @strCorrelativoActivado = modCorrelativoActivado ,
					   @strCorrelativoDigitoPor = modCorrelativoDigitoPor , @strCorrelativoPor = modCorrelativoPor ,
					   @strCorrelativoTipoPor = modCorrelativoTipoPor , @intCorrelativoDigitoCantidad = modCorrelativoDigitoCantidad
				FROM gntParametroModulo
				WHERE modId = 'vn'
												
 
				  IF LEN(@strCorrelativoActivado) = 0 BEGIN
 
					  SET @strCorrelativoActivado = 'N';	
 
				  END;
 
				  IF LEN(@strCorrelativoDigitoPor) = 0 BEGIN
 
					  SET @strCorrelativoDigitoPor = 'G';
 
				  END;
				  IF LEN(@strCorrelativoPor) = 0 BEGIN
					  SET @strCorrelativoPor = 'G';
				  END;
				  IF LEN(@strCorrelativoTipoPor) = 0 BEGIN
					  SET @strCorrelativoTipoPor = 'T';
				  END;
		          SET @strEntidadRelacion = ISNULL((SELECT relPersona FROM vntTxn WHERE vntId=@strvntId),'');
				  IF @strCorrelativoActivado = 'S' BEGIN
					  SET @strDigitoInicial = (SELECT empDigitoId FROM adtEmpresa WHERE empActiva = @intVerdadero);
					  IF @strCorrelativoDigitoPor = 'S' And (@strPveId IS NOT NULL) AND LEN(@strPveId) > 0 BEGIN
						  SET @sucId = (SELECT sucId FROM gntPuntoVenta WHERE pveId = @strPveId);
						  SET @strDigitoInicial = SUBSTRING(@sucId,1,1);
					  END		

					  ELSE BEGIN	
						  IF @strCorrelativoDigitoPor = 'P' AND (@strPveId IS NOT NULL) AND LEN(@strPveId) > 0 BEGIN	
							  SET @strDigitoInicial = SUBSTRING(@strPveId, 1, 1);
						  END;
					  END;
					  EXEC gnpCalculaCorrelativo @strCorrelativoPor, @strDigitoInicial, 'vn', @strTipoTxnVn, @fchFechaDoc, NULL, NULL, 
							@strTdoId, @strCorrelativoTipoPor, @intCorrelativoDigitoCantidad, @varSucId, @strPveId, @strEntidadRelacion,@strNuevoCorrelativo OUTPUT;	
					  DECLARE @USUARIO VARCHAR(50)
					  DECLARE @FECHA DATETIME
					  
					  SET @USUARIO = SYSTEM_USER
					  SET @FECHA = GETDATE()
					  UPDATE vntTxn SET vntCorrelativoTxn = @strNuevoCorrelativo , vntUsuario = @USUARIO , vntFechaCambio = @FECHA
					  WHERE vntId = @strvntId
				  END;
			  END;	
		   RETURN 0;		
		-- MENSAJE DE FIN DE PROCESO		
		PRINT @strNombreParamSP;
	END TRY
	BEGIN CATCH
		IF LEN(ISNULL(@strMensajeError,''))=0 BEGIN
		    SET @strMensajeError=@strNombreParamSP + ' ' + ERROR_MESSAGE();
		END ;
		RAISERROR (@strMensajeError, 16, 1);
		---- THROW;
		
		-- MENSAJE DE ERROR DE PROCESO
		PRINT @strNombreParamSP + ' Error';		
	END CATCH;
END
