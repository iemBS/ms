SELECT
	AcctTm
	,AcctTmLead
FROM
    (
		Select
			AcctTm
			,[AcctTm Manager] As AcctTmLead
			,ROW_NUMBER() Over (PARTITION BY AcctTm Order By [AcctTm Manager]) As AcctTmLeadNumber
		From
			vwDealFactoryExcel   
		Where
			ISNULL([AcctTm Manager],'') Not In ('TBH','','None','TBD')
		GROUP BY
			AcctTm
			,[AcctTm Manager]
    ) t
Where
    AcctTmLeadNumber = 2
Order By
	AcctTm
 
-----

	Select
		AcctTm
	From
	(
		Select Distinct
			AcctTm
			,[AcctTm Manager] As AcctTmLead
		From
			vwDealFactoryExcel
		Where
			ISNULL([AcctTm Manager],'') Not In ('TBH','','None','TBD')
	) t
	Group By
		AcctTm
	Having	
		COUNT(AcctTmLead) > 1
	Order By
		AcctTm
