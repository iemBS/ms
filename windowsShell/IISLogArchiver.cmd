'Requirements

'  - install LogParser on the machine where this will be run (http://www.microsoft.com/download/en/details.aspx?displaylang=en&id=24659)
'  - run using login that has access on this machine
'  - run using login that has access to the SQL server where you are archiving the log
'  - run on a server that has SQL server installed if the log table is to be created automatically. This can run on a server without but the table needs to manually be created.
'

'Set variables

SetLocal
Set SQLServerName=Serpentor
Set SQLDatabaseName=IISLog
Set SQLDBConnectionString=Driver={SQL Server};Server=%SQLServerName%;Database=%SQLDatabaseName%;Trusted_Connection=yes;
Set GeneralLogPath=C:\inetpub\logs\LogFiles\

Echo Off

Cls

Echo On


echo ============== Start: Create archive database table if it does not exist =======================

SQLCMD /Q "If Not Exists(Select * From INFORMATION_SCHEMA.TABLES Where TABLE_NAME = 'IISLog_Serpentor') Begin Create Table IISLog_Serpentor ( [RequestDate] datetime,[RequestTimeInUTC] datetime,[ServerLogsGeneratedOn] varchar(50),[RequestActionType] varchar(50),[ActionTarget] varchar(255),[RequestQuery] varchar(2048),[ServerPortUsed] int,ClientUserName varchar(50),[ClientIPAddress] varchar(50),[ClientBrowserType] varchar(255),[HTTPorFTPStatusCode] int,[HTTPorFTPSubStatusCode] int,[WindowsStatusCode] int,[RequestDurationInMilliseconds] int,[PreviousSite] varchar(255),ArchiveDateTime datetime) End" /E /S110Consulting7 /dIISLog

echo ============== End: Create archive database table if it does not exist =======================

cd "C:\Program Files (x86)\Log Parser 2.2\"

echo ============== Start: Archive logs in W3SVC1 folder =======================

LogParser.exe -i:IISw3c "Select Date As [RequestDate],Time As [RequestTimeInUTC],s-ip As [ServerLogsGeneratedOn],cs-method As [RequestActionType],cs-uri-stem As [ActionTarget],cs-uri-query As [RequestQuery],s-port As [ServerPortUsed],cs-username As ClientUserName,c-ip As [ClientIPAddress],cs(User-Agent) As [ClientBrowserType],sc-status As [HTTPorFTPStatusCode],sc-substatus As [HTTPorFTPSubStatusCode],sc-win32-status As [WindowsStatusCode],time-taken As [RequestDurationInMilliseconds],cs(Referer) As [PreviousSite],TO_LOCALTIME(SYSTEM_TIMESTAMP()) Into IISLog_Serpentor From %GeneralLogPath%W3SVC1\u_ex*.log" -o:SQL -oConnString:"%SQLDBConnectionString%" -Recurse:-1 

echo ============== End: Archive logs in W3SVC1 folder =======================

echo ============== Start: Archive logs in W3SVC2 folder =======================

LogParser.exe -i:IISw3c "Select Date As [RequestDate],Time As [RequestTimeInUTC],s-ip As [ServerLogsGeneratedOn],cs-method As [RequestActionType],cs-uri-stem As [ActionTarget],cs-uri-query As [RequestQuery],s-port As [ServerPortUsed],cs-username As ClientUserName,c-ip As [ClientIPAddress],cs(User-Agent) As [ClientBrowserType],sc-status As [HTTPorFTPStatusCode],sc-substatus As [HTTPorFTPSubStatusCode],sc-win32-status As [WindowsStatusCode],time-taken As [RequestDurationInMilliseconds],cs(Referer) As [PreviousSite],TO_LOCALTIME(SYSTEM_TIMESTAMP()) Into IISLog_Serpentor From C:\inetpub\logs\LogFiles\W3SVC2\u_ex*.log" -o:SQL -oConnString:"Driver={SQL Server};Server=110Consulting7;Database=IISLog;Trusted_Connection=yes;" -Recurse:-1 

echo ============== End: Archive logs in W3SVC2 folder =======================

echo ============== Start: Archive logs in W3SVC3 folder =======================

LogParser.exe -i:IISw3c "Select Date As [RequestDate],Time As [RequestTimeInUTC],s-ip As [ServerLogsGeneratedOn],cs-method As [RequestActionType],cs-uri-stem As [ActionTarget],cs-uri-query As [RequestQuery],s-port As [ServerPortUsed],cs-username As ClientUserName,c-ip As [ClientIPAddress],cs(User-Agent) As [ClientBrowserType],sc-status As [HTTPorFTPStatusCode],sc-substatus As [HTTPorFTPSubStatusCode],sc-win32-status As [WindowsStatusCode],time-taken As [RequestDurationInMilliseconds],cs(Referer) As [PreviousSite],TO_LOCALTIME(SYSTEM_TIMESTAMP()) Into IISLog_Serpentor From C:\inetpub\logs\LogFiles\W3SVC3\u_ex*.log" -o:SQL -oConnString:"Driver={SQL Server};Server=110Consulting7;Database=IISLog;Trusted_Connection=yes;" -Recurse:-1 

echo ============== End: Archive logs in W3SVC3 folder =======================

echo ============== Start: Archive logs in W3SVC4 folder =======================

LogParser.exe -i:IISw3c "Select Date As [RequestDate],Time As [RequestTimeInUTC],s-ip As [ServerLogsGeneratedOn],cs-method As [RequestActionType],cs-uri-stem As [ActionTarget],cs-uri-query As [RequestQuery],s-port As [ServerPortUsed],cs-username As ClientUserName,c-ip As [ClientIPAddress],cs(User-Agent) As [ClientBrowserType],sc-status As [HTTPorFTPStatusCode],sc-substatus As [HTTPorFTPSubStatusCode],sc-win32-status As [WindowsStatusCode],time-taken As [RequestDurationInMilliseconds],cs(Referer) As [PreviousSite],TO_LOCALTIME(SYSTEM_TIMESTAMP()) Into IISLog_Serpentor From C:\inetpub\logs\LogFiles\W3SVC4\u_ex*.log" -o:SQL -oConnString:"Driver={SQL Server};Server=110Consulting7;Database=IISLog;Trusted_Connection=yes;" -Recurse:-1 

echo ============== End: Archive logs in W3SVC4 folder =======================
