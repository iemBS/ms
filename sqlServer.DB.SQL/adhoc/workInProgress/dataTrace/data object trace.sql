


/*
Search a system that uses relational DBs, SSIS in integration catalogs, SQL jobs, Dimensional cubes, and Tabular cubes and 
return a trace of where they are found starting level is cube and ending level is SQL job.
*/

-- declare
declare @searchFor varchar(50)

-- config
@searchFor = ''

-- setup
create table #parentChild
(
	relationType varchar(40),
	parent varchar(40),
	child varchar(40)
)

-- Get SSIS definitions
Select Distinct 
	t.[project],
	t.[package],
    em.package_path As [packagePath], -- find out why this is null sometimes
	t.lastRunTime,
	em.message_source_name As task,
	em.subcomponent_name As subTask -- find out what SSIS.Pipeline is
Into
	#ssisDef -- Get SSIS definition.
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

-- Get SQL Job definitions
Select
	t.*,
	stp.command
Into
	#jobDef
From
	(
		Select 
			sjh.Run_Date As lastRunDate -- in YYYYMMDD format
			,sjh.Run_Time As lastRunTime -- in HHMMSS format
			,sj.[Name] As job
			,sj.[job_id]
			,Dense_Rank() Over (Partition By sj.[Name] Order By sjh.Run_Date desc,sjh.Run_Time desc) As rnk
		From
			msdb.dbo.SysJobs sj
			Inner Join msdb.dbo.SysJobHistory sjh on
				sj.Job_Id = sjh.Job_Id
				And
				sj.[enabled] = 1
				And
				sjh.run_status = 1 -- Succeeded
				And
				sjh.Step_Name != '(Job outcome)'
	) t
	Inner Join [msdb].[dbo].[sysjobsteps] AS stp ON 
		t.[job_id] = stp.[job_id]
Where
	t.rnk = 1
	and
	stp.last_run_date != 0
	and
	stp.subsystem In ('SSIS','TSQL','CmdExec')

	select 

-- Get sproc definitions (run all all 4 relational DBs)
select 
	DB_NAME() + '.' + r.routine_schema + '.' + p.[name] as objectName,
	m.[definition]
from
	sys.procedures p
	inner join sys.sql_modules m on p.object_id = m.object_id
	inner join information_schema.routines r on p.[name] = r.routine_name

	select  * From sys.procedures

-- Search table definitions

-- Search view definitions

-- Search Sproc definitions

-- Search user defined function definitions

-- Search dimensional cube

-- Search tabular cube

-- Search SSIS packages
Select
	*
From
	#ssisDef
Where
	task like '%plancast%'

-- Search SQL jobs


