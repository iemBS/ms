/*
Get last successful run of an SSIS package that is hosted in the integration services catalog
*/

Select
	[project],
	[package],
	lastRunTime
From
	(
		select 
			project_name As [project],
			package_name As [package],
			start_time as lastRunTime,
			Dense_Rank() Over (Partition By project_name,package_name Order By start_time desc) As rnk
		From
			SSISDB.catalog.executions
		Where
			status = 7 -- succeeded
	) t
Where
	rnk = 1


