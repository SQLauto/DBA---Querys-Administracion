--Deja los ultimos 10 dias.
DECLARE @d datetime
SET @d = DATEADD(dd, -10, GETDATE())
EXEC msdb.dbo.sysmail_delete_mailitems_sp @sent_before = @d