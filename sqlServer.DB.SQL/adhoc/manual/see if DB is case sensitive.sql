--replace "dbName" with the database name
SELECT DATABASEPROPERTYEX('dbName', 'Collation') SQLCollation;
-- if the returned collation has "_CI_" then the DB is case insensitive
