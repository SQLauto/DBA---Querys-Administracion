	SELECT COUNT(*) AS [CantConexiones]FROM sys.sysprocesses WHERE hostname NOT IN ('AGSMS-HPDB13','','AGSMS-HPDB03') and loginame <> ''
	SELECT	[Program_Name] AS [ProgramName],
			[Hostname] AS [HostName],
			[LogiName] AS [LogiName],
			db_name(dbid) AS [Dbname],
			count(*) as Total,
			COUNT(CASE WHEN (DATEDIFF(mi,last_batch,getdate())>=5 AND STATUS = 'SLEEPING') THEN 1 END) AS [Idle5min]
	FROM sys.sysprocesses
	WHERE hostname NOT IN ('AGSMS-HPDB13','','AGSMS-HPDB03') and loginame <> ''
	GROUP BY [Program_Name],[Hostname],[Loginame],db_name(dbid)
	ORDER BY [Program_Name],[Hostname]     
	
	
SELECT 'kill '+convert(varchar(10),spid) 
FROM sys.sysprocesses 
WHERE loginame = 'u_argenprop_p' -- Conexiones de X usuario
AND hostname = 'AGSMS-GPWS103' -- Conexiones de X hostname.
WHERE DATEDIFF(mi,last_batch,getdate())>=1 AND STATUS = 'RUNNING' -- Conexiones que hace más de 5 minutos que están en SLEEPING


sp_whoisactive @get_plans = 1
--master..mata_Conexion 'Inmuebles'

sp_readerrorlog
sp_helpindex VisitasVendedor
dbcc show_Statistics (VisitasVendedor,idx_Nonclustered_VisitasVendedor_IdVendedor)

UPDATE STATISTICS (

UPDATE STATISTICS dbo.VisitasVendedor(idx_Nonclustered_VisitasVendedor_IdVendedor) WITH SAMPLE 5 PERCENT;

select * from sys.sysprocesses where program_name = '.Net SqlClient Data Provider                                                                                                    '

dbcc inputbuffer(306)




sp_whoisactive
go
sp_who2 89

USE [Inmuebles]
GO




