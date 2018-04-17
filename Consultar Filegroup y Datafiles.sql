SELECT df.name,df.physical_name,(df.size*8)/1024 as Size_MB,df.state_desc,fg.name,fg.type_desc
FROM sys.database_files df INNER JOIN sys.filegroups fg
			ON df.data_space_id = fg.data_space_id
ORDER BY fg.name