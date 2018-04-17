CREATE PROCEDURE Last_Backup_Full (@dias AS INT = 7)
AS
SET NOCOUNT ON
DECLARE @dbname as sysname,
	@date smalldatetime,
	@fecha varchar(12)

DECLARE cursor_loco CURSOR FOR 
select dbs.name as dbname,max(bkp.backup_finish_date) as backup_finish_date
from master..sysdatabases dbs inner join msdb..backupset bkp
				on dbs.name = bkp.database_name
where bkp.type = 'D' and DATABASEPROPERTYEX(dbs.name,'Status') = 'ONLINE'
group by dbs.name

OPEN cursor_loco

FETCH NEXT FROM cursor_loco 
INTO @dbname,@date

WHILE @@FETCH_STATUS = 0
BEGIN
	IF DATEDIFF(DAY,@date,GETDATE()) > @dias
	BEGIN
	  SET @fecha = CONVERT(varchar(12),@date,103)
	  RAISERROR(90003,17,1, @dbname,@fecha) with log
	END
    FETCH NEXT FROM cursor_loco 
    INTO @dbname,@date
END --WHILE @@FETCH_STATUS = 0

CLOSE cursor_loco
DEALLOCATE cursor_loco

select dbs.name as dbname,max(bkp.backup_finish_date) as backup_finish_date
from master..sysdatabases dbs inner join msdb..backupset bkp
				on dbs.name = bkp.database_name
where bkp.type = 'D' and DATABASEPROPERTYEX(dbs.name,'Status') = 'ONLINE'
group by dbs.name

SET NOCOUNT OFF