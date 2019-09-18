USE [AcctDBsqlerrordb]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_senderroremail]
	@AcctDBlogid int
	,@emailtypename varchar(50)
AS
BEGIN
	SET NOCOUNT ON;

	declare @errormessage varchar(1000)

	if @emailtypename = 'AcctDB Inbound Error'
	begin
		select
			@errormessage = '<p>' + 
			'<b>Database Name:</b> ' + e.databasename + '<br>' + 
			'<b>Component Type</b>: ' + c.componenttypename + '<br>' + 
			'<b>Component Name:</b>' + e.componentname + '<br>' + 
			'<b>Error Message:</b> ' + e.errormessage + '<br>' + 
			'<b>Log Time:</b> ' + cast(e.logtime as varchar(19)) + '<br>' + 
			'<b>Logged By:</b> ' + e.loggedby + '<p>'
		from
			AcctDBsqlerrordb.dbo.inbounderror e
			inner join AcctDBsqlerrordb.dbo.componenttype c on e.componenttypeid = c.componenttypeid
		where
			AcctDBlogid = @AcctDBlogid
	end
	if @emailtypename = 'AcctDB Extract Error'
	begin
		select
			@errormessage = '<p>' + 
			'<b>Database Name:</b> ' + e.databasename + '<br>' + 
			'<b>Component Type</b>: ' + c.componenttypename + '<br>' + 
			'<b>Component Name:</b>' + e.componentname + '<br>' + 
			'<b>Error Message:</b> ' + e.errormessage + '<br>' + 
			'<b>Log Time:</b> ' + cast(e.logtime as varchar(19)) + '<br>' + 
			'<b>Logged By:</b> ' + e.loggedby + '<p>'
		from
			AcctDBsqlerrordb.dbo.extracterror e
			inner join AcctDBsqlerrordb.dbo.componenttype c on e.componenttypeid = c.componenttypeid
		where
			AcctDBlogid = @AcctDBlogid
	end
	if @emailtypename = 'AcctDB Process Error'
	begin
		select
			@errormessage = '<p>' + 
			'<b>Database Name:</b> ' + e.databasename + '<br>' + 
			'<b>Component Type</b>: ' + c.componenttypename + '<br>' + 
			'<b>Component Name:</b>' + e.componentname + '<br>' + 
			'<b>Error Message:</b> ' + e.errormessage + '<br>' + 
			'<b>Log Time:</b> ' + cast(e.logtime as varchar(19)) + '<br>' + 
			'<b>Logged By:</b> ' + e.loggedby + '<p>'
		from
			AcctDBsqlerrordb.dbo.processerror e
			inner join AcctDBsqlerrordb.dbo.componenttype c on e.componenttypeid = c.componenttypeid
		where
			AcctDBlogid = @AcctDBlogid
	end
	if @emailtypename = 'AcctDB UI Error'
	begin
		select
			@errormessage = '<p>' + 
			'<b>Database Name:</b> ' + e.databasename + '<br>' + 
			'<b>Component Type</b>: ' + c.componenttypename + '<br>' + 
			'<b>Component Name:</b>' + e.componentname + '<br>' + 
			'<b>Error Message:</b> ' + e.errormessage + '<br>' + 
			'<b>Log Time:</b> ' + cast(e.logtime as varchar(19)) + '<br>' + 
			'<b>Logged By:</b> ' + e.loggedby + '<p>'
		from
			AcctDBsqlerrordb.dbo.uierror e
			inner join AcctDBsqlerrordb.dbo.componenttype c on e.componenttypeid = c.componenttypeid
		where
			AcctDBlogid = @AcctDBlogid
	end
	if @emailtypename = 'AcctDB Outound Error'
	begin
		select
			@errormessage = '<p>' + 
			'<b>Database Name:</b> ' + e.databasename + '<br>' + 
			'<b>Component Type</b>: ' + c.componenttypename + '<br>' + 
			'<b>Component Name:</b>' + e.componentname + '<br>' + 
			'<b>Error Message:</b> ' + e.errormessage + '<br>' + 
			'<b>Log Time:</b> ' + cast(e.logtime as varchar(19)) + '<br>' + 
			'<b>Logged By:</b> ' + e.loggedby + '<p>'
		from
			AcctDBsqlerrordb.dbo.outbounderror e
			inner join AcctDBsqlerrordb.dbo.componenttype c on e.componenttypeid = c.componenttypeid
		where
			AcctDBlogid = @AcctDBlogid
	end

	declare 
	@to varchar(200)
	,@cc varchar(200)
	,@bcc varchar(200)
	,@_body nvarchar(2000)
	,@_subject varchar(100)

	select
		@to = [to]
		,@cc = cc
		,@bcc = bcc
		,@_body = replace(body,'[error]',@errormessage)
		,@_subject = [subject]
	from
		AcctDBsqlerrordb.dbo.emailtype
	where
		emailtypename = @emailtypename

	exec msdb.dbo.sp_send_dbmail 
		@recipients = @to
		,@copy_recipients = @cc
		,@blind_copy_recipients = @bcc
		,@body = @_body
		,@subject = @_subject
		,@body_format = 'HTML'
		,@profile_name = 'AcctDB Contacts - Email Notification Profile';

END
