SELECT	a.name,
		CASE b.indid 
		  WHEN 0 THEN b.rows
		  WHEN 1 THEN b.rows
		  ELSE 0
		END AS Rows,
		b.name,
		(dpages*8)/1024 as Size_MB
FROM sysobjects a inner join sysindexes b
	on a.id = b.id
WHERE a.xtype = 'U' and indid in (0,1)
	AND b.name not like '_WA%'
ORDER BY b.dpages desc