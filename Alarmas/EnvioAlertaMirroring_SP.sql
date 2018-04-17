USE [master]
GO

/****** Object:  StoredProcedure [dbo].[EnvioAlertaMirroring_SP]    Script Date: 25/04/2016 03:23:48 p.m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[EnvioAlertaMirroring_SP]
AS
SET NOCOUNT ON
DECLARE @asunto AS  NVARCHAR(255),
		@tableHTML NVARCHAR(MAX),
		@query NVARCHAR(MAX),
		@Destinatario VARCHAR(MAX)

SET @query = 'SELECT	db_name(database_id) as DbName,
		mirroring_role_desc as Role, 
		mirroring_state_desc as State
INTO ##MirroringState
FROM sys.database_mirroring
WHERE mirroring_role_desc IN (''PRINCIPAL'',''MIRROR'')'

--print @query

EXEC sp_executesql @query

SET @tableHTML=N'<table border="1"><FONT FACE="Courier New" font size="2">' +
				N'<tr>
				<th align="left">DBName</th>
				<th align="left">Role</th>
				<th align="left">State</th>
				</tr>' +
				CAST((
				SELECT	
				td = CONVERT(VARCHAR(50),DBName)+ ' ','',
				td = CONVERT(VARCHAR(50),Role)+ ' ','',
				td = CONVERT(VARCHAR(50),State)+ ' ',''
				FROM ##MirroringState
				FOR XML PATH('tr'), TYPE
				) AS NVARCHAR(MAX))+N'</table></FONT>'

DROP TABLE ##MirroringState

 SET @asunto = '**ALERT_MIRRORING** INST: '+@@servername
 SELECT @Destinatario = email_address FROM msdb.dbo.sysoperators WHERE name = 'DBA'

 EXEC msdb.dbo.sp_send_dbmail @profile_name = 'ALERT_SQL',
								@recipients = @Destinatario,
								--@recipients = 'monitoreoinmuebles@agea.com.ar',
								@subject = @asunto,
								@body_format = 'HTML',
								@body = @tableHTML

SET NOCOUNT OFF





GO


