/*
Get tables with rows

*/

Select
	t.[name] As [table],
	s.[name] As [schema]
Into
	#tablesWithRows
From
	sys.tables t 
	Inner Join sys.schemas s On 
	  t.schema_id = s.schema_id
        Inner Join sys.indexes i On 
	  t.object_id = i.object_id
        Inner Join sys.partitions p On 
	  i.object_id = p.object_ID
          and
          i.index_id = p.index_id
Where
	t.is_ms_shipped = 0
	And
	i.object_id > 255
	and
	p.[rows] > 0