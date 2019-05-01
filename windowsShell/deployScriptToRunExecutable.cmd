echo off


cls
echo on

echo ============== Begin scripts =======================
echo ============== Begin scripts =======================>> run_AnnuityEmail.log


echo Executing AnnuityEmail.exe "Proactive-Step1-CurrentQTR" "SubRegion" "TEST" "EPG" on %date% at %time% ...>> run_AnnuityEmail.log
AnnuityEmail.exe "Proactive-Step1-CurrentQTR" "SubRegion" "TEST" "EPG" >> run_AnnuityEmail.log
echo Completed execution of AnnuityEmail.exe "Proactive-Step1-CurrentQTR" "SubRegion" "TEST" "EPG" on %date% at %time% ...>> run_AnnuityEmail.log

echo Executing AnnuityEmail.exe "Proactive-Step2-CurrentQTR" "SubRegion" "TEST" "EPG" on %date% at %time% ...>> run_AnnuityEmail.log
AnnuityEmail.exe "Proactive-Step2-CurrentQTR" "SubRegion" "TEST" "EPG" >> run_AnnuityEmail.log
echo Completed execution of AnnuityEmail.exe "Proactive-Step2-CurrentQTR" "SubRegion" "TEST" "EPG" on %date% at %time% ...>> run_AnnuityEmail.log

echo Executing AnnuityEmail.exe "Proactive-Step3-CurrentQTR" "ATU" "TEST" "EPG" on %date% at %time% ...>> run_AnnuityEmail.log
AnnuityEmail.exe "Proactive-Step3-CurrentQTR" "ATU" "TEST" "EPG" >> run_AnnuityEmail.log
echo Completed execution of AnnuityEmail.exe "Proactive-Step3-CurrentQTR" "ATU" "TEST" "EPG" on %date% at %time% ...>> run_AnnuityEmail.log

echo Executing AnnuityEmail.exe "Proactive-Step4-T18" "AcctMgr" "TEST" "EPG" on %date% at %time% ...>> run_AnnuityEmail.log
AnnuityEmail.exe "Proactive-Step4-T18" "AcctMgr" "TEST" "EPG" >> run_AnnuityEmail.log
echo Completed execution of AnnuityEmail.exe "Proactive-Step4-T18" "AcctMgr" "TEST" "EPG" on %date% at %time% ...>> run_AnnuityEmail.log

echo Executing AnnuityEmail.exe "Proactive-Step5-T9" "AcctMgr" "TEST" "EPG" on %date% at %time% ...>> run_AnnuityEmail.log
AnnuityEmail.exe "Proactive-Step5-T9" "AcctMgr" "TEST" "EPG" >> run_AnnuityEmail.log
echo Completed execution of AnnuityEmail.exe "Proactive-Step5-T9" "AcctMgr" "TEST" "EPG" on %date% at %time% ...>> run_AnnuityEmail.log

echo Executing AnnuityEmail.exe "Proactive-Step6-T3" "AcctMgr" "TEST" "EPG" on %date% at %time% ...>> run_AnnuityEmail.log
AnnuityEmail.exe "Proactive-Step6-T3" "AcctMgr" "TEST" "EPG" >> run_AnnuityEmail.log
echo Completed execution of AnnuityEmail.exe "Proactive-Step6-T3" "AcctMgr" "TEST" "EPG" on %date% at %time% ...>> run_AnnuityEmail.log

echo Executing AnnuityEmail.exe "Reactive-Step7-OnTime" "AcctMgr" "TEST" "EPG" on %date% at %time% ...>> run_AnnuityEmail.log
AnnuityEmail.exe "Reactive-Step7-OnTime" "AcctMgr" "TEST" "EPG" >> run_AnnuityEmail.log
echo Completed execution of AnnuityEmail.exe "Reactive-Step7-OnTime" "AcctMgr" "TEST" "EPG" on %date% at %time% ...>> run_AnnuityEmail.log

echo Executing AnnuityEmail.exe "Reactive-Step8-PastDue" "AcctMgr" "TEST" "EPG" on %date% at %time% ...>> run_AnnuityEmail.log
AnnuityEmail.exe "Reactive-Step8-PastDue" "AcctMgr" "TEST" "EPG" >> run_AnnuityEmail.log
echo Completed execution of AnnuityEmail.exe "Reactive-Step8-PastDue" "AcctMgr" "TEST" "EPG" on %date% at %time% ...>> run_AnnuityEmail.log

echo Executing AnnuityEmail.exe "Reactive-Step9-Lost" "AcctMgr" "TEST" "EPG" on %date% at %time% ...>> run_AnnuityEmail.log
AnnuityEmail.exe "Reactive-Step9-Lost" "AcctMgr" "TEST" "EPG" >> run_AnnuityEmail.log
echo Completed execution of AnnuityEmail.exe "Reactive-Step9-Lost" "AcctMgr" "TEST" "EPG" on %date% at %time% ...>> run_AnnuityEmail.log

echo Executing AnnuityEmail.exe "Proactive-Step2-CurrentQTR" "SubRegion" "TEST" "SMS&P" on %date% at %time% ...>> run_AnnuityEmail.log
AnnuityEmail.exe "Proactive-Step2-CurrentQTR" "SubRegion" "TEST" "SMS&P" >> run_AnnuityEmail.log
echo Completed execution of AnnuityEmail.exe "Proactive-Step2-CurrentQTR" "SubRegion" "TEST" "SMS&P" on %date% at %time% ...>> run_AnnuityEmail.log

echo Executing AnnuityEmail.exe "Proactive-Step2-CurrentQtr-US" "District" "TEST" "EPG" on %date% at %time% ...>> run_AnnuityEmail.log
AnnuityEmail.exe "Proactive-Step2-CurrentQtr-US" "District" "TEST" "EPG" >> run_AnnuityEmail.log
echo Completed execution of AnnuityEmail.exe "Proactive-Step2-CurrentQtr-US" "District" "TEST" "EPG" on %date% at %time% ...>> run_AnnuityEmail.log

echo Executing AnnuityEmail.exe "Proactive-Step3-CurrentQtr-US" "ATU" "TEST" "EPG" on %date% at %time% ...>> run_AnnuityEmail.log
AnnuityEmail.exe "Proactive-Step3-CurrentQtr-US" "ATU" "TEST" "EPG" >> run_AnnuityEmail.log
echo Completed execution of AnnuityEmail.exe "Proactive-Step3-CurrentQtr-US" "ATU" "TEST" "EPG" on %date% at %time% ...>> run_AnnuityEmail.log


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
