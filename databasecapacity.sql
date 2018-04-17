ALTER proc databasecapacity(
	@threshold int,									-- database fill-up threshold.
	@exclincl varchar(10) = null,		-- specifies whether database list will be included or excluded, by passing "in" or "ex".
	@iedblist varchar(1000) = null)	-- database list to be either included or excluded.
as
/*
	--	autor:		juan pablo otero
	--	company:	ibm argentina
	--	date:		12/11/2004
	--	version:	1.0

	the following examples illustrate the syntax:

	1. checks all databases for the specified threshold of 90%:
		exec databasecapacity 90

	2. checks all databases, except the ones specified in the exclude list:
		exec databasecapacity 90, 'ex', 'suspectdb, baddb, brokendb, testdb, sickdb'

	3. checks only those databases, which are included in the include list:
		exec databasecapacity 90, 'in', 'gooddb, nicedb, healthydb'
*/
set nocount on

declare 
	@dbname varchar(30),										-- database name.
	@bldstr varchar(8000),									-- variable used to build character strings.
	@totalusedextents dec(15,2),						-- total # of extents, actually in use, for the data portion of the db.
	@totalextents dec(15,2),								-- total # of extents for the data portion of the db.
	@totalpossibleextents dec(15,2),				-- the total number of data extents possible, should the db increase to the max size possible.
	@theoreticaldrop_in_percentused int,		-- theoretical drop in db used %age, should the db size increase to the max size possible.
	@percentused int,												-- %age of the data portion of the db, which is filled up.
	@logicalname nchar(256),								-- logical name of file e.g., mastlog
	@physicalname nchar(520),								-- physical name of file e.g., d:\sql7\data\master.mdf
	@filesize varchar(30),									-- allocated size of a file in kb, as a character string.
	@maxfilesize varchar(30),								-- max size of a file in kb, as a character string.
	@growth varchar(30),										-- growth increment for a file, specified as a %age or in kb, in the form of a character string.
	@usage varchar(30),											-- specifies purpose of file ... data or log.
	@filesize_dec dec(15,2),								-- allocated size of a file in kb, as a decimal number.
	@maxfilesize_dec dec(15,2),							-- max size of a file in kb, as a decimal number.
	@growth_dec dec(15,2),									-- growth increment for a file, specified as a %age or in kb, in the form of a decimal number.
	@growth_increment dec(15,2),						-- actual growth increment in kb, when growth is specified as a %age.
	@drive_letter char(1),									-- drive letter, e.g., c, d etc.
	@drivefreespace dec(15,2),							-- free space on an individual drive in kb.
	@usedspace dec(15,2),										-- used space in kb, for an individual data file.
	@unusedspace dec(15,2),									-- unused portion of a data file, in kb.
	@numincrementspossible int,							-- no. of increases in db size possible, with the current specified increment.
	@theoreticalpossibleincrease_file dec(15,2), -- max theoretical possible increase in the size of one data file, in kb.
	@theoreticalpossibleincrease_db dec(15,2)    -- max theoretical possible increase in the data portion of the size of the whole db, in kb.

/* table used to capture free space on all drives. */
create table #fixed_drives(
	drive_letter char(1),
	mb_free decimal)

/* table used to capture information about individual database files, using sp_helpfile. */
create table #sysfiles(
	logicalname nchar(256),
	fileid smallint,
	physicalname nchar(520),
	filegroup varchar(20) null,
	filesize varchar(30),
	maxfilesize varchar(30),
	growth varchar(30),
	usage varchar(30))

/* table used to capture the output of dbcc showfilestats. */
create table #db_fillup_stats( 
	fileid int not null, 
	filegroup int not null, 
	totalextents dec(15,0) not null,  
	usedextents dec(15,0) not null, 
	name varchar(200) not null, 
	filename varchar(200) not null)	

/* table used to capture database options for databases. */
create table #db_options(
	db_option_name varchar(100))

/* table used to capture names of databases which might need to be excluded or included
   in our checks. */
