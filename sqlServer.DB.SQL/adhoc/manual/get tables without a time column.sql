/*
See if any tables do not have a time column
*/

Select distinct
	'[' + table_schema + '].[' + table_name + ']'
From
	ccgDataMart.INFORMATION_SCHEMA.columns
Where
	data_type Not In ('date','datetime','datetime2')

Except

Select distinct
	'[' + table_schema + '].[' + table_name + ']'
From
	ccgDataMart.INFORMATION_SCHEMA.columns
Where
	data_type In ('date','datetime','datetime2')