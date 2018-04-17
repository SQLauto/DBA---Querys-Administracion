SET NOCOUNT ON
declare @rc int,
	@TraceID int,
	@maxfilesize bigint,
	@EndTime datetime,
	@on bit,
	@path as nvarchar (245),
	@intfilter int,
	@bigintfilter bigint


-- SETEO LAS VARIABLES --
select  @EndTime = '2009-11-16 15:30:00.000', -- Fecha Fin de Traza
	@maxfilesize = 20, -- Tamaño maximo del Archivo
	@path = N'K:\SQL\Tracefiles\DBCL-HHS-'+ (convert(varchar(20),getdate(),112))+'-'+ replace(convert(varchar(20),getdate(),108),':','')


---- CREO LA NUEVA TRAZA ----
exec @rc = sp_trace_create @TraceID output,2,@path,@maxfilesize,@Endtime
if (@rc != 0) goto error


---- SETEO LOS TIPOS DE EVENTOS CON SUS RESPETIVAS COLUMNAS ----
set @on = 1 --variable para habilitar el evento.

-- 12 SQL:BatchCompleted
-- ejemplo: exec sp_trace_setevent  @TraceID,@EventID,@ColumnID,@on
exec sp_trace_setevent @TraceID,12,27,@on -- 27 EventClass
exec sp_trace_setevent @TraceID,12,1,@on  -- 1 TextData
exec sp_trace_setevent @TraceID,12,3,@on  -- 3 DatabaseID
exec sp_trace_setevent @TraceID,12,13,@on -- 13 Duration
exec sp_trace_setevent @TraceID,12,14,@on -- 14 StartTime
exec sp_trace_setevent @TraceID,12,15,@on -- 15 EndTime
exec sp_trace_setevent @TraceID,12,16,@on -- 16 Reads
exec sp_trace_setevent @TraceID,12,17,@on -- 17 Writes
exec sp_trace_setevent @TraceID,12,18,@on -- 18 CPU
exec sp_trace_setevent @TraceID,12,10,@on -- 10 AplicationName
exec sp_trace_setevent @TraceID,12,26,@on -- 26 ServerName
exec sp_trace_setevent @TraceID,12,6,@on  -- 6 NTUserName
exec sp_trace_setevent @TraceID,12,7,@on  -- 7 NTDomainName
exec sp_trace_setevent @TraceID,12,22,@on  -- 22 ObjectID
exec sp_trace_setevent @TraceID,12,51,@on  -- 51 EventSequence
exec sp_trace_setevent @TraceID,12,2,@on  -- 2 BinaryData
exec sp_trace_setevent @TraceID,12,29,@on  -- 29 NestLevel

--43 SP:Completed
exec sp_trace_setevent @TraceID,43,27,@on -- 27 EventClass
exec sp_trace_setevent @TraceID,43,1,@on  -- 1 TextData
exec sp_trace_setevent @TraceID,43,3,@on  -- 3 DatabaseID
exec sp_trace_setevent @TraceID,43,13,@on -- 13 Duration
exec sp_trace_setevent @TraceID,43,14,@on -- 14 StartTime
exec sp_trace_setevent @TraceID,43,15,@on -- 15 EndTime
exec sp_trace_setevent @TraceID,43,16,@on -- 16 Reads
exec sp_trace_setevent @TraceID,43,17,@on -- 17 Writes
exec sp_trace_setevent @TraceID,43,18,@on -- 18 CPU
exec sp_trace_setevent @TraceID,43,10,@on -- 10 AplicationName
exec sp_trace_setevent @TraceID,43,26,@on -- 26 ServerName
exec sp_trace_setevent @TraceID,43,6,@on  -- 6 NTUserName
exec sp_trace_setevent @TraceID,43,7,@on  -- 7 NTDomainName
exec sp_trace_setevent @TraceID,43,22,@on  -- 22 ObjectID
exec sp_trace_setevent @TraceID,43,51,@on  -- 51 EventSequence
exec sp_trace_setevent @TraceID,43,2,@on  -- 2 BinaryData
exec sp_trace_setevent @TraceID,43,29,@on  -- 29 NestLevel

