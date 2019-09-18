

-- parameters
/*
	@valueToSearchFor - Value to search for in column values
	@specificity - "like" or "exact"
	@resultSize - Number of searched columns to return in result. "All" or "10". 
*/

declare @valueToSearchFor nvarchar(100)
declare @specificity varchar(5)
declare @resultSize varchar(5)

set @valueToSearchFor = 'windows' -- *** PARAMETER ***
set @specificity = 'exact' -- *** PARAMETER ***
set @resultSize = '10' -- *** PARAMETER ***

if exists(select * from tempdb.INFORMATION_SCHEMA.TABLES where table_name like '#valueSearch%')
begin
	drop table #valueSearch
end

select
	TABLE_SCHEMA as schemaName
	,TABLE_NAME as tableName
	,COLUMN_NAME as columnName
	,DATA_TYPE as dataType
	,CHARACTER_MAXIMUM_LENGTH as textMaxLength
	,NUMERIC_PRECISION as numberSize
into
	#valueSearch
from
	INFORMATION_SCHEMA.COLUMNS
	
-- variables
declare @textLength int
declare @numberOnlyFlag char(1)
declare @currentCnt int
declare @columnName varchar(100)
declare @tableName varchar(100)
declare @schemaName varchar(25)
declare @whereClause varchar(100)
declare @query nvarchar(500)
declare @totalCnt int
declare @resultsCnt int
	
-- narrow list of columns
begin try
	select @currentCnt = @valueToSearchFor + 1
	set @numberOnlyFlag = 'Y'
end try
begin catch
	set @numberOnlyFlag = 'N'
end catch

--select 'Number Only? ' + @numberOnlyFlag -- test

if (@numberOnlyFlag = 'N')
begin

	-- Value that contains text
	delete
		#valueSearch
	where
		dataType not in
		(
			'varchar'
			,'char'
			,'nvarchar'
			,'ntext'
		)
		
		-- Column that value size can fit into
		delete
			#valueSearch
		where
			LEN(@valueToSearchFor) > textMaxLength
end
else
begin
	-- Value that contains only numbers
	delete
		#valueSearch
	where
		dataType not in
		(
			'int'
			,'float'
			,'bit'
			,'numeric'
		)

		-- Column that value size can fit into
		 -- [need to work on this part]
end
	
-- create query
if (@numberOnlyFlag = 'N')
begin
	if (@specificity = 'like')
	begin
		set @whereClause = ' like ''%' + @valueToSearchFor + '%'''
	end
	else
	begin
		set @whereClause = ' = ''' + @valueToSearchFor + ''''
	end
end
else
begin
	if (@specificity = 'like')
	begin
		set @whereClause = ' like ''%' + @valueToSearchFor + '%'''
	end
	else
	begin
		set @whereClause = ' = ' + @valueToSearchFor 
	end
end


-- find columns that have the value
if exists(select * from tempdb.INFORMATION_SCHEMA.TABLES where table_name like '#valueResults%')
begin
	drop table #valueResults
end

select 
	schemaName
	,tableName
	,columnName
into
	#valueResults
from
	#valueSearch
	
truncate table #valueResults

select @totalCnt = count(1) from #valueSearch
set @resultsCnt = 1

while((select count(1) from #valueSearch) > 0)
begin
	-- search a column for the value
	select top 1
		@schemaName = schemaName
		,@tableName = tableName
		,@columnName = columnName
	from
		#valueSearch
	
	
	set @query = 'begin try insert into #valueResults select top 1 ''' + @schemaName  + ''',''' + @tableName + ''', ''' + @columnName + ''' from ' + @tableName + ' where ' + @columnName + @whereClause + ' end try begin catch print ''' + @tableName + '.' + @schemaName  + '.' + @columnName + ' column could not be searched'' end catch'
	--print @query -- test
	exec(@query)

		
	-- display status
	select @currentCnt = count(1) from #valueSearch
	select @currentCnt = @totalCnt - (@currentCnt - 1) 
	print ''
	print 'status: ' + cast(@currentCnt as varchar) + ' of ' + cast(@totalCnt as varchar) + ' columns checked.'
	print ''
	
	-- display results so far
	if((select (count(1)/10.00) - round(count(1)/10.00,0) from #valueResults having count(1) > 1) = 0 and @resultSize != 'All') 
	begin
		if (@resultsCnt = (select count(1) from #valueResults)/10)
		begin
			select 'result set ' + cast(@resultsCnt as varchar)
			select * from #valueResults
			set @resultsCnt = @resultsCnt + 1
		end
	end
	
	-- drop a column searched
	delete 
		#valueSearch 
	where 
			tableName = @tableName
		and
			columnName = @columnName
end

-- display results
select
	*
from
	#valueResults
	