create table #includeexclude(
	dbname varchar(255)
)

insert #fixed_drives
	exec master..xp_fixeddrives

if @iedblist is null
	begin
		declare dbnamecursor cursor for
		select name from master..sysdatabases
		order by name
	end

if (@iedblist is not null) and (@exclincl not in ('in', 'ex'))
	begin
		print 'the second parameter needs to be either "in" or "ex", to specify whether the db list needs to be included or excluded.'
		return
	end

if  (@iedblist is not null) and (@exclincl is not null)
	begin
		while charindex(',', @iedblist) > 0
			begin
				insert into #includeexclude
					select rtrim(ltrim(substring(@iedblist, 1, charindex(',', @iedblist) - 1)))
				select @iedblist = substring(@iedblist, charindex(',', @iedblist) + 1, 255)
			end

			insert into #includeexclude
			select rtrim(ltrim(@iedblist))
			if @exclincl like 'in%'
				begin
					declare dbnamecursor cursor for
					select name from master..sysdatabases
					where name in (select dbname from #includeexclude)
					order by name
				end
			else if @exclincl like 'ex%'
				begin
					declare dbnamecursor cursor for
					select name from master..sysdatabases
					where name not in (select dbname from #includeexclude)
					order by name
				end
	end

open dbnamecursor 

while (@@fetch_status=@@fetch_status)
begin
   fetch next from dbnamecursor into @dbname
	if @@fetch_status = -2			--row has been deleted.
		continue			--go back to top of the while loop.
	if @@fetch_status = -1			--all rows processed.
		break				--break out of the while loop.
	else
		begin
			select @theoreticalpossibleincrease_db = 0	-- initializing the variable.

			/* skip database, if marked as read only. */

			select @bldstr = 'exec sp_dboption [' + @dbname + ']'
			insert #db_options
				exec(@bldstr)
			if (select count(*) from #db_options where db_option_name like '%read%') > 0
				begin
					truncate table  #db_options
					continue
				end

			/* calcualte %age used, using dbcc showfilestats. if below threshold, go to the next database. if over the threshold, 
			   compute the maximum theoretical increase in the size of the database, taking into account auto-grow and the individual 
			   increments, for all the data files. recompute the %age used based upon the max size of the database. if the new %age 
			   used is still above threshold, raise an alert, otherwise, skip to the next database. */

			select @bldstr = 'use [' + @dbname + '] insert into #db_fillup_stats exec(''dbcc showfilestats with no_infomsgs'')' 
				exec(@bldstr)
			select @totalusedextents = sum(usedextents) from #db_fillup_stats
			select @totalextents = sum(totalextents) from #db_fillup_stats
			select @percentused = (@totalusedextents/@totalextents)* 100 from #db_fillup_stats  
			if @percentused < @threshold
				begin
					truncate table #db_fillup_stats
					truncate table  #db_options
					continue
				end
			else
				begin
					select @bldstr = 'use [' + @dbname + '] exec sp_helpfile'
					insert #sysfiles
						exec(@bldstr)	
					delete #sysfiles where usage like '%log only%'
					update #sysfiles
						set usage = usage + ' :percent' where growth like '%/%%' escape '/'
					update #sysfiles
						set usage = usage + ' :kb' where growth like '%kb%' 
					update #sysfiles
						set growth = replace(growth, ' kb', '')
					update #sysfiles
						set growth = replace(growth, '%', '')
					update #sysfiles
						set filesize = replace(filesize, ' kb', '')
					update #sysfiles
						set maxfilesize = replace(maxfilesize, ' kb', '')
					if (select count(*) from #sysfiles where growth != '0') = 0
						begin
							raiserror(90002,17,1, @dbname, @percentused, '% used.', @threshold, '%. no data files are configured for auto-grow.') with log
							truncate table #sysfiles
							truncate table #db_fillup_stats
							truncate table  #db_options
							continue
						end

					declare dbfilescursor cursor for 
					select logicalname, physicalname, filesize, maxfilesize, growth, usage from #sysfiles where growth != '0'

					open dbfilescursor
					
					while (@@fetch_status=@@fetch_status)
						begin
   							fetch next from dbfilescursor into @logicalname, @physicalname, @filesize, @maxfilesize, @growth, @usage
							if @@fetch_status = -2			--row has been deleted.
								continue			--go back to top of the while loop.
							if @@fetch_status = -1			--all rows processed.
								break				--break out of the while loop.
							else
								begin
									select @growth_dec = convert(dec, @growth)
									select @filesize_dec = convert(dec, @filesize)
									select @drive_letter = substring(@physicalname, 1, 1)
									select @usedspace = usedextents*64 from #db_fillup_stats where name = @logicalname
									if (@usage like '%percent%')
										begin
											select @growth_increment = (@usedspace*@growth_dec)/100
											if @maxfilesize = 'unlimited'
												begin
													select @drivefreespace = (mb_free*1024) from #fixed_drives where drive_letter = @drive_letter
													select @unusedspace = @filesize - @usedspace
													select @numincrementspossible = (@drivefreespace + @unusedspace)/@growth_increment
													select @theoreticalpossibleincrease_file = @growth_increment * @numincrementspossible
													select @theoreticalpossibleincrease_db = @theoreticalpossibleincrease_db + @theoreticalpossibleincrease_file
													continue
												end
											else
												begin
													select @maxfilesize_dec = convert(dec, @maxfilesize)
													select @unusedspace = @filesize - @usedspace
													select @numincrementspossible = ((@maxfilesize_dec - @filesize) + @unusedspace)/@growth_increment
													select @theoreticalpossibleincrease_file = @growth_increment * @numincrementspossible
													select @theoreticalpossibleincrease_db = @theoreticalpossibleincrease_db + @theoreticalpossibleincrease_file
													continue
												end
										end
									if (@usage like '%kb%')
										begin
											select @growth_increment = @growth_dec
											if @maxfilesize = 'unlimited'
												begin
													select @drivefreespace = (mb_free*1024) from #fixed_drives where drive_letter = @drive_letter
													select @unusedspace = @filesize - @usedspace
													select @numincrementspossible = (@drivefreespace + @unusedspace)/@growth_increment
													select @theoreticalpossibleincrease_file = @growth_increment * @numincrementspossible
													select @theoreticalpossibleincrease_db = @theoreticalpossibleincrease_db + @theoreticalpossibleincrease_file
													continue
												end
											else
												begin
													select @maxfilesize_dec = convert(dec, @maxfilesize)
													select @unusedspace = @filesize - @usedspace
													select @numincrementspossible = ((@maxfilesize_dec - @filesize) + @unusedspace)/@growth_increment
													select @theoreticalpossibleincrease_file = @growth_increment * @numincrementspossible
													select @theoreticalpossibleincrease_db = @theoreticalpossibleincrease_db + @theoreticalpossibleincrease_file
													continue
												end
										end
								end
						end
					select @totalpossibleextents = @totalextents + (@theoreticalpossibleincrease_db/64)
					select @theoreticaldrop_in_percentused = (@totalusedextents/@totalpossibleextents) * 100
					if @theoreticaldrop_in_percentused < @threshold
						begin
							truncate table #sysfiles
							truncate table #db_fillup_stats
							truncate table  #db_options
						end
					else
						begin
							raiserror(90002,17,1, @dbname, @theoreticaldrop_in_percentused, '% used.', @threshold, '%. auto-grow will not reduce usage below threshold, due to maxcap or drive space limitations.') with log
							truncate table #sysfiles
							truncate table #db_fillup_stats
							truncate table  #db_options
						end
					close dbfilescursor
					deallocate dbfilescursor
				end
		end
end

close dbnamecursor
deallocate dbnamecursor

/* cleanup */
drop table #fixed_drives
drop table #sysfiles
drop table #db_fillup_stats
drop table #db_options
drop table #includeexclude



