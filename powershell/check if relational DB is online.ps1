$loadStatus = [System.Reflection.Assembly]::Load("Microsoft.SqlServer.Smo,Version=11.0.0.0,Culture=neutral,PublicKeyToken=89845dcd8080cc91")

$sqlConnStr = "Data Source=oiPubVmWu2;Initial Catalog=ccgDataMart;Integrated Security=SSPI;"
$sqlConn = New-Object System.Data.SqlClient.SqlConnection $sqlConnStr

$sqlCmd = New-Object System.Data.SqlClient.SqlCommand
$sqlcmd.Connection = $sqlConn

$query = “select state_desc from sys.databases Where [name] = 'ccgDataMart'”
$sqlcmd.CommandText = $query

$adp = New-Object System.Data.SqlClient.SqlDataAdapter $sqlcmd

$data = New-Object System.Data.DataSet
$adp.Fill($data) | Out-Null

$dbState = $data.Tables[0].state_desc

if($dbState -eq "ONLINE"){
  Write-Host "DB is available!"
}else{
  Write-Error "DB is not available!"  -EA Stop
}