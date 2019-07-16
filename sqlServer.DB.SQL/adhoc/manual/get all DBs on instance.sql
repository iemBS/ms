Select
	[name]
From
	sys.databases
Where
	[name] Not In 
	(
		'master',
		'tempdb',
		'model',
		'msdb'
	)
