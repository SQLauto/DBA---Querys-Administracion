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
