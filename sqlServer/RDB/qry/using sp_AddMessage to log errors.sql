

Exec sp_AddMessage 
	@msgnum = 50003 -- user-defined error messages must have an ID greater than 50k
	,@severity = 25
	,@msgtext = 'Who sank my battleship?'
	,@with_log = 'TRUE' -- this will log the message in the windows log 
