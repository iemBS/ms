If Exists(Select * From TempDB.Information_Schema.Tables Where Table_name = 'temp_sp_who2')
Begin
	Drop Table TempDB.dbo.temp_sp_who2
End
Go

CREATE TABLE TempDB.dbo.temp_sp_who2
    (
      SPID INT,
      Status VARCHAR(1000) NULL,
      Login SYSNAME NULL,
      HostName SYSNAME NULL,
      BlkBy SYSNAME NULL,
      DBName SYSNAME NULL,
      Command VARCHAR(1000) NULL,
      CPUTime INT NULL,
      DiskIO INT NULL,
      LastBatch VARCHAR(1000) NULL,
      ProgramName VARCHAR(1000) NULL,
      SPID2 INT, 
	  REQUESTID INT NULL
    )
Go

INSERT INTO 
	tempdb.dbo.temp_sp_who2
EXEC sp_who2
Go

SELECT 
	SPID,
	Login,
	HostName,
	CPUTime As Usage,
	'CPUTime' As Usagetype
Into 
	#temp_sp_who2
FROM    
	TempDB.dbo.temp_sp_who2
Where
	Login != 'sa'
	And 
	Len(CPUTime) > 5

Union All 

SELECT 
	SPID,
	Login,
	HostName,
	DiskIO As Usage,
	'DiskIO' As Usagetype
FROM    
	TempDB.dbo.temp_sp_who2
Where 
	Login != 'sa'
	And 
	Len(DiskIO) > 6 

Declare @EmailBody Varchar(1000)

Select
	@EmailBody = 
	'<p>' + 
	'SPID: ' + Cast(t2.SPID As Varchar) + 
	', Login: ' + t2.Login + 
	', HostName: ' + t2.HostName + 
	' ,' + t2.UsageType + ': ' + Cast(t2.Usage As Varchar) + 
	'</p>'
From
	(
		Select
			SPID,
			Login,
			HostName,
			Max(Usage) As Usage
		From
			#temp_sp_who2
		Where
			Login != 'sa'
		Group By
			SPID,
			Login,
			HostName
	) t
	Inner Join #temp_sp_who2 t2 On 
		t.Login = t2.Login
		And
		t.HostName = t2.HostName
		And
		t.Usage = t2.Usage 

Declare @EmailSubject Nvarchar(200)
Select @EmailSubject = 'Someone is running an intensive query on AcctDB.'

exec msdb.dbo.sp_send_dbmail 
	@recipients = 'johnd@hotmail.com'
	,@body = @EmailBody
	,@subject = @EmailSubject
	,@body_format = 'HTML'
	,@profile_name = 'Publish - Email Notification Profile';
Go
