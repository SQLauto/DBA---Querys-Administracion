SET NOCOUNT ON
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
go
-- LinkedServer
select name,product,provider,data_source,provider_string 
from sys.servers
where name <> @@servername
go
-- Jobs
USE msdb
Go
SELECT dbo.sysjobs.Name AS 'Job Name', 
	'Job Enabled' = CASE dbo.sysjobs.Enabled
		WHEN 1 THEN 'Yes'
		WHEN 0 THEN 'No'
	END,
	'Frequency' = CASE dbo.sysschedules.freq_type
		WHEN 1 THEN 'Once'
		WHEN 4 THEN 'Daily'
		WHEN 8 THEN 'Weekly'
		WHEN 16 THEN 'Monthly'
		WHEN 32 THEN 'Monthly relative'
		WHEN 64 THEN 'When SQLServer Agent starts'
	END, 
	'Start Date' = CASE active_start_date
		WHEN 0 THEN null
		ELSE
		substring(convert(varchar(15),active_start_date),1,4) + '/' + 
		substring(convert(varchar(15),active_start_date),5,2) + '/' + 
		substring(convert(varchar(15),active_start_date),7,2)
	END,
	'Start Time' = CASE len(active_start_time)
		WHEN 1 THEN cast('00:00:0' + right(active_start_time,2) as char(8))
		WHEN 2 THEN cast('00:00:' + right(active_start_time,2) as char(8))
		WHEN 3 THEN cast('00:0' 
				+ Left(right(active_start_time,3),1)  
				+':' + right(active_start_time,2) as char (8))
		WHEN 4 THEN cast('00:' 
				+ Left(right(active_start_time,4),2)  
				+':' + right(active_start_time,2) as char (8))
		WHEN 5 THEN cast('0' 
				+ Left(right(active_start_time,5),1) 
				+':' + Left(right(active_start_time,4),2)  
				+':' + right(active_start_time,2) as char (8))
		WHEN 6 THEN cast(Left(right(active_start_time,6),2) 
				+':' + Left(right(active_start_time,4),2)  
				+':' + right(active_start_time,2) as char (8))
	END,
--	active_start_time as 'Start Time',
	CASE len(run_duration)
		WHEN 1 THEN cast('00:00:0'
				+ cast(run_duration as char) as char (8))
		WHEN 2 THEN cast('00:00:'
				+ cast(run_duration as char) as char (8))
		WHEN 3 THEN cast('00:0' 
				+ Left(right(run_duration,3),1)  
				+':' + right(run_duration,2) as char (8))
		WHEN 4 THEN cast('00:' 
				+ Left(right(run_duration,4),2)  
				+':' + right(run_duration,2) as char (8))
		WHEN 5 THEN cast('0' 
				+ Left(right(run_duration,5),1) 
				+':' + Left(right(run_duration,4),2)  
				+':' + right(run_duration,2) as char (8))
		WHEN 6 THEN cast(Left(right(run_duration,6),2) 
				+':' + Left(right(run_duration,4),2)  
				+':' + right(run_duration,2) as char (8))
	END as 'Max Duration',
    CASE(dbo.sysschedules.freq_subday_interval)
		WHEN 0 THEN 'Once'
		ELSE cast('Every ' 
				+ right(dbo.sysschedules.freq_subday_interval,2) 
				+ ' '
				+     CASE(dbo.sysschedules.freq_subday_type)
							WHEN 1 THEN 'Once'
							WHEN 4 THEN 'Minutes'
							WHEN 8 THEN 'Hours'
						END as char(16))
    END as 'Subday Frequency'
FROM dbo.sysjobs 
LEFT OUTER JOIN dbo.sysjobschedules 
ON dbo.sysjobs.job_id = dbo.sysjobschedules.job_id
INNER JOIN dbo.sysschedules ON dbo.sysjobschedules.schedule_id = dbo.sysschedules.schedule_id 
LEFT OUTER JOIN (SELECT job_id, max(run_duration) AS run_duration
		FROM dbo.sysjobhistory
		GROUP BY job_id) Q1
