SET NOCOUNT ON

DECLARE @dbname AS SYSNAME,
		@cmd AS NVARCHAR(1000)

DECLARE cursor_dbname CURSOR FOR 
SELECT name 
FROM master..sysdatabases 
WHERE name NOT IN ('master','model','tempdb','msdb')

OPEN cursor_dbname

FETCH NEXT FROM cursor_dbname 
INTO @dbname

WHILE @@FETCH_STATUS = 0
BEGIN
	SET @cmd = 'ALTER DATABASE ['+@dbname+'] SET SINGLE_USER WITH ROLLBACK IMMEDIATE; ALTER DATABASE ['+@dbname+'] SET MULTI_USER WITH ROLLBACK IMMEDIATE; EXEC sp_detach_db @dbname ='+''''+@dbname+''', @skipchecks=''true'''  
	--EXEC sp_executesql @cmd
	PRINT @cmd
    FETCH NEXT FROM cursor_dbname 
    INTO @dbname
END --WHILE @@FETCH_STATUS = 0

CLOSE cursor_dbname
DEALLOCATE cursor_dbname
