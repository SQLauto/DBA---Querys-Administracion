USE [Inmuebles]
GO
/****** Object:  StoredProcedure [dbo].[SmartDefragmentation_SP]    Script Date: 01/03/2016 02:13:38 p.m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SmartDefragmentation_SP]
AS
SET NOCOUNT ON
DECLARE @SchemaName AS NVARCHAR(128), 
		@TableName AS NVARCHAR(128),
		@IndexName AS NVARCHAR(128),
		@IndexType AS NVARCHAR(60),
		@AvgFragPercent AS FLOAT,
		@cmd  AS NVARCHAR(MAX),
		@ClusteredStatsDate DATETIME,
		@InitProcessDate DATETIME,
		@AvgMin FLOAT,
		@AvgMax FLOAT,
		@TotalRows BIGINT,
		@Output VARCHAR(MAX),
		@HorasMaxCorrida INT,
		@alloc_unit_type_desc NVARCHAR(60)

EXEC master.dbo.InsertJobHistory_SP @JobName='DBA - SmartDefragmentation INMUEBLES', @Output = 'INICIO PROCESO'

SELECT @InitProcessDate = GETDATE(), -- Obtengo Fecha Inicio Proceso
	   @AvgMin = 8,
	   @AvgMax = 30,
	   @HorasMaxCorrida=5

SET  @Output = 'OBTENIENDO ESTADISTICAS'
EXEC master.dbo.InsertJobHistory_SP @JobName='DBA - SmartDefragmentation INMUEBLES', @Output = @Output

-- Obtengo Estadísticas.
SELECT
             SCHEMA_NAME(o.schema_id) AS SchemaName               
            ,OBJECT_NAME(o.object_id) AS TableName
            ,i.name  AS IndexName
            ,i.type_desc AS IndexType
            ,dmv.Avg_Fragmentation_In_Percent AS AvgFragPercent
			,p.rows as TotalRows
			,alloc_unit_type_desc
INTO #DBA_IndexStats
FROM sys.partitions AS p WITH (NOLOCK)
INNER JOIN sys.indexes AS i WITH (NOLOCK)
            ON i.object_id = p.object_id
            AND i.index_id = p.index_id
INNER JOIN sys.objects AS o WITH (NOLOCK)
            ON o.object_id = i.object_id
INNER JOIN sys.dm_db_index_physical_stats (DB_ID(), NULL, NULL , NULL, N'LIMITED') dmv
            ON dmv.OBJECT_ID = i.object_id
            AND dmv.index_id = i.index_id
            AND dmv.partition_number  = p.partition_number
WHERE OBJECTPROPERTY(p.object_id, 'ISMSShipped') = 0  AND
	  i.name <> 'HEAP' AND
	  OBJECT_NAME(o.object_id) NOT IN ('EMAILENVIO') AND
	  dmv.Avg_Fragmentation_In_Percent > @AvgMin AND
	  p.rows > 5000
ORDER BY i.type_desc

DECLARE cursor_tablas CURSOR FOR 
SELECT SchemaName,TableName,IndexName,IndexType,AvgFragPercent,TotalRows,alloc_unit_type_desc
FROM #DBA_IndexStats
ORDER BY IndexType

OPEN cursor_tablas

FETCH NEXT FROM cursor_tablas 
INTO @SchemaName,@TableName,@IndexName,@IndexType,@AvgFragPercent,@TotalRows,@alloc_unit_type_desc

WHILE @@FETCH_STATUS = 0 AND DATEDIFF(hh,@InitProcessDate,GETDATE()) < @HorasMaxCorrida
BEGIN
	IF (@AvgFragPercent > @AvgMin AND @AvgFragPercent <= @AvgMax)
	BEGIN
		-- Obtengo Fecha de ultima actualizacion de Cluster de la tabla
		SELECT @ClusteredStatsDate = STATS_DATE ( a.object_id  , index_id ) FROM sys.indexes a INNER JOIN sys.objects b	ON a.object_id=b.object_id WHERE a.type = 1 AND b.name = @TableName AND b.schema_id = SCHEMA_ID(@SchemaName)
		IF (@ClusteredStatsDate < @InitProcessDate) OR @ClusteredStatsDate IS NULL  -- Si el indice Cluster de la tabla no se reindexo durante el proceso de SmartReindex o no tiene índice Cluster.
		BEGIN
			SET  @Output = 'INICIO REORGANIZE INDEX: '+UPPER(@SchemaName)+'.'+UPPER(@TableName)+'('+@IndexName+') - Fragmentacion: '+CONVERT(VARCHAR(3),CONVERT(INT,ROUND(@AvgFragPercent, 0)))+'%'
			EXEC master.dbo.InsertJobHistory_SP @JobName='DBA - SmartDefragmentation INMUEBLES', @Output = @Output
			SET @cmd = 'ALTER INDEX ['+@IndexName+'] ON ['+@SchemaName+'].['+@TableName+'] REORGANIZE'
			IF @alloc_unit_type_desc = 'LOB_DATA'
				SET @cmd = @cmd + ' WITH (LOB_COMPACTION = ON)'
			EXEC sp_executesql @cmd
			--PRINT @cmd
			SET  @Output = 'FIN REORGANIZE INDEX: ' + UPPER(@SchemaName)+'.'+UPPER(@TableName)+'('+@IndexName+')'
			EXEC master.dbo.InsertJobHistory_SP @JobName='DBA - SmartDefragmentation INMUEBLES', @Output = @Output
			IF @TotalRows > 15000000
			BEGIN
				SET @cmd = 'UPDATE STATISTICS ['+@SchemaName+'].['+@TableName+'] ['+@IndexName +'] WITH SAMPLE 10 PERCENT'
				SET  @Output = 'INICIO: '+@cmd
				EXEC master.dbo.InsertJobHistory_SP @JobName='DBA - SmartDefragmentation INMUEBLES', @Output = @Output
				EXEC sp_executesql @cmd
				--PRINT @cmd
				SET  @Output = 'FIN: '+@cmd
				EXEC master.dbo.InsertJobHistory_SP @JobName='DBA - SmartDefragmentation INMUEBLES', @Output = @Output
			END --IF @TotalRows > 15000000
			ELSE
			BEGIN
				SET @cmd = 'UPDATE STATISTICS ['+@SchemaName+'].['+@TableName+'] ['+@IndexName +'] WITH RESAMPLE'
				SET  @Output = 'INICIO: '+@cmd
				EXEC master.dbo.InsertJobHistory_SP @JobName='DBA - SmartDefragmentation INMUEBLES', @Output = @Output
				EXEC sp_executesql @cmd
				--PRINT @cmd
				SET  @Output = 'FIN: '+@cmd
				EXEC master.dbo.InsertJobHistory_SP @JobName='DBA - SmartDefragmentation INMUEBLES', @Output = @Output
			END -- ELSE IF @TotalRows > 15000000
		END --IF @ClusteredStatsDate < @InitProcessDate
	END --IF @AvgFragPercent > 5 AND @AvgFragPercent <= 30
	ELSE
	IF @AvgFragPercent > @AvgMax
	BEGIN
		SET  @Output = 'INICIO REBUILD INDEX: '+UPPER(@SchemaName)+'.'+UPPER(@TableName)+'('+@IndexName+') - Fragmentacion: '+CONVERT(VARCHAR(3),CONVERT(INT,ROUND(@AvgFragPercent, 0)))+'%'
		EXEC master.dbo.InsertJobHistory_SP @JobName='DBA - SmartDefragmentation INMUEBLES', @Output = @Output
		SET @cmd = 'ALTER INDEX ['+@IndexName+'] ON ['+@SchemaName+'].['+@TableName+'] REBUILD WITH (ONLINE = ON)'
		EXEC sp_executesql @cmd
		--PRINT @cmd
		SET  @Output = 'FIN REBUILD INDEX: ' + UPPER(@SchemaName)+'.'+UPPER(@TableName)+'('+@IndexName+')'
		EXEC master.dbo.InsertJobHistory_SP @JobName='DBA - SmartDefragmentation INMUEBLES', @Output = @Output
	END --IF @AvgFragPercent >30
    FETCH NEXT FROM cursor_tablas 
    INTO @SchemaName,@TableName,@IndexName,@IndexType,@AvgFragPercent,@TotalRows,@alloc_unit_type_desc
END --WHILE @@FETCH_STATUS = 0

CLOSE cursor_tablas
DEALLOCATE cursor_tablas

DROP TABLE #DBA_IndexStats

EXEC master.dbo.InsertJobHistory_SP @JobName='DBA - SmartDefragmentation INMUEBLES', @Output = 'FIN PROCESO'
SET NOCOUNT OFF

