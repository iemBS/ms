use tempdb;
go

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

create PROC [dbo].[dataTrace_isQueryInsertingIntoTable] 
	@query varchar(5000),
	@tableName varchar(60), -- enter a table name with or without db or schema
	@IsInserting bit output
AS
BEGIN

declare @msg varchar(300)
if len(@query) = 5000
begin
	set @msg = 'WARNING: length of query equals length of @query parameter of ' + OBJECT_SCHEMA_NAME(@@PROCID) + '.' + OBJECT_NAME(@@PROCID) + ' sproc'
	print @msg
end

declare @searchableQuery varchar(5000)
select @searchableQuery = replace(replace(replace(replace(@query,char(32),''),char(9),''),char(10),''),char(13),'')

-- indicates table is being inserted into
select 
	@IsInserting = 
	case 
		when charindex('insertinto' + @tableName,@searchableQuery) > 0 then 1
		else 0 
	end 
END
GO