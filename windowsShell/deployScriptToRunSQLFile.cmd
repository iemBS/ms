echo off

Call ServerInfo.cmd
cls
echo on

echo ============== Begin deployment scripts =======================
echo ============== Begin deployment scripts =======================> Deployment.log

echo Executing the script Setup_Script.sql ...>> Deployment.log
SQLCMD /E /S%SQLServerName% /i  Setup_Script.sql >> Deployment.log
echo Completed execution of script Setup_Script.sql ...>> Deployment.Log

echo Executing the script vw_Email_Map_RoleAlias_US_EPG_PS.sql ...>> Deployment.log
SQLCMD /E /S%SQLServerName% /i  vw_Email_Map_RoleAlias_US_EPG_PS.sql >> Deployment.log
echo Completed execution of script vw_Email_Map_RoleAlias_US_EPG_PS.sql ...>> Deployment.Log

echo Executing the script update.sql ...>> Deployment.log
SQLCMD /E /S%SQLServerName% /i  update.sql >> Deployment.log
echo Completed execution of script update.sql ...>> Deployment.Log

echo Executing the script sp_DealFactoryReportData_US_Load.sql ...>> Deployment.log
SQLCMD /E /S%SQLServerName% /i  sp_DealFactoryReportData_US_Load.sql >> Deployment.log
echo Completed execution of script sp_DealFactoryReportData_US_Load.sql ...>> Deployment.Log

echo Executing the script sp_Email_EmailData_US_load.sql ...>> Deployment.log
SQLCMD /E /S%SQLServerName% /i  sp_Email_EmailData_US_load.sql >> Deployment.log
echo Completed execution of script sp_Email_EmailData_US_load.sql ...>> Deployment.Log

echo Executing the script sp_Email_Step2_US_EPG_PS.sql ...>> Deployment.log
SQLCMD /E /S%SQLServerName% /i  sp_Email_Step2_US_EPG_PS.sql >> Deployment.log
echo Completed execution of script sp_Email_Step2_US_EPG_PS.sql ...>> Deployment.Log

echo Executing the script sp_Email_Step2_US.sql ...>> Deployment.log
SQLCMD /E /S%SQLServerName% /i  sp_Email_Step2_US.sql >> Deployment.log
echo Completed execution of script sp_Email_Step2_US.sql ...>> Deployment.Log

echo ============== End  deployment scripts =======================
echo ============== End  deployment scripts =======================>> Deployment.log




echo off
cls

echo.
rem        =====================================================================
echo.
echo Deployment is Complete.
echo See Deployment.Log for information.
echo.
rem =====================================================================
echo on
