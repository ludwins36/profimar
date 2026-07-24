/*
  Ajuste LOCAL de periodos para pruebas de aprobación VEN.

  Errores que corrige:
    - capApruebaTxn (modId = 'ca'): catFechaDoc vs modFechaInicial/Final
    - cnpApruebaTxn (modId = 'cn'): cntFechaDoc vs modFechaInicial/Final
      → "Contabilidad - El documento debe estar entre dd/mm/yyyy y dd/mm/yyyy"
    - vmaApruebaTxn (modId = 'vn'): vntFechaDoc vs periodo o fecha diaria

  Cadena de fechas al aprobar un VEN:
    vntTxn.vntFechaDoc
      → cntPosteoCn.posFechaDoc   (vmaGeneraAsientoVentas / CreaPosteo)
      → cntTxn.cntFechaDoc        (cnpGeneraCreaUnaTxnAutomatica / CreaCntTxn)
      → validado en cnpApruebaTxn contra gntParametroModulo modId = 'cn'

  La API asigna vntFechaDoc = fecha del servidor SQL (GETDATE()).

  IMPORTANTE: solo entorno de prueba. No usar en producción.
*/

USE [dbTest];
GO

-- ========== 1) Ver configuración actual ==========
SELECT modId,
       modFechaInicial,
       modFechaFinal,
       modVerificaFechaDiaria,
       modQueFechaAprobacion
FROM gntParametroModulo
WHERE modId IN ('ca', 'cn', 'vn');

SELECT vntId, vntFechaDoc, vntEstado, vntArticuloMoneda, vntTC, tdoid
FROM vntTxn
WHERE vntId IN ('PVEN121324', 'PVEN121323');  -- cambiar al pedido que estés probando

-- ========== 2) Guardar valores originales (copiar resultado antes de cambiar) ==========
-- SELECT modId, modFechaInicial, modFechaFinal, modVerificaFechaDiaria
-- FROM gntParametroModulo WHERE modId IN ('ca', 'cn', 'vn');

BEGIN TRANSACTION;

-- ========== OPCIÓN A (recomendada): ampliar periodo al año en curso ==========
UPDATE gntParametroModulo
SET modFechaInicial = '20260101',
    modFechaFinal   = '20261231',
    modVerificaFechaDiaria = 0
WHERE modId IN ('ca', 'cn', 'vn');

-- ========== OPCIÓN B: exigir solo fecha de hoy (coherente con vntFechaDoc = GETDATE()) ==========
/*
UPDATE gntParametroModulo
SET modVerificaFechaDiaria = 1
WHERE modId IN ('cn', 'vn');
*/

-- ========== OPCIÓN C: mover el pedido al periodo abierto actual (mar–abr 2026) ==========
-- Usar solo si NO quieres tocar gntParametroModulo y el periodo sigue 01/03–01/04/2026:
/*
UPDATE vntTxn
SET vntFechaDoc = '20260315'
WHERE vntId = 'PVEN121324';
*/

-- ========== 3) Confirmar cambio ==========
SELECT modId,
       modFechaInicial,
       modFechaFinal,
       modVerificaFechaDiaria
FROM gntParametroModulo
WHERE modId IN ('ca', 'cn', 'vn');

-- Probar aprobación y luego:
-- COMMIT TRANSACTION;
-- o revertir todo:
ROLLBACK TRANSACTION;

GO
