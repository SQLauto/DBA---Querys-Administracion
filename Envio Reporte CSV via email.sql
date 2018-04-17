DECLARE @tab CHAR(1) = CHAR(9),
		@emailsubject NVARCHAR(255),
		@sqlQuery NVARCHAR(max) 

SELECT @sqlQuery = 'select top 10 EsWeb,UrlFotoPrincipal,IdOrigen,FechaPublicacion,FechaModificacion from Inmuebles.dbo.aviso',
		@emailsubject = 'fchantada@agea.com.ar',
		@sqlQuery = 'SET NOCOUNT ON; '+@sqlQuery

EXEC  msdb.dbo.sp_send_dbmail @profile_name='SQLSERVICES', 
							@recipients='fchantada@agea.com.ar', 
							@subject=@emailsubject, 
							@attach_query_result_as_file=1,
							@query = @sqlQuery, 
							@query_attachment_filename='filename.csv',
							@query_result_separator=@tab,
							@query_result_no_padding=1
