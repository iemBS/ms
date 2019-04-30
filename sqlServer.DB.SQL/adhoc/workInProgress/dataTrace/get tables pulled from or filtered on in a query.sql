/*
Get all character permutations on the left and right side of a table, view, or UDF that returns a table
*/

-- clean up
IF OBJECT_ID('tempdb..##CharBorderOnTablepermutation') IS NOT NULL
    DROP TABLE ##CharBorderOnTablePermutation

-- note the possible characters that can be on either side
select	
	CHAR(32) as [char] -- space
into
	#char

-- note the possible characters that can be on the left side
Select
	[char]
into
	#left
From
	#char

-- note the possible characters that can be on the right side
Select
	[char]
into
	#right
From
	#char
union
select CHAR(41) -- right parenthesis

-- get all permutations of left and right characters
Select
	l.[char] as leftChar,
	r.[char] as rightChar
into
	##CharBorderOnTablePermutation
From
	#left l
	Cross Join #right r

-- clean up
IF OBJECT_ID('tempdb..#char') IS NOT NULL
    DROP TABLE #char

IF OBJECT_ID('tempdb..#left') IS NOT NULL
    DROP TABLE #left

IF OBJECT_ID('tempdb..#right') IS NOT NULL
    DROP TABLE #right

/*
	get what tables, views, and UDFs are pulled from or filtered on in a specified query
*/

declare @query varchar(600)
set @query = 
'Insert Into
	tableC
select
	*
From
	[db o].TableA a
	Inner Join [Table B] b On 
		a.col = b.col 
Where
	b.TableID In (Select TableID From adventureWorks.check.TableF)
union 
select
	*
From
	[db o].TableD d
	Inner Join dbo.[Table E] e On 
		d.col = e.col
union
select * from dbo.udf_TableG() where TableID = 3 

INSERT tableC Exec sp_helpfile

Insert Into TableC select * FROM OPENROWSET(''SQLNCLI'', ''Server=(local)\SQL2008;Trusted_Connection=yes;'',
     ''EXEC getBusinessLineHistory'')
insert into TableC select * FROM OPENQUERY(YOURSERVERNAME, ''EXEC db.schema.sproc 1'')'

IF OBJECT_ID('tempdb..#fromTable') IS NOT NULL
    DROP TABLE #fromTable

declare @searchableQuery varchar(600)

--replace line feed, carriage return, and tab with a space
select @searchableQuery = replace(replace(replace(@query,char(9),' '),char(10),' '),char(13),' ')

-- change series of blank spaces to one blank space
declare @prevQueryLength int
select @prevQueryLength = len(@searchableQuery)
declare @newQueryLength int
set @newQueryLength = 0

while @prevQueryLength > @newQueryLength
begin
	select @prevQueryLength = len(@searchableQuery)
	select @searchableQuery = replace(@searchableQuery,char(32)+char(32),char(32))
	select @newQueryLength = len(@searchableQuery)
end

-- remove blank space next to parenthesis
select @searchableQuery = replace(@searchableQuery,'(' + char(32),'(')
select @searchableQuery = replace(@searchableQuery,char(32) + ')',')')

-- change spaces between square brackets to be special text of |*placeholder*|
declare @idxStart int
declare @idxEnd int
declare @searchPosition int
set @searchPosition = 1
declare @originalSubQuery varchar(600)
declare @updatedSubQuery varchar(600)
declare @spacePlaceholder varchar(15)
set @spacePlaceholder = '|*placeholder*|'

while (select charindex('[',@searchableQuery,@searchPosition)) > 0
begin
	select @idxStart = charindex('[',@searchableQuery,@searchPosition)
	select @searchPosition = @idxStart + 1
	select @idxEnd = charindex(']',@searchableQuery,@idxStart)

	select @originalSubQuery = substring(@searchableQuery,@idxStart,(@idxEnd-@idxStart)+1)
	select @updatedSubQuery = replace(@originalSubQuery,char(32),@spacePlaceholder)

	select @searchableQuery = replace(@searchableQuery,@originalSubQuery,@updatedSubQuery)
end

-- remove space between single quote and closed parenthesis
select @searchableQuery = replace(@searchableQuery,''' )',''')')

-- table pulled from in the "from openrowset" part of query
create table #fromTable
(
	fromTable varchar(60),
	objectType varchar(25)
)

declare @borderText varchar(5)

set @borderText = 'OPENROWSET'
set @searchPosition = 1

while (select charindex(@borderText,@searchableQuery)) > 0
begin
	select @idxStart = charindex(@borderText,@searchableQuery) + len(@borderText)
	select @searchPosition = @idxStart + 1
	select @idxEnd = charindex(''')',@searchableQuery,@searchPosition)

	select  
		@searchableQuery = replace(@searchableQuery,substring(@searchableQuery,@idxStart - len(@borderText) - len('from ') - 1,@idxEnd),'('+replace([value],'''','')+')')
	from
		(
			select [value] from string_split(substring(@searchableQuery,@idxStart,(@idxEnd-@idxStart)+1),',')
			except
			select top 2 [value] from string_split(substring(@searchableQuery,@idxStart,(@idxEnd-@idxStart)+1),',')
		) t
