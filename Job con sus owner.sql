select job.name as 'Nombre_Job',log.name as 'Login' from msdb.dbo.sysjobs job inner join master.dbo.syslogins log
		on job.owner_sid = log.sid where job.enabled = 1