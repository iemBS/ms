CREATE TABLE [SG].[Map_FiscalPeriod](
	[FiscalDateID] [int] NOT NULL,
	[FiscalDate] [datetime] NOT NULL,
	[FiscalMonthID] [int] NOT NULL,
	[FiscalMonthName] [varchar](18) NOT NULL,
	[FiscalMonthNumber] [int] NULL,
	[FiscalMonthPosition] [int] NOT NULL,
	[FiscalMonthStartDate] [date] NULL,
	[FiscalMonthEndDate] [date] NULL,
	[FiscalQuarterID] [int] NOT NULL,
	[FiscalQuarterName] [char](7) NOT NULL,
	[FiscalQuarterPosition] [int] NOT NULL,
	[FiscalQuarterStartDate] [date] NULL,
	[FiscalQuarterEndDate] [date] NULL,
	[FiscalHalfID] [int] NOT NULL,
	[FiscalHalfName] [varchar](50) NOT NULL,
	[FiscalHalfPosition] [int] NOT NULL,
	[FiscalHalfStartDate] [date] NULL,
	[FiscalHalfEndDate] [date] NULL,
	[FiscalYearID] [int] NOT NULL,
	[FiscalYearName] [char](4) NOT NULL,
	[FiscalYearPosition] [int] NOT NULL,
	[FiscalYearStartDate] [date] NULL,
	[FiscalYearEndDate] [date] NULL,
	[YTDFlag] [varchar](1) NOT NULL,
	[PreviousYTDFlag] [varchar](1) NOT NULL,
	[QTDFlag] [varchar](1) NOT NULL
) ON [PRIMARY]

GO

CREATE Procedure [SG].[P_Map_FiscalPeriod_Load]
AS
Begin

Truncate Table SG.Map_FiscalPeriod

Insert Into
	SG.Map_FiscalPeriod
Select
	SalesDateID As FiscalDateID
	,CalendarDate As FiscalDate
	,FiscalMonthID
	,FiscalMonthName
	,(
		Case SubString(FiscalMonthName,0,Len(FiscalMonthName) - 5)
			When 'July' Then 1
			When 'August' Then 2
			When 'September' Then 3
			When 'October' Then 4
			When 'November' Then 5
			When 'December' Then 6
			When 'January' Then 7
			When 'February' Then 8
			When 'March' Then 9
			When 'April' Then 10
			When 'May' Then 11
			When 'June' Then 12
		End
	 ) As FiscalMonthNumber
	,0 As FiscalMonthPosition
	,Cast(FMBeginDate As Date) As FiscalMonthStartDate
	,Cast(FMEndDate As Date) As FiscalMonthEndDate
	,FiscalQuarterID
	,FiscalQuarterName
	,0 As FiscalQuarterPosition
	,Cast('1900-01-01 00:00:00' As Date) As FiscalQuarterStartDate
	,Cast('1900-01-01 00:00:00' As Date) As FiscalQuarterEndDate
	,FiscalSemesterID As FiscalHalfID
	,FiscalSemesterName As FiscalHalfName
	,0 As FiscalHalfPosition
	,Cast('1900-01-01 00:00:00' As Date) As FiscalHalfStartDate
	,Cast('1900-01-01 00:00:00' As Date) As FiscalHalfEndDate
	,FiscalYearID
	,FiscalYearName
	,0 As FiscalYearPosition
	,Cast('1900-01-01 00:00:00' As Date) As FiscalYearStartDate
	,Cast('1900-01-01 00:00:00' As Date) As FiscalYearEndDate
	,'N' As YTDFlag
	,'N' As PreviousYTDFlag
	,'N' As QTDFlag
From
	LinkedBMX.dbBMXProd.BMX.vwSalesDates
Where
	FiscalMonthName != 'N/A'
	And
	FiscalYearName In ('FY11','FY12','FY13','FY14','FY15')
	

Create Table #FiscalPosition
(
	FiscalPeriodName Varchar(100) Null
	,FiscalPeriodPosition Int Null
)


-- Set Month Start and End Dates
Update
	m
Set
	FiscalMonthStartDate = fp.FiscalMonthStartDate
	,FiscalMonthEndDate = fp.FiscalMonthEndDate
From
	(
		Select
			FiscalMonthID
			,Min(FiscalDate) As FiscalMonthStartDate
			,Max(FiscalDate) As FiscalMonthEndDate
		From
			SG.Map_FiscalPeriod
		Group By
			FiscalMonthID
	) fp
	Inner Join SG.Map_FiscalPeriod m On
		fp.FiscalMonthID = m.FiscalMonthID 

-- Set Quarter Start and End Dates
Update
	m
