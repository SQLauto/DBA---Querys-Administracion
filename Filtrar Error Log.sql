--- 2005
create table #testlog(dt datetime, info varchar(200), errtext varchar(max))
insert into #testlog
exec sp_readerrorlog

select * from #testlog where errtext like '%palabra a buscar%'

---2000
create table #testlog(errtext varchar(8000),num int)
insert into #testlog
exec sp_readerrorlog

select * from #testlog where errtext like '%tasadas%'