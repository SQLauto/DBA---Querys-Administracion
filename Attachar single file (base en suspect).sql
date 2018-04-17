If you want to attach a MDF without LDF you can follow the steps below
It is tested and working fine


1. Create a new database with the same name and same MDF and LDF files

2. Stop sql server and rename the existing MDF to a new one and copy the original MDF to this location and delete the LDF files.

3. Start SQL Server

4. Now your database will be marked suspect 5. Update the sysdatabases to update to Emergency mode. This will not use LOG files in start up

Sp_configure "allow updates", 1
go
Reconfigure with override
GO
Update sysdatabases set status = 32768 where name = "BadDbName"
go
Sp_configure "allow updates", 0
go
Reconfigure with override
GO

6. Restart sql server. now the database will be in emergency mode

7. Now execute the undocumented DBCC to create a log file

DBCC REBUILD_LOG(dbname,'c:\dbname.ldf') -- Undocumented step to create a new log file.

(replace the dbname and log file name based on ur requirement)

8. Execute sp_resetstatus <dbname>

9. Restart SQL server and see the database is online.