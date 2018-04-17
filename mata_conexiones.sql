CREATE proc mata_conexion
@base varchar(30)
as
create table #temp_kill
(descrip varchar(30))
insert into #temp_kill
select convert(char(5),spid)
from master..sysprocesses
where dbid= db_id(@base)

declare 
	 @comando varchar(30),
	 @descrip varchar(30)

declare cont_kill cursor for
	select * from #temp_kill

open cont_kill
fetch next from cont_kill into @descrip
while (@@fetch_status <> -1)
begin
	select @comando = ('kill ' + @descrip)
	exec (@comando)
	fetch next from cont_kill into @descrip
end
deallocate cont_kill
drop table #temp_kill





