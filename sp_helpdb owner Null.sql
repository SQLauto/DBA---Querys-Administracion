use  master
go
sp_configure 'allow',1
go
reconfigure with override
go
update  master.dbo.sysdatabases
set sid = 0x01 
where suser_sname(sid) is null
go
sp_configure 'allow',0
go
reconfigure with override
go