-- 45 SP:StmtCompleted
exec sp_trace_setevent @TraceID,45,27,@on -- 27 EventClass
exec sp_trace_setevent @TraceID,45,1,@on  -- 1 TextData
exec sp_trace_setevent @TraceID,45,3,@on  -- 3 DatabaseID
exec sp_trace_setevent @TraceID,45,13,@on -- 13 Duration
exec sp_trace_setevent @TraceID,45,14,@on -- 14 StartTime
exec sp_trace_setevent @TraceID,45,15,@on -- 15 EndTime
exec sp_trace_setevent @TraceID,45,16,@on -- 16 Reads
exec sp_trace_setevent @TraceID,45,17,@on -- 17 Writes
exec sp_trace_setevent @TraceID,45,18,@on -- 18 CPU
exec sp_trace_setevent @TraceID,45,10,@on -- 10 AplicationName
exec sp_trace_setevent @TraceID,45,26,@on -- 26 ServerName
exec sp_trace_setevent @TraceID,45,6,@on  -- 6 NTUserName
exec sp_trace_setevent @TraceID,45,7,@on  -- 7 NTDomainName
exec sp_trace_setevent @TraceID,45,22,@on  -- 22 ObjectID
exec sp_trace_setevent @TraceID,45,51,@on  -- 51 EventSequence
exec sp_trace_setevent @TraceID,45,2,@on  -- 2 BinaryData
exec sp_trace_setevent @TraceID,45,29,@on  -- 29 NestLevel

-- 13 SQL:BatchStarting
exec sp_trace_setevent @TraceID,13,27,@on -- 27 EventClass
exec sp_trace_setevent @TraceID,13,1,@on  -- 1 TextData
exec sp_trace_setevent @TraceID,13,3,@on  -- 3 DatabaseID
exec sp_trace_setevent @TraceID,13,13,@on -- 13 Duration
exec sp_trace_setevent @TraceID,13,14,@on -- 14 StartTime
exec sp_trace_setevent @TraceID,13,15,@on -- 15 EndTime
exec sp_trace_setevent @TraceID,13,16,@on -- 16 Reads
exec sp_trace_setevent @TraceID,13,17,@on -- 17 Writes
exec sp_trace_setevent @TraceID,13,18,@on -- 18 CPU
exec sp_trace_setevent @TraceID,13,10,@on -- 10 AplicationName
exec sp_trace_setevent @TraceID,13,26,@on -- 26 ServerName
exec sp_trace_setevent @TraceID,13,6,@on  -- 6 NTUserName
exec sp_trace_setevent @TraceID,13,7,@on  -- 7 NTDomainName
exec sp_trace_setevent @TraceID,13,22,@on  -- 22 ObjectID
exec sp_trace_setevent @TraceID,13,51,@on  -- 51 EventSequence
exec sp_trace_setevent @TraceID,13,2,@on  -- 2 BinaryData
exec sp_trace_setevent @TraceID,13,29,@on  -- 29 NestLevel

-- 44 SP:StmtStarting
exec sp_trace_setevent @TraceID,44,27,@on -- 27 EventClass
exec sp_trace_setevent @TraceID,44,1,@on  -- 1 TextData
exec sp_trace_setevent @TraceID,44,3,@on  -- 3 DatabaseID
exec sp_trace_setevent @TraceID,44,13,@on -- 13 Duration
exec sp_trace_setevent @TraceID,44,14,@on -- 14 StartTime
exec sp_trace_setevent @TraceID,44,15,@on -- 15 EndTime
exec sp_trace_setevent @TraceID,44,16,@on -- 16 Reads
exec sp_trace_setevent @TraceID,44,17,@on -- 17 Writes
exec sp_trace_setevent @TraceID,44,18,@on -- 18 CPU
exec sp_trace_setevent @TraceID,44,10,@on -- 10 AplicationName
exec sp_trace_setevent @TraceID,44,26,@on -- 26 ServerName
exec sp_trace_setevent @TraceID,44,6,@on  -- 6 NTUserName
exec sp_trace_setevent @TraceID,44,7,@on  -- 7 NTDomainName
exec sp_trace_setevent @TraceID,44,22,@on  -- 22 ObjectID
exec sp_trace_setevent @TraceID,44,51,@on  -- 51 EventSequence
exec sp_trace_setevent @TraceID,44,2,@on  -- 2 BinaryData
exec sp_trace_setevent @TraceID,44,29,@on  -- 29 NestLevel

