USE [master]
GO

/****** Object:  StoredProcedure [dbo].[EnvioAlertaDiskSpace_SP]    Script Date: 25/04/2016 03:23:29 p.m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[EnvioAlertaDiskSpace_SP](@umbral VARCHAR(4))
AS
SET NOCOUNT ON
DECLARE @asunto AS  NVARCHAR(255),
		@tableHTML NVARCHAR(MAX),
		@query NVARCHAR(MAX),
		@Destinatario VARCHAR(MAX)

--DECLARE @umbral VARCHAR(4)
--SET @umbral = 200

SET @query = '
SELECT DISTINCT
  vs.volume_mount_point AS [Drive],
  vs.logical_volume_name AS [DriveName],
  vs.total_bytes/1024/1024 AS [SizeMB],
  vs.available_bytes/1024/1024 AS [FreeSpaceMB],
  (vs.available_bytes*100)/vs.total_bytes AS [FreeSpace%]
INTO ##SpaceDisk
FROM sys.master_files AS f
CROSS APPLY sys.dm_os_volume_stats(f.database_id, f.file_id) AS vs
WHERE (vs.available_bytes*100)/vs.total_bytes < '+@umbral+'
ORDER BY vs.volume_mount_point'

--print @query

EXEC sp_executesql @query

IF EXISTS (SELECT * from ##SpaceDisk)
BEGIN
	SET @tableHTML=N'<table border="1"><FONT FACE="Courier New" font size="2">' +
				N'<tr>
				<th align="left">Drive</th>
				<th align="left">DriveName</th>
				<th align="left">SizeMB</th>
				<th align="left">FreeSpaceMB</th>
				<th align="left">FreeSpace%</th>
				</tr>' +
				CAST((
				SELECT	
				td = CONVERT(VARCHAR(50),Drive)+ ' ','',
				td = CONVERT(VARCHAR(50),DriveName)+ ' ','',
				td = CONVERT(VARCHAR(50),SizeMB)+ ' ','',
				td = CONVERT(VARCHAR(50),FreeSpaceMB)+ ' ','',
				td = CONVERT(VARCHAR(50),[FreeSpace%])+ ' ',''
				FROM ##SpaceDisk
				FOR XML PATH('tr'), TYPE
				) AS NVARCHAR(MAX))+N'</table></FONT>'

	SET @asunto = '**ALERT_DISKSPACE** INST: '+@@servername+' - UMBRAL < '+CONVERT(VARCHAR(6),@umbral)+'% Espacio Libre'
	SELECT @Destinatario = email_address FROM msdb.dbo.sysoperators WHERE name = 'DBA'

	EXEC msdb.dbo.sp_send_dbmail @profile_name = 'ALERT_SQL',
								@recipients = @Destinatario,
								--@recipients = 'monitoreoinmuebles@agea.com.ar',
								@subject = @asunto,
								@body_format = 'HTML',
								@body = @tableHTML
END
DROP TABLE ##SpaceDisk
SET NOCOUNT OFF


GO


