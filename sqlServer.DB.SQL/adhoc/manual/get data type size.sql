
date
datetime
datetime2

/*
decimal

using a query like "select DATALENGTH(9876543.21)" and using the same Scale can determine this

1-9 precision   > 5 bytes (data length)
10-19 precision > 9 bytes (data length)
20-29 precision > 13 bytes (data length)
30-39 precision > 17 bytes (data length)
*/

/*
char

-Can hold 8k bytes
-Use char when the sizes of the column data entries are consistent.
-Use varchar when the sizes of the column data entries vary considerably.
-xxx: can the same data in char and varchar data types be smaller in char?
*/