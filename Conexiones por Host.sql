	select	[Hostname] = CASE WHEN Hostname IS NULL THEN '***** TOTAL DE CONEXIONES *****' ELSE Hostname END,
			[Loginame],
			[Dbname] = CASE WHEN db_name(dbid) IS NULL THEN '-' ELSE db_name(dbid) END ,
			count(*) as Total 
	from sysprocesses
	where hostname NOT IN ('AGSMS-HPDB13','') and loginame <> ''
	group by hostname,[Loginame],db_name(dbid) WITH ROLLUP	
	having hostname is null or	db_name(dbid) is not null
	order by count(*) 


	