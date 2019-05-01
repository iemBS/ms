echo off


cls
echo on

echo ============== Begin scripts =======================
echo ============== Begin scripts =======================>> run_AnnuityEmail.log

echo Executing the script Setup_Script.sql ...>> run_AnnuityEmail.log
SQLCMD /Q "exec EAF.dbo.sp_EPG_MMDDYYYY_load" /E /SDannuity /dEATDW >> run_AnnuityEmail.log
echo Completed execution of script Setup_Script.sql ...>> run_AnnuityEmail.Log

echo ============== End  scripts =======================
echo ============== End  scripts =======================>> run_AnnuityEmail.log




echo off
cls

echo.
rem        =====================================================================
echo.
echo execution is Complete.
echo See run_AnnuityEmail.log for information.
echo.
rem =====================================================================
echo on
