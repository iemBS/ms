Select
	convert(decimal(20,10),MonthlyRevenue) -- make sure is in a form we can see the decimal places
From
	(
		Select
			min(MonthlyRevenue) As MonthlyRevenue -- smallest non-zero number in the column
		From
			(
				Select  
					abs(MonthlyRevenue) - Floor(abs(MonthlyRevenue)) As MonthlyRevenue -- make all positive & get only decimal part of number
				From
					ccgStage.[FinanceForecast].[MonthlyRevenueAndLicense_OutlookStage]
			) t
		Where
			MonthlyRevenue > 0 -- need non-zero values
	) t





   