use tempdb;
go

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

create PROC [dbo].[dataTrace_isSprocInsertingIntoTable] 
	@sprocDbName varchar(60), -- must be DB sproc is in
	@sprocSchemaName varchar(15), -- must be schema for sproc
	@sprocName varchar(60),
	@tableName varchar(60), -- enter a table name with or without db or schema
	@IsInserting bit output
AS
BEGIN

IF OBJECT_ID('tempdb..##dataTrace_isSprocInsertingIntoTable_query') IS NOT NULL
	drop table ##dataTrace_isSprocInsertingIntoTable_query

-- get sproc definition. Remove comments, line feed, tab, and carriage feed to make search faster 
declare @query varchar(5000)
set @query = 
'select
	m.[definition] as query
Into
	##dataTrace_isSprocInsertingIntoTable_query
from
	[' + @sprocDbName + '].sys.procedures p
	inner join [' + @sprocDbName + '].sys.sql_modules m on p.object_id = m.object_id
	inner join [' + @sprocDbName + '].information_schema.routines r on p.[name] = r.routine_name
where
		r.routine_schema = ''' +  @sprocSchemaName + '''
		And
		p.[name] =''' +  @sprocName + ''''

execute(@query) -- inserts into ##dataTrace_isSprocInsertingIntoTable_query table

select @query = query from ##dataTrace_isSprocInsertingIntoTable_query
exec [dbo].dataTrace_isQueryInsertingIntoTable @query,@tableName,@isInserting output

IF OBJECT_ID('tempdb..##dataTrace_isSprocInsertingIntoTable_query') IS NOT NULL
	drop table ##dataTrace_isSprocInsertingIntoTable_query

END
GO
