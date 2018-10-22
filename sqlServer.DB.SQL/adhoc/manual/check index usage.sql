-- All the values in the dm_db_index_usage_stats table are reset each time 
-- SQL server restarts. Indexes that have not been used since the reset
-- will not have an entry in the db_db_index_usage_stats view. 

Select
	@@SERVERNAME As ServerName
	,DB_NAME() As DatabaseName
	,t.TableName
	,i.IndexName
	,i.IndexType
	,i.IsIndexEnabled
	,i.IsIndexPrimaryKey
	,s.user_seeks As NumberOfSeeksByUserQueries
	,s.user_scans As NumberOfScansByUserQueries
	,s.user_lookups As NumberOfLookUpsByUserQueries
	,s.user_updates As NumberOfUpdatesByUserQueries
	,s.last_user_seek As TimeOfLastUserSeek
	,s.last_user_scan As TimeOfLastUserScan
	,s.last_user_lookup As TimeOfLastUserLookup
From
	sys.dm_db_index_usage_stats s
	Inner Join 
	(
		Select
			Object_Id As TableId	
			,Name As TableName
		From
			sys.views
		Union 
		Select
			Object_Id As TableId	
			,Name As TableName
		From
			sys.tables
	) t On
		s.object_id = t.TableId
	Inner Join
	(
		Select
			OBJECT_ID As IndexId
			,name As IndexName
			,type_desc As IndexType
			,(Case is_primary_key When 0 Then 'No' Else 'Yes' End) As IsIndexPrimaryKey
			,(Case is_disabled When 0 Then 'No' Else 'Yes' End) As IsIndexEnabled
		From
			sys.indexes
	) i On
		s.index_id = i.IndexId
	
