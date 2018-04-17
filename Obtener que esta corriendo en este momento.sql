select	s.session_id AS SPID,
		r.blocking_session_id AS Block,
		s.status AS Status,
		r.last_wait_type AS LastWaitType,
		r.command AS CMD,
		SUBSTRING(st.text, (r.statement_start_offset/2)+1, 
        ((CASE r.statement_end_offset
          WHEN -1 THEN DATALENGTH(st.text)
          ELSE r.statement_end_offset
          END - r.statement_start_offset)/2) + 1) as StmtText,
		db_name(r.database_id) AS DBName,
		r.cpu_time AS CPU,
		r.reads+r.writes AS Physical_IO,
		s.login_time AS LoginTime, 
		s.last_request_end_time AS LastBatch,
		r.open_transaction_count AS TransCount,
		CONVERT(VARCHAR(20),s.host_name) as HostName,
		CONVERT(VARCHAR(25),s.login_name) as LoginName,
		net_transport as NetLibrary,
		c.net_packet_size as PacketSize,
		CASE s.transaction_isolation_level 
			WHEN 0 THEN 'Unspecified' 
			WHEN 1 THEN 'ReadUncommitted' 
			WHEN 2 THEN 'ReadCommitted' 
			WHEN 3 THEN 'Repeatable' 
			WHEN 4 THEN 'Serializable' 
			WHEN 5 THEN 'Snapshot' 
		END AS TRANSACTION_ISOLATION_LEVEL
  from sys.dm_exec_sessions as s
  join sys.dm_exec_requests as r
    on r.session_id = s.session_id
  join sys.dm_exec_connections c
	on c.session_id = s.session_id
 cross apply sys.dm_exec_sql_text(r.sql_handle) as st
order by s.last_request_end_time;
