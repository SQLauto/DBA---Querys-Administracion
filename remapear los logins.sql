CREATE PROCEDURE sp_SidMap
@old_domain      varchar(30), -- User Specifies the Old Domain Name
@new_domain      varchar(30), -- User Specifies the New Domain Name
@old_server      varchar(40), -- User specifies the Old Server from where the database was backed up
@new_server      varchar(40)  -- User specifies the New Server where the database is restored to 

AS

SET NOCOUNT ON

DECLARE @domains_different_flag CHAR(1)

-- ERROR IF IN USER TRANSACTION
IF @@trancount > 0
BEGIN
  RAISERROR(15289,-1,-1)
  RETURN(0)
END

-- Check to make sure that all the Parameters are passed
IF (@old_domain IS NULL)
BEGIN
  PRINT'Error: Pass the Old Domain Name where this database existed before, 
as the first parameter to the procedure'
  RETURN(0)
END

IF (@new_domain IS NULL)
BEGIN
  PRINT'Error: Pass the New Domain Name where this database is restored to now, 
as the second parameter to the procedure'
  PRINT''
  PRINT'If the domain is same, pass the old domain as the second parameter, 
otherwise, pass the new domain name'
  RETURN(0)
END

IF (@old_server IS NULL)
BEGIN
  PRINT'Error: Pass the Old Server Name from where where this database existed before, 
as the third parameter to the procedure'
  RETURN(0)
END

IF (@new_server IS NULL)
BEGIN
  PRINT'Error: Pass the Current Server Name to where you restored the database, 
as the fourth parameter to the procedure'
  RETURN(0)
END

-- Only an sa can run this procedure
IF ((SELECT suser_id()) <> 1)
BEGIN
  PRINT'Error: Only the sa may run sp_sidMap'
  RETURN(0)
END

-- Check to make sure not running in master
IF ((SELECT db_name()) = 'master')
BEGIN
  PRINT'Error: Please run sp_SidMap in the user database - not master database'
  RETURN(0)
END

-- Set the Flag if the database is moved OR restored to a different domain than the previous domain
IF @old_domain <> @new_domain
  SET @domains_different_flag = 'T'
ELSE
  SET @domains_different_flag = 'F'

PRINT'----------------------------------'
PRINT'MAPPING OF STANDARD LOGINS STARTED'
PRINT'----------------------------------'
PRINT''

DECLARE @sysusers_name VARCHAR(500), @sysusers_sid VARBINARY(85)
DECLARE @sysxlogins_sid VARBINARY(85), @ret_val INT
DECLARE stdsqlusers_cursor CURSOR
    FOR SELECT name, sid from sysusers
  WHERE issqluser = 1
    AND   issqlrole = 0
    AND   isapprole = 0
    AND   uid > 3
ORDER BY name
  
