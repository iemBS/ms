-- Get table create line without constraints
	--if a table is created without settig columns to be nullable, then they will be null as long as the DB level level config is set to default to null
Select
	COLUMN_NAME + ' ' + 
	DATA_TYPE + 
	CASE
		WHEN CHARACTER_MAXIMUM_LENGTH >= 1 THEN '(' + CAST(CHARACTER_MAXIMUM_LENGTH AS VARCHAR) + ') ' /* string column column */
		ELSE /* number/time column */
			CASE DATA_TYPE
				WHEN 'numeric' THEN '(' + CAST(NUMERIC_PRECISION AS VARCHAR) + ',' + CAST(NUMERIC_SCALE AS VARCHAR) + ') '	
				ELSE ''
			END
	END AS tableCreateLine,
	*
From
	INFORMATION_SCHEMA.COLUMNS 
where
	CHARACTER_MAXIMUM_LENGTH is NOT NULL
