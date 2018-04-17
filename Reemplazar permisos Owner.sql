USE [GP2] -– Te paras sobre la base en cuestion
GO
EXEC sp_addrolemember N'db_datareader', N'DBGPROINDP01\SQLGP2OW' –- Lectura
GO
EXEC sp_addrolemember N'db_datawriter', N'DBGPROINDP01\SQLGP2OW' -- Escritura
GO
EXEC sp_addrolemember N'db_ddladmin', N'DBGPROINDP01\SQLGP2OW' -- Modificar Estructuras
GO
GRANT EXECUTE TO [DBGPROINDP01\SQLGP2OW] -- Ejecutar SP y FN
GO
GRANT VIEW DEFINITION TO [DBGPROINDP01\SQLGP2OW] –- Para que pueda ver todas las definiciones.
