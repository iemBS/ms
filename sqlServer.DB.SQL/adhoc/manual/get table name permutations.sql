/*
Enter a table name in the form of [db].[schema].[table/view] and get all permutations of that name that could be used in code back
*/

declare @tableName varchar(100) 
set @tableName = '[ccgStage].[dbo].[BridgeUserBusiness]'

-- clean up
IF OBJECT_ID('tempdb..#permutation') IS NOT NULL
    DROP TABLE #permutation

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
	#permutation
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
	#permutation
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
	#permutation
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

Select
	*
From
	#permutation