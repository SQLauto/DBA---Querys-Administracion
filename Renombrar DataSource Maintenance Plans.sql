  use msdb

   DECLARE @oldservername as varchar(max)
    SET @oldservername='SQL03.EMPLEOS.TRESVERTICALES.COM'

   -- set the new server name to the current server name

   declare @newservername as varchar(max)
    set @newservername=@@servername

   declare @xml as varchar(max)
    declare @packagedata as varbinary(max)
    -- get all the plans that have the old server name in their connection string
    DECLARE PlansToFix Cursor
    FOR
    SELECT    id
    FROM         sysssispackages
    WHERE     (CAST(CAST(packagedata AS varbinary(MAX)) AS varchar(MAX)) LIKE '%Data Source=' + @oldservername + '%')
	--select '%Data Source=''' + @oldservername + '%'

   OPEN PlansToFix


   declare @planid uniqueidentifier
    fetch next from PlansToFix into @planid

   while (@@fetch_status<>-1)  -- for each plan

   begin
    if (@@fetch_status<>-2)
    begin
    select @xml=cast(cast(packagedata as varbinary(max)) as varchar(max)) from sysssispackages where id= @planid  -- get the plan's xml converted to an xml string

   declare @planname varchar(max)
    select @planname=[name] from  sysssispackages where id= @planid  -- get the plan name
    print 'Changing ' + @planname + ' server from ' + @oldservername + ' to ' + @newservername  -- print out what change is happening

   set @xml=replace(@xml,'Data Source=' + @oldservername + '','Data Source=' + @newservername +'')  -- replace the old server name with the new server name in the connection string
   select @packagedata=cast(@xml as varbinary(max))  -- convert the xml back to binary
	--select @xml
	--select @planid
   UPDATE    sysssispackages SET packagedata = @packagedata WHERE (id= @planid)  -- update the plan

   end
    fetch next from PlansToFix into @planid  -- get the next plan

   end

   close PlansToFix
    deallocate PlansToFix

