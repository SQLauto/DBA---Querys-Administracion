USE [Inmuebles]
GO
/****** Object:  StoredProcedure [dbo].[SmartUpdateStats_SP]    Script Date: 01/03/2016 02:13:40 p.m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SmartUpdateStats_SP] (@hours INT,@PercentModif INT,@Days INT)
AS
SET NOCOUNT ON
-- EXEC [INMUEBLES].dbo.SmartUpdateStats_SP 48,20,30

EXEC master.dbo.InsertJobHistory_SP @JobName='DBA - SmartUpdateStats INMUEBLES', @Output = 'INICIO PROCESO'

DECLARE @SchemaName NVARCHAR(128),
		@ObjectName SYSNAME,
		@StatName SYSNAME,
		@TotalRows INT,
		@cmd NVARCHAR(MAX),
		@Output VARCHAR(MAX),
		@RowsModified INT,
		@StatDate DATETIME

-- Obtengo Datos de indice y estadisticas tuya tabla tenga m�s de 5k de registros y la cantidad de Filas modificadas sea mayor a 5k.
SELECT	SCHEMA_NAME(obj.schema_id) AS SchemaName,
		OBJECT_NAME(ind.id) AS ObjectName,
		ind.name AS StatName,
		STATS_DATE(ind.id, ind.indid) AS StatDate,
		ind.rowmodctr AS RowsModified,
		(SELECT rows FROM sys.sysindexes WHERE OBJECT_NAME(id) = OBJECT_NAME(ind.id) AND indid IN (1,0)) as TotalRows
INTO #Stats
FROM sys.sysindexes ind INNER JOIN sys.objects AS obj WITH (NOLOCK)
					ON obj.object_id = ind.id
WHERE ind.rowmodctr>5000 
	AND (SELECT rows FROM sys.sysindexes WHERE OBJECT_NAME(id) = OBJECT_NAME(ind.id) AND indid IN (1,0)) > 5000
	AND STATS_DATE(ind.id, ind.indid)<=DATEADD(HOUR,-@hours,GETDATE()) 
	--AND id IN (SELECT object_id FROM sys.tables)


-- Lleno cursor
DECLARE StatsCursor CURSOR FOR
SELECT SchemaName,ObjectName,StatName,StatDate,RowsModified,TotalRows
FROM #Stats

OPEN StatsCursor
FETCH NEXT FROM StatsCursor INTO @SchemaName,@ObjectName,@StatName,@StatDate,@RowsModified,@TotalRows

WHILE @@FETCH_STATUS = 0
BEGIN
	-- Si supera el porcentaje de modificaci�n especificado O si la est�d�stica tiene m�s d�as del especificado
	IF ((CAST(@RowsModified AS BIGINT)*100)/@TotalRows > @PercentModif) OR (@StatDate <= DATEADD(DAY,-@Days,GETDATE()))
	BEGIN
		-- Si la tabla tiene m�s de 15millones de registros tomo un Sample de 10%
		IF @TotalRows > 15000000
				BEGIN
					SET @cmd = 'UPDATE STATISTICS ['+@SchemaName+'].['+@ObjectName+'] ['+@StatName +'] WITH SAMPLE 10 PERCENT'
					SET  @Output = 'INICIO: '+@cmd
					EXEC master.dbo.InsertJobHistory_SP @JobName='DBA - SmartUpdateStats INMUEBLES', @Output = @Output
					--PRINT @cmd
					EXEC sp_executesql @cmd
					SET  @Output = 'FIN: '+@cmd
					EXEC master.dbo.InsertJobHistory_SP @JobName='DBA - SmartUpdateStats INMUEBLES', @Output = @Output
				END --IF @TotalRows > 15000000
				ELSE -- Sino tomo el anterior especificado (se supone que toda la tabla)
				BEGIN
					SET @cmd = 'UPDATE STATISTICS ['+@SchemaName+'].['+@ObjectName+'] ['+@StatName +'] WITH RESAMPLE'
					SET  @Output = 'INICIO: '+@cmd
					EXEC master.dbo.InsertJobHistory_SP @JobName='DBA - SmartUpdateStats INMUEBLES', @Output = @Output
					--PRINT @cmd
					EXEC sp_executesql @cmd
					SET  @Output = 'FIN: '+@cmd
					EXEC master.dbo.InsertJobHistory_SP @JobName='DBA - SmartUpdateStats INMUEBLES', @Output = @Output
				END -- ELSE IF @TotalRows > 15000000
	END
	FETCH NEXT FROM StatsCursor INTO @SchemaName,@ObjectName,@StatName,@StatDate,@RowsModified,@TotalRows
END

CLOSE StatsCursor
DEALLOCATE StatsCursor
DROP TABLE #Stats

EXEC master.dbo.InsertJobHistory_SP @JobName='DBA - SmartUpdateStats INMUEBLES', @Output = 'FIN PROCESO'

SET NOCOUNT OFF