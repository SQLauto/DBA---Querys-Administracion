SET NOCOUNT ON
go

-- DATOS GENERAL SERVER
EXEC master..xp_msver
go

-- DATOS DE LA INSTANCIA
SELECT  @@SERVERNAME AS ServerName,
		@@LANGUAGE AS Language, 
		SERVERPROPERTY('Collation') AS ServerCollation, 
		SERVERPROPERTY('ProductVersion') AS ProductVersion,
		SERVERPROPERTY('ProductLevel') AS ProductLevel,
		SERVERPROPERTY('Edition') AS Edition

-- SYSADMINS
select name,sysadmin,denylogin from sys.syslogins 
where sysadmin = 1

-- SP_CONFIGURE
EXEC master..sp_configure 'show advanced options',1
go
reconfigure
go
EXEC master..sp_configure
go
EXEC master..sp_configure 'show advanced options',0
go
reconfigure
go

-- CONFIGURACION DE LAS BASES
SELECT	b.name AS DbName,
		suser_sname(b.sid) AS Owner,
		SUM(CASE WHEN a.groupid <> 0 THEN (a.size*8)/1024 END) AS DataSizeMB,
		SUM(CASE WHEN a.groupid = 0 THEN (a.size*8)/1024 END) AS LogSizeMB, 
		DATABASEPROPERTYEX(b.name,'Collation') AS Collation,  
		CASE DATABASEPROPERTYEX(b.name,'IsAutoCreateStatistics')
		  WHEN 1 THEN 'TRUE'
		  ELSE 'FALSE'
		END AS IsAutoCreateStatistics,
		CASE DATABASEPROPERTYEX(b.name,'IsAutoUpdateStatistics')
		  WHEN 1 THEN 'TRUE'
		  ELSE 'FALSE'
		END AS IsAutoUpdateStatistics,
		CASE DATABASEPROPERTYEX(b.name,'IsAutoShrink')
		  WHEN 1 THEN 'TRUE'
		  ELSE 'FALSE'
		END AS IsAutoShrink,
		CASE DATABASEPROPERTYEX(b.name,'IsAutoClose')
		  WHEN 1 THEN 'TRUE'
		  ELSE 'FALSE'
		END AS IsAutoClose,
		b.cmptlevel AS ComptLevel,
		(SELECT MAX(backup_finish_date) FROM msdb.dbo.backupset WHERE type = 'D' AND database_name = b.name COLLATE Latin1_General_CS_AI GROUP BY database_name) AS LastBkpFullDate,
		CONVERT(VARCHAR(12),DATABASEPROPERTYEX(b.name,'Recovery')) AS RecoveryMode,
		(SELECT MAX(backup_finish_date) FROM msdb.dbo.backupset WHERE type = 'L' AND database_name = b.name COLLATE Latin1_General_CS_AI GROUP BY database_name) AS LastBkpLogDate
FROM master.dbo.sysaltfiles a INNER JOIN master.dbo.sysdatabases b
							ON a.dbid = b.dbid
WHERE a.dbid <> 32767
GROUP BY b.name,suser_sname(b.sid),b.cmptlevel
go
-- LOGICAL NAME Y TAMAÑOS.
select	db_name(database_id) as DBName,
		name as LogicalName,
		physical_name as PhysicalName,
		state_desc as State,
		(size*8)/1024 as SizeMB,
		growth,
		max_size
from sys.master_files
go
-- TAMAÑO BASES
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

GO
-- Configuracion Tempdb
sp_HELPdb tempdb
GO
-- Paquetes de SSIS
IF @@version LIKE '%SQL Server 2005%' 
    SELECT  a.name AS PackageName ,
            a.[description] AS [Description] ,
            b.foldername AS FolderName ,
            CASE a.packagetype
              WHEN 0 THEN 'Default client'
              WHEN 1 THEN 'I/O Wizard'
              WHEN 2 THEN 'DTS Designer'
              WHEN 3 THEN 'Replication'
              WHEN 5 THEN 'SSIS Designer'
              WHEN 6 THEN 'Maintenance Plan'
              ELSE 'Unknown'
            END AS PackageTye ,
            c.name AS OwnerName ,
            a.createdate AS CreateDate ,
            DATALENGTH(a.packagedata) AS PackageSize
    FROM    msdb.dbo.sysdtspackages90 AS a --SQL 2005
            INNER JOIN msdb.dbo.sysdtspackagefolders90 AS b --SQL 2005
            ON a.folderid = b.folderid
            INNER JOIN sys.syslogins AS c ON a.ownersid = c.sid
    ORDER BY a.name
ELSE 
    SELECT  a.name AS PackageName ,
            a.[description] AS [Description] ,
            b.foldername AS FolderName ,
            CASE a.packagetype
              WHEN 0 THEN 'Default client'
              WHEN 1 THEN 'I/O Wizard'
              WHEN 2 THEN 'DTS Designer'
              WHEN 3 THEN 'Replication'
              WHEN 5 THEN 'SSIS Designer'
              WHEN 6 THEN 'Maintenance Plan'
              ELSE 'Unknown'
            END AS PackageTye ,
            c.name AS OwnerName ,
            a.createdate AS CreateDate ,
            DATALENGTH(a.packagedata) AS PackageSize
    FROM    msdb.dbo.sysssispackages AS a --SQL 2008
            INNER JOIN msdb.dbo.sysssispackagefolders AS b --SQL 2008
            ON a.folderid = b.folderid
            INNER JOIN sys.syslogins AS c ON a.ownersid = c.sid
    ORDER BY a.name