set nocount on


print 'Show Size, Space Used, Unused Space, Type, and Name of all database files'

select
	[FileSizeMB]	=
		convert(numeric(10,2),sum(round(a.size/128.,2))),
        [UsedSpaceMB]	=
		convert(numeric(10,2),sum(round(fileproperty( a.name,'SpaceUsed')/128.,2))) ,
        [UnusedSpaceMB]	=
		convert(numeric(10,2),sum(round((a.size-fileproperty( a.name,'SpaceUsed'))/128.,2))) ,
		[UnusedSpace%] =
	 convert(numeric(5,2),(sum(round((a.size-fileproperty( a.name,'SpaceUsed'))/128.,2))*100)/sum(round(a.size/128.,2))),
	[Type] =
		case when a.groupid is null then '' when a.groupid = 0 then 'Log' else 'Data' end,
	[DBFileName]	= isnull(a.name,'*** Total for all files ***')
from
	sysfiles a
group by
	groupid,
	a.name
	with rollup
having
	a.groupid is null or
	a.name is not null
order by
	case when a.groupid is null then 99 when a.groupid = 0 then 0 else 1 end,
	a.groupid,
	case when a.name is null then 99 else 0 end,
	a.name
