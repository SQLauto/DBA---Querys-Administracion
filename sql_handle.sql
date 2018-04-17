DECLARE @Handle binary(20)
SELECT @Handle = sql_handle FROM master..sysprocesses WHERE spid = 52
SELECT * FROM ::fn_get_sql(@Handle) 
