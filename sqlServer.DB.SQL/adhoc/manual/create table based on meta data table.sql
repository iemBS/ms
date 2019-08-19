
--drop temp tables
If OBJECT_ID('tempdb..#tblColCnt') Is Not Null
Begin
	Drop Table #tblColCnt
End

If OBJECT_ID('tempdb..#tblSize') Is Not Null
Begin
	Drop Table #tblSize
End

If OBJECT_ID('tempdb..#lastColumn') Is Not Null
Begin
	Drop Table #lastColumn
End

If OBJECT_ID('tempdb..#tblCreateLines') Is Not Null
Begin
	Drop Table #tblCreateLines
End

--Get all tables in DB
Select
	t.TABLE_SCHEMA,
	t.TABLE_NAME,
	Count(1) As tblColCnt 
Into
	#tblColCnt
From
	INFORMATION_SCHEMA.TABLES t WITH (NOLOCK)
	Inner Join INFORMATION_SCHEMA.COLUMNS c WITH (NOLOCK) On 
		t.TABLE_SCHEMA = c.TABLE_SCHEMA
		And
		t.TABLE_NAME = c.TABLE_NAME
Where
	t.TABLE_TYPE = 'BASE TABLE' -- include only tables, no views
Group By
	t.TABLE_SCHEMA,
	t.TABLE_NAME

SET NOCOUNT ON
DECLARE @TableInfo TABLE (tblName VARCHAR(255), tblRowCnt INT, tblReservedMemory VARCHAR(255), tblUsedMemory VARCHAR(255), tblIndexUsedMemory VARCHAR(255), tblUnUsedMemory VARCHAR(255))
DECLARE @cmd1 VARCHAR(500)
SET @cmd1 = 'EXEC sp_spaceused ''?'''

INSERT INTO @TableInfo (tblName,tblRowCnt,tblReservedMemory,tblUsedMemory,tblIndexUsedMemory,tblUnUsedMemory)
EXEC sp_MSforeachtable @command1=@cmd1  --includes only tables, no views

SELECT
	t.tblName,
	c.tblColCnt,
	t.tblRowCnt,
	t.tblReservedMemory,
	t.tblUsedMemory,
	t.tblUnUsedMemory
INTO
	#tblSize
FROM 
	#tblColCnt c
	Inner Join @TableInfo t On 
		'[' + c.TABLE_SCHEMA + '].[' + c.TABLE_NAME + ']' = t.tblName
WHERE
	Convert(int,Replace(t.tblUsedMemory,' KB','')) > 0 -- only tables with data in them
ORDER BY 
	Convert(int,Replace(t.tblUsedMemory,' KB','')) DESC

SELECT
	c.TABLE_SCHEMA,
	c.TABLE_NAME,
	MAX(c.ORDINAL_POSITION) AS LAST_ORDINAL_POSITION
INTO
	#lastColumn
FROM
	#tblSize s
	INNER JOIN INFORMATION_SCHEMA.COLUMNS c ON
		s.tblName =  '[' + c.TABLE_SCHEMA + '].[' + c.TABLE_NAME + ']'
GROUP BY
	c.TABLE_SCHEMA,
	c.TABLE_NAME

Select
	c.TABLE_SCHEMA,
	c.TABLE_NAME,
	COLUMN_NAME + ' ' + 
	DATA_TYPE + 
	CASE
		WHEN CHARACTER_MAXIMUM_LENGTH >= 1 THEN '(' + CAST(CHARACTER_MAXIMUM_LENGTH AS VARCHAR) + ') ' /* string column */
		ELSE /* number/time column */
			CASE DATA_TYPE
				WHEN 'numeric' THEN '(' + CAST(NUMERIC_PRECISION AS VARCHAR) + ',' + CAST(NUMERIC_SCALE AS VARCHAR) + ') '	
				ELSE ''
			END
	END + 
	CASE 
		WHEN lc.LAST_ORDINAL_POSITION IS NULL THEN ','
		ELSE ''
	END AS tableCreateLine,
	c.ORDINAL_POSITION
INTO
	#tblCreateLines
From
	INFORMATION_SCHEMA.COLUMNS c 
	LEFT OUTER JOIN #lastColumn lc ON 
		c.TABLE_SCHEMA = lc.TABLE_SCHEMA
		AND
		c.TABLE_NAME = lc.TABLE_NAME
		AND
		c.ORDINAL_POSITION = lc.LAST_ORDINAL_POSITION

--copy & paste the results of this to create table drops
	--Send results to TEXT instead of GRID to get GO to show on next line of each query
SELECT 
	'IF OBJECT_ID(''' + '[xxx].[' + SS.TABLE_NAME + ']' + ''') IS NOT NULL BEGIN DROP TABLE ' + '[xxx].[' + SS.TABLE_NAME + ']' + ' END' + CHAR(13)+CHAR(10) + ' GO' AS dropTableScript
FROM 
	#lastColumn SS
GROUP BY 
	SS.TABLE_SCHEMA, 
	SS.TABLE_NAME
ORDER BY 1

--copy & paste the results of this to create table create statements 
	--Send results to TEXT instead of GRID to get GO to show on next line of each query
SELECT 
	'CREATE TABLE [xxx].[' + SS.TABLE_NAME + '] (' + 
   (
		SELECT 
			'' + US.tableCreateLine -- use of preceding text removes XML tag named after column name
		FROM 
			#tblCreateLines US
		WHERE 
			US.TABLE_SCHEMA = SS.TABLE_SCHEMA
			AND
			US.TABLE_NAME = SS.TABLE_NAME
		ORDER BY
			ORDINAL_POSITION
		FOR XML PATH('')
	) + ')' + CHAR(13)+CHAR(10) + ' GO' AS createTableScript
FROM 
	#lastColumn SS
GROUP BY 
	SS.TABLE_SCHEMA,
	SS.TABLE_NAME
ORDER BY 1

