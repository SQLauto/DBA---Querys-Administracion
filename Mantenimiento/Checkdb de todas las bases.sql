SET NOCOUNT ON
DECLARE @dbname sysname,
		@cmd as nvarchar(max)

DECLARE cursor_db CURSOR FOR 
SELECT name
FROM sys.databases 
WHERE name <> 'tempdb'

OPEN cursor_db

FETCH NEXT FROM cursor_db 
INTO @dbname

WHILE @@FETCH_STATUS = 0
BEGIN
	SET @cmd = 'DBCC CHECKDB(['+@dbname+'],NOINDEX) WITH NO_INFOMSGS'
    --PRINT @cmd
	EXEC sp_executesql @cmd
    FETCH NEXT FROM cursor_db 
    INTO @dbname
END --WHILE @@FETCH_STATUS = 0

CLOSE cursor_db
DEALLOCATE cursor_db

SET NOCOUNT OFF