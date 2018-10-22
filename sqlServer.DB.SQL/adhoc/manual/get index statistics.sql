Select
	d.name As DatabaseName
	,t.name As TableName
	,s.partition_number
	,s.index_type_desc
	,s.index_depth
	,s.index_level
	,i.name As IndexName
	,i.type_desc As IndexType
	,(Case i.is_unique When 1 Then 'Y' When 0 Then 'N' Else '-' End) As IndexIsUniqueFlag
	,(Case i.is_primary_key When 1 Then 'Y' When 0 Then 'N' Else '-' End) As IndexIsPrimaryKeyFlag
	,(Case i.is_unique_constraint When 1 Then 'Y' When 0 Then 'N' Else '-' End) As IndexIsUniqueConstraintFlag
	,(Case i.is_disabled When 1 Then 'Y' When 0 Then 'N' Else '-' End) As IndexIsDisabledFlag
	,s.alloc_unit_type_desc
	,s.avg_fragmentation_in_percent
	,s.fragment_count
	,s.avg_fragment_size_in_pages
	,s.page_count
	,s.avg_page_space_used_in_percent
	,s.record_count
	,s.ghost_record_count
	,s.version_ghost_record_count
	,s.min_record_size_in_bytes
	,s.max_record_size_in_bytes
	,s.avg_record_size_in_bytes
	,s.forwarded_record_count
	,s.compressed_page_count
From
	EATDW.sys.dm_db_index_physical_stats
	(
		DB_ID()
		,OBJECT_ID('EATDW.dbo.Email_Map_RoleAlias')
		,NULL
		,NULL
		,'DETAILED'
	) As s
	Inner Join Sys.Tables t On
		s.object_id = t.object_id
	Inner Join Sys.Databases d On
		s.database_id = d.database_id
	Inner Join Sys.indexes i On
		s.index_id = i.index_id


