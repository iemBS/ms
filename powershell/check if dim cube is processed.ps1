[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.AnalysisServices")>$NULL
$server = New-Object Microsoft.AnalysisServices.Server
$server.connect("ccgPublishes")
$db=$server.databases["OneCube"] # test value: $db|select-object name
$cubes=New-object Microsoft.AnalysisServices.Cube
$cubes=$db.cubes # test value: $cube|select-object Name
$cube=$cubes|select-object name,state,lastprocessed |where-object Name -eq "OneCube" # where filters must exist in select
   
$state = $cube|select state  # test values: $cube|select name,state,lastprocessed
if($state.state -eq "Processed"){
  Write-Host "cube accessible!"
}else{
  Write-Host "cube NOT accessible!"
}

$processTime = ($cube|select lastprocessed).lastprocessed
$processDate = Get-Date($processTime.Month.ToString() + "/" + $processTime.Day.ToString() + "/" + $processTime.Year.ToString() + " 00:00:00")
$today = Get-Date
$todaysDate =  Get-Date($today.Month.ToString() + "/" + $today.Day.ToString() + "/" + $today.Year.ToString() + " 00:00:00")
if($processDate -eq $todaysDate){
  Write-Host "cube has been processed today!"
}else{
  Write-Host "cube has NOT been processed today!"
}

