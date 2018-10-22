/*
	Those with admin server access or server access via a group
	Info on server roles can be found at: http://www.techrepublic.com/article/understanding-roles-in-sql-server-security/1061781
*/
CREATE TABLE #Login
 (
     account_name        sysname NULL,
     type                char(8) NULL,
     privilege           char(9) NULL,
     mapped_login_name   sysname NULL,
     permission_path     sysname NULL
 )

Insert Into
	#Login
EXEC 
	xp_LogInInfo
	
Select  
	'Those with admin server access or server access via a group' As CheckType
	,account_name
	,type
	,privilege
	,mapped_login_name
	,permission_path
From    
	#Login
Where
	(
		privilege = 'Admin'
		Or
		[Type] = 'Group'
	)
	 
DROP TABLE #Login

/*
	those with server roles other than "public"
*/
Select
	'those with server roles other than "public"' As CheckType
	,SUSER_NAME(SRoleMembers.member_principal_id) As Login
	,SUSER_NAME(SRoleMembers.role_principal_id) AS [Role]
From 
	sys.server_role_members as SRoleMembers
Where
	SUSER_NAME(SRoleMembers.role_principal_id) != 'public'
Order By
	SUSER_NAME(SRoleMembers.role_principal_id);

		



/*
	those with database roles other than "db_datareader" 
	Description of database roles found at: http://msdn.microsoft.com/en-us/library/ms189121.aspx
*/
SELECT
	'those with database roles other than "db_datareader"' As CheckType 
	,USER_NAME(DBRoleMembers.member_principal_id) As UserName
	,DBRoleNames.Name As DBRoleName
FROM 
	sys.database_role_members AS DBRoleMembers
	Inner Join sys.database_principals As DBRoleNames On 
		DBRoleMembers.role_principal_id = DBRoleNames.principal_id
Where
	DBRoleNames.Name != 'db_datareader'


/*
	those with no database role specified but have a user name associated with database
*/
Select
	'those with no database role specified but have a user name associated with database'
	,Name As UserName
	,DB_NAME() As DBName
From
	sys.database_principals
Where
	type_desc = 'WINDOWS_USER'
And
	Name Not In (Select USER_NAME(member_principal_id) From sys.database_role_members)
	