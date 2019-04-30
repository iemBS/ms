# Variables
$SSISNamespace = "Microsoft.SqlServer.Management.IntegrationServices"
$TargetServerName = "oiEtlVmWu2Uat"
$TargetFolderName = "CCGBI"
$DownloadFolder = "D:\CDS_Traceability_Matrix\ispac\"
[bool]$isTest=0 # 1-enables testing, 0-disables testing
[bool]$hasSQL=1 # 1-enables SQL to run, 0-disables SQL

# Load the IntegrationServices assembly
$loadStatus = [System.Reflection.Assembly]::Load("Microsoft.SQLServer.Management.IntegrationServices, "+
    "Version=14.0.0.0, Culture=neutral, PublicKeyToken=89845dcd8080cc91, processorArchitecture=MSIL")

# Load the Compression assembly
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
$loadStatus = [System.Reflection.Assembly]::LoadWithPartialName("System.IO.Compression")

# Create a connection to the server
$sqlConnectionString = "Data Source=" + $TargetServerName + ";Initial Catalog=master;Integrated Security=SSPI;"
$sqlConnection = New-Object System.Data.SqlClient.SqlConnection $sqlConnectionString

# Create the Integration Services object
$integrationServices = New-Object $SSISNamespace".IntegrationServices" $sqlConnection

# Get the Integration Services catalog
$catalog = $integrationServices.Catalogs["SSISDB"]

# Get the folder
$folder = $catalog.Folders[$TargetFolderName]

#remove extra space on SQL queries
function RemoveSpace {
	param(
		[string]$str
	)
	
	#replace tab characters with space characters
	$str = $str.Replace("`t", " ")
	
	#make two blank spaces one blank space
	$str = $str.Replace("  ", " ")
	
	#remove blank spaces on left and right of string
	$str = $str.trim()
	
	return $str
}#End RemoveSpace

#get DB Names
function GetDBNames {
	$selectQuery=" 
	With dbName_CTE As
	(
		Select
			[name] As db
		From
			sys.databases
		Where
			database_id > 4
	)
	Select db From dbName_CTE
	Union All
	select '['+db+']' From dbName_CTE"

	Invoke-SQLcmd -ServerInstance 'oiEtlVmWu2Uat,1433' -query $selectQuery -Database tempdb  
}#End GetDBNames

#Create SQL table to collecting the mappings
function CreateSQLTable {
	$createquery=" 
	Use [CDS_Traceability_Matrix]
	Go
	  if Exists(Select * From Information_Schema.Tables Where Table_Schema = 'dbo' And Table_Name = 'auto_data_map_from_SSIS')
	  Begin
		 Drop table [dbo].[auto_data_map_from_SSIS] 
	  End

	  create table [dbo].[auto_data_map_from_SSIS] 
	  (
		 child varchar(max),
		 parent varchar(max),
		 childType varchar(50),
		 parentType varchar(50)
	  )
	  GO" 

	Invoke-SQLcmd -ServerInstance 'oiEtlVmWu2Dev1,1433' -query $createquery -Database CDS_Traceability_Matrix  
}#End CreateSQLTable

#Create SQL table
if($hasSQL){CreateSQLTable}

function InsertIntoSQLTable {
	param
	(
	[string]$child,[string]$parent,[string]$childType,[string]$parentType
	)

	$insertquery=" 
	Use [CDS_Traceability_Matrix]
	Go
	  if Not Exists(Select * From Information_Schema.Tables Where Table_Schema = 'dbo' And Table_Name = 'auto_data_map_from_SSIS')
	  Begin
		 Drop table [dbo].[auto_data_map_from_SSIS] 
	  End

	  INSERT INTO 
		 [dbo].[auto_data_map_from_SSIS] 
		 (
			child,
			parent,
			childType,
			parentType
		 ) 
	  VALUES 
		 (
			'$child'
			,'$parent' 
			,'$childType'
			,'$parentType'
		 ) 
	  GO" 

	Invoke-SQLcmd -ServerInstance 'oiEtlVmWu2Dev1,1433' -query $insertquery -Database CDS_Traceability_Matrix  
} #End InsertIntoSQLTable

