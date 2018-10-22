SELECT
	[AM1].[EMailType],
	[AM1].[AM],
	STUFF
	(
		(
			SELECT TOP 5
				';'+ CAST([AcctTmLead] AS VarChar)
			FROM
				#TLM AS [AM2]
			WHERE
				[AM2].[AM] = [AM1].[AM]
			ORDER BY
				[AM2].[AM],
				[AM2].[AcctTmLead]
			FOR XML PATH(''), TYPE
		).value('.','VarChar(MAX)') 
		,1
		,1
		,SPACE(0)
	) AS [AcctTmLeads]
FROM
	#TLM AS [AM1]
GROUP BY
	[AM1].[EmailType],
	[AM1].[AM] 
ORDER BY 
	[AM1].[EmailType],
	[AM1].[AM];
