echo off


cls
echo on

echo ============== Begin scripts =======================
echo ============== Begin scripts =======================>> c:\scopeQuery\scope.log

echo Executing cd.exe c:\scopeQuery on %date% at %time% ...>> c:\scopeQuery\scope.log
cd.exe c:\scopeQuery  >> c:\scopeQuery\scope.log
echo Completed execution of Executing cd.exe c:\scopeQuery  on %date% at %time% ...>> c:\scopeQuery\scope.log

echo Executing powershell.exe -NoP -NonI -Command "Expand-Archive '.\ScopeSDK.zip' '.\ScopeSDK\'" on %date% at %time% ...>> c:\scopeQuery\scope.log
powershell.exe -NoP -NonI -Command "Expand-Archive '.\ScopeSDK.zip' '.\ScopeSDK\'" ...>> c:\scopeQuery\scope.log
echo Completed execution of powershell.exe -NoP -NonI -Command "Expand-Archive '.\ScopeSDK.zip' '.\ScopeSDK\'" on %date% at %time% ...>> c:\scopeQuery\scope.log
echo ============== End  scripts =======================
echo ============== End  scripts =======================>> c:\scopeQuery\scope.log




echo off
cls

echo.
rem        =====================================================================
echo.
echo execution is Complete.
echo See scope.log for information.
echo.
rem =====================================================================
echo on
