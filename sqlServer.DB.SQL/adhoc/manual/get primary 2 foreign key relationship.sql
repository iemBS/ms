SELECT 
	f.name AS ForeignKey, 
	OBJECT_SCHEMA_NAME(f.parent_object_id) As table_schema_pk,
	OBJECT_NAME(f.parent_object_id) AS table_name_pk,
    COL_NAME(fc.parent_object_id, fc.parent_column_id) AS column_name_pk,
	OBJECT_SCHEMA_NAME (f.referenced_object_id) AS table_schema_fk,
    OBJECT_NAME (f.referenced_object_id) AS table_name_fk,
    COL_NAME(fc.referenced_object_id, fc.referenced_column_id) AS column_name_fk
FROM 
	sys.foreign_keys AS f with (nolock)
	INNER JOIN sys.foreign_key_columns AS fc with (nolock) ON 
		f.OBJECT_ID = fc.constraint_object_id
