EXECUTE sp_addlinkedserver @server = 'linkedEAFOLAP',@provider = 'MSOLAP',@srvproduct = '',@datasrc = 'eafolap', @catalog='eafolap'
EXECUTE  sp_serveroption 'linkedEAFOLAP', 'rpc', 'true'
EXECUTE  sp_serveroption 'linkedEAFOLAP', 'rpc out', 'true'
EXEC master.dbo.sp_MSset_oledb_prop N'MOLAP', N'AllowInProcess', 1  -- Note: Can also go to Object Explorer > Your Server > Server Objects > Linked Servers > Providers > MOLAP > Context Menu > Enable "Allow Inprocess"