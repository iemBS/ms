EXECUTE sp_addlinkedserver @server = 'LinkedChexSqlEbs01',@provider = 'SQLNCLI',@srvproduct = '',@datasrc = 'ChexSqlEbs01',@catalog = 'Hadoop'
EXECUTE  sp_serveroption 'LinkedChexSqlEbs01', 'rpc', 'true'
EXECUTE  sp_serveroption 'LinkedChexSqlEbs01', 'rpc out', 'true'
EXECUTE  sp_serveroption 'LinkedChexSqlEbs01', 'Use Remote Collation', 'false'


-- when using this linked server code from my laptop
--EXECUTE sp_addlinkedsrvlogin 'LinkedChexSqlEbs01', 'false', 'NorthAmerica\v-scburn', 'user110', 'One10user2'

-- when using this linked server code from Expedia server
EXECUTE sp_addlinkedsrvlogin 'LinkedChexSqlEbs01', 'false', 'SEA\v-sburnell', 'user110', 'One10user2'