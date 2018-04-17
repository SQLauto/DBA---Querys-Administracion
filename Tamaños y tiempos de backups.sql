select	database_name,
		CASE type
		  WHEN 'D' THEN 'FULL'
		  WHEN 'L' THEN 'TLOG'
		  WHEN 'I' THEN 'DIFF'
		  ELSE 'OTHER'
		END as type,
		CONVERT(VARCHAR(20),CONVERT(int,(backup_size/1024)/1024))+' MB' as size,
		--CONVERT(VARCHAR(20),CONVERT(int,(compressed_backup_size/1024)/1024))+' MB' as size_compressed,
		backup_start_date,
		backup_finish_date,
		CONVERT(VARCHAR(20),datediff(minute,backup_start_date,backup_finish_date))+' Min' as duration ,
		description
from msdb..backupset 
where database_name = 'NOMBRE_BASE'
order by backup_finish_date desc