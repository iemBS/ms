/*
Get max date from all date or date time columns in the database
*/

Select
	IDENTITY(int,1,1) as ID,
	TABLE_SCHEMA as [schema],
	table_name as [table],
	column_name as [column],
	getdate() - 100 As tableLastUpdated 
Into
	tempdb.dbo.tableWithDate_scottb
From
	INFORMATION_SCHEMA.columns
Where
	data_type In ('date','datetime','datetime2')
	
-- loop through columns
declare @query varchar(700)
declare @ID int 
set @ID = 1
while exists(select top 1 ID From tempdb.dbo.tableWithDate_scottb where ID = @ID)
begin
	select @query = '
	declare @maxTime datetime
	select @maxTime = maxTime from (select isnull(max([' + [column] + ']),getdate() - 100) as maxTime from [' + [schema] + '].[' + [table] + '] where [' + [column] + '] <= getdate()) t where DateDiff(m,getdate(),maxTime) < 3
	if @maxTime = '''' begin Delete tempdb.dbo.tableWithDate_scottb Where ID = ' + cast(@ID as varchar) + ' end else begin Update tempdb.dbo.tableWithDate_scottb Set tableLastUpdated = @maxTime Where ID = ' + cast(@ID as varchar) + ' end' From tempdb.dbo.tableWithDate_scottb where ID = @ID
	execute(@query)
	set @ID = @ID + 1
end

select count(1) from tempdb.dbo.tableWithDate_scottb

drop table tempdb.dbo.tableWithDate_scottb



	-- get max date (up to today) for a column

	-- if max date is within 3 months from now, then node the schema, table, column and max date