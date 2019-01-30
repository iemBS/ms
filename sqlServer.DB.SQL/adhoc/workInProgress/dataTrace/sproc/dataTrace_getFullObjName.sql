use tempdb;
go

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

create PROC [dbo].[dataTrace_getFullObjName] 
	@objectName varchar(60),
	@dbName varchar(60),
	@isSproc bit = 0,
	@objectNameUpdate varchar(60) output
AS
BEGIN

/*
Change object name format to be one of these
	[db].[schema].[table]
	[db].[schema].[view]
	[db].[schema].sproc
	[db].[schema].udf()
*/

-- clean-up
IF OBJECT_ID('tempdb..#part') IS NOT NULL
    DROP TABLE #part

-- change tables to use [db].[schema].[table] name format 

	-- split based on "." to see if db and schema in name, if not add them
	select identity(int,1,1) As ID,[value] as part into #part From string_split(@objectName,'.')

	declare @cnt int
	select @cnt = count(1) from #part
	set @objectNameUpdate = 
	case @cnt
		when 1 then 
		    /* db & schema */
			'[' + @dbName + '].[dbo].' + 
			/* table */
			case 
				/* from a sproc */
				when @isSproc = 1 then @objectName
				/* from a UDF */
				when charindex('()',@objectName) > 0 then @objectName
				/* from a table or view */
				when charindex('[',(select part from #part where ID = 1)) = 0 then '[' + @objectName + ']'
				else @objectName
			end
		when 2 then 
			/* db */
			'[' + @dbName + '].' + 
			/* schema */
			case charindex('[',(select part from #part where ID = 1))
				when 0 then '[' + (select part from #part where ID = 1) + ']'
				else (select part from #part where ID = 1)
			end
			/* table */
			 + '.' + 
			case 
				/* from a sproc */
				when @isSproc = 1 then (select part from #part where ID = 2)
				/* from a UDF */
				when charindex('()',@objectName) > 0 then (select part from #part where ID = 2)
				/* from a table or view */
				when charindex('[',(select part from #part where ID = 2)) = 0 then '[' + (select part from #part where ID = 2) + ']'
				else (select part from #part where ID = 2)
			end
		when 3 then
			/* db */
			case charindex('[',(select part from #part where ID = 1)) 
				when 0 then '[' + (select part from #part where ID = 1) + ']'
				else (select part from #part where ID = 1)
			end
			/* schema */
			 + '.' + 
			case charindex('[',(select part from #part where ID = 2)) 
				when 0 then '[' + (select part from #part where ID = 2) + ']'
				else (select part from #part where ID = 2)
			end
			/* table */
			 + '.' + 
			case  
				/* from a sproc */
				when @isSproc = 1 then (select part from #part where ID = 3)
				/* from a UDF */
				when charindex('()',@objectName) > 0 then (select part from #part where ID = 3)
				/* from a table or view */
				when charindex('[',(select part from #part where ID = 3)) = 0 then '[' + (select part from #part where ID = 3) + ']'
				else (select part from #part where ID = 3)
			end
	end
END
GO


