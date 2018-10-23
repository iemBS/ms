/*
Last successful run of an enabled SQL job
*/

Select
	lastRunDate,
	lastRunTime, -- need to find out how to convert this time to my curren time
	job
Into
	#LastCompletedRun -- last successful run of job
From
	(
		Select 
			sjh.Run_Date As lastRunDate
			,sjh.Run_Time As lastRunTime
			,sj.[Name] As job,
			Dense_Rank() Over (Partition By sj.[Name] Order By sjh.Run_Date desc,sjh.Run_Time desc) As rnk
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
	) t
Where
	rnk = 1

