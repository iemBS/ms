Echo Off

'Call IISLogArchiver.Config
Cls

Echo On

echo ============== Start: Archive logs in W3SVC1 folder =======================
echo ============== Start: Archive logs in W3SVC1 folder =======================> IISLogArchiver.log

LogParser.exe 
	-i:IISw3c 
		"
			Select 
				date As [RequestDate]
				,time As [RequestTimeInUTC]
				,s-ip As [ServerLogsGeneratedOn]
				,cs-method As [RequestActionType]
				,cs-uri_stem [ActionTarget]
				,cs-uri-query As [RequestQuery]
				,s-port As [ServerPortUsed]
				,cs-username As ClientUserName
				,c-ip As [ClientIPAddress]
				,cs(User-Agent) As [ClientBrowserType]
				,sc-status As [HTTPorFTPStatusCode]
				,sc-substatus As [HTTPorFTPSubStatusCode]
				,sc-win32-status As [WindowsStatusCode]
				,time-taken As [RequestDurationInMilliseconds]
				,cs(Referer) As [PreviousSite]
			From
				C:\inetpub\logs\LogFiles\W3SVC1\u_ex*.log 
		" 
	-o:SQL 
	-oConnString: 
		"Driver={SQL Server Native Client 10.0};Server=110Consulting7; Database=IISLog; Trusted_Connection=yes;" 

echo ============== End: Archive logs in W3SVC1 folder =======================
echo ============== End: Archive logs in W3SVC1 folder =======================> IISLogArchiver.log



echo off
cls

echo.
rem =====================================================================
echo.
echo IIS Log archive complete
echo See IISLogArchiver.Log for information.
echo.
rem =====================================================================
echo on