-- 10 RPC:Completed
exec sp_trace_setevent @TraceID,10,27,@on -- 27 EventClass
exec sp_trace_setevent @TraceID,10,1,@on  -- 1 TextData
exec sp_trace_setevent @TraceID,10,3,@on  -- 3 DatabaseID
exec sp_trace_setevent @TraceID,10,13,@on -- 13 Duration
exec sp_trace_setevent @TraceID,10,14,@on -- 14 StartTime
exec sp_trace_setevent @TraceID,10,15,@on -- 15 EndTime
exec sp_trace_setevent @TraceID,10,16,@on -- 16 Reads
exec sp_trace_setevent @TraceID,10,17,@on -- 17 Writes
exec sp_trace_setevent @TraceID,10,18,@on -- 18 CPU
exec sp_trace_setevent @TraceID,10,10,@on -- 10 AplicationName
exec sp_trace_setevent @TraceID,10,26,@on -- 26 ServerName
exec sp_trace_setevent @TraceID,10,6,@on  -- 6 NTUserName
exec sp_trace_setevent @TraceID,10,7,@on  -- 7 NTDomainName
exec sp_trace_setevent @TraceID,10,22,@on  -- 22 ObjectID
exec sp_trace_setevent @TraceID,10,51,@on  -- 51 EventSequence
exec sp_trace_setevent @TraceID,10,2,@on  -- 2 BinaryData
exec sp_trace_setevent @TraceID,10,29,@on  -- 29 NestLevel

-- 11 RPC:Starting
exec sp_trace_setevent @TraceID,11,27,@on -- 27 EventClass
exec sp_trace_setevent @TraceID,11,1,@on  -- 1 TextData
exec sp_trace_setevent @TraceID,11,3,@on  -- 3 DatabaseID
exec sp_trace_setevent @TraceID,11,13,@on -- 13 Duration
exec sp_trace_setevent @TraceID,11,14,@on -- 14 StartTime
exec sp_trace_setevent @TraceID,11,15,@on -- 15 EndTime
exec sp_trace_setevent @TraceID,11,16,@on -- 16 Reads
exec sp_trace_setevent @TraceID,11,17,@on -- 17 Writes
exec sp_trace_setevent @TraceID,11,18,@on -- 18 CPU
exec sp_trace_setevent @TraceID,11,10,@on -- 10 AplicationName
exec sp_trace_setevent @TraceID,11,26,@on -- 26 ServerName
exec sp_trace_setevent @TraceID,11,6,@on  -- 6 NTUserName
exec sp_trace_setevent @TraceID,11,7,@on  -- 7 NTDomainName
exec sp_trace_setevent @TraceID,11,22,@on  -- 22 ObjectID
exec sp_trace_setevent @TraceID,11,51,@on  -- 51 EventSequence
exec sp_trace_setevent @TraceID,11,2,@on  -- 2 BinaryData
exec sp_trace_setevent @TraceID,11,29,@on  -- 29 NestLevel

-- 16 Attention
exec sp_trace_setevent @TraceID,16,27,@on -- 27 EventClass
exec sp_trace_setevent @TraceID,16,1,@on  -- 1 TextData
exec sp_trace_setevent @TraceID,16,22,@on  -- 22 ObjectID

-- 79 Missing Column Statistics
exec sp_trace_setevent @TraceID,79,27,@on -- 27 EventClass
exec sp_trace_setevent @TraceID,79,1,@on  -- 1 TextData
exec sp_trace_setevent @TraceID,79,22,@on  -- 22 ObjectID

---- SETEO LOS FILTROS ----
-- ejemplo: exec sp_trace_setfilter @TraceID,@ColumnID,@logical_operator,@comparison_operator,@value 
--select @bigintfilter = 5000000
--exec sp_trace_setfilter @TraceID,13,0,4,@bigintfilter -- que capture solo los eventos que tardan mas de 5 segundos.

exec sp_trace_setfilter @TraceID,3,0,0,15 -- FILTRO LA BASE A TRACEAR.


---- SETEO PARA QUE LA TRAZA COMIENZE A EJECUTARSE ----
exec sp_trace_setstatus @TraceID, 1
select 'El ID de la traza es: ', @TraceID
goto finish


--- SI NO PUDO CREAR LA TRAZA DEVUELVE EL ERROR CON SU CODIGO ---
error: 
begin
select
ErrorCode=@rc,
Case @rc 
  when 1 then 'Error Desconocido.'
  when 10 then 'Opciones no válidas. Se devuelve cuando las opciones especificadas no son compatibles.'
  when 12 then 'Archivo no creado.'
  when 13 then 'Memoria insuficiente. Se devuelve cuando no hay memoria suficiente para realizar la acción especificada.'
  when 14 then 'Hora de detención no válida. Se devuelve cuando ya se ha alcanzado la hora de detención especificada.'
  when 15 then 'Parámetros no válidos. Se devuelve cuando el usuario ha proporcionado parámetros no compatibles.'
end as Descripcion
end --fin error:


finish: 
go

SET NOCOUNT OFF