

-- Obtener Fecha último reinicio
SELECT sqlserver_start_time FROM sys.dm_os_sys_info

-- TOP 50 avg_logical_reads
SELECT TOP 50 
		SUBSTRING(qt.TEXT, (qs.statement_start_offset/2)+1,
		((CASE qs.statement_end_offset
				WHEN -1 THEN DATALENGTH(qt.TEXT)
				ELSE qs.statement_end_offset
		   END - qs.statement_start_offset)/2)+1),
		(SELECT name from sys.databases where database_id = qt.dbid) as database_name,
		qs.execution_count,
		total_logical_reads/qs.execution_count avg_logical_reads,
		qs.total_logical_reads, 
		qs.last_logical_reads,
		total_logical_writes/qs.execution_count avg_logical_writes,
		qs.total_logical_writes, 
		qs.last_logical_writes,
		qs.total_elapsed_time/1000000 total_elapsed_time_in_S,
		(qs.total_elapsed_time/qs.execution_count)/1000000 Time_avg_in_S,
		qs.last_elapsed_time/1000000 last_elapsed_time_in_S,
		qs.last_execution_time
FROM sys.dm_exec_query_stats qs CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) qt
								CROSS APPLY sys.dm_exec_query_plan(qs.plan_handle) qp
ORDER BY (total_logical_reads/qs.execution_count) DESC 

-- TOP 50 avg_logical_writes
SELECT TOP 50 
		SUBSTRING(qt.TEXT, (qs.statement_start_offset/2)+1,
		((CASE qs.statement_end_offset
				WHEN -1 THEN DATALENGTH(qt.TEXT)
				ELSE qs.statement_end_offset
		   END - qs.statement_start_offset)/2)+1),
		(SELECT name from sys.databases where database_id = qt.dbid) as database_name,
		qs.execution_count,
		total_logical_reads/qs.execution_count avg_logical_reads,
		qs.total_logical_reads, 
		qs.last_logical_reads,
		total_logical_writes/qs.execution_count avg_logical_writes,
		qs.total_logical_writes, 
		qs.last_logical_writes,
		qs.total_elapsed_time/1000000 total_elapsed_time_in_S,
		(qs.total_elapsed_time/qs.execution_count)/1000000 Time_avg_in_S,
		qs.last_elapsed_time/1000000 last_elapsed_time_in_S,
		qs.last_execution_time
FROM sys.dm_exec_query_stats qs CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) qt
								CROSS APPLY sys.dm_exec_query_plan(qs.plan_handle) qp
ORDER BY (total_logical_writes/qs.execution_count) DESC 

-- TOP 50 execution_count
SELECT TOP 50 
		SUBSTRING(qt.TEXT, (qs.statement_start_offset/2)+1,
		((CASE qs.statement_end_offset
				WHEN -1 THEN DATALENGTH(qt.TEXT)
				ELSE qs.statement_end_offset
		   END - qs.statement_start_offset)/2)+1),
		(SELECT name from sys.databases where database_id = qt.dbid) as database_name,
		qs.execution_count,
		total_logical_reads/qs.execution_count avg_logical_reads,
		qs.total_logical_reads, 
		qs.last_logical_reads,
		total_logical_writes/qs.execution_count avg_logical_writes,
		qs.total_logical_writes, 
		qs.last_logical_writes,
		qs.total_elapsed_time/1000000 total_elapsed_time_in_S,
		(qs.total_elapsed_time/qs.execution_count)/1000000 Time_avg_in_S,
		qs.last_elapsed_time/1000000 last_elapsed_time_in_S,
		qs.last_execution_time
FROM sys.dm_exec_query_stats qs CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) qt
								CROSS APPLY sys.dm_exec_query_plan(qs.plan_handle) qp
ORDER BY execution_count DESC 



