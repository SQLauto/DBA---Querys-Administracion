SET NOCOUNT ON


SELECT	CONVERT(VARCHAR(25),SERVERPROPERTY('ServerName')) as ServerName,
		CONVERT(VARCHAR(15),SERVERPROPERTY('ProductVersion')) as Build,
		CASE (CONVERT(DECIMAL(3,1),(SUBSTRING(CONVERT(VARCHAR(20),SERVERPROPERTY('ProductVersion')),1,CHARINDEX('.',CONVERT(VARCHAR(20),SERVERPROPERTY('ProductVersion')))+1))))
			WHEN 8 THEN 'Microsoft SQL Server 2000'
			WHEN 9 THEN 'Microsoft SQL Server 2005'
			WHEN 10 THEN 'Microsoft SQL Server 2008'
			WHEN 10.5 THEN 'Microsoft SQL Server 2008 R2'
		END + ' ' + CONVERT(VARCHAR(30),SERVERPROPERTY('Edition')) + ' - ' + CONVERT(VARCHAR(3),SERVERPROPERTY('ProductLevel')) AS Version,
		(SELECT COUNT(*) FROM master..sysdatabases WHERE name NOT IN ('MASTER','MODEL','MSDB','TEMPDB','DISTRIBUTION')) AS CantDBUsuario
		
-- DATOS DE LA INSTANCIA
SELECT  @@SERVERNAME AS ServerName,
		@@LANGUAGE AS Language, 
		SERVERPROPERTY('Collation') AS ServerCollation, 
		SERVERPROPERTY('ProductVersion') AS ProductVersion,
		SERVERPROPERTY('ProductLevel') AS ProductLevel,
		SERVERPROPERTY('Edition') AS Edition

select name,sysadmin from syslogins where sysadmin = 1

-- DATOS DE CADA BASE
SELECT  CONVERT(VARCHAR(40),a.name) AS Name,
		CONVERT(VARCHAR(10),SUM((b.size*8)/1024)) AS SizeMB, 
		CONVERT(VARCHAR(20),suser_sname(a.sid)) AS Owner, 
		CONVERT(VARCHAR(35),DATABASEPROPERTYEX(a.name,'Collation')) AS Collation,  
		CASE DATABASEPROPERTYEX(a.name,'IsAutoCreateStatistics')
		  WHEN 1 THEN 'TRUE'
		  ELSE 'FALSE'
		END AS IsAutoCreateStatistics,
		CASE DATABASEPROPERTYEX(a.name,'IsAutoUpdateStatistics')
		  WHEN 1 THEN 'TRUE'
		  ELSE 'FALSE'
		END AS IsAutoUpdateStatistics,
		CASE DATABASEPROPERTYEX(a.name,'IsAutoShrink')
		  WHEN 1 THEN 'TRUE'
		  ELSE 'FALSE'
		END AS IsAutoShrink,
		CASE DATABASEPROPERTYEX(a.name,'IsAutoClose')
		  WHEN 1 THEN 'TRUE'
		  ELSE 'FALSE'
		END AS IsAutoClose,
		CONVERT(VARCHAR(12),DATABASEPROPERTYEX(a.name,'Recovery')) AS RecoveryMode,
		CASE CONVERT(VARCHAR(12),DATABASEPROPERTYEX(a.name,'Recovery'))
		  WHEN 'FULL' THEN (SELECT max(backup_finish_date) FROM msdb..backupset WHERE database_name = a.name COLLATE SQL_Latin1_General_CP1_CI_AS AND type = 'L')
		  ELSE NULL
		END AS Last_Backup_Log_Date,
		CONVERT(VARCHAR(10),a.cmptlevel) AS ComptLevel
FROM master.dbo.sysdatabases a INNER JOIN master.dbo.sysaltfiles b
								ON a.dbid = b.dbid
WHERE a.version <> 0
GROUP BY a.name,CONVERT(VARCHAR(20),suser_sname(a.sid)),a.cmptlevel
ORDER BY SUM((b.size*8)/1024) desc

-- CANTIDAD DE OBJETOS X BASE
DECLARE @base AS VARCHAR(50),
		@query AS VARCHAR(400)

DECLARE bases CURSOR READ_ONLY FAST_FORWARD FOR 
SELECT UPPER(name) FROM master.dbo.sysdatabases WHERE name NOT IN ('master','msdb','tempdb','model') AND version <> 0
ORDER BY name
OPEN bases

FETCH NEXT FROM bases 
INTO @base

WHILE @@FETCH_STATUS = 0
BEGIN
  SET @query = 'SELECT '''+@base+': Cant. Tablas: ''+CONVERT(VARCHAR(4),count(*)) FROM ['+@base+'].dbo.sysobjects WHERE xtype = ''U'' AND name NOT LIKE ''sys%'''
  EXEC(@query)
  SET @query = 'SELECT '''+@base+': Cant. Vistas: ''+CONVERT(VARCHAR(4),count(*)) FROM ['+@base+'].dbo.sysobjects WHERE xtype = ''V'' AND name NOT LIKE ''sys%'' AND name NOT LIKE ''syncobj%'''
  EXEC(@query)
  SET @query = 'SELECT '''+@base+': Cant. SP: ''+CONVERT(VARCHAR(4),count(*)) FROM [' +@base+'].dbo.sysobjects WHERE xtype = ''P'' AND name NOT LIKE ''dt_%'''
  EXEC(@query)
  SET @query = 'SELECT '''+@base+': Cant. Funciones: ''+CONVERT(VARCHAR(4),count(*)) FROM ['+@base+'].dbo.sysobjects WHERE xtype = ''FN'''
  EXEC(@query)
  SET @query = 'SELECT '''+@base+': Cant. Usuarios: ''+CONVERT(VARCHAR(4),count(*)) FROM ['+@base+'].dbo.sysusers WHERE hasdbaccess = 1 AND islogin = 1'
  EXEC(@query)
  FETCH NEXT FROM bases 
  INTO @base
END

CLOSE bases
DEALLOCATE bases


