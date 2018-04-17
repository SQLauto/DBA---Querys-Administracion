SELECT 'kill '+convert (varchar(3),spid) AS TSQL,last_batch,hostname from sysprocesses 
WHERE loginame = 'inmuebles_app' AND DATEDIFF(mi,last_batch,getdate()) > 10 --AND Hostname = 'AGSMS-HPWS04' AND db_name(dbid) = 'Inmuebles'
order by last_batch 