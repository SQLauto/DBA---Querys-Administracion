DECLARE @tableHTML NVARCHAR(MAX),
		@cant SMALLINT,
		@asunto NVARCHAR(255)

IF EXISTS (SELECT va.id FROM VisibilidadAviso va JOIN Aviso a ON a.Id = va.IdAviso JOIN Vendedor v ON v.Id = a.IdVendedor JOIN Sistema s ON s.Id = a.IdSistemaOrigen WHERE ((va.IdTipoDestaque in (1,6) and v.UsaPuntos = 0) OR (va.Puntos = 0 and v.UsaPuntos = 1)) AND va.IdEstadoAviso != 1 AND va.Visible=1)
BEGIN
 SELECT @cant = COUNT(*) FROM VisibilidadAviso va JOIN Aviso a ON a.Id = va.IdAviso JOIN Vendedor v ON v.Id = a.IdVendedor JOIN Sistema s ON s.Id = a.IdSistemaOrigen WHERE ((va.IdTipoDestaque in (1,6) and v.UsaPuntos = 0) OR (va.Puntos = 0 and v.UsaPuntos = 1)) AND va.IdEstadoAviso != 1 AND va.Visible=1
 SET @asunto = 'ALERTA INCONSISTENCIA DATOS - Existen '+CONVERT(VARCHAR(5),@cant)+' Avisos con Visible=1 sin Destaque\Puntos'
 SET @tableHTML =N'<table><FONT FACE="Courier New" font size="2">' +
				N'<tr>
				<th align="left">IdAviso</th>
				<th align="left">IdVisibilidad</th>
				<th align="left">SistemaOrigen</th>
				<th align="left">FechaPublicacion</th>
				<th align="left">FechaModificacion</th>
				</tr>' +
				CAST ( (
				 SELECT td = CONVERT(VARCHAR(10),a.Id)+ ' ','', 
				td = CONVERT(VARCHAR(10),va.Id)+ ' ','',
				td = CONVERT(VARCHAR(20),s.Nombre)+ ' ','',
				td = CONVERT(VARCHAR(16),a.FechaPublicacion,120)+ ' ','',
				td = CONVERT(VARCHAR(16),a.FechaModificacion,120)+ ' ',''
				FROM VisibilidadAviso va
				JOIN Aviso a ON a.Id = va.IdAviso
				JOIN Vendedor v ON v.Id = a.IdVendedor
				JOIN Sistema s ON s.Id = a.IdSistemaOrigen
				WHERE
				((va.IdTipoDestaque in (1,6) and v.UsaPuntos = 0) OR (va.Puntos = 0 and v.UsaPuntos = 1))
				AND va.IdEstadoAviso != 1
				AND va.Visible=1
				ORDER BY FechaModificacion DESC
				FOR XML PATH('tr'), TYPE
				) AS NVARCHAR(MAX))+N'</table></FONT>'

 EXEC msdb.dbo.sp_send_dbmail 
				@profile_name = 'ALERT_SQL', 
				@recipients = 'fchantada@agea.com.ar', 
				@subject = @asunto,
				@body_format = 'HTML',
				@body = @tableHTML

END




DECLARE @tableHTML NVARCHAR(MAX),
		@cant SMALLINT,
		@asunto NVARCHAR(255)

IF EXISTS (SELECT va.id FROM VisibilidadAviso va JOIN Aviso a ON a.Id = va.IdAviso JOIN Vendedor v ON v.Id = a.IdVendedor JOIN Sistema s ON s.Id = a.IdSistemaOrigen WHERE (va.IdTipoDestaque NOT IN (1,6) OR va.Puntos != 0) AND va.IdEstadoAviso = 1 AND va.Visible=0)
BEGIN
 SELECT @cant = COUNT(*) FROM VisibilidadAviso va JOIN Aviso a ON a.Id = va.IdAviso JOIN Vendedor v ON v.Id = a.IdVendedor JOIN Sistema s ON s.Id = a.IdSistemaOrigen WHERE (va.IdTipoDestaque NOT IN (1,6) OR va.Puntos != 0) AND va.IdEstadoAviso = 1 AND va.Visible=0
 SET @asunto = 'ALERTA INCONSISTENCIA DATOS - Existen '+CONVERT(VARCHAR(5),@cant)+' Avisos con Visible=0 con Destaque\Puntos'
 SET @tableHTML =N'<table><FONT FACE="Courier New" font size="2">' +
				N'<tr>
				<th align="left">IdAviso</th>
				<th align="left">IdVisibilidad</th>
				<th align="left">SistemaOrigen</th>
				<th align="left">FechaPublicacion</th>
				<th align="left">FechaModificacion</th>
				</tr>' +
				CAST ( (
				 SELECT td = CONVERT(VARCHAR(10),a.Id)+ ' ','', 
				td = CONVERT(VARCHAR(10),va.Id)+ ' ','',
				td = CONVERT(VARCHAR(20),s.Nombre)+ ' ','',
				td = CONVERT(VARCHAR(16),a.FechaPublicacion,120)+ ' ','',
				td = CONVERT(VARCHAR(16),a.FechaModificacion,120)+ ' ',''
				FROM VisibilidadAviso va
				JOIN Aviso a ON a.Id = va.IdAviso
				JOIN Vendedor v ON v.Id = a.IdVendedor
				JOIN Sistema s ON s.Id = a.IdSistemaOrigen
				WHERE
				(va.IdTipoDestaque NOT IN (1,6) OR va.Puntos != 0)
				AND va.IdEstadoAviso = 1
				AND va.Visible=0
				ORDER BY FechaModificacion DESC
				FOR XML PATH('tr'), TYPE
				) AS NVARCHAR(MAX))+N'</table></FONT>'

 EXEC msdb.dbo.sp_send_dbmail 
				@profile_name = 'ALERT_SQL', 
				@recipients = 'fchantada@agea.com.ar;gvillanustre@agea.com.ar',  
				@subject = @asunto,
				@body_format = 'HTML',
				@body = @tableHTML

END


