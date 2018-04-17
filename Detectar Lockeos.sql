
select spid,blocked,waitresource from sys.sysprocesses where waitresource <> '' -- ver bloqueos de paginas


-- Verificar que Paginas, tablas, etc estan bloqueadas. Reemplazar los valores del Waitresourse en el dbcc page
dbcc traceon (3604)
go
dbcc page (5, 1, 229645)              



--Si el Lockeo es del tipo KEY para buscar el mismo

SELECT o.name, i.name 
FROM sys.partitions p 
JOIN sys.objects o ON p.object_id = o.object_id 
JOIN sys.indexes i ON p.object_id = i.object_id 
AND p.index_id = i.index_id 
WHERE p.hobt_id = 72057594065256448