select b.spid,a.net_transport,a.auth_scheme, b.last_batch, b.hostname, b.program_name, b.loginame
from sys.dm_exec_connections a inner join sysprocesses b 
								on a.session_id = b.spid