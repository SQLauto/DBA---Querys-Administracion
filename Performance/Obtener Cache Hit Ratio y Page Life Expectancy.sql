
SELECT base.cntr_value * 1.0 / rat.cntr_value * 100.0 AS [Buffer Cache Hit Ratio]
, base.cntr_value AS [Buffer cache hit ratio base]
, rat.cntr_value AS [Buffer cache hit ratio]
FROM sys.dm_os_performance_counters base CROSS JOIN sys.dm_os_performance_counters rat
WHERE base.counter_name = 'Buffer cache hit ratio base'
AND rat.counter_name = 'Buffer cache hit ratio'
GO

SELECT counter_name
, cntr_value AS [PLE in sec]
, cntr_value / 60 AS [PLE in min]
FROM sys.dm_os_performance_counters 
WHERE counter_name = 'Page life expectancy'
AND OBJECT_NAME LIKE '%:Buffer Manager%'