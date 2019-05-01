USE [AcctDB]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[usp_ExecuteSSIS]
(
	@PackageName NVARCHAR(100),
	@FileName NVARCHAR(100),
	@ReturnCode INT OUTPUT
)
AS
BEGIN	 
	Declare @cmd varchar(2000)
	select @cmd = 'DTEXEC /sq "' + @PackageName + '" /ser deafsql ' + '/set \package.variables[User::FileName].Value;' + @FileName --'DTExec /F "' + @FilePath + @Filename + '"' 	
	-- select @cmd
	EXEC @ReturnCode = master..xp_cmdshell @cmd	
END
GO


