EXECUTE sp_addlinkedserver @server = 'LinkedAcctSQL',@provider = 'SQLNCLI',@srvproduct = '',@datasrc = 'Acctsql'
EXECUTE  sp_serveroption 'LinkedAcctSQL', 'rpc', 'true'
EXECUTE  sp_serveroption 'LinkedAcctSQL', 'rpc out', 'true'
EXECUTE  sp_serveroption 'LinkedAcctSQL', 'Use Remote Collation', 'false'