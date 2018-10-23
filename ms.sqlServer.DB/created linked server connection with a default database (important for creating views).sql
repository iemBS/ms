EXECUTE sp_addlinkedserver @server = 'LinkedCrymea',@provider = 'SQLNCLI',@srvproduct = '',@datasrc = 'crymea',@catalog = 'workArea'
EXECUTE  sp_serveroption 'LinkedCrymea', 'rpc', 'true'
EXECUTE  sp_serveroption 'LinkedCrymea', 'rpc out', 'true'
EXECUTE  sp_serveroption 'LinkedCrymea', 'Use Remote Collation', 'false'