# go through projects in folder
$projects = $folder.Projects
foreach ($project in $projects) {
	# collect details for a single project
	# download ispac file for project
	$ispac = $project.GetProjectBytes()
	[System.IO.File]::WriteAllBytes(($DownloadFolder + "\" + $project.Name + ".ispac"),$ispac)
	# delete unzipped ispac file if it already exists
	if (Test-Path ($DownloadFolder + "\" + $project.Name))
	{
		[System.IO.Directory]::Delete(($DownloadFolder + "\" + $project.Name), $true)
	}
	# unzip ispac file
	[io.compression.zipfile]::ExtractToDirectory(($DownloadFolder + "\" + $project.Name + ".ispac"), ($DownloadFolder + "\" + $project.Name))
	# delete ispac because I have the unzipped ispac now
	[System.IO.File]::Delete(($DownloadFolder + "\" + $project.Name + ".ispac"))

  # get project level connections in project #todo: put function outside of loop
  function GetProjectLevelConnections {
		param
		(
		[string]$projectName
		)

		$projectManifestFilePath = -join($DownloadFolder,"\",$projectName,"\@Project.manifest")
		[xml]$projectManifestXml = get-content $projectManifestFilePath
		$ns = [System.Xml.XmlNamespaceManager]($projectManifestXml.NameTable)
		$ns.AddNamespace("SSIS", "www.microsoft.com/SqlServer/SSIS")
		$ns.AddNamespace("DTS", "www.microsoft.com/SqlServer/Dts")

		$connectionManagerFiles = $projectManifestXml.SelectNodes("//SSIS:ConnectionManager", $ns)
		
		#Remove variable to create a new list of project level connections for each project
		if($GetProjectLevelConnections_return) {
		  Remove-Variable $GetProjectLevelConnections_return
		} #End if
		
		#create new list to collect the connections
		$GetProjectLevelConnections_return = New-Object System.Collections.Generic.List[System.Object]

		foreach ($connectionManagerFile in $connectionManagerFiles) {
		  $connectionManagerFilePath = -join($DownloadFolder,"\",$projectName,"\",$connectionManagerFile.Name.Replace(" ","%20"))
		  if (!(Test-Path $connectionManagerFilePath)) {
		    Write-Host "***GetProjectLevelConnections function: file does not exist " $connectionManagerFilePath 
		  }
		  [xml]$connectionManagerXml = get-content $connectionManagerFilePath
		  $creationName = $connectionManagerXml.SelectNodes("/DTS:ConnectionManager",$ns)[0].CreationName
		  $dtsid = $connectionManagerXml.SelectNodes("/DTS:ConnectionManager",$ns)[0].DTSID
		  $connectionManagerName = $connectionManagerXml.SelectNodes("/DTS:ConnectionManager",$ns)[0].ObjectName
		  $connectionManager = $connectionManagerXml.SelectNodes("//DTS:ObjectData/DTS:ConnectionManager", $ns)[0]
		  $connectionString = $connectionManager.ConnectionString.split(";")
			  
		  if($creationName -eq 'OLEDB') {
			$server = $connectionString[0].Replace("Data Source=","")
			$db = $connectionString[1].Replace("Initial Catalog=","")
			if($isTest){Write-Host "GetProjectLevelConnections function a: " $connectionManagerName}
			if($isTest){Write-Host "GetProjectLevelConnections function b: " $creationName}
			if($isTest){Write-Host "GetProjectLevelConnections function c: " $server}
			if($isTest){Write-Host "GetProjectLevelConnections function d: " $db}
			if($isTest){Write-Host "GetProjectLevelConnections function e: " $dtsid}
			
			$connectionElement = New-Object System.Collections.Generic.List[System.Object]
			$connectionElement.Add($connectionManagerName)
			$connectionElement.Add($creationName)
			$connectionElement.Add($server)
			$connectionElement.Add($db)
			$connectionElement.Add($dtsid)
			$GetProjectLevelConnections_return.Add($connectionElement)
		  }#End if
		  elseif($creationName -eq 'EXCEL'){
			$fullFilePath = $connectionString[1].Replace("Data Source=","").ToLower().Replace("localhost","oiEtlVmWu2")
			$connectionStringParts = $fullFilePath.split("\")
			$file = $connectionStringParts[$connectionStringParts.Count - 1]
			$filePath = $fullFilePath.Replace($file,"") 
			
			if($isTest){Write-Host "GetProjectLevelConnections function a: " $connectionManagerName}
			if($isTest){Write-Host "GetProjectLevelConnections function b: " $creationName}
			if($isTest){Write-Host "GetProjectLevelConnections function c: " $filePath}
			if($isTest){Write-Host "GetProjectLevelConnections function d: " $file}
			if($isTest){Write-Host "GetProjectLevelConnections function e: " $dtsid}
			
			$connectionElement = New-Object System.Collections.Generic.List[System.Object]	
			$connectionElement.Add($connectionManagerName)
			$connectionElement.Add($creationName)
			$connectionElement.Add($filePath)
			$connectionElement.Add($file)
			$connectionElement.Add($dtsid)
			$GetProjectLevelConnections_return.Add($connectionElement)
		  }#End elseif
		  elseif($creationName -eq 'FLATFILE'){
		   if($isTest){Write-Host "GetProjectLevelConnections function: connection string part count for FLATFILE type " $connectionString.Count}
		   
			$fullFilePath = $connectionString[0].Replace("Data Source=","").ToLower().Replace("localhost","oiEtlVmWu2")
			$connectionStringParts = $fullFilePath.split("\")
			$file = $connectionStringParts[$connectionStringParts.Count - 1]
			$filePath = $fullFilePath.Replace($file,"") 
			if($isTest){Write-Host "GetProjectLevelConnections function a: " $connectionManagerName}
			if($isTest){Write-Host "GetProjectLevelConnections function b: " $creationName}
			if($isTest){Write-Host "GetProjectLevelConnections function c: " $filePath}
			if($isTest){Write-Host "GetProjectLevelConnections function d: " $file}
			if($isTest){Write-Host "GetProjectLevelConnections function e: " $dtsid}
			$connectionElement = New-Object System.Collections.Generic.List[System.Object]	
			$connectionElement.Add($connectionManagerName)
			$connectionElement.Add($creationName)
			$connectionElement.Add($filePath)
			$connectionElement.Add($file)
			$connectionElement.Add($dtsid)
			$GetProjectLevelConnections_return.Add($connectionElement)  
		  }#End elseif
		  else {
		    Write-Host "***GetProjectLevelConnections function: has invalid creationName " $creationName
		  } #End else
		} #End foreach
		
		  if($isTest){
			  foreach($a in $GetProjectLevelConnections_return) {
			    $b = -join($a[0],"|",$a[1],"|",$a[2],"|",$a[3],"|",$a[4])
			    Write-Host "connections variable elements in GetProjectLevelConnections function: " $b
			  }
		  }

		return $GetProjectLevelConnections_return
  }#End GetProjectLevelConnections

  $connections = GetProjectLevelConnections $project.Name
  
	# get package level connection   #todo: put function outside of loop
   function GetPackageLevelConnection {
  	param
  		(
  		[xml]$packageXml,[string]$dtsid
  		)
  		
		  $connectionManagers = $packageXml.SelectNodes(".//DTS:ConnectionManagers/DTS:ConnectionManager", $ns)
		  $packagelLevelCreationName = ""
		  $connectionString = ""
		  foreach($connectionManager in $connectionManagers){
		    if($connectionManager.DTSID -eq $dtsid -OR $connectionManager.refId -eq $dtsid) {
		      $packagelLevelCreationName = $connectionManager.CreationName 
		      $connectionString = $connectionManager.SelectNodes(".//DTS:ObjectData/DTS:ConnectionManager",$ns)[0].ConnectionString.split(";")
		    }#End if
		  }#End foreach
		  
		  if($isTest){Write-Host "GetPackageLevelConnection function: connection type from attribute " $packagelLevelCreationName}
		  if($isTest){Write-Host "GetPackageLevelConnection function: dtsid passed in " $dtsid}
		  if($isTest){
		  	foreach($part in $connectionString){
		  	  Write-Host "GetPackageLevelConnection function: connection string part from attribute " $part
		  	}
		  }
		  
		  if($packagelLevelCreationName -eq 'OLEDB') {
			$server = $connectionString[0].Replace("Data Source=","")
			$db = $connectionString[1].Replace("Initial Catalog=","")
			$GetPackageLevelConnection_return = @($connectionManagerName,$packagelLevelCreationName,$server,$db,$dtsid)
		  }#End if
		  elseif($packagelLevelCreationName -eq 'EXCEL'){
			$fullFilePath = $connectionString[1].Replace("Data Source=","").ToLower().Replace("localhost","oiEtlVmWu2")
			$connectionStringParts = $fullFilePath.split("\")
			$file = $connectionStringParts[$connectionStringParts.Count - 1]
			$filePath = $fullFilePath.Replace($file,"") 
			$GetPackageLevelConnection_return = @($connectionManagerName,$packagelLevelCreationName,$filePath,$file,$dtsid)
		  }#End elseif
		  elseif($packagelLevelCreationName -eq 'FLATFILE'){
			$fullFilePath = $connectionString[0].ToLower().Replace("localhost","oiEtlVmWu2")
			$connectionStringParts = $fullFilePath.split("\")
			$file = $connectionStringParts[$connectionStringParts.Count - 1]
			$filePath = $fullFilePath.Replace($file,"") 
			$GetPackageLevelConnection_return = @($connectionManagerName,$packagelLevelCreationName,$filePath,$file,$dtsid) 
		  }#End elseif
		  elseif($packagelLevelCreationName -eq ''){
		  	Write-Host "GetPackageLevelConnection function: connection does not exist in package" 
		  	$GetPackageLevelConnection_return = @("not exist",$packagelLevelCreationName,"not exist","not exist",$dtsid)
		  }
		  else {
		    Write-Host "GetPackageLevelConnection function: Creation Name other than OLEDB, EXCEL, FLATFILE exists for a connection manager " $packagelLevelCreationName 
		    $GetPackageLevelConnection_return = @("unknown",$packagelLevelCreationName,"unknown","unknown",$dtsid)
		  } #End else
		  
 		if($isTest){Write-Host "GetPackageLevelConnection function: connection name "$GetPackageLevelConnection_return[0]}
 		if($isTest){Write-Host "GetPackageLevelConnection function: connection type "$GetPackageLevelConnection_return[1]}
 		if($isTest){Write-Host "GetPackageLevelConnection function: server or file path "$GetPackageLevelConnection_return[2]}
		if($isTest){Write-Host "GetPackageLevelConnection function: db or file "$GetPackageLevelConnection_return[3]}
  		
  		return $GetPackageLevelConnection_return
  }#End GetPackageLevelConnection
  
  #todo: put function outside of loop
  function DetermineConnection {
  		param
  		(
  		[xml]$packageXml,[string]$dtsid
  		)
  		
  		$DetermineConnection_return = @() #initialize so variable passes PowerShell validation
  		$dtsidClean = $dtsid.Replace(":external","")
  		
  		#search for connection at project level
		foreach($conn in $connections){
		  if($dtsidClean -eq $conn[4]) {
		    $DetermineConnection_return = $conn.ToArray()
		    break
		  } #End if
		}#End for
		
		#search for connection at package level if not found at project level
  		if($DetermineConnection_return.Count -eq 0) {
  		  $DetermineConnection_return = GetPackageLevelConnection $packageXml $dtsidClean
  		}#End if
  		
  		# remove invalid data connections
  		if($dtsid.split(":")[1] -eq "invalid") {
  		  $DetermineConnection_return = @("unknown","unknown","invalid server or file path","invalid db or file","unknown")
  		}#End if

  		return $DetermineConnection_return
  		
  }#End DetermineConnection
  
  function UpdateSQLObjectName {
  	param (
  		[string]$objectName
  	)
  	
  
  }#End UpdateSQLObjectName

  function UpdatePath {
		param
		(
		[string]$path,[string[]]$connection,[bool]$isFormattedSQLObject
		)
		
		if($isTest){Write-Host "UpdatePath function: connection name "$connection[0]}
		if($isTest){Write-Host "UpdatePath function: connection type "$connection[1]}
		if($isTest){Write-Host "UpdatePath function: server or file path "$connection[2]}
		if($isTest){Write-Host "UpdatePath function: db or file "$connection[3]}
		
		#get list of databases on the server
		$dbNames = @('ccgDataMart','ccgStage') #test: GetDBNames
		
		#see if DB name already specified
		if($connection[1] -eq 'OLEDB') {
			[bool]$hasDBName = 0
			foreach($dbName in $dbNames){
				if($path.IndexOf($dbName) -eq 0){
					$hasDBName = 1
					break
				}#End if
			}#End foreach
		}
				
		#update path
		if($connection[1] -eq 'OLEDB') {
		  # in CDS
		  if("ccgStage|ccgWarehouse|ccgDataMart|ccgOperations".IndexOf($connection[3],[System.StringComparison]::CurrentCultureIgnoreCase) -gt -1) {
		    #Know this is just a table/view
		  	 if($isFormattedSQLObject -eq 1) {
		      $UpdatePath_return = -join("[",$connection[3],"].",$path)
		    }
		    #Do not know if this is a table/view
		    else {
		    	if($hasDBName){
		    		$UpdatePath_return = -join("|QUERY START|",$path,"|QUERY END|")
		    	}#End if
		    	else {
		      	$UpdatePath_return = -join("[",$connection[3],"].","|QUERY START|",$path,"|QUERY END|")
		      }
		    }
       } #End if
       # not in CDS
       else{

		    #Know this is just a table/view
		    if($isFormattedSQLObject -eq 1) {
		      $UpdatePath_return = -join("[",$connection[2],"].[",$connection[3],"].",$path)
		    }
		    #Do not know if this is a table/view
		    else {
		    	if($hasDBName){
		    		$UpdatePath_return = -join("[",$connection[2],"].","|QUERY START|",$path,"|QUERY END|")
		    	}
		      else {
		      	$UpdatePath_return = -join("[",$connection[2],"].[",$connection[3],"].","|QUERY START|",$path,"|QUERY END|")
		      }
		    }
			} #End else
		} #End if
		elseif($connection[1] -eq 'EXCEL') {
		  $UpdatePath_return = -join("[",$connection[2],$connection[3],"\",$path,"]")
		} #End elseif
		elseif($connection[1] -eq 'FLATFILE') {
		  $UpdatePath_return = -join("[",$connection[2],$connection[3],"]")
		} #End elseif
		elseif($connection[1] -eq 'unknown') {
		  $UpdatePath_return = -join("[",$connection[3],"].","|QUERY START|",$path,"|QUERY END|")
		}
		elseif($connection[1] -eq 'not exist') {
		  $UpdatePath_return = -join("[",$connection[3],"].","|QUERY START|",$path,"|QUERY END|")
		}
		else {
		  Write-Host "***UpdatePath function: Cannot update type = " $connection[1] " ,connection called " $connection[0]
		  $UpdatePath_return = -join("[",$connection[3],"].","|QUERY START|",$path,"|QUERY END|")
		}#End else
		
		if($isTest){Write-Host "returned by UpdatePath function: " $UpdatePath_return}
		
		return [string]$UpdatePath_return

  } #End UpdatePath
 
 
  # go through packages in project
  foreach ($package in $project.Packages) {
    # collect details for a single package
    $packagePath = -join($DownloadFolder,"\",$project.Name,"\",$package.name.Replace(" ","%20"))
    [xml]$xml = get-content $packagePath
    $tasks = $xml
    $ns = [System.Xml.XmlNamespaceManager]($tasks.NameTable)
    $ns.AddNamespace("DTS", "www.microsoft.com/SqlServer/Dts")
    $ns.AddNameSpace("SQLTask","www.microsoft.com/sqlserver/dts/tasks/sqltask")

	# get package name
	$packageName = $tasks.SelectNodes("//DTS:Executable[@DTS:ExecutableType='Microsoft.Package']", $ns).ObjectName

	# get all data flow task executables that are in any number of containers
	$dataFlowTasks = $tasks.SelectNodes("//DTS:Executable[@DTS:ExecutableType='Microsoft.Pipeline']", $ns)

	# get all non-data flow executables that are in any number of containers
	$nonDataFlowTasks = $tasks.SelectNodes("//DTS:Executable[(@DTS:ExecutableType='Microsoft.ExecuteSQLTask' or @DTS:ExecutableType='Microsoft.ExecutePackageTask') and (@DTS:ObjectName!='Get IsDependenciesReady' and @DTS:ObjectName!='LogStatus DataNotReady' and @DTS:ObjectName!='LogStatus DependenciesNotReady' and @DTS:ObjectName!='LogStatus Running' and @DTS:ObjectName!='LogStatus Success' and @DTS:ObjectName!='LogStatus Failure 1' and @DTS:ObjectName!='LogStatus Failure 1 1' and @DTS:ObjectName!='Check Data Source Ready Semaphore' and @DTS:ObjectName!='LogStatus Failure' and substring(@DTS:ObjectName,0,8)!='TRUNCATE' and substring(@DTS:ObjectName,0,8)!='Truncate' and @DTS:ObjectName!='Return Dynamic Filters' and @DTS:ObjectName!='Return Static Filters')]", $ns)
	 
	function ShowTask {
	  param
	  (
	   [System.Xml.XmlNodeList]$paramTasks
	  )
	   # go through each task 
		foreach ($task in $paramTasks) {
		    #see if disabled attribute exists on task
		    if($task.Disabled -ne $null) {
		      # see if task disabled
		      if($task.Disabled -eq 'True') {
		        #skip disabled tasks
		        continue
		      } #End if
		    } #End if
		    		    
		    $isFormattedSQLObject = 0

		    if($task.ExecutableType -eq 'Microsoft.ExecuteSQLTask') {
		    
		    	$subTask = $task.SelectNodes(".//SQLTask:SqlTaskData", $ns)[0]
		    	$query = RemoveSpace $subTask.SqlStatementSource
		    	
		    	#skip execute tasks with truncate
		    	if(($query.substring(0,8) -ieq 'truncate') -OR ($query.substring($query.length-8,8) -ieq 'truncate')){
		    		continue 
		    	}#End if
		         
				#write child (SQL) and parent (SSIS task path) to screen
				$dtsid = $subTask.Connection
				$connection = DetermineConnection $tasks $dtsid
				$SQLPath = UpdatePath $query $connection $isFormattedSQLObject
				$SSISpath = -join("[",$task.refId,"]")
				$SSISpath = $SSISpath.Replace("[Package\",-join("[CCGBI\",$project.Name,"\",$packageName,".dtsx\")) 

				if($isTest){
					$test = -join($SQLPath,"~",$SSISpath,"~","SQL.table","~","SSIS.package.task")
					Write-Host $test
				}#End if

				if($hasSQL){InsertIntoSQLTable $SQLPath $SSISpath "SQL.table" "SSIS.package.task"}

		      continue # get next executable 
		    } #End if

		    if($task.ExecutableType -eq 'Microsoft.ExecutePackageTask') {
		      $subTask = $task.SelectNodes(".//PackageName", $ns) 
		      
		      #write child (SSIS package) and parent (SSIS task path) to screen
		      $childPackage = -join("[CCGBI\",$project.Name,"\",$subTask.InnerXml,"]") #assume child package is in same SSIS project as parent package
				$SSISpath = -join("[",$task.refId,"]")
				$SSISpath = $SSISpath.Replace("[Package\",-join("[CCGBI\",$project.Name,"\",$packageName,".dtsx\")) 
		      
		      if($isTest){
		      	$test = -join($childPackage,"~",$SSISpath,"~","SSIS.package","~","SSIS.package.task")
		      	Write-Host $test
		      }
		      
		      if($hasSQL){InsertIntoSQLTable $childPackage $SSISpath "SSIS.package" "SSIS.package.task"}
		      continue # get next executable 
		    } #End if	 

		    if($task.ExecutableType -eq 'Microsoft.Pipeline') {
		      # note distinct list of component types that exist in data flow tasks 
		      	#todo
		      	
		      # Only get components for executable with sources and destinations
		      $components = $task.SelectNodes(".//component[@componentClassID='Microsoft.OLEDBSource' or @componentClassID='Microsoft.ExcelSource' or @componentClassID='Microsoft.FlatFileSource' or @componentClassID='Microsoft.OLEDBDestination']", $ns)
		      
		      if($components.Count -eq 0) {
		        continue # Components without a source and destination are skipped. Components like: Microsoft.DerivedColumn,Microsoft.Lookup, Microsoft.ConditionalSplit
		      }
		      
		      # loop through all components in data flow task 
		      foreach($component In $components) {
		      	#flag nicely formatted view/table names in source and destination so we can make them available without the start and end query query borders in the result
		         $isFormattedSQLObject = 0
		             
		         # source part of data flow task
		      	if($component.componentClassID.contains("Source")) {
						
						$accessMode = $component.SelectNodes(".//property[@name='AccessMode']", $ns)[0].InnerXml

						if($accessMode -eq 2){
							# SQL query
							Write-Host "SQL query source in data flow task"
							$property = $component.SelectNodes(".//properties/property[@name='SqlCommand']", $ns)[0]
						}
						elseif ($accessMode -eq 0) {
							# table or view
							Write-Host "table or view source in data flow task"
							$property = $component.SelectNodes(".//properties/property[@name='OpenRowset']", $ns)[0]
							$isFormattedSQLObject = 1
						}
						elseif ($accessMode -eq 3) {
							# SQL in variable
							Write-Host "SQL variable source source in data flow task"
							$property = $component.SelectNodes(".//properties/property[@name='SqlCommandVariable']", $ns)[0]
						}
						elseif ($accessMode -eq 1) {
							# table or view name in variable
							Write-Host "table or view name in variable source in data flow task"
							$property = $component.SelectNodes(".//properties/property[@name='OpenRowsetVariable']", $ns)[0]
							$isFormattedSQLObject = 1
						}
						# AccessMode is not used for flat files
						elseif($task.SelectNodes(".//component[@componentClassID='Microsoft.FlatFileSource']").Count -gt 0) {
							Write-Host "flat file source"
							$property = $component

							if($isTest){Write-Host "location of flat file: " $component.refId}	
						}
						else {
							Write-Host "***ShowTask function: Has some other source for data flow task!!!"
							continue # skip this component
						}

						$dtsid = $component.SelectNodes(".//connection",$ns)[0].connectionManagerID
						$connection = DetermineConnection $tasks $dtsid

						# get queries & tables/views from SSIS variables
						if($accessMode -eq 3 -OR $accessMode -eq 1) {
							Write-Host "Variable, OLEDB or Excel source"
							$variable = $property.InnerXml.Replace("User::","") # ignore "Project::" variables
							$variableValue = $tasks.SelectNodes(".//DTS:Variable[@DTS:ObjectName='$variable']/DTS:VariableValue", $ns)[0]
							$SQLPath = RemoveSpace $variableValue.InnerXml
							$SQLPath = UpdatePath $SQLPath $connection $isFormattedSQLObject
							$SSISpath = -join("[",$component.refId,"]")
							$SSISpath = $SSISpath.Replace("[Package\",-join("[CCGBI\",$project.Name,"\",$packageName,".dtsx\")) 

							if($isTest){
								$test = -join($SQLPath,"~",$SSISpath,"~","SQL.table","~","SSIS.package.task.dataFlow.source")
								Write-Host $test
							}

							if($hasSQL){InsertIntoSQLTable $SQLPath $SSISpath "SQL.table" "SSIS.package.task.dataFlow.source"}
							continue # get next component
						} #End if
						# get tables/views from components
						else {
							if($component.componentClassID.contains("Microsoft.ExcelSource")) {
								Write-Host "Non-variable, Excel source" 
								$excel = $property.InnerXml.Replace("$","")
								$ExcelPath = UpdatePath $excel $connection $isFormattedSQLObject
								$SSISpath = -join("[",$component.refId,"]")
								$SSISpath = $SSISpath.Replace("[Package\",-join("[CCGBI\",$project.Name,"\",$packageName,".dtsx\")) 

								if($isTest){
									$test = -join($ExcelPath,"~",$SSISpath,"~","file.xlsx.tab","~","SSIS.package.task.dataFlow.source")
									Write-Host $test
								}

								if($hasSQL){InsertIntoSQLTable $ExcelPath $SSISpath "file.xlsx.tab" "SSIS.package.task.dataFlow.source"}
							}
							elseif($component.componentClassID.contains("Microsoft.OLEDBSource")) {
								Write-Host "Non-variable, OLEDB source" 
								$sql = $property.InnerXml.Replace("$","")
								$SQLPath = UpdatePath $sql $connection $isFormattedSQLObject
								$SSISpath = -join("[",$component.refId,"]")
								$SSISpath = $SSISpath.Replace("[Package\",-join("[CCGBI\",$project.Name,"\",$packageName,".dtsx\")) 

								if($isTest){
									$test = -join($SQLPath,"~",$SSISpath,"~","SQL.table","~","SSIS.package.task.dataFlow.source")
									Write-Host $test
								}

								if($hasSQL){InsertIntoSQLTable $SQLPath $SSISpath "SQL.table" "SSIS.package.task.dataFlow.source"}
							} #End elseif
							elseif($component.componentClassID.contains("Microsoft.FlatFileSource")) {
								Write-Host "Non-variable, FlatFile source" 
								$FlatFilePath = UpdatePath "" $connection $isFormattedSQLObject
								$SSISpath = -join("[",$component.refId,"]")
								$SSISpath = $SSISpath.Replace("[Package\",-join("[CCGBI\",$project.Name,"\",$packageName,".dtsx\")) 

								if($isTest){
									$test = -join($FlatFilePath,"~",$SSISpath,"~","file.txt","~","SSIS.package.task.dataFlow.destination")
									Write-Host $test
								}

								if($hasSQL){InsertIntoSQLTable $FlatFilePath $SSISpath "file.txt" "SSIS.package.task.dataFlow.destination"}
							} #End elseif
							continue # get next component
						 } #End else
					  } #End if
					  # destination
					  else {				
						# loop through each component
						#write child (SQL) and parent (SSIS task path) to screen
						$dtsid = $component.SelectNodes(".//connection",$ns)[0].connectionManagerID
						$connection = DetermineConnection $tasks $dtsid
						$property = $component.SelectNodes(".//properties/property[@name='OpenRowset']", $ns)[0]
						$SQLPath = UpdatePath $property.InnerXml $connection $isFormattedSQLObject  #todo: add file path and file are noted as server and db for destination table for Excel data pull
						$SSISpath = -join("[",$component.refId,"]")
						$SSISpath = $SSISpath.Replace("[Package\",-join("[CCGBI\",$project.Name,"\",$packageName,".dtsx\")) 						

						if($isTest){
							$test = -join($SQLPath,"~",$SSISpath,"~","SQL.table","~","SSIS.package.task.dataFlow.destination")	
							Write-Host $test
						}

						if($hasSQL){InsertIntoSQLTable $SQLPath $SSISpath "SQL.table" "SSIS.package.task.dataFlow.destination"}

						continue # get next component
			   	} #End else
		   	} #End foreach
			} #End if	
		} #End foreach
	} #End ShowTask

	ShowTask $dataFlowTasks
	ShowTask $nonDataFlowTasks

  } #End foreach for packages
}#End foreach for projects





