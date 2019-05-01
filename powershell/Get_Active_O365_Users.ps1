$cred = Get-Credential
Import-Module MSOnline
Connect-MsolService -Credential $cred
Get-MsolUser | where-object {$_.BlockCredential -eq $false -and $_.IsLicensed -eq $true} | select DisplayName | Export-CSV ./Get_Active_O365_Users.csv
