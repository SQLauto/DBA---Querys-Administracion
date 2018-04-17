select b.*
FROM dbo.sysjobs a
LEFT OUTER JOIN dbo.sysjobschedules b
ON a.job_id = b.job_id
where a.name = 'Reservas Riesgos en Curso'


sp_update_schedule @schedule_id = 28, @owner_login_name = 'HLGV\JRoldanRM'
