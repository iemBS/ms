If Exists(Select * From Tempdb.INFORMATION_SCHEMA.TABLES Where TABLE_NAME Like '#LinkedServers%')
Begin
	Drop Table #LinkedServers
End
Go	
Create Table #LinkedServers 
(
	SRV_NAME varchar(128) not null, 
	SRV_PROVIDERNAME varchar(128) not null, 
	SRV_PRODUCT varchar(255) null, 
	SRV_DATASOURCE varchar(255) null, 
	SRV_PROVIDERSTRING varchar(255) null, 
	SRV_LOCATION varchar(255) null, 
	SRV_CAT varchar(255) null)
Go
Insert 
	#LinkedServers 
exec sp_LinkedServers
Go
If Exists(Select * From #LinkedServers Where SRV_NAME = 'LinkedMAL_OLD')
Begin
	Execute sp_DropServer LinkedMAL_OLD, droplogins	
End