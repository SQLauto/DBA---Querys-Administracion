Declare @PageSize as int
Select @PageSize= low/1024.0 from master.dbo.spt_values Where Number=1 And type='E'

SELECT	object_name(i.object_id) as [TableName], 
		Convert(numeric(18,3), Convert(numeric(18,3),@PageSize * SUM(CASE WHEN a.type <> 1 THEN a.used_pages WHEN p.index_id < 2 THEN a.data_pages ELSE 0 END)) / 1024) As [DataUsedMB], 
		Convert(numeric(18,3),Convert(numeric,@PageSize * SUM(a.used_pages - CASE WHEN a.type <> 1 THEN a.used_pages WHEN p.index_id < 2 THEN a.data_pages ELSE 0 END)) / 1024) As [IndexUsedMB],
		Convert(numeric(18,3), Convert(numeric(18,3),@PageSize * SUM(a.used_pages)) / 1024) As [TotalUsedMB], 
		SUM(Case When p.index_id=1 and a.type=1 Then p.rows else 0 end) As [TotalRows]
FROM sys.indexes as i
JOIN sys.partitions as p ON p.object_id = i.object_id and p.index_id = i.index_id
JOIN sys.allocation_units as a ON a.container_id = p.partition_id
LEFT Join sys.tables t ON i.object_id=t.object_id 
WHERE t.type='U'
GROUP BY object_name(i.object_id)
ORDER BY 4 DESC
