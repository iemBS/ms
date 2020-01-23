declare @textToSearchFor varchar(100)
declare @objectTypeToSearch char(1)
declare @query varchar(4000)
declare @queryPart varchar(2000)

set @textToSearchFor = 'myText' -- specify, include square brackets if you think the text is in square brackets, include schema if you want
set @objectTypeToSearch = 'a'  -- use this as a sproc parameter (t=table,p=procedure,v=views,f=functions,a=all)

-- procedures
if(@objectTypeToSearch in ('a','p'))
begin
	set @query = 
	'select 
		''stored procedure'' as objectType
		,''stored procedure definition'' as objectPart
		,schema_name(p.schema_id) + ''.'' + p.[name] as objectName
	from
		sys.procedures p
		inner join sys.sql_modules m on p.object_id = m.object_id
	where
		m.definition like ''%' + replace(replace(@textToSearchFor,'_','/_'),'[','/[') + '%'' ESCAPE ''/'''
end

-- tables
if(@objectTypeToSearch in ('a','t'))
begin
	set @queryPart = 
	'
	select
		''table'' as objectType
		,''table name'' as objectPart
		,table_schema + ''.'' + table_name as objectName
	from
		information_schema.tables
	where
		TABLE_TYPE = ''BASE TABLE''
		and
		(
			table_name like ''%' + replace(replace(@textToSearchFor,'_','/_'),'[','/[') + '%'' ESCAPE ''/'' --search on table name only
			or
			table_schema + ''.'' + table_name like ''%' + replace(replace(@textToSearchFor,'_','/_'),'[','/[') + '%'' ESCAPE ''/'' --search on table name only
			or
			table_schema + ''.'' + table_name = ''' + @textToSearchFor + '''
		)'
	print @queryPart
		
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
	'
	select 
		''view'' as objectType
		,''view definition'' as objectPart
		,schema_name(v.schema_id) + ''.'' + v.[name] as objectName
	from 
		sys.views v
		inner join sys.sql_modules m on 
			v.object_id = m.object_id
	where
		v.type = ''V''
		and
		m.definition like ''%' + replace(replace(@textToSearchFor,'_','/_'),'[','/[') + '%'' ESCAPE ''/'' 
	union  
	select
		''view'' as objectType
		,''view name'' as objectPart
		,t.table_schema + ''.'' + v2.[name] as objectName
	from
		sys.all_columns c2
		inner join sys.objects v2 on c2.object_id = v2.object_id
		inner join information_schema.tables t on v2.[name] = t.table_name
	where
		v2.[type] = ''v''
		and
		t.table_type = ''VIEW''
	and
		(
			v2.[name] like ''%' + replace(replace(@textToSearchFor,'_','/_'),'[','/[') + '%'' ESCAPE ''/'' --search on view name only
			or
			(t.table_schema + ''.'' + v2.[name]) like ''%' + replace(replace(@textToSearchFor,'_','/_'),'[','/[') + '%'' ESCAPE ''/''-- search on view schema and name
		)'
		
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
		,''function definition'' as objectPart
		,schema_name(p.schema_id) + ''.'' + p.[name] as objectName
	from
		sys.objects p
		inner join sys.sql_modules m on p.object_id = m.object_id
	where
		p.[type] = ''FN''
	and
		m.definition like ''%' + replace(replace(@textToSearchFor,'_','/_'),'[','/[') + '%'' ESCAPE ''/'''

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
