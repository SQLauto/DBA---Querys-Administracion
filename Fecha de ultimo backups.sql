select database_name,name,user_name,backup_finish_date 
from msdb..backupset 
where type in ('D','I') and database_name = 'NOMBRE_DB' -- CAMBIAR NOMBRE DE BASE
order by backup_finish_date desc 