Set
	FiscalQuarterStartDate = fp.FiscalQuarterStartDate
	,FiscalQuarterEndDate = fp.FiscalQuarterEndDate
From
	(
		Select
			FiscalQuarterID
			,Min(FiscalDate) As FiscalQuarterStartDate
			,Max(FiscalDate) As FiscalQuarterEndDate
		From
			SG.Map_FiscalPeriod
		Group By
			FiscalQuarterID
	) fp
	Inner Join SG.Map_FiscalPeriod m On
		fp.FiscalQuarterID = m.FiscalQuarterID 

-- Set Half Start and End Dates
Update
	m
Set
	FiscalHalfStartDate = fp.FiscalHalfStartDate
	,FiscalHalfEndDate = fp.FiscalHalfEndDate
From
	(
		Select
			FiscalHalfID
			,Min(FiscalDate) As FiscalHalfStartDate
			,Max(FiscalDate) As FiscalHalfEndDate
		From
			SG.Map_FiscalPeriod
		Group By
			FiscalHalfID
	) fp
	Inner Join SG.Map_FiscalPeriod m On
		fp.FiscalHalfID = m.FiscalHalfID 

-- Set Year Start and End Dates
Update
	m
Set
	FiscalYearStartDate = fp.FiscalYearStartDate
	,FiscalYearEndDate = fp.FiscalYearEndDate
From
	(
		Select
			FiscalYearID
			,Min(FiscalDate) As FiscalYearStartDate
			,Max(FiscalDate) As FiscalYearEndDate
		From
			SG.Map_FiscalPeriod
		Group By
			FiscalYearID
	) fp
	Inner Join SG.Map_FiscalPeriod m On
		fp.FiscalYearID = m.FiscalYearID 
	
-- Set FiscalMonthPosition

	-- Set Current Month
	Update
		SG.Map_FiscalPeriod
	Set
		FiscalMonthPosition = 0
	Where
		SG.UDF_FiscalPeriod_Current() Between FiscalMonthStartDate And FiscalMonthEndDate
	
	-- Set Previous Months	
	Insert Into
		#FiscalPosition
	Select
		FiscalMonthName
		,(Rank() Over (Order By FiscalMonthEndDate Desc)) * -1 As FiscalMonthPosition
	From
		(Select Distinct FiscalMonthName,FiscalMonthEndDate From SG.Map_FiscalPeriod) t
	Where
		FiscalMonthEndDate < SG.UDF_FiscalPeriod_Current()
	Order By
		FiscalMonthEndDate Desc
			
	-- Set Future Months
	Insert Into
		#FiscalPosition
	Select
		FiscalMonthName
		,Rank() Over (Order By FiscalMonthStartDate) As FiscalMonthPosition
	From
		(Select Distinct FiscalMonthName,FiscalMonthStartDate From SG.Map_FiscalPeriod) t
	Where
		FiscalMonthStartDate > SG.UDF_FiscalPeriod_Current()
	Order By
		FiscalMonthStartDate 

	Update
		m
	Set
		FiscalMonthPosition = fp.FiscalPeriodPosition
	From
		#FiscalPosition fp
		Inner Join SG.Map_FiscalPeriod m On
			fp.FiscalPeriodName = m.FiscalMonthName

-- Set FiscalQuarterPosition

	Truncate Table #FiscalPosition

	-- Set Current Quarter
	Update
		SG.Map_FiscalPeriod
	Set
		FiscalQuarterPosition = 0
	Where
		SG.UDF_FiscalPeriod_Current() Between FiscalQuarterStartDate And FiscalQuarterEndDate
	
	-- Set Previous Quarters	
	Insert Into
		#FiscalPosition
	Select
		FiscalQuarterName
		,(Rank() Over (Order By FiscalQuarterEndDate Desc)) * -1 As FiscalQuarterPosition
	From
		(Select Distinct FiscalQuarterName,FiscalQuarterEndDate From SG.Map_FiscalPeriod) t
	Where
		FiscalQuarterEndDate < SG.UDF_FiscalPeriod_Current()
	Order By
		FiscalQuarterEndDate Desc
			
	-- Set Future Quarters
	Insert Into
		#FiscalPosition
	Select
		FiscalQuarterName
		,Rank() Over (Order By FiscalQuarterStartDate) As FiscalQuarterPosition
	From
		(Select Distinct FiscalQuarterName,FiscalQuarterStartDate From SG.Map_FiscalPeriod) t
	Where
		FiscalQuarterStartDate > SG.UDF_FiscalPeriod_Current()
	Order By
		FiscalQuarterStartDate 

	Update
		m
	Set
		FiscalQuarterPosition = fp.FiscalPeriodPosition
	From
		#FiscalPosition fp
		Inner Join SG.Map_FiscalPeriod m On
			fp.FiscalPeriodName = m.FiscalQuarterName

