use tempdb;
go

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

create PROC [dbo].[dataTrace_isUDFInsertingIntoTable] 
	@UDFDbName varchar(60), -- must be DB UDF is in
	@UDFSchemaName varchar(15), -- must be schema for UDF
	@UDFName varchar(60),
	@tableName varchar(60), -- enter a table name with or without db or schema
	@IsInserting bit output
AS
BEGIN

IF OBJECT_ID('tempdb..##dataTrace_isUDFInsertingIntoTable_query') IS NOT NULL
	drop table ##dataTrace_isUDFInsertingIntoTable_query

-- get UDF definition. Remove comments, line feed, tab, and carriage feed to make search faster 
declare @query varchar(5000)
set @query = 
'select
	m.[definition] as query
Into
	##dataTrace_isUDFInsertingIntoTable_query
from
	[' + @UDFDbName + '].sys.objects p
	inner join [' + @UDFDbName + '].sys.sql_modules m on p.object_id = m.object_id
	inner join [' + @UDFDbName + '].information_schema.routines r on p.[name] = r.routine_name
where
	p.[type] = ''FN''
	and
	r.routine_schema = ''' +  @UDFSchemaName + '''
	And
	p.[name] =''' +  @UDFName + ''''

execute(@query) -- inserts into ##dataTrace_isUDFInsertingIntoTable_query table

select @query = query from ##dataTrace_isUDFInsertingIntoTable_query
exec [dbo].dataTrace_isQueryInsertingIntoTable @query,@tableName,@isInserting output

IF OBJECT_ID('tempdb..##dataTrace_isUDFInsertingIntoTable_query') IS NOT NULL
	drop table ##dataTrace_isUDFInsertingIntoTable_query

END
GO
