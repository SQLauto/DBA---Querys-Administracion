select db_name(dbid),(sum(size)*8)/1024
from sysaltfiles 
where filename like 'e:\%' and db_name(dbid) not in ('master','model','msdb','tempdb')
group by db_name(dbid)
order by (sum(size)*8)/1024

