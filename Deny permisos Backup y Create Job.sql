USE [master]
GO
DENY BACKUP DATABASE TO [DBGPROINDP01\SQLGP2OW]
DENY BACKUP LOG TO [DBGPROINDP01\SQLGP2OW]
DENY RESTORE DATABASE TO [DBGPROINDP01\SQLGP2OW]
GO
USE [msdb]
GO
DENY EXECUTE ON [sp_add_jobserver] TO [DBGPROINDP01\SQLGP2OW]
DENY EXECUTE ON [sp_update_jobstep] TO [DBGPROINDP01\SQLGP2OW]
