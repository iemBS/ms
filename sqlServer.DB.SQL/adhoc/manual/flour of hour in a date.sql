Declare @tstTm DateTime

Select @tstTm = GetDate()

Select
	@tstTm As currTm,
	DATEPART(hour,@tstTm) As h4CurrTm,
    CONVERT(VARCHAR(13), @tstTm, 120) As currTmFloorToHrInStr,
	cast(CONVERT(VARCHAR(13), @tstTm, 120)+':00' as datetime) As currTmFloorToHrInDT,
	DATEPART(hour,cast(CONVERT(VARCHAR(13), @tstTm, 120)+':00' as datetime)) As m4CurrTmFloorToHr
