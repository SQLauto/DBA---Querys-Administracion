USE [DEAUTOS_P]
GO
/****** Object:  StoredProcedure [dbo].[SmartUpdateStats_SP]    Script Date: 17/05/2016 02:09:58 p.m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[SmartUpdateStats_SP] (@hours INT,@PercentModif INT,@Days INT)
AS
BEGIN TRY
SET NOCOUNT ON
-- EXEC [DEAUTOS_P].dbo.SmartUpdateStats_SP 48,20,30

DECLARE @SchemaName NVARCHAR(128),
		@ObjectName SYSNAME,
		@StatName SYSNAME,
		@TotalRows INT,
		@cmd NVARCHAR(MAX),
		@Output VARCHAR(MAX),
		@RowsModified INT,
		@StatDate DATETIME,
		@ErrorMessage NVARCHAR(4000),
		@ErrorSeverity INT,
		@ErrorState INT,
		@JobName SYSNAME

SET @JobName = 'DBA - SmartUpdateStats DEAUTOS_P'
	
EXEC master.dbo.InsertJobHistory_SP @JobName=@JobName, @Output = 'INICIO PROCESO'

-- Obtengo Datos de indice y estadisticas tuya tabla tenga más de 5k de registros y la cantidad de Filas modificadas sea mayor a 5k.
SELECT	SCHEMA_NAME(obj.schema_id) AS SchemaName,
		OBJECT_NAME(ind.id) AS ObjectName,
		ind.name AS StatName,
		STATS_DATE(ind.id, ind.indid) AS StatDate,
		ind.rowmodctr AS RowsModified,
		(SELECT rows FROM sys.sysindexes WHERE id = ind.id AND indid IN (1,0)) as TotalRows
INTO #Stats
FROM sys.sysindexes ind INNER JOIN sys.objects AS obj WITH (NOLOCK)
					ON obj.object_id = ind.id
WHERE ind.rowmodctr>5000 
	AND (SELECT rows FROM sys.sysindexes WHERE id = ind.id AND indid IN (1,0)) > 5000
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
	-- Si supera el porcentaje de modificación especificado O si la estádística tiene más días del especificado
	IF ((CAST(@RowsModified AS BIGINT)*100)/@TotalRows > @PercentModif) OR (@StatDate <= DATEADD(DAY,-@Days,GETDATE()))
	BEGIN
		-- Si la tabla tiene más de 15millones de registros tomo un Sample de 10%
		IF @TotalRows > 15000000
				BEGIN
					SET @cmd = 'UPDATE STATISTICS ['+@SchemaName+'].['+@ObjectName+'] ['+@StatName +'] WITH SAMPLE 20 PERCENT'
					SET  @Output = 'INICIO: '+@cmd
					EXEC master.dbo.InsertJobHistory_SP @JobName=@JobName, @Output = @Output
					--PRINT @cmd
					EXEC sp_executesql @cmd
					SET  @Output = 'FIN: '+@cmd
					EXEC master.dbo.InsertJobHistory_SP @JobName=@JobName, @Output = @Output
				END --IF @TotalRows > 15000000
				ELSE -- Sino tomo el anterior especificado (se supone que toda la tabla)
				BEGIN
					SET @cmd = 'UPDATE STATISTICS ['+@SchemaName+'].['+@ObjectName+'] ['+@StatName +'] WITH RESAMPLE'
					SET  @Output = 'INICIO: '+@cmd
					EXEC master.dbo.InsertJobHistory_SP @JobName=@JobName, @Output = @Output
					--PRINT @cmd
					EXEC sp_executesql @cmd
					SET  @Output = 'FIN: '+@cmd
					EXEC master.dbo.InsertJobHistory_SP @JobName=@JobName, @Output = @Output
				END -- ELSE IF @TotalRows > 15000000
	END
	FETCH NEXT FROM StatsCursor INTO @SchemaName,@ObjectName,@StatName,@StatDate,@RowsModified,@TotalRows
END

CLOSE StatsCursor
DEALLOCATE StatsCursor
DROP TABLE #Stats

EXEC master.dbo.InsertJobHistory_SP @JobName=@JobName, @Output = 'FIN PROCESO'

SET NOCOUNT OFF
END TRY
BEGIN CATCH
	SELECT @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE(); 
	EXEC master.dbo.InsertJobHistory_SP @JobName=@JobName, @Output = @ErrorMessage
	EXEC master.dbo.InsertJobHistory_SP @JobName=@JobName, @Output = 'FIN PROCESO'
	RAISERROR (@ErrorMessage,@ErrorSeverity,@ErrorState) 
END CATCH






