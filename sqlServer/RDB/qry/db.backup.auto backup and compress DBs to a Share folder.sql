/*
Put this query in a SQL job to schecule backups of a relational DB to a share folder, This specific case is looking for DBs called "venus" and "mars" on the server and copying them
to a share folder on a server called "newYork". 
*/

Declare @DateStamp Varchar(8)
Select @DateStamp = SubString(Cast(Year(GetDate()) As Varchar),3,2)+SubString('0'+Cast(Month(GetDate()) As Varchar),Len('0'+Cast(Month(GetDate()) As Varchar))-1,2)+SubString('0'+Cast(Day(GetDate()) As Varchar),Len('0'+Cast(Day(GetDate()) As Varchar))-1,2)

Declare @Query Nvarchar(500)
Select @Query = '
USE [?] 
IF ''?'' = ''venus'' Or ''?'' = ''mars'' 
Begin
	BACKUP DATABASE [?] TO  DISK = N''\\newYork\DBBackups\?_' + @DateStamp + '.bak'' WITH NOFORMAT, NOINIT,  NAME = N''?-Full Database Backup'', SKIP, NOREWIND, NOUNLOAD, COMPRESSION,  STATS = 10 
End'

Execute Master.Sys.sp_MSforeachdb @Query
