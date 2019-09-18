USE [AcctDB]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure [SG].[P_SprocExecution_Archive_Load]
AS
Begin


Select 
    QUOTENAME(OBJECT_SCHEMA_NAME([object_id])) + '.' + QUOTENAME(OBJECT_NAME([object_id])) As ProcedureName
    ,Last_Execution_Time As LastRunTimeStart
    ,Round((Cast(Max_Worker_Time As Float) / 1000000),3) As LongestRunTimeInSeconds
    ,Round((Cast(Last_Worker_Time As Float) / 1000000),3) As LastRunTimeInSeconds
Into
	#SprocExecution_Archive
From 
	sys.dm_exec_procedure_stats
Where 
	Database_Id = DB_ID()
	And
	QUOTENAME(OBJECT_SCHEMA_NAME([object_id])) + '.' + QUOTENAME(OBJECT_NAME([object_id])) != '[SG].[P_SprocExecution_Archive_Load]'
Order By 
	Last_Execution_Time Desc 
	
If Not Exists(Select * From Information_Schema.Tables Where Table_Schema = 'SG' And Table_Name = 'SprocExecution_Archive')
Begin
	Select
		ProcedureName
		,LastRunTimeStart
		,LongestRunTimeInSeconds
		,LastRunTimeInSeconds
	Into
		SG.SprocExecution_Archive
	From
		#SprocExecution_Archive
End
Else
Begin
	Insert Into
		SG.SprocExecution_Archive
	Select
		ProcedureName
		,LastRunTimeStart
		,LongestRunTimeInSeconds
		,LastRunTimeInSeconds
	From
		#SprocExecution_Archive
		
	Except 
	
	Select
		ProcedureName
		,LastRunTimeStart
		,LongestRunTimeInSeconds
		,LastRunTimeInSeconds
	From
		SG.SprocExecution_Archive
End

	
End

GO


