if exists(select * from tempdb.information_schema.tables where table_name like '#xp_results%')
begin
	drop table #xp_results
end


CREATE TABLE #xp_results 
(
  job_id uniqueidentifier NOT NULL,
  last_run_date int NOT NULL,
  last_run_time int NOT NULL,
  next_run_date int NOT NULL,
  next_run_time int NOT NULL,
  next_run_schedule_id int NOT NULL,
  requested_to_run int NOT NULL, -- BOOL
  request_source int NOT NULL,
  request_source_id sysname COLLATE database_default NULL,
  running int NOT NULL, -- BOOL
  current_step int NOT NULL,
  current_retry_attempt int NOT NULL,
  job_state int NOT NULL
)
    
insert into
	#xp_results
execute	master.dbo.xp_sqlagent_enum_jobs 1, ''

select 
	sj.name as sqlJobName
	,ss.name as scheduleName
	,(case sj.enabled when 1 then 'Y' else 'N' end) as IsJobEnabledFlag
	,(case ss.enabled when 1 then 'Y' else 'N' end) as IsScheduleEnabledFlag
	,(case r.running when 1 then 'Y' else 'N' end) as IsRunningNowFlag
	,cast((left(cast(sjs.next_run_date as varchar(19)),4) + '-' + substring(cast(sjs.next_run_date as varchar(19)),5,2) + '-' + substring(cast(sjs.next_run_date as varchar(19)),7,2) + ' ' + cast(sjs.next_run_time / 10000 as varchar(10)) + ':' + right('00' + cast(sjs.next_run_time % 10000 / 100 as varchar(10)),2)) as datetime) as nextScheduledRunDateTime
	,getdate() as currentDateTime
	,datediff(minute,getdate(),cast((left(cast(sjs.next_run_date as varchar(19)),4) + '-' + substring(cast(sjs.next_run_date as varchar(19)),5,2) + '-' + substring(cast(sjs.next_run_date as varchar(19)),7,2) + ' ' + cast(sjs.next_run_time / 10000 as varchar(10)) + ':' + right('00' + cast(sjs.next_run_time % 10000 / 100 as varchar(10)),2)) as datetime)) as minutesTillNextRun
from
	msdb.dbo.sysjobs sj
	inner join msdb.dbo.sysjobschedules sjs on 
		sj.job_id = sjs.job_id 
	inner join msdb.dbo.sysSchedules ss on
		sjs.schedule_id = ss.schedule_id 
	inner join #xp_results r on 
		sj.job_id = r.job_id
where
	sj.enabled = 1
and
	(
			datediff(minute,getdate(),cast((left(cast(sjs.next_run_date as varchar(19)),4) + '-' + substring(cast(sjs.next_run_date as varchar(19)),5,2) + '-' + substring(cast(sjs.next_run_date as varchar(19)),7,2) + ' ' + cast(sjs.next_run_time / 10000 as varchar(10)) + ':' + right('00' + cast(sjs.next_run_time % 10000 / 100 as varchar(10)),2)) as datetime)) >= 0
		or
			r.running = 1
	)
order by
	sj.name
	
if exists(select * from tempdb.information_schema.tables where table_name like '#xp_results%')
begin
	drop table #xp_results
end