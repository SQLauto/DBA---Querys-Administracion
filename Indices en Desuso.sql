SELECT sqlserver_start_time FROM sys.dm_os_sys_info
go
SELECT o.name Object_Name,
       SCHEMA_NAME(o.schema_id) Schema_name,
	   o.type,
       i.name Index_name,
	   i.is_disabled,
       i.Type_Desc,
	   (8 * SUM(a.used_pages))/1024 AS 'Indexsize(MB)',
	   s.user_seeks,
	   s.user_scans,
	   s.user_lookups,
	   'DROP INDEX ['+i.name+'] ON ['+SCHEMA_NAME(o.schema_id)+'].['+o.name+']' as 'TSQL para Borrado'
 FROM sys.objects AS o JOIN sys.indexes AS i ON o.object_id = i.object_id
	JOIN sys.dm_db_index_usage_stats AS s ON i.object_id = s.object_id AND i.index_id = s.index_id
	JOIN sys.partitions AS p ON p.OBJECT_ID = i.OBJECT_ID AND p.index_id = i.index_id
	JOIN sys.allocation_units AS a ON a.container_id = p.partition_id
 WHERE --Clustered and Non-Clustered indexes 
	--i.type IN (1, 2)
	-- Indexes that have been updated by not used
 -- AND(s.user_seeks = 0 and s.user_scans = 0 and s.user_lookups = 0 )
  --is_unique = 0 
  --AND is_primary_key = 0
o.name = 'postulante'
GROUP BY o.name,SCHEMA_NAME(o.schema_id),o.type,i.name,i.is_disabled,i.Type_Desc,s.user_seeks,s.user_scans,s.user_lookups


