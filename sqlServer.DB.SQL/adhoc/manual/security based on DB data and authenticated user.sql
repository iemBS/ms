CREATE VIEW	[RPT].[VW_RPT_Benchmark_FY14Revenue_NewBusiness]
AS

Select
	t.AreaName
	,t.SubRegionName
	,t.SubsidiaryName
	,t.StdRptgReportedSubSegmentName
	,t.SubSegmentName
	,t.FiscalQuarter
	,Sum(t.Actuals) As Actuals
	,Sum(t.Scheduled) As Scheduled
From
	SG.Security ms
	Inner Join RPT.RPT_Benchmark_FY14Revenue_NewBusiness t On 
		ms.BusinessName = t.BusinessName
		And
		ms.SubsidiaryName = t.SubsidiaryName
Where
	ms.UserAlias = SubString(SUSER_NAME(),charIndex('\',SUSER_NAME())+1,LEN(SUSER_NAME()))
Group By
	t.AreaName
	,t.SubRegionName
	,t.SubsidiaryName
	,t.StdRptgReportedSubSegmentName
	,t.SubSegmentName
	,t.FiscalQuarter
