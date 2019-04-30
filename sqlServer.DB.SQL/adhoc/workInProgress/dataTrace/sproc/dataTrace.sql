/*
add sprocs to a DB in this order

xxx
*/

use tempdb;
go

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

create PROC [dbo].[dataTrace] 
	@tableName varchar(60), -- enter a table or view name with a format of [db].[schema].[table]
	@dataTrace varchar(60) output
AS
BEGIN

/*
	confirm if [db].[schema].[table] format is used
*/
-- add code to stop if [db].[schema].[table] format is not used

/*
	get table/view name permutations
*/

declare @permutation table
(
	ID int identity(1,1),
	permutation varchar(100)
)

insert into	
	@permutation
exec dbo.dataTrace_getTableNamePermutation @tablename

declare @allSprocInServer
(
	ID int identity(1,1),
	sprocName varchar(60) -- must use [db].[schema].[sproc] name format
)

insert into
	@allSprocInServer -- get a copy of the list of all sprocs that we care about on the server. 
	(sprocName)
exec dbo.dataTrace_getAllSprocInServer()

-- add code to exit if error

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

declare @mapRowCnt int
Select @mapRowCnt = count(1) From ##parentChildMap
declare @mapRowCntUpdate int
Select @mapRowCntUpdate = 1

declare @permutationTableName varchar(40)
declare @sprocDbName varchar(40),@sprocSchemaName varchar(10),@sprocName varchar(40)

-- stop searching when no more objects can be added to the mapping
while @mapRowCnt < @mapRowCntUpdate
begin

/*
See if a table is being inserted into within a sproc
*/

declare @IsInserting bit 

-- loop through all permutations of the table name
declare @i int,@j int
set @i = 1
set @j = 1
while @i <= (select max(ID) from @permutation)
begin
        -- get permutation of table name
	select @permutationTableName = permutation from @permutation where ID = @i

	while  @j < (select max(ID) from @allSprocInServer)
        begin
		select
			@sprocDbName = sprocDbName,
                        @sprocSchemaName = sprocSchemaName,
                        @sprocName = sprocName
		from
			@allSprocInServer
		Where
			ID = @j

		-- if table does not have db in name, it must be in same db as sproc
		if(
		(select 
		  case
		    when charindex(@sprocDBName,@permutationTableName) = 0 then 
		      case when charindex(@sprocDBName,@tableName) > 0 then 1 else 0 end
                    else 1
                  end) = 0 
                )
                begin
			set @j = @j + 1
			continue
		end

		exec [dbo].[dataTrace_isSprocInsertingIntoTable] @sprocDbName,@sprocSchemaName,@sprocName,@permutationTableName,@IsInserting output

		if @IsInserting = 1
		begin
			insert into	
				##parentChildMap
			select
				@tableName, -- note full name of table ([db].[schema].[table]) instead of permutation form of it
				@sprocName,
				'table',
				'sproc'

			delete 
				@allSprocInServer -- remove the sproc after the first permutation of the table name is found in it
			where
				ID = @j 
		end
                set @j = @j + 1
	end
	set @i = @i + 1
end

/*
See if a table is being inserted into in some UDF in a relational DB
*/


set @i = 1
while i@ <= (select max(ID) from @permutation)
begin
	exec [dbo].[dataTrace_isUDFInsertingIntoTable] (select [value] from string_split(xxx,xxx)),@UDFSchemaName,@UDFName,@tableName,@IsInserting output

	if @IsInserting = 1
	begin
		insert into	
			##parentChildMap
		select
			@tableName,
			@sprocName,
			'table',
			'UDF'
	end

	set @i = @i + 1
end

/*
See if a table is being inserted into in some SSIS package
*/

/*
See if a table is being inserted into in some SQL job
*/

/*
Update table name to have [db].[schema].[table] format
*/
exec dbo.dataTrace_getFullObjName

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

	Select @mapRowCntUpdate = count(1) From ##parentChildMap
end
-- end of while loop


END
GO


