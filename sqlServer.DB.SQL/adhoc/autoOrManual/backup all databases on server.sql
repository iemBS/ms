DECLARE @name VARCHAR(255) -- database name  
DECLARE @path VARCHAR(255) -- path for backup files  
DECLARE @fileName VARCHAR(500) -- filename for backup  
DECLARE @fileDate VARCHAR(20) -- used for file name 

--Specify location to backup DBs to
SET @path = 'C:\sburnell_111213\'  

SELECT @fileDate = CONVERT(VARCHAR(20),GETDATE(),112) 

--Define what DBs will not be backed up
DECLARE db_cursor CURSOR FOR  
SELECT name 
FROM master.dbo.sysdatabases 
WHERE name NOT IN 
(
	'master'
	,'model'
	,'msdb'
	,'tempdb'
	,'BillysDB'
)  

OPEN db_cursor   
FETCH NEXT FROM db_cursor INTO @name   

WHILE @@FETCH_STATUS = 0   
BEGIN   
       SET @fileName = @path + @name + '_' + @fileDate + '.BAK'  
       BACKUP DATABASE @name TO DISK = @fileName  

       FETCH NEXT FROM db_cursor INTO @name   
END   

CLOSE db_cursor   
DEALLOCATE db_cursor 