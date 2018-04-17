-- El tama�o del log segun politica definida por ADMIN_SQL es el 20% de Dat para bases menos a 10gb. Para mayores se setea a un 10% del DAT.
-- 	Script para obtener la proyecci�n de crecimiento de una base de datos en base a los espacios ocupados tomados del backup.
-- 	En base a la fecha de inicio ingresada se calcula hasta el �ltimo registro de fecha guardado en cat�logo.
-- 
-- Entradas:
-- 	@base : Definir la base de datos sobre la que se debe tomar la medici�n.
-- 	@ini_fecha : Definir la fecha de inicio del per�odo a analizar.
-- 	@proyeccion : Definir la cantidad de meses de la proyecci�n.
-- 
-- Salidas:
-- 	Prom. Crec. Mes: Promedio del crecimiento en MB por mes en el per�odo elejido.
-- 	Meses Medidos: Cantidad de meses utilizados en la medici�n.
-- 	Meses Proyecci�n: Cantidad de meses utilizados para la proyecci�n.
-- 	Proyecci�n Meses: Proyecci�n total de crecimiento en MB en base a la cantidad de meses de proyeci�n deseada.


declare @ini_fecha datetime
declare @base      varchar(20)
declare @cantmeses int
declare @fin_fecha datetime
declare @ini_size int
declare @fin_size int
declare @proyeccion int

-- Definir variables de entrada

set @proyeccion = 24
set @base = 'DEAUTOS_P'
-- Valido el nombre en caso de Case Sensitive.

set @base = (select name from master.dbo.sysdatabases where upper(name) = upper(@base))


set @ini_fecha = '08/04/15'
set @ini_fecha = (select min(backup_start_date) from msdb.dbo.backupset where type = 'D'
		  and database_name = @base
  		and backup_start_date > @ini_fecha)


set @fin_fecha = (select max(backup_start_date) from msdb.dbo.backupset where type = 'D'
		  and database_name = @base
  		and backup_start_date > @ini_fecha)


set @ini_size = (select convert(int,backup_size/1024/1024) from msdb.dbo.backupset where type = 'D' and database_name = @base
		  and backup_start_date = @ini_fecha)

set @fin_size = (select convert(int,backup_size/1024/1024) from msdb.dbo.backupset where type = 'D' and database_name = @base
		  and backup_start_date = @fin_fecha)

set @cantmeses = (select datediff(mm,@ini_fecha,@fin_fecha))

select 	'Prom Crec. Mes (MB)'= (@fin_size-@ini_size)/@cantmeses,
	'Meses Medidos' = @cantmeses,
	'Meses Proyecci�n' =  @proyeccion,
	'Proyecci�n Meses (MB)' = ((@fin_size-@ini_size)/@cantmeses)*@proyeccion


