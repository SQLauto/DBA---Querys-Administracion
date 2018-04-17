USE [master]
GO

/****** Object:  StoredProcedure [dbo].[EnvioAlertaTLog_SP]    Script Date: 25/04/2016 03:23:58 p.m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



CREATE PROC [dbo].[EnvioAlertaTLog_SP] (@dbname SYSNAME = 'master')
AS
SET NOCOUNT ON
DECLARE @asunto AS  NVARCHAR(255),
		@tableHTML NVARCHAR(MAX),
		@query NVARCHAR(MAX),
		@Destinatario VARCHAR(MAX)

SET @query = 'USE ['+@dbname+'];
SELECT	db_name() AS [DBName],
		sum(round(a.size/128.,2)) AS [FileSizeMB],
		sum(round((a.size-fileproperty(a.name,''SpaceUsed''))/128.,2))*100/sum(round(a.size/128.,2)) AS [UnusedSpace],
		DATABASEPROPERTYEX('''+@dbname+''',''Recovery'') AS [RecoveryModel],
		(SELECT MAX(backup_finish_date) FROM msdb.dbo.backupset WHERE type = ''L'' AND database_name = db_name() GROUP BY database_name) AS [LastBkpTlogDate]
INTO ##Logsize
FROM sysfiles a
WHERE a.groupid = 0
GROUP BY a.groupid'

--print @query

EXEC sp_executesql @query

SET @tableHTML=N'<table border="1"><FONT FACE="Courier New" font size="2">' +
				N'<tr>
				<th align="left">DBName</th>
				<th align="left">FileSizeMB</th>
				<th align="left">UnusedSpace%</th>
				<th align="left">RecoveryModel</th>
				<th align="left">LastBkpTlogDate</th>
				</tr>' +
				CAST((
				SELECT	
				td = DBName+ ' ','',
				td = CONVERT(VARCHAR(20),FileSizeMB)+ ' ','',
				td = CONVERT(VARCHAR(20),UnusedSpace)+ ' ','',
				td = CONVERT(VARCHAR(20),RecoveryModel)+ ' ','',
				td = CONVERT(VARCHAR(20),LastBkpTlogDate,120)+ ' ',''
				FROM ##Logsize
				FOR XML PATH('tr'), TYPE
				) AS NVARCHAR(MAX))+N'</table></FONT>'

DROP TABLE ##Logsize

 SET @asunto = '**ALERT_T-LOG** INST: '+@@servername+' DB: '+@dbname+' - UMBRAL: 90% de Espacio Ocupado'
 SELECT @Destinatario = email_address FROM msdb.dbo.sysoperators WHERE name = 'DBA'

 EXEC msdb.dbo.sp_send_dbmail @profile_name = 'ALERT_SQL',
								@recipients = @Destinatario,
								--@recipients = 'monitoreoinmuebles@agea.com.ar',
								@subject = @asunto,
								@body_format = 'HTML',
								@body = @tableHTML

SET NOCOUNT OFF




GO


