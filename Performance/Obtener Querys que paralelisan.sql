SELECT
object_name(p.objectid),
p.query_plan,
cp.plan_handle,
qs.execution_count,
qs.last_execution_time,
qs.last_worker_time,
qs.last_logical_reads,
qs.last_physical_reads,
qs.last_logical_writes,
qs.last_elapsed_time
FROM sys.dm_exec_cached_plans cp
CROSS APPLY sys.dm_exec_query_plan(cp.plan_handle) p
CROSS APPLY sys.dm_exec_sql_text(cp.plan_handle) q
INNER JOIN sys.dm_exec_query_stats qs
				ON qs.plan_handle = cp.plan_handle
WHERE cp.cacheobjtype = 'Compiled Plan'
AND p.query_plan.value('declare namespace p="http://schemas.microsoft.com/sqlserver/2004/07/showplan";max(//p:RelOp/@Parallel)', 'float') > 0
ORDER BY qs.execution_count desc
