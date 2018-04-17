CREATE PROCEDURE Backup_Hist_sp
@datetime datetime = NULL,
@dbname sysname = NULL
AS

SET NOCOUNT ON
SET ARITHABORT OFF

IF @datetime IS NULL
BEGIN
SET @datetime = (SELECT GETDATE()-1)
END

IF @dbname IS NULL
BEGIN
SELECT CONVERT (varchar(30), @@servername) AS Instance, 
CONVERT (varchar(30), database_name) AS DBName,
CONVERT (varchar(30), backup_start_date) AS BackupStartDate,
CONVERT (varchar(30), backup_finish_date) AS BackupFinishDate,
CASE WHEN type = 'D' THEN 'Full' WHEN type = 'L' THEN 'Log' WHEN type = 'I' THEN 'DIFF' WHEN type = 'F' THEN 'File' END AS Type,
CEILING (backup_size / 1024 / 1024) AS 'Size(MB)',
CONVERT (varchar(40), [description]) AS 'Description'
FROM msdb..backupset 
WHERE backup_start_date > @datetime 
ORDER BY backup_start_date DESC 
END
ELSE
BEGIN
SELECT CONVERT (varchar(30), @@servername) AS Instance,
CONVERT (varchar(30), database_name) AS DBName,
CONVERT (varchar(30), backup_start_date) AS BackupStartDate,
CONVERT (varchar(30), backup_finish_date) AS BackupFinishDate,
CASE WHEN type = 'D' THEN 'Full' WHEN type = 'L' THEN 'Log' WHEN type = 'I' THEN 'DIFF' WHEN type = 'F' THEN 'File' END AS Type,
CEILING (backup_size / 1024 / 1024) AS 'Size(MB)',
CONVERT (varchar(40), [description]) AS 'Description'
FROM msdb..backupset
WHERE backup_start_date > @datetime and database_name = @dbname 
ORDER BY backup_start_date DESC 
END
 