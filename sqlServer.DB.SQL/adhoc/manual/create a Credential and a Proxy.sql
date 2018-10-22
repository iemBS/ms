/*
This credential and proxy is based on the "johnd" alias in the "seattle" domain.
*/
-- Specify variables
declare @windowsLogin varchar(100) -- Needs to be in the format of DOMAIN\alias that has access to the database and server already.
declare @windowsPassword varchar(15) -- Needs to be the password for the windows login just added.
declare @proxyName varchar(40) -- Proxy name will be applied by a server user to an sql job

-- Set variables
set @windowsLogin = 'seattle\johnd'
set @windowsPassword = '[put your windows password here]'
set @proxyName = 'johnd'

-- Create a credential
print 'start: creating credential'

declare @credentialString varchar(200)
set @credentialString = 'create credential ' + @proxyName + '_credential WITH identity = ''' + @windowsLogin + ''', secret = ''' + @windowsPassword + ''''
exec(@credentialString)

print 'end: creating credential'

-- Create Proxy 
print 'start: creating proxy'

use msdb;
declare @credentialName varchar(50)
set @credentialName = @proxyName + '_credential'
exec sp_add_proxy @proxy_name = @proxyName, @credential_name = @credentialName

print 'end: creating proxy'

-- Give the proxy permission to access the operating system
exec sp_grant_proxy_to_subsystem 
		@proxy_name = @proxyName
		,@subsystem_name = 'CmdExec'