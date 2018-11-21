
declare @query varchar(300)
set @query = 
'Insert Into
	tableC
select
	*
From
	TableA a
	Inner Join TableB b On 
		a.col = b.col'
declare @tableName varchar(100)
set @tableName = 'tableC'

declare @searchableQuery varchar(300)
select @searchableQuery = replace(replace(replace(replace(@query,char(32),''),char(9),''),char(10),''),char(13),'')

-- indicates table is being inserted into
select charindex('insertinto' + @tableName,@searchableQuery)