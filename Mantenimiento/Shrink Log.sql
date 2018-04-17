DECLARE @data AS BIGINT,
	  @porc AS INT,
	  @name AS VARCHAR(30),
	  @porc_log AS SMALLINT

------------ Inicio Reduccion del Log de BILLING ------------
SET @porc_log = 20  --Setear Porcentaje de Log
--Obtengo el tamaño del log actual de BILLING
SELECT @data = SUM(CONVERT(BIGINT,CASE WHEN STATUS & 64 = 0 THEN SIZE ELSE 0 END)) FROM [BILLING].dbo.sysfiles
--Obtengo el nombre logico del FileLog de BILLING
SELECT @name = RTRIM(name) FROM [BILLING].dbo.sysfiles WHERE name LIKE '%log%'
--Saco el 20 porciento del tamaño en megas del log actual de BILLING
SELECT @porc = ((CONVERT(INT,ROUND((CONVERT(DEC(15,2),@data))*8192/1048576,0)))*@porc_log)/100
 -- fuerzo para que haga el checkpoint varias veces
CHECKPOINT
CHECKPOINT
CHECKPOINT
USE [BILLING]
IF @porc < 3000 -- SI EL LOG ES MENOR A 3000 Mb
  DBCC SHRINKFILE(@name,@porc) -- realizo la reduccion del log
ELSE -- SINO LO SHRINKEO A 3000 Mb
  DBCC SHRINKFILE(@name,3000) -- realizo la reduccion del log
------------ Fin Reduccion del Log de BILLING ------------