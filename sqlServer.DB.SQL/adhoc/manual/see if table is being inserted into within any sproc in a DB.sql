/*
See if a table is being inserted into in some sproc in a relational DB
*/

use ccgDataMart
Go

declare @tableName varchar(40)
set @tableName = 'CCGDataMart.dbo.FactFinanceForecast'

select 
	'[' + r.routine_schema + '].[' + p.[name] + ']' as objectName
from
	sys.procedures p
	inner join sys.sql_modules m on p.object_id = m.object_id
	inner join information_schema.routines r on p.[name] = r.routine_name
where
	charindex('insertinto' + @tableName,replace(replace(replace(replace(m.[definition] ,char(32),''),char(9),''),char(10),''),char(13),'')) > 0
