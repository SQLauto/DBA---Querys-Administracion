DECLARE @DirBackupNew AS VARCHAR(MAX),
		@DirBackupOld AS VARCHAR(MAX)

SELECT	@DirBackupOld = 'D:\Backupsdb\AGSMS-HPDB06\',
		@DirBackupNEW = 'E:\MSSQL\Backup\'
		

select a.server_name, a.database_name, backup_finish_date, 
((a.backup_size/1024)/1024) as Size_MB,
CASE a.[type] -- Let's decode the three main types of backup here
 WHEN 'D' THEN 'Full'
 WHEN 'I' THEN 'Differential'
 WHEN 'L' THEN 'Transaction Log'
 ELSE a.[type]
END as BackupType
 ,b.physical_device_name,
 'RESTORE DATABASE ['+a.database_name+'_PRUEBA] FROM DISK = N'''+REPLACE(b.physical_device_name,@DirBackupOld,@DirBackupNew)+''' WITH NORECOVERY,STATS = 25'
from msdb.dbo.backupset a join msdb.dbo.backupmediafamily b
  on a.media_set_id = b.media_set_id
where a.database_name = 'Empleos' and backup_finish_date between '20160306 02:00' and '20160306 22:01' and a.[type] = 'L'
order by backup_finish_date
