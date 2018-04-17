USE [master]
GO

/****** Object:  StoredProcedure [dbo].[EnvioSesionesBloqueadas_SP]    Script Date: 25/04/2016 03:24:09 p.m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[EnvioSesionesBloqueadas_SP]
AS
SET NOCOUNT ON
DECLARE @asunto AS  NVARCHAR(255),
		@CantSesiones AS SMALLINT,
		@Umbral AS SQL_VARIANT,
		@tableHTML NVARCHAR(MAX),
		@Destinatario VARCHAR(MAX)

SELECT db.name AS DBName,
		tl.request_session_id AS RqstSPID,
		se1.login_name AS RqstLogin,
		h1.TEXT AS RequestText,
		wt.blocking_session_id AS BlkSPID,
		se2.login_name AS BlkLogin,
		h2.TEXT AS BlockingText,
		wt.wait_duration_ms AS DurSec,
		tl.resource_type AS Type,
		tl.request_mode AS Mode
INTO #Bloqueos
FROM sys.dm_tran_locks AS tl INNER JOIN sys.databases db ON db.database_id = tl.resource_database_id 
							INNER JOIN sys.dm_os_waiting_tasks AS wt ON tl.lock_owner_address = wt.resource_address
							INNER JOIN sys.dm_exec_connections ec1 ON ec1.session_id = tl.request_session_id
							INNER JOIN sys.dm_exec_connections ec2 ON ec2.session_id = wt.blocking_session_id
							CROSS APPLY sys.dm_exec_sql_text(ec1.most_recent_sql_handle) AS h1
							CROSS APPLY sys.dm_exec_sql_text(ec2.most_recent_sql_handle) AS h2
							INNER JOIN sys.dm_exec_sessions AS se1 ON ec1.session_id = se1.session_id
							INNER JOIN sys.dm_exec_sessions AS se2 ON ec2.session_id = se2.session_id

SELECT @cantsesiones = COUNT(*) FROM #Bloqueos
							
IF @CantSesiones > 0
BEGIN
 SELECT @Umbral = value FROM sys.configurations where name = 'blocked process threshold (s)'

 SET @tableHTML=N'<table border="1"><FONT FACE="Courier New" font size="2">' +
				N'<tr>
				<th align="left">DBName</th>
				<th align="left">RqstSPID</th>
				<th align="left">RqstLogin</th>
				<th align="left">RequestText</th>
				<th align="left">BlkSPID</th>
				<th align="left">BlkLogin</th>
				<th align="left">BlockingText</th>
				<th align="left">DurSec</th>
				<th align="left">Type</th>
				<th align="left">Mode</th>
				</tr>' +
				CAST((
				SELECT td = CONVERT(VARCHAR(15),DBName)+ ' ','',
				td = CONVERT(CHAR(4),RqstSPID)+ ' ','',
				td = CONVERT(VARCHAR(20),RqstLogin)+ ' ','',
				td = CONVERT(VARCHAR(500),REPLACE(REPLACE(REPLACE(REPLACE(RequestText,CHAR(13),' '),CHAR(10),' '),CHAR(8),' '),CHAR(9),' '))+ ' ','',
				td = CONVERT(CHAR(4),BlkSPID)+ ' ','',
				td = CONVERT(VARCHAR(20),BlkLogin)+ ' ','',
				td = CONVERT(VARCHAR(500),REPLACE(REPLACE(REPLACE(REPLACE(BlockingText,CHAR(13),' '),CHAR(10),' '),CHAR(8),' '),CHAR(9),' '))+ ' ','',
				td = CONVERT(VARCHAR(14),(DurSec)/1000)+ ' ','',
				td = CONVERT(VARCHAR(8),Type)+ ' ','',
				td = CONVERT(VARCHAR(4),Mode)+ ' ',''
				FROM #Bloqueos
				FOR XML PATH('tr'), TYPE
				) AS NVARCHAR(MAX))+N'</table></FONT>'


 SET @asunto = '**ALERT_BLKDSESSION** INST: '+@@servername+' - CANT_SESIONES:'+CONVERT(VARCHAR(3),@CantSesiones)+' - UMBRAL: '+CONVERT(VARCHAR(4),@Umbral)+' segundos'
 SELECT @Destinatario = email_address FROM msdb.dbo.sysoperators WHERE name = 'DBA'

 EXEC msdb.dbo.sp_send_dbmail @profile_name = 'ALERT_SQL',
								@recipients = @Destinatario,
								@subject = @asunto,
								@body_format = 'HTML',
								@body = @tableHTML

END
DROP TABLE #Bloqueos
SET NOCOUNT OFF





GO


