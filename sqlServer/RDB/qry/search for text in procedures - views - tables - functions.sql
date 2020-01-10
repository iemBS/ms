declare @textToSearchFor varchar(100)
declare @objectTypeToSearch char(1)
declare @query varchar(4000)
declare @queryPart varchar(2000)

set @textToSearchFor = 'xxx' -- specify, include square brackets if you think the text is in square brackets, include schema if you want
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
		(
			charindex(''['',''' + @textToSearchFor + ''') = 0
			and
			m.definition like ''%' + @textToSearchFor + '%''
		)
		or
		(
			charindex(''['',''' + @textToSearchFor + ''') > 0
			and
			m.definition like ''%' + @textToSearchFor + '%'' ESCAPE ''[''
		)'
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
		(
			(
				charindex(''['',''' + @textToSearchFor + ''') = 0
				and 
				v.[name] like ''%' + @textToSearchFor + '%''
			)
			or
			(
				charindex(''['',''' + @textToSearchFor + ''') > 0
				and 
				v.[name] like ''%' + @textToSearchFor + '%'' ESCAPE ''[''
			)
		) 

	union all 
	select
		''table'' as objectType
		,table_schema + ''.'' + table_name as objectName
	from
		information_schema.tables
	where
		(
			charindex(''['',''' + @textToSearchFor + ''') = 0
			and 
			table_name like ''%' + @textToSearchFor + '%''
		)
		or
		(
			charindex(''['',''' + @textToSearchFor + ''') > 0
			and 
			table_name like ''%' + @textToSearchFor + '%'' ESCAPE ''[''
		)
	
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
			(
				(
					charindex(''['',''' + @textToSearchFor + ''') = 0
					and 
					c.column_name like ''%' + @textToSearchFor + '%''
				)
				or
				(
					charindex(''['',''' + @textToSearchFor + ''') > 0
					and 
					c.column_name like ''%' + @textToSearchFor + '%'' ESCAPE ''[''
				)
			)'
		
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
		(
			charindex(''['',''' + @textToSearchFor + ''') = 0
			and
			m2.definition like ''%' + @textToSearchFor + '%''
		)
		or
		(
			charindex(''['',''' + @textToSearchFor + ''') > 0
			and
			m2.definition like ''%' + @textToSearchFor + '%'' ESCAPE ''[''
		)
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
		(
			(
				charindex(''['',''' + @textToSearchFor + ''') = 0
				and 
				v2.[name] like ''%' + @textToSearchFor + '%''
			)
			or
			(
				charindex(''['',''' + @textToSearchFor + ''') > 0
				and 
				v2.[name] like ''%' + @textToSearchFor + '%'' ESCAPE ''[''
			)
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
		,r.routine_schema + ''.'' + p.[name] as objectName
	from
		sys.objects p
		inner join sys.sql_modules m on p.object_id = m.object_id
		inner join information_schema.routines r on p.[name] = r.routine_name
	where
		p.[type] = ''FN''
	and
		(
			charindex(''['',''' + @textToSearchFor + ''') = 0
			and
			m.definition like ''%' + @textToSearchFor + '%''
		)
		or
		(
			charindex(''['',''' + @textToSearchFor + ''') > 0
			and
			m.definition like ''%' + @textToSearchFor + '%'' ESCAPE ''[''
		)'
		
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
