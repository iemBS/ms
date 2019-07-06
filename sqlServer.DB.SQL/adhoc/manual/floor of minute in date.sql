Declare @tstTm DateTime

Select @tstTm = GetDate()

Select
	@tstTm As currTm,
	DATEPART(minute,@tstTm) As m4CurrTm,
	CONVERT(VARCHAR(16), @tstTm, 120) As currTmFloorToMinInStr,
	Cast(CONVERT(VARCHAR(16), @tstTm, 120) AS datetime) As currTmFloorToMinInDT,
	DATEPART(minute,Cast(CONVERT(VARCHAR(16), @tstTm, 120) AS datetime)) As m4CurrTmFloorToMin
