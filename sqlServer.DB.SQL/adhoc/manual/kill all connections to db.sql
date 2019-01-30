/*
Kill all current sessions on SQL server DB. Will not kill this session. 
*/

Use [master];
go

Declare @dbName Varchar(40)
Set @dbName = 'DQF_CDS'
Declare @kill Varchar(8000) = '';  

Select 'Sessions on server before kill'

Select
	*
From 
	sys.dm_exec_sessions
Where 
	database_id  = db_id(@dbName)

select 'Current Session ID: ' + Cast(@@SPID as Varchar(10))

While exists(Select 1 From sys.dm_exec_sessions Where database_id  = db_id(@dbName))
Begin
	Select
		@kill = @kill + 'kill ' + CONVERT(varchar(5), session_id) + ';'  
	From 
		sys.dm_exec_sessions
	Where 
		database_id  = db_id(@dbName)

	EXEC(@kill);
End

Select 'Sessions on server after kill'

Select
	*
From 
	sys.dm_exec_sessions
Where 
	database_id  = db_id(@dbName)
	

	select suser_name()