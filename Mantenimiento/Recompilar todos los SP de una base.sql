/*
Autor: Francisco Chantada
Descripcion: Recompila todos los SP de la base.
IMPORTANTE: cambiar el nombre de la base por la que queres obtener el informe (USE [nombre_base])
*/
SET NOCOUNT ON
USE [nombre_base]
DECLARE @tabla as varchar(100),
	@tmp as varchar(100)

DECLARE cursor_loco CURSOR FOR 
select name from sysobjects 
where xtype = 'P' order by name

select * from sysobjects

OPEN cursor_loco

FETCH NEXT FROM cursor_loco 
INTO @tabla

WHILE @@FETCH_STATUS = 0
BEGIN
  SET @tmp = @tabla
  WHILE (@tmp = @tabla) and (@@FETCH_STATUS = 0)
  BEGIN
    PRINT 'RECOMPILANDO SP: ' + upper(@tabla)
    EXEC sp_recompile @tabla
    PRINT ''
    FETCH NEXT FROM cursor_loco 
    INTO @tabla
  END -- WHILE (@tmp = @tabla)
END --WHILE @@FETCH_STATUS = 0

CLOSE cursor_loco
DEALLOCATE cursor_loco

SET NOCOUNT OFF