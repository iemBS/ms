Select 
	j.name As JobName,
	s.step_id as StepPosition,
	s.step_name as StepName,s.command as StepCommand,
	sh.StartTime as Step_StartTime,
	sh.EndTime As Step_EndTime,
	sh.DurationMinutes as Step_DurationMinutes,
	jh.StartTime as Job_StartTime,
	jh.EndTime As Job_EndTime,
	jh.DurationMinutes As Job_DurationMinutes
From 
	msdb.dbo.sysjobs j 
	INNER JOIN msdb.dbo.sysjobsteps s ON 
		j.job_id = s.job_id
	INNER JOIN 
	(
		Select	
			job_id,
			step_id,
			msdb.dbo.agent_datetime(run_date, run_time) As StartTime,
			run_status,
			((run_duration/10000*3600 + (run_duration/100)%100*60 + run_duration%100 + 31 ) / 60) As DurationMinutes,
			msdb.dbo.agent_datetime(run_date, run_time) + 
			(
				run_time * 9
				+ run_time % 10000 * 6
				+ run_time % 100 * 10
				+ run_duration * 9
				+ run_duration % 10000 * 6
				+ run_duration % 100 * 10
			) / 216e4 As EndTime
		From
			msdb.dbo.sysjobhistory 
		Where
			step_id != 0
	) sh ON 
		j.job_id = sh.job_id 
		AND 
		s.step_id = sh.step_id 
	INNER JOIN 
	(
		Select	
			job_id,
			msdb.dbo.agent_datetime(run_date, run_time) As StartTime,
			run_status,
			((run_duration/10000*3600 + (run_duration/100)%100*60 + run_duration%100 + 31 ) / 60) As DurationMinutes,
			msdb.dbo.agent_datetime(run_date, run_time) + 
			(
				run_time * 9
				+ run_time % 10000 * 6
				+ run_time % 100 * 10
				+ run_duration * 9
				+ run_duration % 10000 * 6
				+ run_duration % 100 * 10
			) / 216e4 As EndTime
		From
			msdb.dbo.sysjobhistory 
		Where
			step_id = 0
	) jh On 
		j.job_id = jh.job_id
		And
		sh.StartTime Between jh.StartTime And jh.EndTime
Where
	j.[name] = 'DQF'
order by 
	jh.StartTime desc,
	sh.StartTime asc
