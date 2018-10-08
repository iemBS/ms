EXECUTE sp_addlinkedserver @server = 'LinkedWWIOISQL',@provider = 'SQLNCLI',@srvproduct = '',@datasrc = 'wwioisql'
EXECUTE  sp_serveroption 'LinkedWWIOISQL', 'rpc', 'true'
EXECUTE  sp_serveroption 'LinkedWWIOISQL', 'rpc out', 'true'
EXECUTE  sp_serveroption 'LinkedWWIOISQL', 'Use Remote Collation', 'false'