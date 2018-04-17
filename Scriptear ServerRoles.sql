SET NOCOUNT ON
DECLARE @SQLCmd nvarchar(1000)
DECLARE @RoleName sysname
DECLARE @Login sysname
DECLARE @Count int

Create table #ServerRoles (
ServerRole sysname,
MemberName sysname,
MemberSID varbinary(85))

INSERT INTO #ServerRoles
exec master.dbo.sp_helpsrvrolemember 

DECLARE ServerRoleCursor Cursor 
FOR SELECT ServerRole,MemberName 
FROM #ServerRoles 
WHERE MemberName not like 'NT SERVICE%' AND 
MemberName <> 'sa' AND
MemberName not like 'NT AUTHORITY%'

OPEN ServerRoleCursor

FETCH NEXT FROM ServerRoleCursor
INTO @RoleName, @Login


SET @Count = 0

WHILE @@FETCH_STATUS = 0
BEGIN
 SET @SQLCmd = 'exec master.dbo.sp_addsrvrolemember ''' + @Login + ''' , ''' + @RoleName + ''''
 PRINT @SQLCmd

 SET @Count = @Count + 1 

 FETCH NEXT FROM ServerRoleCursor
 INTO @RoleName, @Login
END

CLOSE ServerRoleCursor
DEALLOCATE ServerRoleCursor

DROP TABLE #ServerRoles
