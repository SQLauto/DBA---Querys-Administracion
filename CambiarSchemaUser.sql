SET NOCOUNT ON

DECLARE @dbname AS sysname,
		@cmd AS nvarchar(max),
		@username AS sysname

DECLARE cursor_dbname CURSOR FOR 
SELECT name 
FROM master..sysdatabases 
WHERE name NOT IN ('master','model','tempdb','msdb')

OPEN cursor_dbname

FETCH NEXT FROM cursor_dbname 
INTO @dbname

CREATE TABLE ##ChangeSchemaUsers (dbname sysname,username sysname )

WHILE @@FETCH_STATUS = 0
BEGIN
	SET @cmd = 'SELECT '''+@dbname+''',name FROM '+@dbname+'.sys.sysusers WHERE issqluser = 1 AND uid > 4'  
	--PRINT @cmd
	INSERT ##ChangeSchemaUsers
	EXEC(@cmd)
    FETCH NEXT FROM cursor_dbname 
    INTO @dbname
END --WHILE @@FETCH_STATUS = 0

CLOSE cursor_dbname
DEALLOCATE cursor_dbname

DECLARE cursor_ChangeSchemaUsers CURSOR FOR 
SELECT dbname,username
FROM ##ChangeSchemaUsers


OPEN cursor_ChangeSchemaUsers

FETCH NEXT FROM cursor_ChangeSchemaUsers 
INTO @dbname,@username

WHILE @@FETCH_STATUS = 0
BEGIN
	SET @cmd = 'EXEC(''USE ['+@dbname+']; ALTER USER ['+@username+'] WITH DEFAULT_SCHEMA=[dbo]'')'
	EXEC(@cmd)
	--PRINT @cmd
    FETCH NEXT FROM cursor_ChangeSchemaUsers 
    INTO @dbname,@username
END --WHILE @@FETCH_STATUS = 0

CLOSE cursor_ChangeSchemaUsers
DEALLOCATE cursor_ChangeSchemaUsers
DROP TABLE ##ChangeSchemaUsers

SET NOCOUNT OFF