ON dbo.sysjobs.job_id = Q1.job_id
WHERE Next_run_time = 0
UNION
SELECT dbo.sysjobs.Name AS 'Job Name', 
	'Job Enabled' = CASE dbo.sysjobs.Enabled
		WHEN 1 THEN 'Yes'
		WHEN 0 THEN 'No'
	END,
	'Frequency' = CASE dbo.sysschedules.freq_type
		WHEN 1 THEN 'Once'
		WHEN 4 THEN 'Daily'
		WHEN 8 THEN 'Weekly'
		WHEN 16 THEN 'Monthly'
		WHEN 32 THEN 'Monthly relative'
		WHEN 64 THEN 'When SQLServer Agent starts'
	END, 
	'Start Date' = CASE next_run_date
		WHEN 0 THEN null
		ELSE
		substring(convert(varchar(15),next_run_date),1,4) + '/' + 
		substring(convert(varchar(15),next_run_date),5,2) + '/' + 
		substring(convert(varchar(15),next_run_date),7,2)
	END,
	'Start Time' = CASE len(next_run_time)
		WHEN 1 THEN cast('00:00:0' + right(next_run_time,2) as char(8))
		WHEN 2 THEN cast('00:00:' + right(next_run_time,2) as char(8))
		WHEN 3 THEN cast('00:0' 
				+ Left(right(next_run_time,3),1)  
				+':' + right(next_run_time,2) as char (8))
		WHEN 4 THEN cast('00:' 
				+ Left(right(next_run_time,4),2)  
				+':' + right(next_run_time,2) as char (8))
		WHEN 5 THEN cast('0' + Left(right(next_run_time,5),1) 
				+':' + Left(right(next_run_time,4),2)  
				+':' + right(next_run_time,2) as char (8))
		WHEN 6 THEN cast(Left(right(next_run_time,6),2) 
				+':' + Left(right(next_run_time,4),2)  
				+':' + right(next_run_time,2) as char (8))
	END,
--	next_run_time as 'Start Time',
	CASE len(run_duration)
		WHEN 1 THEN cast('00:00:0'
				+ cast(run_duration as char) as char (8))
		WHEN 2 THEN cast('00:00:'
				+ cast(run_duration as char) as char (8))
		WHEN 3 THEN cast('00:0' 
				+ Left(right(run_duration,3),1)  
				+':' + right(run_duration,2) as char (8))
		WHEN 4 THEN cast('00:' 
				+ Left(right(run_duration,4),2)  
				+':' + right(run_duration,2) as char (8))
		WHEN 5 THEN cast('0' 
				+ Left(right(run_duration,5),1) 
				+':' + Left(right(run_duration,4),2)  
				+':' + right(run_duration,2) as char (8))
		WHEN 6 THEN cast(Left(right(run_duration,6),2) 
				+':' + Left(right(run_duration,4),2)  
				+':' + right(run_duration,2) as char (8))
	END as 'Max Duration',
    CASE(dbo.sysschedules.freq_subday_interval)
		WHEN 0 THEN 'Once'
		ELSE cast('Every ' 
				+ right(dbo.sysschedules.freq_subday_interval,2) 
				+ ' '
				+     CASE(dbo.sysschedules.freq_subday_type)
							WHEN 1 THEN 'Once'
							WHEN 4 THEN 'Minutes'
							WHEN 8 THEN 'Hours'
						END as char(16))
    END as 'Subday Frequency'
FROM dbo.sysjobs 
LEFT OUTER JOIN dbo.sysjobschedules ON dbo.sysjobs.job_id = dbo.sysjobschedules.job_id
INNER JOIN dbo.sysschedules ON dbo.sysjobschedules.schedule_id = dbo.sysschedules.schedule_id 
LEFT OUTER JOIN (SELECT job_id, max(run_duration) AS run_duration
		FROM dbo.sysjobhistory
		GROUP BY job_id) Q1
