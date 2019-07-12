/*
Resource database in SQL Server

See doc at https://docs.microsoft.com/en-us/sql/relational-databases/databases/resource-database?view=sql-server-2017

-Is a read-only database that contains all the system objects that are included with SQL Server. 
-SQL Server system objects, such as sys.objects, are physically persisted in the Resource database, but they logically appear in the sys schema of every database. 
-The Resource database does not contain user data or user metadata.
-The Resource database makes upgrading to a new version of SQL Server an easier and faster procedure. In earlier versions of SQL Server, upgrading required dropping and creating system objects. Because the Resource database file contains all system objects, an upgrade is now accomplished simply by copying the single Resource database file to the local server.

-limits of "Resource" db
	-SQL Server cannot backup
		-alternate backup method: ou can perform your own file-based or a disk-based backup by treating the mssqlsystemresource.mdf file as if it were a binary (.EXE) file, rather than a database file.
	-restore "Resource" db: Restoring a backup copy of mssqlsystemresource.mdf can only be done manually, and you must be careful not to overwrite the current Resource database with an out-of-date or potentially insecure version.

*/


--attributes for the "Resource" db

	--physical name
		--data file: mssqlsystemresource.mdf
		--log file: mssqlsystemresource.ldf

	--physical path to the .mdf & .ldf files
		--<drive>:\Program Files\Microsoft SQL Server\MSSQL<version>.<instance_name>\MSSQL\Binn\ 
		--do not move them from here
		--Each instance of SQL Server has one and only one associated mssqlsystemresource.mdf file, and instances do not share this file.

	--upgrade impact 
		--Upgrades and service packs sometimes provide a new resource database which is installed to the BINN folder.

	--version #
	SELECT SERVERPROPERTY('ResourceVersion');  
	GO  

	--last update time 
	SELECT SERVERPROPERTY('ResourceLastUpdateDateTime');  
	GO  

	--access SQL definitions of system objects, use the OBJECT_DEFINITION function
		--"sys.objects" is used as an example, sys.objects is a table 
	SELECT OBJECT_DEFINITION(OBJECT_ID('sys.objects'));  
	GO 