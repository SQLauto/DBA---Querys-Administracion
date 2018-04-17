SET NOCOUNT ON

DECLARE @dbname AS SYSNAME,
		@query AS NVARCHAR(MAX)

CREATE TABLE #databasespace (DbName SYSNAME,DataSizeMB INT, DataUsedMB INT,LogSizeMB INT, LogUsedMB INT)

DECLARE cursor_loco CURSOR FOR 
SELECT name FROM master.dbo.sysdatabases
WHERE DATABASEPROPERTYEX(name,'status')= 'ONLINE'

OPEN cursor_loco

FETCH NEXT FROM cursor_loco 
INTO @dbname

WHILE @@FETCH_STATUS = 0
BEGIN
	SET @query = 'SET ANSI_WARNINGS OFF;
	USE ['+@dbname+'];
	SELECT	'''+@dbname+''',
			SUM(CASE WHEN (groupid = 1) THEN CONVERT(INT,ROUND(size/128.,2))END) AS DataSizeMB,
			SUM(CASE WHEN (groupid = 1) THEN CONVERT(INT,ROUND(fileproperty(name,''SpaceUsed'')/128.,2)) END) AS DataUsedMB,
			SUM(CASE WHEN (groupid = 0) THEN CONVERT(INT,ROUND(size/128.,2))END) AS LogSizeMB,
			SUM(CASE WHEN (groupid = 0) THEN CONVERT(INT,ROUND(fileproperty(name,''SpaceUsed'')/128.,2)) END) AS LogUsedMB
	FROM dbo.sysfiles'
	
	INSERT INTO #databasespace
	EXEC sp_executesql @query
	
	FETCH NEXT FROM cursor_loco 
	INTO @dbname
END --WHILE @@FETCH_STATUS = 0

SELECT * FROM #databasespace

DROP TABLE #databasespace

CLOSE cursor_loco
DEALLOCATE cursor_loco
