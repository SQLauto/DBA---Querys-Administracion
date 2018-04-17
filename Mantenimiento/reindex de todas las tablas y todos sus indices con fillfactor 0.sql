/*
Autor: Francisco Chantada
Descripcion: Reindexa la base que especifico por completo (todas las tablas con todos sus indices). 
El fillfactor en 0 utiliza el ultimo fillfactor utilizado.
IMPORTANTE: Cambiar en USE el nombre de la base
*/
SET NOCOUNT ON
DECLARE @tabla as varchar(100)
USE [master] --cambiar la base

DECLARE cursor_tablas CURSOR FOR 
SELECT '[' + table_schema + ']' + '.' + '[' + table_name + ']'
from INFORMATION_SCHEMA.TABLES 
where table_type = 'BASE TABLE'

OPEN cursor_tablas

FETCH NEXT FROM cursor_tablas 
INTO @tabla

WHILE @@FETCH_STATUS = 0
BEGIN
    PRINT 'REINDEXANDO TABLA: ' + upper(@tabla)
    DBCC DBREINDEX(@tabla,'',0)
    PRINT ''
    FETCH NEXT FROM cursor_tablas 
    INTO @tabla
END --WHILE @@FETCH_STATUS = 0

CLOSE cursor_tablas
DEALLOCATE cursor_tablas

SET NOCOUNT OFF
