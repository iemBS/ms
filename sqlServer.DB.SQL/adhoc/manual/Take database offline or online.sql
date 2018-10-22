-- Take the Database Offline
 ALTER DATABASE [AcctDB] SET OFFLINE WITH
 ROLLBACK IMMEDIATE
 GO
 -- Take the Database Online
 ALTER DATABASE [AcctDB] SET ONLINE
 GO
 