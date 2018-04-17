/*
Autor: Francisco Chantada
Descripcion: Crea un Rol y le da permisos de EXECUTE a todos los SP y FN, y de SELECT a todas las Vistas
*/
DECLARE @objeto as varchar(300),
	@query as varchar(500)

-- Si existe el roll lo borro
IF  EXISTS (SELECT * FROM sysusers WHERE name = 'EXEC_SP_FN_SEL_VW')
  EXEC dbo.sp_droprole @rolename = N'EXEC_SP_FN_SEL_VW'

-- Creo el Roll
EXEC dbo.sp_addrole @rolename = N'EXEC_SP_FN_SEL_VW'

-- Armo cursor con nombre de los SP y Funciones
DECLARE procedures CURSOR FOR 
SELECT a.name FROM sysobjects a INNER JOIN sysusers b
			ON  a.uid = b.uid
WHERE   a.xtype in ('P','FN') AND 
	b.name = 'dbo' AND a.status >=0

OPEN procedures

FETCH NEXT FROM procedures INTO @objeto

WHILE @@FETCH_STATUS = 0
BEGIN
  -- Le voy permisos al roll sobre los SP y Funciones
  SET @query = '  GRANT EXECUTE ON ' + @objeto + ' TO [EXEC_SP_FN_SEL_VW]'
  EXEC (@query)
  PRINT @query
  FETCH NEXT FROM procedures INTO @objeto
END --WHILE @@FETCH_STATUS = 0

CLOSE procedures
DEALLOCATE procedures


-- Armo cursor con nombre de las Vistas
DECLARE vistas CURSOR FOR 
SELECT a.name FROM sysobjects a INNER JOIN sysusers b
			ON  a.uid = b.uid
WHERE   a.xtype = 'V' AND 
	b.name = 'dbo' AND a.status >=0

OPEN vistas

FETCH NEXT FROM vistas INTO @objeto

--Por Cada Vista
WHILE @@FETCH_STATUS = 0
BEGIN
  -- Le voy permisos al roll sobre las vista
  SET @query = '  GRANT SELECT ON ' + @objeto + ' TO [EXEC_SP_FN_SEL_VW]'
  EXEC (@query)
  PRINT @Query
  FETCH NEXT FROM vistas INTO @objeto
END --WHILE @@FETCH_STATUS = 0

CLOSE vistas
DEALLOCATE vistas
