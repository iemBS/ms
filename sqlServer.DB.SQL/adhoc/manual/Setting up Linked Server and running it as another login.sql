EXECUTE sp_addlinkedserver @server = 'LinkedAcctDB',@provider = 'SQLNCLI',@srvproduct = '',@datasrc = 'AcctDB',@catalog = 'Hadoop'
EXECUTE  sp_serveroption 'LinkedAcctDB', 'rpc', 'true'
EXECUTE  sp_serveroption 'LinkedAcctDB', 'rpc out', 'true'
EXECUTE  sp_serveroption 'LinkedAcctDB', 'Use Remote Collation', 'false'


-- when using this linked server code from my laptop
--EXECUTE sp_addlinkedsrvlogin 'LinkedAcctDB', 'false', 'seattle\johnd', 'anotherUser', 'password4OtherUser'

