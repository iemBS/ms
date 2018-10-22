select
	objectType
	,objectName
	,tableNameIfObjectTypeIsColumn
from
	(
		-- stored procedures
		select 
			'stored procedure' as objectType
			,r.routine_schema + '.' + p.[name] as objectName
			,'' as tableNameIfObjectTypeIsColumn
		from
			sys.procedures p
			inner join sys.sql_modules m on p.object_id = m.object_id
			inner join information_schema.routines r on p.[name] = r.routine_name

		union 
			
		-- columns
		select
			'columns' as objectType
			,table_schema + '.' + column_name + ' (in ' + table_name + ')' as objectName
			,table_name as tableNameIfObjectTypeIsColumn
		from
			information_schema.columns

		union

		-- tables
		select
			'table' as objectType
			,table_schema + '.' + table_name as objectName
			,'' as tableNameIfObjectTypeIsColumn
		from
			information_schema.tables

		union

		-- views
		select 
			'view' as objectType
			,t.table_schema + '.' + p2.[name] as objectName
			,'' as tableNameIfObjectTypeIsColumn
		from
			sys.views p2
			inner join sys.sql_modules m2 on p2.object_id = m2.object_id
			inner join information_schema.tables t on p2.[name] = t.table_name

		union

		-- functions
		select 
			'function' as objectType
			,r.routine_schema + '.' + p.[name] as objectName
			,'' as tableNameIfObjectTypeIsColumn
		from
			sys.objects p
			inner join sys.sql_modules m on p.object_id = m.object_id
			inner join information_schema.routines r on p.[name] = r.routine_name
		where
			p.[type] = 'FN'
	) t
where
--	objectName collate SQL_Latin1_General_CP1_CS_AS = lower(objectName) collate SQL_Latin1_General_CP1_CS_AS
--or
	objectName like '% %'
--or
--	substring(objectName,patIndex('%.%',objectName) + 1,1) collate SQL_Latin1_General_CP1_CS_AS = upper(substring(objectName,patIndex('%.%',objectName) + 1,1)) collate SQL_Latin1_General_CP1_CS_AS
or 
	objectType = 'view' and substring(objectName,patIndex('%.%',objectName) + 1,2) != 'vw'
or
	objectType = 'stored procedure' and substring(objectName,patIndex('%.%',objectName) + 1,1) != 'p'
	

	
	
