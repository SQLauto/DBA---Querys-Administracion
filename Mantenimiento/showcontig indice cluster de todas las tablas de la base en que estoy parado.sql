/*
Autor: Francisco Chantada
Descripcion: Devuelve un query para saber la fragmentacion de todos indices cluster de las tablas en la 
base en la que te encontras parado.
*/
SET NOCOUNT ON
DECLARE @tabla as varchar(100)

DECLARE cursor_loco CURSOR FOR 
SELECT a.name
FROM sysobjects a INNER JOIN sysindexes b
		ON a.id = b.id
WHERE a.xtype = 'U' and b.indid = 1
ORDER BY a.name

OPEN cursor_loco

FETCH NEXT FROM cursor_loco 
INTO @tabla

WHILE @@FETCH_STATUS = 0
BEGIN
  PRINT 'FRAGMENTACION DE LA TABLA: ' + upper(@tabla)
  DBCC SHOWCONTIG(@tabla,1)
  PRINT ''
  FETCH NEXT FROM cursor_loco 
  INTO @tabla
END --WHILE @@FETCH_STATUS = 0

CLOSE cursor_loco
DEALLOCATE cursor_loco

SET NOCOUNT OFF