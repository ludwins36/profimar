/*
  Cuentas válidas para TRANSFER (concepto BAN).

  Al aprobar, vmaGeneraAsientoVentas busca:
    cntConceptoCuenta WHERE conId = 'BAN' AND ccuReferencia = fptReferenciaIngreso

  pedido_pago_referencia debe ser exactamente un ccuReferencia de esta lista
  (ej. DOL-1042116792), no un texto libre como CTA-BANCO-001.
*/

USE [dbTest];
GO

-- Cuentas bancarias configuradas para el concepto BAN
SELECT
    cc.ccuReferencia AS pedido_pago_referencia,
    cc.ctaId,
    c.ctaNombre,
    cc.octId,
    cc.ccuTabla
FROM cntConceptoCuenta AS cc
LEFT JOIN cntCuenta AS c ON c.ctaId = cc.ctaId
WHERE cc.conId = N'BAN'
ORDER BY cc.ccuReferencia;

-- Relación con cuentas propias de banco (si aplica)
SELECT TOP 50
    cp.cprId,
    cp.banId,
    cp.monId
FROM bntCuentaPropia AS cp
ORDER BY cp.cprId;
GO
