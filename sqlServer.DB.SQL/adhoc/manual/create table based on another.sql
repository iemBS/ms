Select 
	*
Into
	#tblCpy
From
	[Andesa_Work].[UV2Files]
Where
	1 = 0

select * from information_schema.columns where table_schema = 'Andesa_Work' and table_name = 'UV2Files'
select * from tempdb.information_schema.columns where table_name like '#tblCpy%'

xxx: need to see if use of cast or convert function will change the size of the column in the new table
