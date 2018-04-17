SET NOCOUNT ON

DECLARE @spid AS SMALLINT,
		@query AS VARCHAR(100)

DECLARE cursor_loco CURSOR FOR 
SELECT spid 
FROM sysprocesses 
WHERE	open_tran = 1 AND 
		hostname <> 'CRMAMVONLINE02' AND
		status = 'sleeping' AND
		DATEDIFF(mi,last_batch,getdate()) > 5		

OPEN cursor_loco

FETCH NEXT FROM cursor_loco INTO @spid

WHILE @@FETCH_STATUS = 0
BEGIN
  SET @query = 'KILL '+CONVERT(VARCHAR(4),@spid)
  --PRINT  @query
  EXEC(@query)
  FETCH NEXT FROM cursor_loco INTO @spid
END --WHILE @@FETCH_STATUS = 0

CLOSE cursor_loco
DEALLOCATE cursor_loco

SET NOCOUNT OFF