end

-- table pulled from in the "from openquery" part of query
set @borderText = 'OPENQUERY'
set @searchPosition = 1

while (select charindex(@borderText,@searchableQuery)) > 0
begin
	select @idxStart = charindex(@borderText,@searchableQuery) + len(@borderText)
	select @searchPosition = @idxStart + 1
	select @idxEnd = charindex(''')',@searchableQuery,@searchPosition)

	select  
		@searchableQuery = replace(@searchableQuery,substring(@searchableQuery,@idxStart - len(@borderText) - len('from ') - 1,@idxEnd),'('+replace([value],'''','')+')')
	from
		(
			select [value] from string_split(substring(@searchableQuery,@idxStart,(@idxEnd-@idxStart)+1),',')
			except
			select top 1 [value] from string_split(substring(@searchableQuery,@idxStart,(@idxEnd-@idxStart)+1),',')
		) t
end

-- table pulled from in the "from" part of the query
set @borderText = 'from '
set @searchPosition = 1
declare @obj varchar(50)

while (select charindex(@borderText,@searchableQuery,@searchPosition)) > 0
begin
	select @idxStart = charindex(@borderText,@searchableQuery,@searchPosition) + len(@borderText)
	select @searchPosition = @idxStart + 1
	select @idxEnd = charindex(char(32),@searchableQuery,@searchPosition)
	select @obj = substring(@searchableQuery,@idxStart,(@idxEnd-@idxStart)+1)
	if charindex('()',@obj) > 0
	begin
		insert into #fromTable select @obj,'UDF'
	end
	else
	begin
		insert into #fromTable select @obj,'table,view'
	end
end

-- table pulled from in the "join" part of the query
set @borderText = 'join '
set @searchPosition = 1

while (select charindex(@borderText,@searchableQuery,@searchPosition)) > 0
begin
	select @idxStart = charindex(@borderText,@searchableQuery,@searchPosition) + len(@borderText)
	select @searchPosition = @idxStart + 1
	select @idxEnd = charindex(char(32),@searchableQuery,@searchPosition)
	if @idxEnd = 0 begin select @idxEnd = len(@searchableQuery) end -- if no characters after table name
	select @obj = substring(@searchableQuery,@idxStart,(@idxEnd-@idxStart)+1)
	if (select charindex('()',@obj)) > 0
	begin
		insert into #fromTable select @obj,'UDF'
	end
	else
	begin
		insert into #fromTable select @obj,'table,view'
	end
end

-- table pulled from in the "execute" part of the query
set @borderText = 'execute '
set @searchPosition = 1

while (select charindex(@borderText,@searchableQuery,@searchPosition)) > 0
begin
	select @idxStart = charindex(@borderText,@searchableQuery,@searchPosition) + len(@borderText)
	select @searchPosition = @idxStart + 1
	select @idxEnd = charindex(char(32),@searchableQuery,@searchPosition)
	if @idxEnd = 0 begin select @idxEnd = len(@searchableQuery) end -- if no characters after table name
	insert into #fromTable select substring(@searchableQuery,@idxStart,(@idxEnd-@idxStart)+1),'sproc'
end

-- table pulled from in the "exec" part of the query
set @borderText = 'exec '
set @searchPosition = 1

while (select charindex(@borderText,@searchableQuery,@searchPosition)) > 0
begin
	select @idxStart = charindex(@borderText,@searchableQuery,@searchPosition) + len(@borderText)
	select @searchPosition = @idxStart + 1
	select @idxEnd = charindex(char(32),@searchableQuery,@searchPosition)
	if @idxEnd = 0 begin select @idxEnd = len(@searchableQuery) end -- if no characters after table name
	insert into #fromTable select substring(@searchableQuery,@idxStart,(@idxEnd-@idxStart)+1),'sproc'
end

-- put space back into table name
Update
	#fromTable
Set
	fromTable = replace(fromTable,@spacePlaceholder,char(32))
Where
	charindex(@spacePlaceholder,fromTable) > 0 

-- remove parenthesis on right border of table name, but ignore UDFs when doing this
update
	#fromTable
Set
	fromTable =  left(fromTable,len(fromTable)-1)
Where	
	charIndex(')',fromTable) = len(fromTable)
	and
	charIndex('(',fromTable) != (len(fromTable)-1) -- filter out UDFs


-- change tables to use [db].[schema].[table] name format 
set @searchPosition = 1
declare @fromTable varchar(60)
declare @dirtyFromTable varchar(60)
declare @isSproc bit
declare @dbName varchar(60)
set @dbName = 'xyz'

while @searchPosition <= (select max(ID) From #fromTable)
begin
	select 
		@dirtyFromTable = fromTable,
		@isSproc = case when objectType = 'sproc' then 1 else 0 end
	From 
		#fromTable where ID = @searchPosition

	exec [dbo].[dataTrace_getFullObjName] @dirtyFromTable,@dbName,1,@fromTable output

	update
		#fromTable
	set
		fromTable = @fromTable
	where
		ID = @searchPosition

	set @searchPosition = @searchPosition + 1
end

-- return tables
select * From #fromTable