CREATE PROCEDURE capApruebaTxn 
	@strTxnId VARCHAR(50) --strTxnId As String
--WITH ENCRYPTION 
AS
BEGIN
	-- DEFINE OPCIONES DE EJECUCION
	SET NOCOUNT ON;

	-- DECLARA VARIABLES
	DECLARE @strNombreParamSP VARCHAR(200);
	DECLARE @strMensajeError VARCHAR(500);	

	BEGIN TRY
		-- VALIDA PARAMETROS
		--IF (LEN(@strCabId) = 0 OR @strCabId IS NULL) BEGIN
		--	SET @strMensajeError = @strNombreSP + ' ERROR: cabId debe existir';
		--	RAISERROR (@strMensajeError, 16, 1);
		--	---- THROW 51000, @strMensajeError, 1;
		--END;
		SET @strNombreParamSP = 'capApruebaTxn - ' + ISNULL(@strTxnId,'')
		--Function capApruebaTxn(strTxnId As String) As Integer
		--	On Error Resume Next
		--	Dim miBD As Database
		--	Dim varResultado As Variant
		--	Dim strCondicion As String
		--	Dim strSql As String
		--	Dim varTotalTxn As Variant
		--	Dim dblMontoTxn As Double
		--	Dim strCtaCte As String
		--	Dim strEstado As String
		    
		--	' Variables Para Los Asientos Contables
		--	Dim intStatus As Integer
		--	Dim varModEstado As Variant
		--	Dim dblTotal   As Double
		--	Dim flgGenerico As Boolean
		--	Dim strOctId As String
		--	Dim fchFechaDoc As Date
		--	Dim varStatus As Variant
		--	Dim strTipoTdo As String
		--	Dim strTipoTxn As String
		--	Dim strResId As String
		--	Dim strMonId As String
		--	Dim strCatOrigen As String
		--	Dim strCatDestino As String
		--	Dim strDescripcion As String
		--	Dim dblTcMcMp As Double
		--	Dim strModId As String
		--	Dim strConceptoDebe As String
		--	Dim strConceptoHaber As String
		--	Dim strReferenciaDebe As String
		--	Dim strReferenciaHaber As String
		--	Dim varProId As Variant
		--	Dim strFiltraCuentasBalance As String * 1
		--	Dim varCuenta As Variant
		--	Dim strCtaId As String
		--	Dim booBorraTxn As Boolean
		    
		        
		--	'Control De Variables Globales
		--	If IsNull(strMonIdC) Or Len(strMonIdC) = 0 Then
		--	   varStatus = CargaTodaEstructura
		--	End If
		    
		--	'Incializa variables
		--	If strTipoBD = "S" Then
		--		Set miBD = DbNovus
		--	Else
		--		Set miBD = CurrentDb
		--	End If
			DECLARE @strCatId VARCHAR(50);
		    DECLARE @strEstado VARCHAR(1);
		    DECLARE @strTipoTxn VARCHAR(50);
		    DECLARE @dblMontoTxn DECIMAL(24,12);
		    DECLARE @strMonId VARCHAR(50);
		    DECLARE @dblTcMcMp DECIMAL(24,12);
		    DECLARE @strTipoTdo VARCHAR(50);
		    DECLARE @fchFechaDoc DATETIME;
		    DECLARE @strModId VARCHAR(2);
		    DECLARE @strResId VARCHAR(50);
		    DECLARE @strCatOrigen VARCHAR(50);
		    DECLARE @strCatDestino VARCHAR(50);
		    DECLARE @varProId VARCHAR(50);
		    DECLARE @strCentroAnalisis VARCHAR(50);
		    DECLARE @strCanHabilitado VARCHAR(1);
		    DECLARE @varObligaSucursal VARCHAR(1);
			DECLARE @strCorrelativoActivado VARCHAR(1);
			DECLARE @strCorrelativoDigitoPor VARCHAR(1);
			DECLARE @strCorrelativoPor VARCHAR(1);
			DECLARE @fchInicial DATETIME;
			DECLARE @fchFinal DATETIME;
			DECLARE @booVerificaFechaDiaria BIT; 
			DECLARE @varStatus VARCHAR(1);
			DECLARE @varResultado VARCHAR(50);
			DECLARE @strDigitoInicial VARCHAR(1);
			DECLARE @strNuevoCorrelativo VARCHAR(50);
			DECLARE @strFiltraCuentasBalance VARCHAR(1);
			DECLARE @varCuenta VARCHAR(50);
			DECLARE @strCtaId VARCHAR(50);
			DECLARE @booBorraTxn BIT;
			SET @strCatId = NULL;
		--	capApruebaTxn = 0
		--	strCondicion = "catId = '" & strTxnId & "'"
		--	varResultado = recuperaRegistroSQL("catId", "catTxn", strCondicion, , "catEstado", "ttxId", "catMontoMoneda", "monId", "catTcMcMp", "tdoId", "catfechadoc", "modId", "resId", "catOrigen", "catDestino", "proId")
			
			SELECT @strCatId = catId, 
			       @strEstado = catEstado, 
			       @strTipoTxn =ttxId, 
			       @dblMontoTxn = catMontoMoneda, 
			       @strMonId =monId, 
			       @dblTcMcMp = catTcMcMp, 
			       @strTipoTdo = tdoId, 
			       @fchFechaDoc = catfechadoc, 
			       @strModId = modId, 
			       @strResId =resId, 
			       @strCatOrigen = catOrigen, 
			       @strCatDestino = catDestino, 
			       @varProId = proId 
			  FROM catTxn WHERE catId = @strTxnId;
		--	If IsNull(varResultado) Then
			IF (@@ROWCOUNT = 0) BEGIN
		--		capApruebaTxn = errNoExisteDocumento
				SET @strMensajeError = @strNombreParamSP + ' ERROR: No Existe Documento.';
				RAISERROR (@strMensajeError, 16, 1);
				---- THROW 51000, @strMensajeError, 1;
		--		Exit Function
		--	End If
			END;
		    
		--	strEstado = recuperacampo(varResultado, 2)
		--	If strEstado <> "R" Then
			IF (@strEstado <> 'R') BEGIN
		--		capApruebaTxn = ErrNoEstaEnRevision
				SET @strMensajeError = @strNombreParamSP + ' ERROR: No Esta En Revision.';
				RAISERROR (@strMensajeError, 16, 1);
				---- THROW 51000, @strMensajeError, 1;
		--		Exit Function
		--	End If
			END;
		--	strTipoTxn = recuperacampo(varResultado, 3)
		--	dblMontoTxn = recuperacampo(varResultado, 4)
		--	strMonId = recuperacampo(varResultado, 5)
		--	dblTcMcMp = recuperacampo(varResultado, 6)
		--	strTipoTdo = recuperacampo(varResultado, 7)
		--	fchFechaDoc = recuperacampo(varResultado, 8)
		--	strModId = recuperacampo(varResultado, 9)
		--	strResId = recuperacampo(varResultado, 10)
		--	strCatOrigen = recuperacampo(varResultado, 11)
		--	strCatDestino = recuperacampo(varResultado, 12)
		--	varProId = recuperacampo(varResultado, 13)
		    
		--	If dblMontoTxn = 0 Then
			IF (@dblMontoTxn = 0) BEGIN
		--		capApruebaTxn = ErrNoExisteTotalPorTransaccion
				SET @strMensajeError = @strNombreParamSP + ' ERROR: No Existe Total Por Transaccion.';
				RAISERROR (@strMensajeError, 16, 1);
				---- THROW 51000, @strMensajeError, 1;
		--		Exit Function
		--	End If
			END;
		       
		--	If IsNull(strCatOrigen) Or Len(Trim(strCatOrigen)) = 0 Then
			IF (@strCatOrigen IS NULL OR LEN(LTRIM(RTRIM(@strCatOrigen))) = 0) BEGIN
		--		capApruebaTxn = ErrNoExisteElOrigen
				SET @strMensajeError = @strNombreParamSP + ' ERROR: No Existe El Origen.';
				RAISERROR (@strMensajeError, 16, 1);
				---- THROW 51000, @strMensajeError, 1;
		--		Exit Function
		--	End If
			END;
		--	If IsNull(strCatDestino) Or Len(Trim(strCatDestino)) = 0 Then
			IF (@strCatDestino IS NULL OR LEN(LTRIM(RTRIM(@strCatDestino))) = 0) BEGIN
		--		capApruebaTxn = ErrNoExisteElDestino
				SET @strMensajeError = @strNombreParamSP + ' ERROR: No Existe El Destino.';
				RAISERROR (@strMensajeError, 16, 1);
				---- THROW 51000, @strMensajeError, 1;
		--		Exit Function
		--	End If
			END;
		    
		--	'Verifica si centro de análisis está habilitado
		--	Dim strCentroAnalisis As String
		--	If strTipoTxn = "ECA" Then
			IF (@strTipoTxn = 'ECA') BEGIN
		--		strCentroAnalisis = strCatOrigen
				SET @strCentroAnalisis = @strCatOrigen;
		--	Else
			END ELSE BEGIN
		--		strCentroAnalisis = strCatDestino
				SET @strCentroAnalisis = @strCatDestino;
		--	End If
			END;
		--	varResultado = recuperaRegistroSQL("canHabilitado", "catCentroAnalisis", "canId = '" & strCentroAnalisis & "'")
			SELECT @strCanHabilitado = canHabilitado FROM catCentroAnalisis WHERE canId = @strCentroAnalisis;
		--	If varResultado = "N" Then
			IF (@strCanHabilitado ='N') BEGIN
		--		gvarMensajeError = "El centro de análisis no está habilitado... "
				SET @strMensajeError = @strNombreParamSP + ' ERROR: El centro de análisis no está habilitado...';
				RAISERROR (@strMensajeError, 16, 1);
				---- THROW 51000, @strMensajeError, 1;
		--		capApruebaTxn = ErrMensajeMudo
		--		Exit Function
		--	End If
			END;
		    
		--	'Carga valores parametro gntParametroModulo
		--	Dim varObligaSucursal As Variant
		--	Dim strCorrelativoActivado As String
		--	Dim strCorrelativoDigitoPor As String
		--	Dim strCorrelativoPor As String
			
		--	varResultado = recuperaRegistroSQL("modObligaSucursal", "gntParametroModulo", "modId = 'ca'", , "modCorrelativoActivado", "modCorrelativoDigitoPor", "modCorrelativoPor")
			SELECT @varObligaSucursal = modObligaSucursal, @strCorrelativoActivado = modCorrelativoActivado, @strCorrelativoDigitoPor = modCorrelativoDigitoPor, @strCorrelativoPor = modCorrelativoPor FROM gntParametroModulo WHERE modId = 'ca';
		--	varObligaSucursal = recuperacampo(varResultado, 1)
		--	strCorrelativoActivado = recuperacampo(varResultado, 2)
		--	If Len(strCorrelativoActivado) = 0 Then
			IF (LEN(@strCorrelativoActivado) =0 ) BEGIN
		--		strCorrelativoActivado = "N"
				SET @strCorrelativoActivado = 'N';
		--	End If
			END;
		--	strCorrelativoDigitoPor = recuperacampo(varResultado, 3)
		--	If Len(strCorrelativoDigitoPor) = 0 Then
			IF (LEN(@strCorrelativoDigitoPor) = 0) BEGIN
		--		strCorrelativoDigitoPor = "G"
				SET @strCorrelativoDigitoPor = 'G';
		--	End If
			END;
		--	strCorrelativoPor = recuperacampo(varResultado, 4)
		--	If Len(strCorrelativoPor) = 0 Then
			IF (LEN(@strCorrelativoPor) =0) BEGIN
		--		strCorrelativoPor = "G"
				SET @strCorrelativoPor = 'G';
		--	End If
			END;
		    
		--	'Valida fecha del documento
		--	Dim booVerificaFechaDiaria As Boolean
		--	Dim strValores As String
		--	Dim fchInicial As Date
		--	Dim fchFinal As Date
		--	Dim strCondicionValidaFecha As String
			
		--	strCondicionValidaFecha = "modId = 'ca'"
		--	strValores = recuperaRegistroSQL("modFechaInicial", "gntParametroModulo", strCondicionValidaFecha, , "modFechaFinal", "modVerificaFechaDiaria")
			SELECT @fchInicial = modFechaInicial, @fchFinal = modFechaFinal, @booVerificaFechaDiaria = modVerificaFechaDiaria FROM gntParametroModulo WHERE modId = 'ca';
		--	fchInicial = recuperacampo(strValores, 1)
		--	fchFinal = recuperacampo(strValores, 2)
		--	booVerificaFechaDiaria = recuperacampo(strValores, 3)
		--	If booVerificaFechaDiaria Then
			IF (@booVerificaFechaDiaria = 1) BEGIN
		--		If Format(fchFechaDoc, "dd/mm/yyyy") <> Format(Date, "dd/mm/yyyy") Then
				IF (CONVERT(VARCHAR(50),@fchFechaDoc, 112) <> CONVERT(VARCHAR(50),GETDATE(), 112)) BEGIN
		--			gvarMensajeError = "Centros de Análisis - La Fecha Del Documento Debe Ser La Actual"
					SET @strMensajeError = @strNombreParamSP + ' ERROR: Centros de Análisis - La Fecha Del Documento Debe Ser La Actual';
					RAISERROR (@strMensajeError, 16, 1);
					---- THROW 51000, @strMensajeError, 1;
		--			capApruebaTxn = ErrMensajeMudo
		--			Exit Function
		--		End If
				END;
		--	Else
			END ELSE BEGIN
		--		If Not ((fchFechaDoc >= fchInicial) And (fchFechaDoc <= fchFinal)) Then
				IF (NOT ((@fchFechaDoc> = @fchInicial) AND (@fchFechaDoc <= @fchFinal))) BEGIN
		--			gvarMensajeError = "Centros de Análsis - El documento debe estar entre " & fchInicial & " y " & fchFinal
					SET @strMensajeError = @strNombreParamSP + ' ERROR: Centros de Análsis - El documento debe estar entre ' + CONVERT(VARCHAR(50),@fchInicial,103) + ' y ' + CONVERT(VARCHAR(50), @fchFinal, 103);
					RAISERROR (@strMensajeError, 16, 1);
					---- THROW 51000, @strMensajeError, 1;
		--			capApruebaTxn = ErrMensajeMudo
		--			Exit Function
		--		End If
				END;
		--	End If
		    END;
		--	'Valida Proyecto y Tipo de Documento
		--	varStatus = recuperaRegistroSQL("capValidaTdoId", "catParametro", "1=1")
			SELECT @varStatus = capValidaTdoId FROM catParametro WHERE 1=1;
		--	If Not IsNull(varStatus) Then
			IF (@varStatus IS NOT NULL) BEGIN
		--		If varStatus = "S" Then
				IF (@varStatus = 'S') BEGIN
		--			If IsNull(strTipoTdo) Or Len(Trim(strTipoTdo)) = 0 Then
					IF (@strTipoTdo IS NULL OR LEN(LTRIM(RTRIM(@strTipoTdo)))= 0) BEGIN
		--				capApruebaTxn = ErrMensajeMudo: gvarMensajeError = "Falta Ingresar el Tipo De Documento Para El Centro De Análisis ... "
						SET @strMensajeError = @strNombreParamSP + ' ERROR: Falta Ingresar el Tipo De Documento Para El Centro De Análisis ...';
						RAISERROR (@strMensajeError, 16, 1);
						---- THROW 51000, @strMensajeError, 1;
		--				Exit Function
		--			End If
					END;
		--		End If
				END;
		--	End If
			END;
		    
		--	varStatus = recuperaRegistroSQL("capValidaProyecto", "catParametro", "1=1")
			SELECT @varStatus = capValidaProyecto FROM catParametro WHERE 1=1;
		--	If Not IsNull(varStatus) Then
			IF (@varStatus IS NOT NULL) BEGIN
		--		If varStatus = "S" Then
				IF (@varStatus = 'S') BEGIN
		--			If IsNull(varProId) Or Len(Trim(varProId)) = 0 Then
					IF (@varProId IS NULL OR LEN(LTRIM(RTRIM(@varProId)))=0) BEGIN
		--				capApruebaTxn = ErrMensajeMudo: gvarMensajeError = "Falta Ingresar el Proyecto Para El Centro De Análisis ... "
						SET @strMensajeError = @strNombreParamSP + ' ERROR: Falta Ingresar el Proyecto Para El Centro De Análisis ...';
						RAISERROR (@strMensajeError, 16, 1);
						---- THROW 51000, @strMensajeError, 1;
		--				Exit Function
		--			End If
					END;
		--		End If
				END;
		--	End If
			END;
		        
		--	'Valida que tipo de documento este relacionado con tipo de txn
		--	If Len(strTipoTdo) > 0 Then
			IF (LEN(@strTipoTdo) > 0) BEGIN
		--		strCondicion = "tdoId = '" & strTipoTdo & "' AND ttxId = '" & strTipoTxn & "'"
		--		varResultado = recuperaRegistroSQL("ttxId", "gntTipoDocTxn", strCondicion)
				SELECT @varResultado = ttxId FROM gntTipoDocTxn WHERE tdoId = @strTipoTdo AND ttxId = @strTipoTxn;
		--		If IsNull(varResultado) Then
				IF (@varResultado IS NULL) BEGIN
		--			gvarMensajeError = strTipoTdo
		--			capApruebaTxn = ErrNoExisteTdoAsociadoATtx
					SET @strMensajeError = @strNombreParamSP + ' ERROR: No Existe el tipo de documento: ' + @strTipoTdo + ' Asociado A tipo de txn: ' + ISNULL(@strTipoTxn,'');
					RAISERROR (@strMensajeError, 16, 1);
					---- THROW 51000, @strMensajeError, 1;
		--			Exit Function
		--		End If
				END;
		--	End If
			END;
		    print '@strCorrelativoActivado:'+ISNULL(@strCorrelativoActivado,'nulo');
		--	If strCorrelativoActivado = "S" Then
			IF (@strCorrelativoActivado = 'S') BEGIN
		--		Dim strNuevoCorrelativo As String
		--		Dim strDigitoInicial As String
		--		varResultado = recuperaRegistro("empDigitoId", "adtEmpresa", "empActiva = " & intVerdadero)
				SELECT @strDigitoInicial = empDigitoId FROM adtEmpresa WHERE empActiva = 1;
		--		strDigitoInicial = varResultado
		--		'If strCorrelativoDigitoPor = "S" And Not IsNull(strPveId) And Len(strPveId) > 0 Then
		--		'    strDigitoInicial = mid(strPveId, 1, 1)
		--		'End If
		--		strNuevoCorrelativo = gnpCalculaCorrelativo(strCorrelativoPor, strDigitoInicial, "ca", strTipoTxn, fchFechaDoc)
				EXEC gnpCalculaCorrelativo 
					@strCorrelativoPor = @strCorrelativoPor,
					@strDigitoInicial = @strDigitoInicial,
					@strModulo = 'ca',
					@strTipoTxn = @strTipoTxn,
					@fchFechaTxn = @fchFechaDoc,
					@strCorrelativoNuevo = @strNuevoCorrelativo OUTPUT;
		--		strSql = "update catTxn SET catEstado = 'A', catCorrelativoTxn = '" & strNuevoCorrelativo & "'"
				update catTxn SET catEstado = 'A', catCorrelativoTxn = @strNuevoCorrelativo,
		--		strSql = strSql & ", catUsuario = '" & CurrentUser & "', catFechaCambio = '" & Format(Now, strFormatoFecha) & "'"
				catUsuario = SYSTEM_USER , catFechaCambio = GETDATE()
		--		strSql = strSql & " WHERE catId = '" & strTxnId & "'"
				WHERE catId = @strTxnId;
		--	Else
			END ELSE BEGIN
		--		strCondicion = "catId = '" & strTxnId & "'"
		--		strSql = "Update catTxn set catEstado = 'A' "
				Update catTxn set catEstado = 'A',
		--		strSql = strSql & ", catUsuario = '" & CurrentUser & "', catFechaCambio = '" & Format(Now, strFormatoFecha) & "'"
				catUsuario = SYSTEM_USER , catFechaCambio = GETDATE(),catUsuarioAprobacion = SYSTEM_USER , catFechaAprobacion = GETDATE()
		--		strSql = strSql & "  where " & strCondicion
				WHERE catId = @strTxnId;
		--	End If
			END;
		--	If strTipoBD = "S" Then
		--	   miBD.Execute strSql
		--	Else
		--	   miBD.Execute strSql, dbFailOnError
		--	End If
		--	If Err.Number <> 0 Then
		--		capApruebaTxn = Err.Number
		--		Exit Function
		--	End If
		    
		--	'Verifica si filtra las cuentas de balance 
		--	varStatus = recuperaRegistroSQL("capFiltraCuentasBalance", "catParametro", "1=1")
			SELECT @varStatus = capFiltraCuentasBalance FROM catParametro WHERE 1=1;
		--	If Not IsNull(varStatus) Then
			IF (@varStatus IS NOT NULL) BEGIN
		--		If varStatus = "S" Then
				IF (@varStatus = 'S') BEGIN
		--			strFiltraCuentasBalance = "S"
					SET @strFiltraCuentasBalance = 'S';
		--		Else
				END ELSE BEGIN
		--			strFiltraCuentasBalance = "N"
					SET @strFiltraCuentasBalance = 'N';
		--		End If
				END;
		--	Else
			END ELSE BEGIN
		--		strFiltraCuentasBalance = "N"
				SET @strFiltraCuentasBalance = 'N';
		--	End If
			END;
		--	booBorraTxn = False
			SET @booBorraTxn = 0;
		--	If strFiltraCuentasBalance = "S" Then
			IF (@strFiltraCuentasBalance = 'S') BEGIN
		--		'Borra la Txn
		--		If Not IsNull(strTipoTdo) And Len(Trim(strTipoTdo)) <> 0 Then
				IF (@strTipoTdo IS NOT NULL AND LEN(LTRIM(RTRIM(@strTipoTdo))) <> 0) BEGIN
		            
		--			varCuenta = recuperaRegistroSQL("ctaid", "cntCuenta", "tdoid = '" & strTipoTdo & "'")
					SELECT @varCuenta = ctaid FROM cntCuenta WHERE tdoid = @strTipoTdo;
		--			If IsNull(varCuenta) Or Len(Trim(strTipoTdo)) = 0 Then
					IF (@varCuenta IS NULL OR LEN(LTRIM(RTRIM(@varCuenta))) = 0) BEGIN
		--				capApruebaTxn = ErrMensajeMudo: gvarMensajeError = "El Tipo Documento No Tiene Asociado Una Cuenta Contable..., Tipo Doc " & strTipoTdo
						SET @strMensajeError = @strNombreParamSP + ' ERROR: El Tipo Documento No Tiene Asociado Una Cuenta Contable..., Tipo Doc ' + @strTipoTdo;
						RAISERROR (@strMensajeError, 16, 1);
						---- THROW 51000, @strMensajeError, 1;
		--				Exit Function
		--			End If
					END;
		--			strCtaId = varCuenta
					SET @strCtaId = @varCuenta;
		            
		--			varCuenta = recuperaRegistroSQL("ctaid", "cntConcepto", "conid = 'ACT'")
					SELECT @varCuenta = ctaid FROM cntConcepto WHERE conid = 'ACT';
		--			If Not IsNull(varCuenta) Then 'Verifica Activo
					IF (@varCuenta IS NOT NULL) BEGIN
		--				If Mid(varCuenta, 1, 1) = Mid(strCtaId, 1, 1) Then
						IF (SUBSTRING(@varCuenta,1,1) = SUBSTRING(@strCtaId,1,1)) BEGIN
		--					booBorraTxn = True
							SET @booBorraTxn = 1;
		--				End If
						END;
		--			End If
					END;
		--			'Verifica Pasivo
		--			varCuenta = recuperaRegistroSQL("ctaid", "cntConcepto", "conid = 'PAS'")
					SELECT @varCuenta = ctaid FROM cntConcepto WHERE conid = 'PAS';
		--			If Not IsNull(varCuenta) Then 'Verifica Pasivo
					IF (@varCuenta IS NOT NULL) BEGIN
		--				If Mid(varCuenta, 1, 1) = Mid(strCtaId, 1, 1) Then
						IF (SUBSTRING(@varCuenta,1,1) = SUBSTRING(@strCtaId,1,1)) BEGIN
		--					booBorraTxn = True
							SET @booBorraTxn = 1;
		--				End If
						END;
		--			End If
					END;
		--			'Verifica Patrimonio
		--			varCuenta = recuperaRegistroSQL("ctaid", "cntConcepto", "conid = 'PAT'")
					SELECT @varCuenta = ctaid FROM cntConcepto WHERE conid = 'PAT';
		--			If Not IsNull(varCuenta) Then 'Verifica Patrimonio
					IF (@varCuenta IS NOT NULL) BEGIN
		--				If Mid(varCuenta, 1, 1) = Mid(strCtaId, 1, 1) Then
						IF (SUBSTRING(@varCuenta,1,1) = SUBSTRING(@strCtaId,1,1)) BEGIN
		--					booBorraTxn = True
							SET @booBorraTxn = 1;
		--				End If
						END;
		--				If Mid(varCuenta, 1, 3) = Mid(strCtaId, 1, 3) Then
						IF (SUBSTRING(@varCuenta,1,3) = SUBSTRING(@strCtaId,1,3)) BEGIN
		--					booBorraTxn = True
							SET @booBorraTxn = 1;
		--				End If
						END;
		--			End If
					END;
		--			If booBorraTxn Then
					IF (@booBorraTxn = 1) BEGIN
		--				strSql = "delete from catTxn where catId = '" & strTxnId & "'"
						DELETE FROM catTxn WHERE catId = @strTxnId;
		--				If strTipoBD = "S" Then
		--				   miBD.Execute strSql
		--				Else
		--				   miBD.Execute strSql, dbFailOnError
		--				End If
		--			End If
					END;
		--		End If
				END;
		--	End If
			END;
		--End Function
		
		-- MENSAJE DE FIN DE PROCESO		
		PRINT @strNombreParamSP;
	END TRY
	BEGIN CATCH
		--PRINT ERROR_MESSAGE();
		IF LEN(ISNULL(@strMensajeError,''))=0 BEGIN
		    SET @strMensajeError=@strNombreParamSP + ' ' + ERROR_MESSAGE();
		END ;
		RAISERROR (@strMensajeError, 16, 1);
		---- THROW;
		
		-- MENSAJE DE ERROR DE PROCESO
		PRINT @strNombreParamSP + ' Error';		
	END CATCH;
END
