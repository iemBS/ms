
[System.reflection.Assembly]::LoadWithPartialName("Microsoft.AnalysisServices")

$cubeSvr = new-Object Microsoft.AnalysisServices.Server
$cubeSvr.Connect("adcrm_sql05")

foreach ($db in $svr.Databases)
{
# Print the Database Name
"Database: " + $db.Name
foreach ($role in $db.Roles)
  {
    $foundMember = $null
    # Print the Role Name
    "   Role: " + $role.Name    #Print the role name
    foreach ($member in $role.Members)
    {
     # Print the member name(s) in the role
      "      " + $member.Name
      if ($member.Name -eq "domain_name\old_group_name")
      {
        $foundMember = $member
      }
    }
    If ($foundMember -ne $null)
    {
      "    Member Found!"
      $role.Members.Remove($foundMember)
      $newRole = New-Object Microsoft.AnalysisServices.RoleMember("domain_name\new_group_name")
      $role.Members.Add($newRole)
      $role.Update()
    }
  }
}
$svr.Disconnect()
