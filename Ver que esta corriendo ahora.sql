SELECT	r.session_id,
		r.start_time,
		s.login_name,
		s.host_name,
		s.program_name,
		st.text,
		getdate() as TimeStamp,
		net_packet_size,
		CASE s.transaction_isolation_level 
			WHEN 0 THEN 'Unspecified'
			WHEN 1 THEN 'ReadUncomitted'
			WHEN 2 THEN 'ReadCommitted'
			WHEN 3 THEN 'Repeatable'
			WHEN 4 THEN 'Serializable'
			WHEN 5 THEN 'Snapshot'
		END
FROM sys.dm_exec_requests r LEFT JOIN sys.dm_exec_connections c
								ON r.session_id = c.session_id
							INNER JOIN sys.dm_exec_sessions s
								ON r.session_id = s.session_id
							CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) st
WHERE Host_name IS NOT NULL
