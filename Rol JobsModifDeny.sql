CREATE ROLE [JobsModifDeny]
DENY EXECUTE ON dbo.sp_add_jobserver TO JobsModifDeny
DENY EXECUTE ON dbo.sp_add_jobstep TO JobsModifDeny
DENY EXECUTE ON dbo.sp_update_jobstep TO JobsModifDeny
DENY EXECUTE ON dbo.sp_delete_jobstep TO JobsModifDeny
DENY EXECUTE ON dbo.sp_add_jobschedule TO JobsModifDeny
DENY EXECUTE ON dbo.sp_add_job TO JobsModifDeny
