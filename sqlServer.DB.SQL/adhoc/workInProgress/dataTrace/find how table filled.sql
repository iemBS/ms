/*
  find how a table is filled
*/

declare @table varchar(50)
declare @fullPath varchar(500)
set @table = 

-- see if full path already known
select 'start > end' As map,'xxx' As fullPath

-- see if table exists in user defined function

	-- if yes
		-- record path [udf] > [table]

		-- see if udf exists in view

			-- if yes
				
				-- record path [view] > [udf] > [table]

-- see if table, udf, or view exists in stored procedure

	-- see if is known paths of table, udf, or view in sproc
	select 'sproc > table' As map,'[ccgDataMart].[dbo].[usp_LoadFactFinanceForecast]' As parent,'[CCGDataMart].[dbo].[FactFinanceForecast]' As child

	-- if yes
		
			-- record path [sproc] > [objects]

			-- see if sproc pulls from a table

				-- see if known path of sproc from table
				select 'table > sproc' As map,'[CCGwarehouse].[dbo].[FinanceForecast]' As parent,'[ccgDataMart].[dbo].[usp_LoadFactFinanceForecast]' As child
				union all
				select 'table > sproc','[CCGwarehouse].[dbo].[SellInForecastWeekly_PctSplitMap]','[ccgDataMart].[dbo].[usp_LoadFactFinanceForecast]'
				union all
				select 'table > sproc' as map,'[CCGwarehouse].[dbo].[SellThruForecastWeekly_PctSplitMap]','[ccgDataMart].[dbo].[usp_LoadFactFinanceForecast]'

				-- if yes

					-- record path [table] > [sproc] > [objects]

					

-- see if table, udf, view, or sproc exists in SSIS

  -- see if in known paths of table, udf, view, or sproc in SSIS is known
  select 'SSIS Task > table' As map,'[ExtractTransformFinanceForecast].[ExtractFinanceForecast.dtsx].[Load FinanceForecastFull].[FinanceForecastStage]' As parent,'[ccgStage].[dbo].[FinanceForecastFull]' As child

  -- if yes

      -- record path [SSIS] > [objects]

	  -- see if SSIS in another SSIS, run SSIS loop again

	    -- if yes

			-- record path [SSIS] > [SSIS] > [objects]

  -- if maybe

    -- show pssible paths [SSIS] > [objects]

-- see if table, udf, view, sproc, SSIS exists in job

	-- see if in known paths of table, udf, view, sproc, or SSIS in job is known

	-- if yes

		-- record path [job] > [objects]

	-- if maybe

		-- show possible paths [job] > [objects]


-- see if job triggered by another job

	-- if yes

		-- record path [job] > [job] > [objects]

	-- if maybe

		-- shw possible paths [job] > [objects]