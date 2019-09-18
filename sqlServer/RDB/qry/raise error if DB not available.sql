If Not Exists(select state_desc from sys.databases Where state_desc = 'ONLINE' and [name] = 'MyDB')
Begin
	RAISERROR ('"MyDB" db is not available yet!',11,1);
End
