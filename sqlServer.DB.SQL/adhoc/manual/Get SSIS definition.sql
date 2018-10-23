/*
Get SSIS definition. Cannot get all the details though. Things like SQL script in an execute task. 
*/

Select Distinct 
	t.[project],
	t.[package],
    em.package_path As [packagePath], -- find out why this is null sometimes
	t.lastRunTime,
	em.message_source_name As task,
	em.subcomponent_name As subTask -- find out what SSIS.Pipeline is
From
	(
	    -- last successful run of SSIS packages
		Select  
			[project],
			[package],
			lastRunTime,
			ex.end_time
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
			) t2
			Inner Join SSISDB.catalog.executions ex On
				t2.[project] = ex.project_name
				and
				t2.[package] = ex.package_name
				and
				t2.lastRunTime = ex.start_time
		Where
			rnk = 1
	) t
	Inner Join SSISDB.catalog.event_messages em On
	  t.[package] = em.package_name
	  And
	  em.message_time Between t.lastRunTime and t.end_time
Order By
	t.[project],
	t.[package],
	em.package_path

	select top 10 * From SSISDB.catalog.event_messages



