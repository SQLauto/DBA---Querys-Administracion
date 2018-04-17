DECLARE @table_name VARCHAR(500) 
DECLARE @schema_name VARCHAR(500) 
DECLARE @tab1 TABLE(
        tablename VARCHAR (500) collate database_default
       ,schemaname VARCHAR(500) collate database_default
)

CREATE TABLE #temp_Table (
        tablename sysname
       ,row_count INT
       ,reserved VARCHAR(50) collate database_default
       ,data VARCHAR(50) collate database_default
       ,index_size VARCHAR(50) collate database_default
       ,unused VARCHAR(50) collate database_default 
)

INSERT INTO @tab1 
SELECT Table_Name, Table_Schema 
FROM information_schema.tables 
WHERE TABLE_TYPE = 'BASE TABLE'

DECLARE c1 CURSOR FOR
SELECT Table_Schema + '.' + Table_Name  
FROM information_schema.tables t1 
WHERE TABLE_TYPE = 'BASE TABLE'

OPEN c1
FETCH NEXT FROM c1 INTO @table_name
WHILE @@FETCH_STATUS = 0 
BEGIN  
        SET @table_name = REPLACE(@table_name, '[',''); 
        SET @table_name = REPLACE(@table_name, ']',''); 

        -- make sure the object exists before calling sp_spacedused
        IF EXISTS(SELECT id FROM sysobjects WHERE id = OBJECT_ID(@table_name))
        BEGIN
               INSERT INTO #temp_Table EXEC sp_spaceused @table_name, false;
        END
        
        FETCH NEXT FROM c1 INTO @table_name
END
CLOSE c1
DEALLOCATE c1

SELECT  t1.*
       ,t2.schemaname 
FROM #temp_Table t1 
INNER JOIN @tab1 t2 ON (t1.tablename = t2.tablename )
ORDER BY schemaname,t1.tablename;

DROP TABLE #temp_Table