-- Set FiscalHalfPosition

	Truncate Table #FiscalPosition

	-- Set Current Half
	Update
		SG.Map_FiscalPeriod
	Set
		FiscalHalfPosition = 0
	Where
		SG.UDF_FiscalPeriod_Current() Between FiscalHalfStartDate And FiscalHalfEndDate
	
	-- Set Previous Halfs	
	Insert Into
		#FiscalPosition
	Select
		FiscalHalfName
		,(Rank() Over (Order By FiscalHalfEndDate Desc)) * -1 As FiscalHalfPosition
	From
		(Select Distinct FiscalHalfName,FiscalHalfEndDate From SG.Map_FiscalPeriod) t
	Where
		FiscalHalfEndDate < SG.UDF_FiscalPeriod_Current()
	Order By
		FiscalHalfEndDate Desc
			
	-- Set Future Halfs
	Insert Into
		#FiscalPosition
	Select
		FiscalHalfName
		,Rank() Over (Order By FiscalHalfStartDate) As FiscalHalfPosition
	From
		(Select Distinct FiscalHalfName,FiscalHalfStartDate From SG.Map_FiscalPeriod) t
	Where
		FiscalHalfStartDate > SG.UDF_FiscalPeriod_Current()
	Order By
		FiscalHalfStartDate 

	Update
		m
	Set
		FiscalHalfPosition = fp.FiscalPeriodPosition
	From
		#FiscalPosition fp
		Inner Join SG.Map_FiscalPeriod m On
			fp.FiscalPeriodName = m.FiscalHalfName

-- Set FiscalYearPosition

	Truncate Table #FiscalPosition

	-- Set Current Year
	Update
		SG.Map_FiscalPeriod
	Set
		FiscalYearPosition = 0
	Where
		SG.UDF_FiscalPeriod_Current() Between FiscalYearStartDate And FiscalYearEndDate
	
	-- Set Previous Years	
	Insert Into
		#FiscalPosition
	Select
		FiscalYearName
		,(Rank() Over (Order By FiscalYearEndDate Desc)) * -1 As FiscalYearPosition
	From
		(Select Distinct FiscalYearName,FiscalYearEndDate From SG.Map_FiscalPeriod) t
	Where
		FiscalYearEndDate < SG.UDF_FiscalPeriod_Current()
	Order By
		FiscalYearEndDate Desc
			
	-- Set Future Years
	Insert Into
		#FiscalPosition
	Select
		FiscalYearName
		,Rank() Over (Order By FiscalYearStartDate) As FiscalYearPosition
	From
		(Select Distinct FiscalYearName,FiscalYearStartDate From SG.Map_FiscalPeriod) t
	Where
		FiscalYearStartDate > SG.UDF_FiscalPeriod_Current()
	Order By
		FiscalYearStartDate 

	Update
		m
	Set
		FiscalYearPosition = fp.FiscalPeriodPosition
	From
		#FiscalPosition fp
		Inner Join SG.Map_FiscalPeriod m On
			fp.FiscalPeriodName = m.FiscalYearName
			
	-- Set To Date Flags
	UPDATE
		[sg].[Map_FiscalPeriod]
	SET
		[YTDFlag] = 'Y'
	WHERE
		[FiscalYearName] IN (
								SELECT DISTINCT
									[FiscalYearName]
								FROM
									[sg].[Map_FiscalPeriod]
								WHERE
									[FiscalMonthPosition] = -1
							)
		AND [FiscalYearPosition] = 0
		AND [FiscalMonthPosition] < 0

	UPDATE
		[sg].[Map_FiscalPeriod]
	SET
		[QTDFlag] = 'Y'
	WHERE
		[FiscalQuarterName] IN (
									SELECT DISTINCT
										[FiscalQuarterName]
									FROM
										[sg].[Map_FiscalPeriod]
									WHERE
										[FiscalMonthPosition] = -1
								)
	AND [FiscalYearPosition] = 0
	AND [FiscalMonthPosition] < 0

	UPDATE
		[sg].[Map_FiscalPeriod]
	SET
		[PreviousYTDFlag] = 'Y'
	WHERE
		[FiscalMonthID] IN  (
								SELECT
									([FiscalMonthID] - 12) AS [FiscalMonthID]
								FROM
									[sg].[Map_FiscalPeriod]
								WHERE
									[YTDFlag] = 'Y'
							)
	
End
GO