OPEN stdsqlusers_cursor 
WHILE (1 = 1)
BEGIN
  FETCH NEXT FROM stdsqlusers_cursor INTO @sysusers_name, @sysusers_sid
  IF(@@FETCH_STATUS <> 0)
  BEGIN
    CLOSE stdsqlusers_cursor
    DEALLOCATE stdsqlusers_cursor
    BREAK
  END

  IF NOT EXISTS (SELECT name FROM master..sysxlogins WHERE name = @sysusers_name)
  BEGIN
    EXEC @ret_val = sp_addlogin @loginame = @sysusers_name, @sid = @sysusers_sid
    IF @ret_val <> 0 
    BEGIN
      RAISERROR(15497,16,1,@sysusers_name)
      PRINT'MSG ****: Please add the Login : ' + @sysusers_name + ' using sp_addlogin.'
      CONTINUE
    END
  END
  
  EXEC sp_change_users_login update_one, @sysusers_name, @sysusers_name
  PRINT'Successfully mapped : ''' + @sysusers_name + ''''
  PRINT''       
END

PRINT'------------------------------------'
PRINT'MAPPING OF STANDARD LOGINS COMPLETED'
PRINT'------------------------------------'
PRINT''

PRINT''
PRINT'------------------------------------'
PRINT'MAPPING OF INTEGRATED LOGINS STARTED'
PRINT'------------------------------------'
PRINT''

PRINT'-----------------------------------------------------------------------------------'
PRINT'Please save the following output and follow the directions given by the text MSG***'
PRINT'After you follow all the steps until the end, Re-run the procedure sp_SidMap'
PRINT'-----------------------------------------------------------------------------------'
PRINT''

DECLARE integrated_users_cursor CURSOR
FOR 
SELECT name, sid
  FROM sysusers
 WHERE (isntgroup = 1 OR isntuser = 1)
   AND isaliased = 0
   AND issqlrole = 0
   AND isapprole = 0

CREATE TABLE #t_ambigous_logins(sysxlogins_name VARCHAR(500), sysusers_name VARCHAR(500))
CREATE TABLE #t_mapped_logins(sysusers_name VARCHAR(500), sysxlogins_name VARCHAR(500))
CREATE TABLE #t_created_logins(sysusers_name VARCHAR(500))

DECLARE @new_server_login VARCHAR(500), @old_server_login VARCHAR(500)
DECLARE @old_domain_login VARCHAR(500), @new_domain_login VARCHAR(500)
DECLARE @strippedoff_sysusers_name VARCHAR(500), @regular_sysusers_name VARCHAR(500)
DECLARE @sysusers_count INT, @sysxlogins_count INT
DECLARE @sysxlogins_name VARCHAR(500), @has_prefix_flag CHAR(1)
DECLARE @no_prefix_local_login CHAR(1), @no_prefix_global_login CHAR(1), @user_is_local_login CHAR(1)
   
OPEN integrated_users_cursor
WHILE (1 = 1)
BEGIN
  -- Initialize PARAMS
  SET @strippedoff_sysusers_name = NULL
  SET @regular_sysusers_name = NULL
  SET @old_server_login = NULL
  SET @new_server_login = NULL
  SET @old_domain_login = NULL
  SET @new_domain_login = NULL
  SET @sysxlogins_count = NULL
  SET @has_prefix_flag = NULL
  SET @user_is_local_login = 'F'

  FETCH NEXT FROM integrated_users_cursor INTO  @sysusers_name, @sysusers_sid
  IF(@@FETCH_STATUS <> 0)
  BEGIN
    DEALLOCATE integrated_users_cursor
    BREAK
  END

  --Build a regular version and a stripped off version of sysusers.name
  IF CHARINDEX('\', @sysusers_name)<> 0
  BEGIN 
    SET @strippedoff_sysusers_name = lower(substring(@sysusers_name, (charindex('\', @sysusers_name)+ 1), 256))
    SET @has_prefix_flag = 'T'
    
    -- Get a count of matching logins from sysxlogins for this user when the user has a prefix
    SELECT @sysxlogins_count = COUNT(*)
      FROM master..sysxlogins
     WHERE name = @sysusers_name
  END
  ELSE IF CHARINDEX('\', @sysusers_name)= 0 
  BEGIN
    SET @strippedoff_sysusers_name = lower(@sysusers_name)
    SET @has_prefix_flag = 'F'

    -- Get a count of matching logins from sysxlogins for this user when 
    -- the user does not have a prefix
    SELECT @sysxlogins_count = COUNT(*)
      FROM master..sysxlogins
     WHERE name LIKE '%\' + @sysusers_name
  END

  -- Build the New Server, Old Server, Old Domain, New Domain Login strings here
  SET @old_server_login = @old_server + '\' + @strippedoff_sysusers_name
  SET @new_server_login = @new_server + '\' + @strippedoff_sysusers_name
  SET @old_domain_login = @old_domain + '\' + @strippedoff_sysusers_name
  SET @new_domain_login = @new_domain + '\' + @strippedoff_sysusers_name
 
  -- There are two possibilities if the count in sysxlogins = 1. It is either a local 
  -- user that has already been mapped or it is a global user for which nothing needs 
  -- to be done as the database was moved to a Server in the same domain
  IF @sysxlogins_count = 1
  BEGIN
  -- If the user does not have a prefix, but the sysxlogins table has an entry for this user
  -- then update sysusers and map the SIDs
  IF @has_prefix_flag = 'F'
  BEGIN
    SELECT @sysxlogins_sid = sid, @sysxlogins_name = name 
      FROM master..sysxlogins WHERE name LIKE '%\' + @sysusers_name
    IF @sysxlogins_sid <> @sysusers_sid
    BEGIN
      UPDATE sysusers SET sid = @sysxlogins_sid, name = @sysxlogins_name
       WHERE name = @sysusers_name
      INSERT INTO #t_mapped_logins VALUES(@sysusers_name, @sysxlogins_name)
    END
  END -- has_prefix_flag = F
  ELSE
  BEGIN
    SELECT @sysxlogins_sid = sid FROM master..sysxlogins WHERE name = @sysusers_name
    IF @sysxlogins_sid <> @sysusers_sid
    BEGIN
    -- The following is true ONLY when sp_prefix_sysusersname procedure is executed and 
    -- the sysusers.name is changed to a local login or a global login on the new server.
      UPDATE sysusers SET sid = @sysxlogins_sid WHERE name = @sysusers_name
      INSERT INTO #t_mapped_logins VALUES(@sysusers_name, @sysusers_name)
    END
  END -- has_prefix_flag = T       
  
END 
-- End of sysxlogins_count = 1

-- Begin of sysxlogins_count = 0      
IF @sysxlogins_count = 0
BEGIN

-- Initialize the flags
SET @no_prefix_local_login = 'F'
SET @no_prefix_global_login = 'F'

IF ((@has_prefix_flag = 'T') AND (@sysusers_name = @old_server_login))
BEGIN
  -- Flag that this is a local user and will not have to be looked at again in the different 
  -- domains section of code.
  SET @user_is_local_login = 'T'
  -- Case when sysusers.name has the prefix of the local server name 
  -- and it exists in sysxlogins
  IF EXISTS(SELECT sid FROM master..sysxlogins WHERE name = @new_server_login)
  BEGIN
    SELECT @sysxlogins_sid = sid FROM master..sysxlogins WHERE name = @new_server_login
    UPDATE sysusers SET sid = @sysxlogins_sid, name = @new_server_login
     WHERE name = @sysusers_name
    INSERT INTO #t_mapped_logins VALUES(@sysusers_name, @new_server_login)
  END
  ELSE
  BEGIN
  -- Case when sysusers.name has the prefix of the local server name but it does not 
  -- exist in sysxlogins. So try granting the user account or group access to SQL Server.
    EXEC @ret_val = sp_grantlogin @new_server_login
    IF (@ret_val = 0)
      BEGIN
        PRINT''
        UPDATE sysusers SET name = @new_server_login,
               sid = ( SELECT sid from master..sysxlogins WHERE  name = @new_server_login )
         WHERE name = @sysusers_name
        INSERT INTO #t_created_logins VALUES(@sysusers_name)
      END
    ELSE IF (@ret_val = 1)
    -- If the user account or group cannot be granted access to SQL Server, 
    -- output a message for the user to first create the user account or group.
      PRINT'MSG ***: Create the Windows NT user account or group.'
      PRINT''
  END
END
ELSE IF ((@has_prefix_flag = 'T') AND (@sysusers_name = @old_domain_login) AND (@domains_different_flag = 'F'))
BEGIN
  IF EXISTS(SELECT sid FROM master..sysxlogins WHERE name = @old_domain_login)
  -- Case when sysusers.name has the prefix of the domain name and it exists in sysxlogins
  -- Nothing needs to be done as this is a global user account or group and the SIDs are same.
    PRINT''
  ELSE
  BEGIN
    -- Case when sysusers.name has the prefix of the domain name and it does not exist 
    -- in sysxlogins, first try granting the user account or group access to SQL Server
    EXEC @ret_val = sp_grantlogin @old_domain_login
    IF ( @ret_val = 0 )
    BEGIN   
      UPDATE sysusers SET name = @old_domain_login,
               sid = ( SELECT sid from master..sysxlogins WHERE  name = @old_domain_login )
         WHERE name = @sysusers_name
      INSERT INTO #t_created_logins VALUES(@old_domain_login)
      PRINT''
    END
    ELSE IF (@ret_val = 1)
    BEGIN
    -- If granting access for the global user account or group to SQL server fails, output a message
    -- to the user to do it explicitly as it may not be there in rhe domain yet
      PRINT'MSG ***: Create this Windows NT user account or group on the domain.'
      PRINT''
    END -- @ret_val = 1
  END -- If the domain user account or group does not exist in sysxlogins
END -- If the has_prefix_flag = 'T'
ELSE IF (@has_prefix_flag = 'F')
BEGIN
-- Case when sysusers.name does not have the prefix and the user does not have an entry 
-- in sysxlogins. There is no way of knowing which user account or group this belongs to.
-- Output a message asking to resolve the user by adding the user account or group 
-- at the Operating System level and then grant access to SQL Server.
  PRINT'MSG ***: Unable to resolve the user account or group : ''' + @sysusers_name + ''''   
  PRINT'MSG ***: Create a Windows NT user account or group for the above if it does not already exist.'
  PRINT'MSG ***: Grant this user account or group access to SQL Server using sp_grantlogin.'
  PRINT''
END

-- Case where sysusers.name has a prefix of the old domain name or it does not have a prefix
-- But, the database has moved to a new domain
IF ((@domains_different_flag = 'T') AND (@user_is_local_login = 'F'))
BEGIN
-- Case when sysusers.name exists in sysxlogins then map the SIDs and change 
-- the sysusers.name to reflect the new domain name.
  IF EXISTS ( SELECT sid FROM master..sysxlogins WHERE name = @new_domain_login )
  BEGIN
    SELECT @sysxlogins_sid = sid FROM master..sysxlogins WHERE name = @new_domain_login
    UPDATE sysusers SET sid = @sysxlogins_sid, name = @new_domain_login
     WHERE name = @sysusers_name             
    INSERT INTO #t_mapped_logins VALUES(@sysusers_name, @new_domain_login)
  END
  ELSE
  BEGIN
    IF (@has_prefix_flag = 'T')
    BEGIN
    -- Case when sysusers.name has a prefix of the old domain name, but it does not 
    -- exist in the sysxlogins table, try granting the user account or group access to 
    -- SQL Server.
      EXEC @ret_val = sp_grantlogin @new_domain_login
      IF ( @ret_val = 0 )
      BEGIN
	SELECT @sysxlogins_sid = sid FROM master..sysxlogins WHERE name = @new_domain_login
        UPDATE sysusers SET sid = @sysxlogins_sid, name = @new_domain_login
         WHERE name = @sysusers_name
        INSERT INTO #t_created_logins VALUES(@new_domain_login)
        PRINT''
      END
      ELSE IF ( @ret_val = 1 )
      -- If granting the user account or group access to SQL Server fails, give the ability 
      -- for the user to create the user account or group and then grant to SQL Server.
      BEGIN
        PRINT'MSG ***: Could not find the global user account or group in the domain ' + @new_domain + '.'
        PRINT'MSG ***: Create this global user account or group on the new domain.'
        PRINT''
      END -- ret_val = 1
    END -- has_prefix_flag = 'T'
  END -- Else Clause for existence of the domain login in sysxlogins
  END -- The 'T' Flag
END -- The count = 0

IF @sysxlogins_count > 1
BEGIN
-- Case when the sysusers.name does not have any prefix and there are multiple logins 
-- for this user in the sysxlogins table. Example would be a local login and a global 
-- login with the same name.
   INSERT INTO #t_ambigous_logins SELECT name, @sysusers_name
     FROM master..sysxlogins WHERE name LIKE '%\' + @sysusers_name
END -- IF COUNT > 1

END -- End the WHILE LOOP

-- Print the login mapping and login creation information 
IF EXISTS( SELECT 1 FROM #t_mapped_logins )
BEGIN
  DECLARE mapped_logins_cur CURSOR
  FOR
  SELECT sysusers_name, sysxlogins_name
    FROM #t_mapped_logins
  DECLARE @sqlstr varchar(1000), @var1 VARCHAR(400), @var2 VARCHAR(400)

  PRINT''
  PRINT''
  PRINT'USER ACCOUNT OR GROUP MAPPING INFORMATION:'
  PRINT'-----------------------------------------'
  OPEN mapped_logins_cur
  WHILE (1 = 1)
  BEGIN
    FETCH NEXT FROM mapped_logins_cur INTO  @var1, @var2
    IF(@@FETCH_STATUS <> 0)
    BEGIN
      DEALLOCATE mapped_logins_cur
      BREAK
    END
    SELECT @sqlstr = '''' + RTRIM(@var1) + ''''+ ' is mapped to ' + '''' + RTRIM(@var2) + ''''
    PRINT @sqlstr      
  END
END

IF EXISTS( SELECT 1 FROM #t_created_logins )
BEGIN
  DECLARE created_logins_cur CURSOR
  FOR
  SELECT sysusers_name
    FROM #t_created_logins

  PRINT''
  PRINT''
  PRINT'USER ACCOUNT OR GROUP GRANT AND MAPPING INFORMATION:'
  PRINT'---------------------------------------------------'
  OPEN created_logins_cur
  WHILE (1 = 1)
  BEGIN
    FETCH NEXT FROM created_logins_cur INTO  @var1
    IF(@@FETCH_STATUS <> 0)
    BEGIN
      DEALLOCATE created_logins_cur
      BREAK
    END
    SELECT @sqlstr = ''''+ @var1 + ''''+ ' is granted access to SQL Server and then mapped to sysxlogins'
    PRINT @sqlstr      
  END
END

IF EXISTS( SELECT 1 FROM #t_ambigous_logins )
BEGIN
  DECLARE ambigous_logins_cur CURSOR
  FOR
  SELECT RTRIM(sysusers_name), RTRIM(sysxlogins_name) 
    FROM #t_ambigous_logins
  ORDER BY sysusers_name

  PRINT''
  PRINT''
  PRINT'MULTIPLE LOGINS FOR EACH USER INFORMATION:'
  PRINT'-----------------------------------------'
  OPEN ambigous_logins_cur
  WHILE (1 = 1)
  BEGIN
    FETCH NEXT FROM ambigous_logins_cur INTO  @var1, @var2
    IF(@@FETCH_STATUS <> 0)
    BEGIN
      DEALLOCATE ambigous_logins_cur
      BREAK
    END
    SELECT @sqlstr = 'Name in Sysusers is : ' + ''''+ @var1 + '''' + '  ,  ' + 'Name in Sysxlogins is : ' + '''' + @var2 + ''''  
    PRINT @sqlstr      
  END

  PRINT''
  PRINT''
  PRINT'RESOLVE MULTIPLE LOGINS INFORMATION:'
  PRINT'------------------------------------'
  
  DECLARE ambigous_logins_cur CURSOR
  FOR
  SELECT RTRIM(sysusers_name), RTRIM(sysxlogins_name) 
    FROM #t_ambigous_logins
  ORDER BY sysusers_name
  
  OPEN ambigous_logins_cur
  WHILE (1 = 1)
  BEGIN
    FETCH NEXT FROM ambigous_logins_cur INTO  @var1, @var2
    IF(@@FETCH_STATUS <> 0)
    BEGIN
      DEALLOCATE ambigous_logins_cur
      BREAK
    END
    SELECT @sqlstr = 'exec sp_Prefix_SysusersName ' + '''' + db_name() + ''''+ ', ' + '''' + @var1+ '''' + ', ''' + @var2+ ''''
    PRINT @sqlstr      
  END
END

PRINT''
PRINT'--------------------------------------'
PRINT'MAPPING OF INTEGRATED LOGINS COMPLETED'
PRINT'--------------------------------------'

SET NOCOUNT OFF

RETURN(1)
-- End of Procedure sp_SidMap

