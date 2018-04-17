declare @rc int
declare @dir nvarchar(5)

exec @rc = master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE',N'Software\Microsoft\MSSQLServer\MSSQLServer\SuperSocketNetLib\Tcp',N'TcpPort', @dir output

select @dir