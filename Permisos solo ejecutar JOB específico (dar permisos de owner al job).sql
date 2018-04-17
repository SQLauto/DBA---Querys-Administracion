use [msdb]
GO
CREATE USER [u_Empleos_Ectoplasma] FOR LOGIN [u_Empleos_Ectoplasma]
GO
ALTER ROLE [SQLAgentUserRole] ADD MEMBER [u_Empleos_Ectoplasma]
GO
CREATE ROLE JobsModifDeny
GO
DENY EXECUTE ON sp_delete_jobstep TO JobsModifDeny
DENY EXECUTE ON sp_add_jobserver TO JobsModifDeny
DENY EXECUTE ON sp_add_job TO JobsModifDeny
DENY EXECUTE ON sp_add_jobstep TO JobsModifDeny
DENY EXECUTE ON sp_update_jobstep TO JobsModifDeny
DENY EXECUTE ON sp_add_jobschedule  TO JobsModifDeny
GO
ALTER ROLE [JobsModifDeny] ADD MEMBER [u_Empleos_Ectoplasma]
