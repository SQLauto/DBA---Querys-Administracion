select database_name,type,max(backup_finish_date) 
from msdb..backupset bkp inner join master..sysdatabases dat
			on bkp.database_name = dat.name
where type = 'D'
group by database_name,type