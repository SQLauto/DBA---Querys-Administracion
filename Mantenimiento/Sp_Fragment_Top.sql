CREATE PROCEDURE [dbo].[SP_Fragment_Top] AS
SET NOCOUNT ON

-- Declare variables
SET NOCOUNT ON
DECLARE @tablename	SYSNAME,
	@execstr	VARCHAR (2000),
	@objectid	INT,
	@indexname	SYSNAME,
	@frag		DECIMAL,
	@density	DECIMAL,
	@maxlogfrag	DECIMAL,
	@scandensity	DECIMAL

-- Decide on the maximum fragmentation to allow
SELECT	@maxlogfrag = 15.0,
	@scandensity = 90.0

-- Declare cursor
DECLARE tables CURSOR FOR
	SELECT TABLE_SCHEMA+'.'+TABLE_NAME
	FROM INFORMATION_SCHEMA.TABLES
	WHERE TABLE_TYPE = 'BASE TABLE' 

-- Create the table
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[DBA_FRAGMENT]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[DBA_FRAGMENT]

CREATE TABLE dbo.DBA_FRAGMENT (
	ObjectName CHAR (255),
	ObjectId INT,
	IndexName CHAR (255),
	IndexId INT,
	Lvl INT,
	CountPages INT,
	CountRows INT,
	MinRecSize INT,
	MaxRecSize INT,
	AvgRecSize INT,
	ForRecCount INT,
	Extents INT,
	ExtentSwitches INT,
	AvgFreeBytes INT,
	AvgPageDensity INT,
	ScanDensity DECIMAL,
	BestCount INT,
	ActualCount INT,
	LogicalFrag DECIMAL,
	ExtentFrag DECIMAL)

-- Open the cursor
OPEN tables

-- Loop through all the tables in the database
FETCH NEXT
	FROM tables
	INTO @tablename

WHILE @@FETCH_STATUS = 0
BEGIN
-- Do the showcontig of all indexes of the table
	INSERT INTO dbo.DBA_FRAGMENT 
	EXEC ('DBCC SHOWCONTIG (''' + @tablename + ''') 
	WITH FAST, TABLERESULTS, ALL_INDEXES, NO_INFOMSGS')
	
	FETCH NEXT
	FROM tables
	INTO @tablename
END

-- Depuro registros que tienen más de 2 meses
DELETE FROM master.dbo.DBA_FRAGMENT_HIST
WHERE DATEDIFF(mm,ShowContig_Date,getdate()) > 2

-- Insert into History
INSERT INTO master.dbo.DBA_FRAGMENT_HIST
SELECT 	db_name(),ObjectName, ObjectId, IndexName,IndexId,CountPages,ScanDensity,BestCount,ActualCount,LogicalFrag,getdate()
FROM dbo.DBA_FRAGMENT

-- Close and deallocate the cursor
CLOSE tables
DEALLOCATE tables

-- Declare cursor for list of indexes to be defragged
DECLARE indexes CURSOR FOR
	SELECT TOP 50 ObjectName, ObjectId, IndexName, LogicalFrag,ScanDensity
	FROM dbo.DBA_FRAGMENT
	WHERE 	(LogicalFrag >= @maxlogfrag OR ScanDensity < @scandensity) AND 
		INDEXPROPERTY (ObjectId, IndexName, 'IndexDepth') > 0
	ORDER BY LogicalFrag DESC,ScanDensity ASC

-- Open the cursor
OPEN indexes

-- loop through the indexes
FETCH NEXT
	FROM indexes
	INTO @tablename, @objectid, @indexname, @frag,@density

WHILE @@FETCH_STATUS = 0
BEGIN
	PRINT 'Table: '+RTRIM(@tablename)+' IndexName: '+RTRIM(@indexname)+' Fragmentation: '+RTRIM(CONVERT(varchar(15),@frag))+'% Density: '+RTRIM(CONVERT(varchar(15),@density))
	SET @execstr = 'DBCC DBREINDEX ('+RTRIM(@tablename)+','''+ISNULL(RTRIM(@indexname)+'''','''''')+',100)'
	PRINT (@execstr)
	EXEC (@execstr)

	FETCH NEXT
		FROM indexes
      		INTO @tablename, @objectid, @indexname, @frag,@density
END

-- Close and deallocate the cursor
CLOSE indexes
DEALLOCATE indexes

--Delete the temporary table
DROP TABLE dbo.DBA_FRAGMENT

GO
USE [master]
GO
CREATE TABLE Master.[dbo].[DBA_FRAGMENT_HIST](
	[DatabaseName] nvarchar(128) NULL,
	[ObjectName] [char](255) NULL,
	[ObjectId] [int] NULL,
	[IndexName] [char](255) NULL,
	[IndexId] [int] NULL,
	[CountPages] [int] NULL,
	[ScanDensity] [decimal](18, 0) NULL,
	[BestCount] [int] NULL,
	[ActualCount] [int] NULL,
	[LogicalFrag] [decimal](18, 0) NULL,
	[ShowContig_Date] [datetime] NULL
) ON [PRIMARY]

GO
