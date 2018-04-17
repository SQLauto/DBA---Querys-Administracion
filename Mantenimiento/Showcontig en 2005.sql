SELECT db_name(database_id) as database_name,object_name(a.object_id) as object_name,b.name as index_name,index_type_desc,avg_fragmentation_in_percent,fragment_count,avg_fragment_size_in_pages,page_count
FROM sys.dm_db_index_physical_stats (db_id('Usuarios'),null,null,null,null) a INNER JOIN sys.indexes b
																				ON a.object_id = b.object_id AND
																				a.index_id = b.index_id
ORDER BY object_name(a.object_id)



--Reference Values (in %)				Action			SQL statement
--avg_fragmentation_in_percent > 5 AND < 30 		Reorganize Index	ALTER INDEX REORGANIZE
--avg_fragmentation_in_percent > 30			Rebuild Index		ALTER INDEX REBUILD