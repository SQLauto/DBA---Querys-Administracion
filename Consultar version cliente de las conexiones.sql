SELECT	session_id, 
		client_net_address
		client_tcp_port,
		local_tcp_port,
		protocol_type, 
		connect_time,
		driver_version =
CASE CONVERT(CHAR(4), CAST(protocol_version AS BINARY(4)), 1)
WHEN '0x70' THEN 'SQL Server 7.0'
WHEN '0x71' THEN 'SQL Server 2000'
WHEN '0x72' THEN 'SQL Server 2005'
WHEN '0x73' THEN 'SQL Server 2008'
WHEN '0x74' THEN 'SQL Server 2012'
ELSE 'Unknown driver'
END,
loginame as LoginName
FROM sys.dm_exec_connections a inner join sys.sysprocesses b
								on b.spid = a.session_id
ORDER BY client_tcp_port