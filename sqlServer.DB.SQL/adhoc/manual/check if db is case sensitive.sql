DECLARE @Tmp TABLE(mystring VARCHAR(20))
INSERT @Tmp SELECT 'Test One'
INSERT @Tmp SELECT 'Test one'

SELECT CHARINDEX('Test One', mystring COLLATE Latin1_General_CS_AS) FROM @Tmp --case sensitive
SELECT CHARINDEX('Test One', mystring) FROM @Tmp -- my database collation is case insensitive