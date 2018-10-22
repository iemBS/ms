/*
Check if SQL job completed successfully. In this case the job is "Run sp_Dashboard_load"
*/
Select Top 1
	sjh.Run_Date
	,sjh.Run_Time
Into
	#LastCompletedRun
From
	msdb.dbo.SysJobs sj
	Inner Join msdb.dbo.SysJobHistory sjh on
		sj.Job_Id = sjh.Job_Id
Where
	sj.Name = 'Run sp_Dashboard_load'
And
	sjh.Step_Name = '(Job outcome)'
And
	sjh.Run_Time = 
	(
		Select Top 1
			sjh.Run_Time
		From
			msdb.dbo.SysJobs sj
			Inner Join msdb.dbo.SysJobHistory sjh on
				sj.Job_Id = sjh.Job_Id
		Where
			sj.Name = 'Run sp_Dashboard_load'
		And
			sjh.Step_Name = 'Run sp_Dashboard_load'
		Order By 
			sjh.Run_Date
			,sjh.Run_Time desc
	)
Order By 
	sjh.Run_Date
	,sjh.Run_Time desc


Select
	sjh.Run_Status -- status: 1 = successful, 0 = not successful, 3 = job was stopped by person
From
	msdb.dbo.SysJobs sj
	Inner Join msdb.dbo.SysJobHistory sjh on
		sj.Job_Id = sjh.Job_Id
	Inner Join #LastCompletedRun lr on
			sjh.run_date = lr.Run_Date
		And
			sjh.Run_Time = lr.Run_Time
Where
	sj.Name = 'Run sp_Dashboard_load'
And
	sjh.Step_Name = '(Job outcome)'
And
	CONVERT(datetime, CONVERT(varchar,sjh.run_date,101)) = CONVERT(datetime, CONVERT(varchar,GETDATE(),101))
	