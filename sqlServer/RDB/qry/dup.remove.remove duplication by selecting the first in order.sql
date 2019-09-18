
		Select
			AcctTm
			,AcctTmLead
		From
			(
				Select
					AccountTeamUnit As AcctTm
					,AcctTmManagerAlias As AcctTmLead
					,ROW_NUMBER() Over (PARTITION BY AccountTeamUnit Order By AcctTmManagerAlias) As AcctTmLeadNumber
				From
					AcctDB.dbo.Account   
				Where
					ISNULL(AcctTmManagerAlias,'') Not In ('TBH','','None','TBD')
				GROUP BY
					AccountTeamUnit
					,AcctTmManagerAlias
			) t
		Where
			AcctTmLeadNumber = 1
