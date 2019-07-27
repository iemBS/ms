-- this excludes views
SELECT
	t.TABLE_SCHEMA, 
	t.TABLE_NAME,
	STUFF
	(
		(
			Select 
				', ' + c.COLUMN_NAME
			From 
				INFORMATION_SCHEMA.COLUMNS As c
			Where 
				c.TABLE_SCHEMA = t.TABLE_SCHEMA
				And 
				c.TABLE_NAME = t.TABLE_NAME
			Order By 
				c.ORDINAL_POSITION
			For Xml Path('')
        ), 
		1, 
		2, 
		''
	) AS Columns
FROM 
	INFORMATION_SCHEMA.TABLES AS T
    LEFT Join INFORMATION_SCHEMA.VIEWS AS V ON 
		V.TABLE_SCHEMA = T.TABLE_SCHEMA
        AND 
		V.TABLE_NAME = T.TABLE_NAME
WHERE
	V.TABLE_NAME IS Null
