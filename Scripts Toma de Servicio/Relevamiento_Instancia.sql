SET NOCOUNT ON
go
-- DATOS GENERAL SERVER
EXEC master..xp_msver
go
SELECT	CONVERT(VARCHAR(25),SERVERPROPERTY('ServerName')) as ServerName,
		CONVERT(VARCHAR(15),SERVERPROPERTY('ProductVersion')) as Build,
		CASE (CONVERT(DECIMAL(3,1),(SUBSTRING(CONVERT(VARCHAR(20),SERVERPROPERTY('ProductVersion')),1,CHARINDEX('.',CONVERT(VARCHAR(20),SERVERPROPERTY('ProductVersion')))+1))))
			WHEN 8 THEN 'Microsoft SQL Server 2000'
			WHEN 9 THEN 'Microsoft SQL Server 2005'
			WHEN 10 THEN 'Microsoft SQL Server 2008'
			WHEN 10.5 THEN 'Microsoft SQL Server 2008 R2'
		END + ' ' + CONVERT(VARCHAR(30),SERVERPROPERTY('Edition')) + ' - ' + CONVERT(VARCHAR(3),SERVERPROPERTY('ProductLevel')) AS Version,
		(SELECT
go
-- DATOS DE LA INSTANCIA
SELECT  @@SERVERNAME AS ServerName,
		@@LANGUAGE AS Language, 
		SERVERPROPERTY('Collation') AS ServerCollation, 
		SERVERPROPERTY('ProductVersion') AS ProductVersion,
		SERVERPROPERTY('ProductLevel') AS ProductLevel,
		SERVERPROPERTY('Edition') AS Edition
-- SYSADMINS
select name,sysadmin,denylogin from syslogins 
where sysadmin = 1

-- SP_CONFIGURE
EXEC master..sp_configure 'show advanced options',1
go
reconfigure
go
EXEC master..sp_configure
go
EXEC master..sp_configure 'show advanced options',0
reconfigure
go
-- CONFIGURACION DE LAS BASES
SELECT	CONVERT(VARCHAR(40),a.name) AS name,
		CONVERT(VARCHAR(10),SUM((b.size*8)/1024)) AS SizeMB,
		CONVERT(VARCHAR(20),suser_sname(a.owner_sid)) AS Owner, 
		CONVERT(VARCHAR(35),a.collation_name) AS collation_name,  
		CASE a.is_auto_create_stats_on
		  WHEN 1 THEN 'TRUE'
		  ELSE 'FALSE'
		END AS is_auto_create_stats_on,
		CASE a.is_auto_update_stats_on
		  WHEN 1 THEN 'TRUE'
		  ELSE 'FALSE'
		END AS is_auto_update_stats_on,
		CASE a.is_auto_update_stats_async_on
		  WHEN 1 THEN 'TRUE'
		  ELSE 'FALSE'
		END AS is_auto_update_stats_async_on,
		CASE a.is_auto_shrink_on
		  WHEN 1 THEN 'TRUE'
		  ELSE 'FALSE'
		END AS is_auto_shrink_on,
		CASE a.is_auto_close_on
		  WHEN 1 THEN 'TRUE'
		  ELSE 'FALSE'
		END AS is_auto_close_on,
		CONVERT(VARCHAR(12),a.recovery_model_desc) AS recovery_model_desc,
		CONVERT(VARCHAR(10),a.compatibility_level) AS compatibility_level
FROM sys.databases a INNER JOIN master.dbo.sysaltfiles b
								ON a.database_id = b.dbid
WHERE a.state_desc = 'ONLINE'
GROUP BY a.name,suser_sname(a.owner_sid),a.collation_name,is_auto_create_stats_on,is_auto_update_stats_on,
		is_auto_update_stats_async_on,is_auto_close_on,is_auto_shrink_on,a.recovery_model_desc,a.compatibility_level

