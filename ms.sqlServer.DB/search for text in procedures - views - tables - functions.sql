declare @textToSearchFor varchar(100)
declare @objectTypeToSearch char(1)
declare @query varchar(4000)
declare @queryPart varchar(1000)

set @textToSearchFor = 'SG.BMX_OpportunitySnapShots' -- use this as a sproc parameter
set @objectTypeToSearch = 'a'  -- use this as a sproc parameter (t=table,p=procedure,v=views,f=functions,a=all)

-- procedures
if(@objectTypeToSearch in ('a','p'))
begin
	set @query = 
	'select 
		''stored procedure'' as objectType
		,r.routine_schema + ''.'' + p.[name] as objectName
	from
		sys.procedures p
		inner join sys.sql_modules m on p.object_id = m.object_id
		inner join information_schema.routines r on p.[name] = r.routine_name
	where
		m.definition like ''%' + @textToSearchFor + '%'''
end

-- tables
if(@objectTypeToSearch in ('a','t'))
begin
	set @queryPart = 
	'select
		''table'' as objectType
		,t.table_schema + ''.'' + v.[name] as objectName
	from
		sys.all_columns c
		inner join sys.objects v on c.object_id = v.object_id
		inner join information_schema.tables t on v.[name] = t.table_name
	where
		v.[type] = ''t''
	and
		v.[name] like ''%' + @textToSearchFor + '%''

	union all 

	select
		''table'' as objectType
		,table_schema + ''.'' + table_name as objectName
	from
		information_schema.tables
	where
		table_name like ''%' + @textToSearchFor + '%''
	
	union all
	
	select distinct 
		''table'' as objectType
		,c.table_schema + ''.'' + c.table_name as objectName
	from
		information_schema.columns c
		inner join information_schema.tables t on
			c.table_name = t.table_name
	where
			t.table_type = ''BASE TABLE''
		and
			c.column_name like ''%' + @textToSearchFor + '%'''
		
	if(@objectTypeToSearch = 'a')
	begin
		set @query = @query + CHAR(13)+CHAR(10)+ ' union all ' + CHAR(13)+CHAR(10)+ + @queryPart
	end
	else
	begin
		set @query = @queryPart
	end
end

-- views
if(@objectTypeToSearch in ('a','v'))
begin
	set @queryPart = 
	'select 
		''view'' as objectType
		,t.table_schema + ''.'' + p2.[name] as objectName
	from
		sys.views p2
		inner join sys.sql_modules m2 on p2.object_id = m2.object_id
		inner join information_schema.tables t on p2.[name] = t.table_name
	where
		m2.definition like ''%' + @textToSearchFor + '%''

	union all 

	select
		''view'' as objectType
		,t.table_schema + ''.'' + v2.[name] as objectName
	from
		sys.all_columns c2
		inner join sys.objects v2 on c2.object_id = v2.object_id
		inner join information_schema.tables t on v2.[name] = t.table_name
	where
		v2.[type] = ''v''
	and
		v2.[name] like ''%' + @textToSearchFor + '%'''
		
	if(@objectTypeToSearch = 'a')
	begin
		set @query = @query + CHAR(13)+CHAR(10)+ ' union all ' + CHAR(13)+CHAR(10) + @queryPart
	end
	else
	begin
		set @query = @queryPart
	end
end

-- functions
if(@objectTypeToSearch in ('a','f'))
begin
	set @queryPart = 
	'select 
		''function'' as objectType
		,r.routine_schema + ''.'' + p.[name] as objectName
	from
		sys.objects p
		inner join sys.sql_modules m on p.object_id = m.object_id
		inner join information_schema.routines r on p.[name] = r.routine_name
	where
		p.[type] = ''FN''
	and
		m.definition like ''%' + @textToSearchFor + '%'''
		
	if(@objectTypeToSearch = 'a')
	begin
		set @query = @query + CHAR(13)+CHAR(10) + ' union all ' + CHAR(13)+CHAR(10) + @queryPart
	end
	else
	begin
		set @query = @queryPart
	end
end

exec (@query)
