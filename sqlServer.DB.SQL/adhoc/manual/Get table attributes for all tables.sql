
-- Get Table Schema, Table Name, Column Count in Table, and Row Count in table
Select 
	t.Table_Schema
	,t.Table_name
	,c.ColumnCnt
	,'Select ''' + t.Table_Schema + ''' As SchemaName, ''' + t.Table_Name + ''' As TableName,' +  Cast(c.ColumnCnt As Varchar) + ' As ColumnCnt, Count(1) As RownCnt From ' + t.Table_Schema + '.' + t.Table_Name + ' Union All '
From
	Information_schema.Tables t
	Inner Join
	(
		Select
			Table_Name
			,Count(Column_Name) As ColumnCnt
		From
			Information_schema.Columns
		Group By
			Table_Name
	) c On
		t.Table_Name = c.Table_Name
Order By
	t.Table_Schema
	,t.Table_Name