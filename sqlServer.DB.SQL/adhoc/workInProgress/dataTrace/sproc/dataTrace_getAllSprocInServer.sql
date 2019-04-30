use tempdb;
go

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

create PROC [dbo].[dataTrace_getAllSprocInServer] 
AS
BEGIN
        -- limit to sprocs, DBs, and schemas. Must return these three column names
	select
		db_name() As sprocDbName,
		routine_schema As sprocSchemaName,
		routine_name As sprocName
	into
		#allSprocInServer
	from
		ccgStage.information_schema.routines
	where
		routine_schema in ('dbo','MSSales','MSSalesOEM','Lima','IEB','IPT','XboxDadMad','Fusion','MAU','SMSGPL','ConsoleInventory')
		and
		routine_name not in 
		(
			'sp_helpdiagrams',
			'sp_helpdiagramdefinition',
			'sp_creatediagram',
			'sp_renamediagram',
			'sp_alterdiagram',
			'sp_dropdiagram',
			'fn_diagramobjects',
			'sp_upgraddiagrams'
		)

	union all

	select
		db_name() As sprocDbName,
		routine_schema As sprocSchemaName,
		routine_name As sprocName
	from
		ccgWareHouse.information_schema.routines
	where
		routine_schema in ('dbo','Retailer','IPT')
		and
		routine_name not in ('')

	union all 

	select
		db_name() As sprocDbName,
		routine_schema As sprocSchemaName,
		routine_name As sprocName
	from
		ccgDataMart.information_schema.routines
	where
		routine_schema in ('dbo','Retailer','IPT')
		and
		routine_name not in ('')
		
	select 
		*
	from
		#allSprocInServer
END
GO


