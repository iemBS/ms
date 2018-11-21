/*
Last successful run of an enabled SQL job
*/


declare @prefix varchar(30)
Set @prefix = 'Executed as user: '


Select
	*,
	Dense_Rank() Over (Partition By Job_Id Order By alias desc) As aliasPerJob
Into
	#jobRunAlias -- job can have more than one alias because each step of a job can run as a different alias
From
	(
		Select Distinct 
			Job_Id,
			substring(msgTruncate,0,charindex(' ',msgTruncate)-1) As alias
		From
			(
				Select 
					Job_Id,
					replace([message],@prefix,'') As msgTruncate,
					Dense_Rank() Over (Partition By Job_Id Order By Run_Date desc,Run_Time desc) As rnk
				From 
					msdb.dbo.sysjobhistory
				Where
					run_status = 1 -- Succeeded
					And
					Step_Name != '(Job outcome)'
					And
					CHARINDEX(@prefix,[message]) > 0
					And
					DateDiff(month,convert(date,convert(varchar(8),20181101,120)),cast(getdate() as date)) <= 3 -- job ran within the last 3 months
			) t
		Where
			rnk = 1
	) t2
Order By
	Job_Id,
	aliasPerJob desc
	
Delete
	#jobRunAlias
Where
	Job_ID In (Select Job_ID From #jobRunAlias Where aliasPerJob = 2)
	And
	aliasPerJob = 1


Select
	lastRunDate,
	lastRunTime, -- need to find out how to convert this time to my curren time
	job,
	runAs
Into
	#LastCompletedRun -- last successful run of job
From
	(
		Select 
			sjh.Run_Date As lastRunDate -- in YYYYMMDD format
			,sjh.Run_Time As lastRunTime -- in HHMMSS format
			,sj.[Name] As job,
			Dense_Rank() Over (Partition By sj.[Name] Order By sjh.Run_Date desc,sjh.Run_Time desc) As rnk,
			apj.alias as runAs
		From
			msdb.dbo.SysJobs sj
			Inner Join msdb.dbo.SysJobHistory sjh on
				sj.Job_Id = sjh.Job_Id
				And
				sj.[enabled] = 1
				And
				sjh.run_status = 1 -- Succeeded
				And
				sjh.Step_Name = '(Job outcome)'
			Left Outer Join #jobRunAlias apj On 
				sj.Job_Id = apj.Job_Id
	) t
Where
	rnk = 1

	