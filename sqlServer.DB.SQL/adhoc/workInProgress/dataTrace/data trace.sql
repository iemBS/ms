

/*
	get table/view name permutations
*/

declare @tableName varchar(100) 
set @tableName = '[ccgDatamart].[dbo].[FactFinanceForecast]'

-- clean up
IF OBJECT_ID('tempdb..##permutation') IS NOT NULL
    DROP TABLE ##permutation

-- split a table name with the form of [db].[schema].[table/view] and split it into its db, schema, and table\view name parts
Select 
	*,
	identity(int,1,1) as id
into
	#parts
From
	string_split(@tableName,'.')

-- store db part in the db table
Select
	[value] as db
into
	#db
From
	#parts
Where
	id = 1

-- store schema part in the schema table 
Select
	[value] as [schema]
into
	#schema
From
	#parts
Where
	id = 2

-- store table part in the table table
Select
	[value] as [table]
into
	#table
From
	#parts
Where
	id = 3

-- insert table name part without brackets
Insert Into
	#db
Select
	replace(replace(db,'[',''),']','')
From
	#db

Insert Into
	#schema
Select
	replace(replace([schema],'[',''),']','')
From
	#schema

Insert Into
	#table
Select
	replace(replace([table],'[',''),']','')
From
	#table

-- insert blank table name part
Insert Into
	#db
Select ''

Insert Into
	#schema
Select ''

-- any of the three parts w or wo brackets is 2 x 2 x 2 permutations
Select
	[db]+'.'+
	[schema]+'.'+
	[table] as permutation
Into
	##permutation
From
	#db
	cross join #schema
	cross join #table
Where
	[db] != ''
	And
	[schema] != ''

-- no db, schema and table w or wo brackets is 1 x 2 x 2 permutations
Insert Into	
	##permutation
Select
	[schema]+'.'+
	[table] as permutation
From
	#schema
	cross join #table
Where
	[schema] != ''

-- no db, no schema and table w or wo brackets is 1 x 1 x 2 permutations
Insert Into	
	##permutation
Select
	[table] as permutation
From
	#table

-- clean up
IF OBJECT_ID('tempdb..#parts') IS NOT NULL
    DROP TABLE #parts

IF OBJECT_ID('tempdb..#db') IS NOT NULL
    DROP TABLE #db

IF OBJECT_ID('tempdb..#schema') IS NOT NULL
    DROP TABLE #schema

IF OBJECT_ID('tempdb..#table') IS NOT NULL
    DROP TABLE #table

/*
Create child to parent map table
*/
create table ##parentChildMap
(
	child varchar(100),
	parent varchar(100),
	childType varchar(25),
	parentType varchar(25)
)

/*
See if a table is being inserted into in some sproc in a relational DB
*/

create table ##filledBy
(
	permutation varchar(100),
	objName varchar(200),
	objType varchar(30)
)

EXEC sp_MSforeachdb 
@command1 = '
insert into
	##parentChildMap
select distinct 
	pm.permutation,
	''['' + db_name() + ''].['' + r.routine_schema + ''].['' + p.[name] + '']'',
	''table'',
	''sproc''
from
	?.sys.procedures p
	inner join ?.sys.sql_modules m on 
		p.object_id = m.object_id
	inner join ?.information_schema.routines r on 
		p.[name] = r.routine_name
	inner join ##permutation pm on
		charindex(''insertinto'' + pm.permutation,replace(replace(replace(replace(m.[definition] ,char(32),''''),char(9),''''),char(10),''''),char(13),'''')) > 0 
where
	db_name() In (''ccgStage'',''ccgWarehouse'',''ccgDatamart'',''ccgOperations'')
';

/*
See if a table is being inserted into in some UDF in a relational DB
*/

/*
See if a table is being inserted into in some SSIS package
*/

/*
See if a table is being inserted into in some SQL job
*/

/*
Update table name to have [db].[schema].[table] format
*/

/*
if child table found in sproc, get from tables from sproc
*/

/*
if child table found in UDF, get from tables from UDF
*/

/*
if child table found in SSIS package, get from tables from SSIS package
*/
	-- setup manual relational DB to SSIS package map

	-- search the relational DB to SSIS package map

/*
if child table found in SQL job, get from tables from SQL job
*/



/*
Check if source is reached
*/

	-- Check if first table is reached in CDS system

	-- if yes, then get the source location

