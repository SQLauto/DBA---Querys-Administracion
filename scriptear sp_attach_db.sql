

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF
DECLARE @db sysname,
	@cmd varchar(1000),
	@a Varchar(2000),
	@Filecnt int,
	@cnt int,
	@sq char(1),
	@dq char(2),
	@TempFilename Varchar(1000),
	@TempFilename1 Varchar(1000)


SELECT 	@sq = '''',
	@dq = '''''',
	@cnt = 1


  declare db_cursor cursor for 
  Select name from sysdatabases Where name not in ('tempdb','msdb','model','master') order by dbid
  open db_cursor 
  fetch next from db_cursor into @db
  while @@fetch_status = 0 
    begin 
    Create table #2 (fileid int,filename sysname,name sysname)
    SET @cmd = 'Insert into #2 (fileid,filename,name) Select fileid,filename,name from ' + QuoteName(@db)  + '.dbo.sysfiles'
    exec (@cmd)
    select @filecnt =  max(fileid) from #2
      While @cnt <= @filecnt
      Begin 
      Select @TempFileName = filename from #2 where fileid = @cnt
      Select @TempFileName = rtrim(@TempFileName)
      Select @a = @a+', '
      Select  @a = @a  +'@filename'+Convert(varchar(2),@cnt)+' = '+@sq+@TempFilename+@sq
      Set @cnt = @cnt + 1
      End
    Select @a = 'EXEC sp_attach_db @dbname = ' +@sq+@db+@sq+@a
    Print @a
    Print 'GO' 
    Select @a = ' '
    drop table #2
    set @cnt = 1
    fetch next from db_cursor into @db
    end 
  close db_cursor 
  deallocate db_cursor 

