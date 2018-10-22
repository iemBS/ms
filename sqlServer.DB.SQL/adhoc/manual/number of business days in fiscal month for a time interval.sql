	Select
		PackageName
		,ScheduledExecutionDateTime
		,IsCompletedFlag
		,IsSuccessfulFlag
		,(DateDiff(day,FirstDayOfMonth,LastDayOfInterval) + 1) - 
		(DateDiff(Week,FirstDayOfMonth,LastDayOfInterval) * 2) - 
		(Case When DateName(dw,FirstDayOfMonth) = 'Sunday' Then 1 Else 0 End) - 
		(Case When DateName(dw,LastDayOfInterval) = 'Saturday' Then 1 Else 0 End) As BusinessDayInFiscalMonth
	From
	(
		Select
			PackageName
			,ScheduledExecutionDateTime
			,IsCompletedFlag
			,IsSuccessfulFlag
			,Cast(ScheduledExecutionDateTime As DateTime) - (Day(ScheduledExecutionDateTime)-1) As FirstDayOfMonth
			,ScheduledExecutionDateTime As LastDayOfInterval
		From
			AnO.dbo.OpsETLPackageSchedule
	) l1