ON dbo.sysjobs.job_id = Q1.job_id
WHERE Next_run_time <> 0
ORDER BY [Start Date],[Start Time]
go
-- Steps Jobs
SELECT
	 [sJOB].[name] AS [JobName]
    , [sJSTP].[step_id] AS [StepNo]
    , [sJSTP].[step_name] AS [StepName]
    , CASE [sJSTP].[subsystem]
        WHEN 'ActiveScripting' THEN 'ActiveX Script'
        WHEN 'CmdExec' THEN 'Operating system (CmdExec)'
        WHEN 'PowerShell' THEN 'PowerShell'
        WHEN 'Distribution' THEN 'Replication Distributor'
        WHEN 'Merge' THEN 'Replication Merge'
        WHEN 'QueueReader' THEN 'Replication Queue Reader'
        WHEN 'Snapshot' THEN 'Replication Snapshot'
        WHEN 'LogReader' THEN 'Replication Transaction-Log Reader'
        WHEN 'ANALYSISCOMMAND' THEN 'SQL Server Analysis Services Command'
        WHEN 'ANALYSISQUERY' THEN 'SQL Server Analysis Services Query'
        WHEN 'SSIS' THEN 'SQL Server Integration Services Package'
        WHEN 'TSQL' THEN 'Transact-SQL script (T-SQL)'
        ELSE sJSTP.subsystem
      END AS [StepType]
    , [sPROX].[name] AS [RunAs]
    , [sJSTP].[database_name] AS [Database]
    , [sJSTP].[command] AS [ExecutableCommand]
    , CASE [sJSTP].[on_success_action]
        WHEN 1 THEN 'Quit the job reporting success'
        WHEN 2 THEN 'Quit the job reporting failure'
        WHEN 3 THEN 'Go to the next step'
        WHEN 4 THEN 'Go to Step: ' 
                    + QUOTENAME(CAST([sJSTP].[on_success_step_id] AS VARCHAR(3))) 
                    + ' ' 
                    + [sOSSTP].[step_name]
      END AS [OnSuccessAction]
    , [sJSTP].[retry_attempts] AS [RetryAttempts]
    , [sJSTP].[retry_interval] AS [RetryInterval (Minutes)]
    , CASE [sJSTP].[on_fail_action]
        WHEN 1 THEN 'Quit the job reporting success'
        WHEN 2 THEN 'Quit the job reporting failure'
        WHEN 3 THEN 'Go to the next step'
        WHEN 4 THEN 'Go to Step: ' 
                    + QUOTENAME(CAST([sJSTP].[on_fail_step_id] AS VARCHAR(3))) 
                    + ' ' 
                    + [sOFSTP].[step_name]
      END AS [OnFailureAction]
FROM
    [msdb].[dbo].[sysjobsteps] AS [sJSTP]
    INNER JOIN [msdb].[dbo].[sysjobs] AS [sJOB]
        ON [sJSTP].[job_id] = [sJOB].[job_id]
    LEFT JOIN [msdb].[dbo].[sysjobsteps] AS [sOSSTP]
        ON [sJSTP].[job_id] = [sOSSTP].[job_id]
        AND [sJSTP].[on_success_step_id] = [sOSSTP].[step_id]
    LEFT JOIN [msdb].[dbo].[sysjobsteps] AS [sOFSTP]
        ON [sJSTP].[job_id] = [sOFSTP].[job_id]
        AND [sJSTP].[on_fail_step_id] = [sOFSTP].[step_id]
    LEFT JOIN [msdb].[dbo].[sysproxies] AS [sPROX]
        ON [sJSTP].[proxy_id] = [sPROX].[proxy_id]
ORDER BY [JobName], [StepNo]
go
-- ErrorLog
sp_readerrorlog