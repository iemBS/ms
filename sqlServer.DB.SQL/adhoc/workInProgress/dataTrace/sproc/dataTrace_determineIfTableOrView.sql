/*

Determine if table or view

*/

use tempdb;
go

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

create PROC [dbo].[dataTrace_determineIfTableOrView] 
	@tableName varchar(60), -- enter a table or view name with a format of [db].[schema].[table]
	@objectType varchar(10) output
AS
BEGIN

END
GO


