Declare @loginName nvarchar(50) = SUSER_NAME()

DECLARE @whotbl TABLE
(
	SPID		INT	NULL
	,Status	VARCHAR(50)	NULL
	,Login		SYSNAME	NULL
	,HostName	SYSNAME	NULL
	,BlkBy		VARCHAR(5)	NULL
	,DBName	SYSNAME	NULL
	,Command	VARCHAR(1000)	NULL
	,CPUTime	INT	NULL
	,DiskIO	INT	NULL
	,LastBatch VARCHAR(50)	NULL
	,ProgramName VARCHAR(200)	NULL
	,SPID2		INT	NULL
	,RequestID INT	NULL
	)

Insert Into 
	@whotbl
EXEC sp_who2

If OBJECT_ID('tempdb..#who3') Is Not Null
Begin
	Drop Table #who3
End

Select
	w.SPID,
	w.Status,
	w.Login,
	w.HostName,
	w.BlkBy,
	w.DBName,
	w.Command As commandType,
	w.CPUTime,
	w.DiskIO,
	Convert(DateTime, Replace(Convert(VarChar(4), Year(GetDate())) + '/' + w.LastBatch, '/', '')) As LastBatch,
	w.ProgramName As programRunningCommand,
	sql.text As CommandText,
	pln.query_plan As ExecutionPlan
Into
	#who3
FROM 
	(Select Distinct * From @whotbl Where [Login] = @loginName)  W
	Left Outer Join sys.dm_exec_requests der On 
		der.session_id = w.SPID
	Outer Apply SYS.dm_exec_sql_text (der.sql_handle) Sql
	Outer Apply sys.dm_exec_query_plan (der.plan_handle) pln
	Left Outer Join sys.objects so On 
		so.object_id = sql.objectid

Select * From #who3 Where CommandText Not Like '% @whotbl %'

-- Show general tempdb size and usage 
SELECT 
	instance_name AS 'db',
	[Data File(s) Size (KB)]/1024 AS [data file size (MB)],
	[Log File(s) Size (KB)]/1024 AS [log file size (MB)],
	[Log File(s) Used Size (KB)]/1024 AS [Log file space used by all users (MB)],
	[Used memory (KB)]/1024 AS [Memory used by all users (MB)]
FROM 
	(
		SELECT 
			object_name,
			counter_name,
			instance_name,
			cntr_value,
			cntr_type
		FROM 
			sys.dm_os_performance_counters
		WHERE 
			counter_name IN
			(
				'Data File(s) Size (KB)',
				'Log File(s) Size (KB)',
				'Log File(s) Used Size (KB)',
				'Used memory (KB)'
			)
			AND 
			object_name = 'SQLServer:Databases'
	) AS A
PIVOT
(
	MAX(cntr_value) 
	FOR 
	counter_name IN
	(
		[Data File(s) Size (KB)],
		[LOG File(s) Size (KB)],
		[Log File(s) Used Size (KB)],
		[Used memory (KB)]
	)
) AS B
GO

-- size of all tables in tempdb
If OBJECT_ID('tempdb..#tempDBdataFileTableSize') Is Not Null
Begin
	Drop Table #tempDBdataFileTableSize
End

SELECT 
	db_name() as db,
	TBL.name As TableName,
	STAT.used_page_count * 8 AS UsedSizeKB,
	STAT.reserved_page_count * 8 AS RevervedSizeKB 
Into
	#tempDBdataFileTableSize
From
	tempdb.sys.partitions AS PART 
	INNER JOIN tempdb.sys.dm_db_partition_stats AS STAT ON 
		PART.partition_id = STAT.partition_id 
		AND 
		PART.partition_number = STAT.partition_number 
	INNER JOIN tempdb.sys.tables AS TBL ON 
		STAT.object_id = TBL.object_id 

	/* add in usage of data file size for others DBs on server */

-- amount of usage of data file for tempdb 
Select	
	Sum(UsedSizeKB) / 1024 As [tempDB data file size used by all users (MB)],
	Sum(RevervedSizeKB) / 1024 As [tempDB data file size reserved for all users (MB)]
From
	#tempDBdataFileTableSize

-- Temp tables created in tempdb when you started running your queries
If (Select Count(1) From #who3 Where CommandText Not Like '% @whotbl %') > 0
Begin
	SELECT
		t.[name] As tempTableCreatedAfterYourQueryStarted,
		t.create_date As tempTableCreateTime,
		t.modify_date As tempTableUpdateTime,
		ts.UsedSizeKB As tempTableUsedSizeKB,
		ts.RevervedSizeKB As tempTableReservedSizeKB
	FROM
		tempdb.sys.tables AS t
		Left Outer Join
		(
			Select	
				[name],
				UsedSizeKB,
				RevervedSizeKB
			From
				#tempDBdataFileTableSize		
		) ts On 
			t.[name] = ts.[name]
	Where
		t.create_date >= (Select min(lastBatch) As lastBatch From #who3 Where CommandText Is Not Null)
		And
		object_id != OBJECT_ID('tempdb..#who3')
		And
		object_id != OBJECT_ID('tempdb..#tempDBdataFileTableSize')
	Order By
		t.create_date
End

Declare @loginName nvarchar(50) = SUSER_NAME()

SELECT 
    DB_NAME(dbid) as dbName, 
    COUNT(dbid) as sqlServerConnectionCount,
	5 as allowedSqlServerConnectionCountPerLogin,
    loginame as loginName
FROM
    sys.sysprocesses
WHERE 
	loginame = @loginName
	And
    dbid > 0
GROUP BY 
    dbid, loginame



-- Server RAM used on SQL server for you query objects. NEEDS WORK BEFORE IT CAN BE USED
/*
;WITH src AS
(
	SELECT
		[Object] = o.name,
		[Type] = o.type_desc,
		[Index] = COALESCE(i.name, ''),
		[Index_Type] = i.type_desc,
		p.[object_id],
		p.index_id,
		au.allocation_unit_id
	FROM
		sys.partitions AS p
		INNER JOIN sys.allocation_units AS au On 
			p.hobt_id = au.container_id
		INNER JOIN sys.objects AS o ON 
			p.[object_id] = o.[object_id]
		INNER JOIN sys.indexes AS i ON 
			o.[object_id] = i.[object_id]
			AND 
			p.index_id = i.index_id
	WHERE
		o.schema_id In (Select schema_id From sys.schemas Where [name] = CURRENT_USER)
		And
		au.[type] IN (1,2,3)
		AND 
		o.is_ms_shipped = 0
)
SELECT
src.[Object],
src.[Type],
src.[Index],
src.Index_Type,
buffer_pages = COUNT_BIG(b.page_id),
buffer_mb = COUNT_BIG(b.page_id) / 128
FROM
src
INNER JOIN
sys.dm_os_buffer_descriptors AS b
ON src.allocation_unit_id = b.allocation_unit_id
WHERE
b.database_id = DB_ID()
GROUP BY
src.[Object],
src.[Type],
src.[Index],
src.Index_Type
ORDER BY
buffer_pages DESC;
*/
