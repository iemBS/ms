Get Table Size
  -Guidance @ https://docs.microsoft.com/en-us/sql/relational-databases/system-stored-procedures/sp-spaceused-transact-sql?view=sql-server-2017
  
Main Success Scenario:
  1. See code below
  
	If OBJECT_ID('tempdb..#tblColCnt') Is Not Null
	Begin
		Drop Table #tblColCnt
	End

	Select
		table_schema,
		table_name,
		Count(1) As tblColCnt
	Into
		#tblColCnt
	From
		INFORMATION_SCHEMA.COLUMNS WITH (NOLOCK)
	Where
		[TABLE_SCHEMA] Not In ('guest','information_schema') -- filter out schemas we do not want to include
		And
		[TABLE_SCHEMA] Not like 'db_%' -- make sure no user created schema starts w this
	Group By
		table_schema,
		table_name

	SET NOCOUNT ON
	DECLARE @TableInfo TABLE (tblName varchar(255), tblRowCnt int, tblReservedMemory varchar(255), tblUsedMemory varchar(255), tblIndexUsedMemory varchar(255), tblUnUsedMemory varchar(255))
	DECLARE @cmd1 varchar(500)
	SET @cmd1 = 'exec sp_spaceused ''?'''

	INSERT INTO @TableInfo (tblName,tblRowCnt,tblReservedMemory,tblUsedMemory,tblIndexUsedMemory,tblUnUsedMemory)
	EXEC sp_msforeachtable @command1=@cmd1

	Select
		t.tblName,
		c.tblColCnt,
		t.tblRowCnt,  -- add > 0 filter if trying to get tables with data, because tblUsedMemory is not enough
		t.tblReservedMemory,
		t.tblUsedMemory, --NOT include indices
		t.tblUnUsedMemory,
		t.tblIndexUsedMemory
	FROM 
	    #tblColCnt c
		Inner Join @TableInfo t On 
			'[' + c.TABLE_SCHEMA + '].[' + c.TABLE_NAME + ']' = t.tblName
	ORDER BY 
		Convert(int,Replace(t.tblUsedMemory,' KB','')) DESC

Alternatives:
  1a. Do not have access to "sp_msforeachtable" sproc
    1a1. Use "dataLength" function on columns and sum to get table size
