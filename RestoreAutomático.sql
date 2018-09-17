USE [msdb]
GO
/****** Object:  StoredProcedure [dbo].[RestoreAutomatico_SP]    Script Date: 8/6/2018 10:13:01 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER procedure [dbo].[RestoreAutomatico_SP] 
(@dbname sysname,
@path_datafile sysname, 
@path_indexfile sysname,
@path_logfile sysname,
@path_backupfull sysname,
@path_backupdiff sysname,
@login_owner sysname,
@debug bit = 0)
WITH EXECUTE AS OWNER
AS
SET NOCOUNT ON

-- EXEC msdb.dbo.[RestoreAutomatico_SP] 'DEAUTOS_DEV2','D:\MSSQL\DATA\','D:\MSSQL\TLOG\','D:\MSSQL\Backup\FULL\DEAUTOS_P\DEAUTOS_P_backup_FULL.bak','D:\MSSQL\Backup\DIFF\DEAUTOS_P\DEAUTOS_P_backup_DIFF.bak','deautos_dev2_app',1

declare @query nvarchar (255)
declare @sql varchar (max)

-- Obtengo Logicalname de los data/logfiles.
SET @query = 'RESTORE FILELISTONLY FROM DISK = ''' + @path_backupfull + ''''

CREATE TABLE #restoretemp
(
 LogicalName varchar(500),
 PhysicalName varchar(500),
 type varchar(10),
 FilegroupName varchar(200),
 size bigint,
 maxsize bigint,
 fileid bigint,
 createlsn numeric(26),
 droplsn numeric(26),
 uniqueid uniqueidentifier,
 readonlylsn numeric(26),
 readwritelsn numeric(26),
 BackupSizeInBytes bigint,
 SourceBlockSize int,
 FileGroupId int,
 LogGroupGUID uniqueidentifier,
 DifferentialBaseLSN numeric(26),
 DifferentialBaseGUID uniqueidentifier,
 IsReadOnly bit,
 IsPresent bit,
 TDEThumbPRINT varbinary(40)
)
INSERT #restoretemp EXEC (@query)

-- Chequeo si existe la base la Pongo OFFLINE
IF EXISTS (SELECT name FROM sys.databases WHERE name = @dbname AND state = 0)
BEGIN
	SET @sql = 'ALTER DATABASE ['+@dbname+ '] SET  OFFLINE WITH ROLLBACK IMMEDIATE'
	IF @debug = 1
	  PRINT @sql
	EXEC(@sql)
END

-- Armo Script de Restore FULL
SET @sql = 'RESTORE DATABASE ' + @dbname + ' FROM DISK = ''' + @path_backupfull  +  ''' WITH STATS = 10, REPLACE, NORECOVERY, '
SELECT @sql = CASE TYPE WHEN 'D' THEN 
					CASE
						WHEN CHARINDEX('index',LogicalName) = 0 
						THEN @sql + char(13) + ' MOVE ''' + LogicalName + ''' TO ''' + @path_datafile + @dbname + '_' + RIGHT(PhysicalName,CHARINDEX('\',reverse (PhysicalName))-1) + ''','
						ELSE @sql + char(13) + ' MOVE ''' + LogicalName + ''' TO ''' + @path_indexfile + @dbname + '_' + RIGHT(PhysicalName,CHARINDEX('\',reverse (PhysicalName))-1) + ''','
					END 
						WHEN 'L' THEN @sql + char(13) + ' MOVE ''' + LogicalName + ''' TO ''' + @path_logfile + @dbname + '_' + RIGHT(PhysicalName,CHARINDEX('\',reverse (PhysicalName))-1) + ''','
				END
FROM #restoretemp

-- Ejecuta Restore FULL
SET @sql = SUBSTRING(@sql,1,LEN(@sql)-1)
IF @debug = 1
	  PRINT @sql
EXEC(@sql)

-- Si especifica DIFF arma el SQL para hacer restaurarlo.
IF @path_backupdiff IS NOT NULL
BEGIN
  SET @sql = 'RESTORE DATABASE ' + @dbname + ' FROM DISK = ''' + @path_backupdiff  +  ''' WITH STATS = 10, RECOVERY'  
END
ELSE
BEGIN -- Sino especifica DIFF solo arma el recovery
  SET @sql = 'RESTORE DATABASE ' + @dbname + ' WITH RECOVERY'  
END
IF @debug = 1
	PRINT @sql
EXEC(@sql)

-- Cambia Owner de la base a SRL
SET @sql = 'USE ['+@dbname+']; EXEC dbo.sp_changedbowner @loginame = N''srl'', @map = false'
IF @debug = 1
	  PRINT @sql
EXEC(@sql)

-- Setea recovery model a SIMPLE
SET @sql = 'ALTER DATABASE ['+@dbname+ '] SET RECOVERY SIMPLE WITH NO_WAIT'
IF @debug = 1
	  PRINT @sql
EXEC(@sql)

-- Habilita el Update_Statistics
SET @sql = 'ALTER DATABASE ['+@dbname+ '] SET AUTO_UPDATE_STATISTICS ON WITH NO_WAIT'
IF @debug = 1
	  PRINT @sql
EXEC(@sql)

-- Reduce tamaño del Tlog.
SELECT @sql = CASE TYPE WHEN 'L' THEN 'USE ['+@dbname+']; DBCC SHRINKFILE (N'''+LogicalName+''' , 2000)'
				END
FROM #restoretemp
IF @debug = 1
	  PRINT @sql
EXEC(@sql)

DROP TABLE #restoretemp

-- Asigna permisos de Owner
SET @sql = 'USE ['+@dbname+']; CREATE USER ['+@login_owner+'] FOR LOGIN ['+@login_owner+']; ALTER ROLE [db_owner] ADD MEMBER ['+@login_owner+']'
IF @debug = 1
	  PRINT @sql
EXEC(@sql)