EXECUTE sp_addlinkedserver @server = 'LinkedAcct',@provider = 'SQLNCLI',@srvproduct = '',@datasrc = 'Acct',@catalog = 'wrk'
EXECUTE  sp_serveroption 'LinkedAcct', 'rpc', 'true'
EXECUTE  sp_serveroption 'LinkedAcct', 'rpc out', 'true'
EXECUTE  sp_serveroption 'LinkedAcct', 'Use Remote Collation', 'false'

