CREATE TRIGGER [connection_limit_trigger]
ON ALL SERVER 
FOR LOGON
AS 
 
 set nocount on 
 
 BEGIN
 IF app_name() like '%Office%' -- si la app es office hacemos rollback de la conexion
    ROLLBACK;
 END;
GO 
 
ENABLE TRIGGER [connection_limit_trigger] ON ALL SERVER
GO