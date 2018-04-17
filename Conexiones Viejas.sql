select spid,kpid,blocked,status,lastwaittype,dbid,cpu,physical_io,login_time,last_batch,open_tran,hostname,loginame, net_library
from master..sysprocesses
where	spid > 37 and 
		status <> 'sleeping' and
		loginame <> 'SA' and
		DATEDIFF(mi,last_batch,getdate()) > 30