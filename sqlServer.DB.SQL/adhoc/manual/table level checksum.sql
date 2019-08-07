--returns null if there is no data in the table
SELECT CHECKSUM_AGG(BINARY_CHECKSUM(*)) FROM [dbo].[TableName]
