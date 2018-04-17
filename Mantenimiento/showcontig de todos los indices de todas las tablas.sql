/*
Autor: Francisco Chantada
Descripcion: Informa la fragmentacion de todos indices de cada tabla.
IMPORTANTE: cambiar el nombre de la base por la que queres obtener el informe (USE [nombre_base])
*/
SET NOCOUNT ON
USE [nombre_base]
DECLARE @tabla as varchar(100),
	@tmp as varchar(100)

DECLARE cursor_loco CURSOR FOR 
select table_schema + '.' + table_name 
from INFORMATION_SCHEMA.TABLES 
where table_type = 'BASE TABLE'

OPEN cursor_loco

FETCH NEXT FROM cursor_loco 
INTO @tabla

WHILE @@FETCH_STATUS = 0
BEGIN
  SET @tmp = @tabla
  WHILE (@tmp = @tabla) and (@@FETCH_STATUS = 0)
  BEGIN
    PRINT 'FRAGMENTACION DE LA TABLA: ' + upper(@tabla)
    DBCC SHOWCONTIG(@tabla) WITH ALL_INDEXES
    PRINT ''
    FETCH NEXT FROM cursor_loco 
    INTO @tabla
  END -- WHILE (@tmp = @tabla)
END --WHILE @@FETCH_STATUS = 0

CLOSE cursor_loco
DEALLOCATE cursor_loco

SET NOCOUNT OFF