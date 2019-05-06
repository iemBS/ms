Use MSDB
Go
Declare @AccountName VarChar(255), @ProfileName VarChar(255)

Select
	@AccountName = 'Clark Kent',  -- set an  account name
	@ProfileName = 'Clark Kent profile' -- set a profile name

If Exists (Select 1 From sysmail_profileaccount pa Join sysmail_profile p On p.Profile_Id = pa.Profile_Id And p.Name = @ProfileName Join sysmail_account a On a.Account_Id = pa.Account_Id And a.Name = @AccountName)
	Exec sysmail_delete_profileaccount_sp
		@profile_name = @ProfileName,
		@account_name = @AccountName

If Exists (Select 1 From sysmail_profile Where Name = @ProfileName)
	Exec sysmail_delete_profile_sp
		@profile_name = @ProfileName

If Exists (Select 1 From sysmail_account Where Name = @AccountName)
	Exec sysmail_delete_account_sp
		@account_name = @AccountName

Exec sysmail_add_account_sp
	@account_name = @AccountName,
	@email_address = 'ckent@hotmail.com', -- Set an email address that will represent the email sender
	@display_name = 'Clark Kent sender!', -- Set the display name of the email sender 
	@mailserver_name = 'smtphost.hotmail.com', -- Set the SMTP mail host server
	@username = 'ckent@hotmail.com', -- Set the username for the alias that represents the email sender
	@password = '' -- Set the password for the alias that represents the email sender

Exec sysmail_add_profile_sp
	@profile_name = @ProfileName

Exec sysmail_add_profileaccount_sp
	@profile_name = @ProfileName,
	@account_name = @AccountName,
	@sequence_number = 1
Go

/*
After running this set of queries do the following

1. Navigate to the "Management" node in "Object Explorer" in "SQL Server Management Studio". Expland the "Management" node.
   Right click on "Database Mail" and choose "Configure Database Mail" from the context menu. Click the "Next" button
   until you get to the "Select Configuration Task" window. Choose "Manage profile security" in the 
   "Select Configuration Task" window. Choose your profile and set the "Default Profile" to "yes". Click the 
   "Next" and "Finish" buttons to complete the update. 
2. Navigate to "SQL Server Agent" in "Object Explorer". Expland the node and then right click the "Operators" node and
   choose "New Operator" from the context menu. Specify the "Name" and the "E-mail name" of the person that you want 
   to receive any emails. Click the "OK" button to complete the update. 
3. Navigate to "SQL Server Agent" in "Object Explorer". Right click on "SQL Server Agent" and
   choose "Properties" from the context menu. In the "SQL Server Agent Properties" window
   choose the "Alert System" tab. On the "Alert System" tab, check "Enable mail profile". Also on
   the "Alert System" tab, check the "Enable fail-safe operator" and specify an operator and check "Email". 
   Restart the "SQL Server Agent" service after making these changes.
4. Navigate to the job that you want to send emails. Right click the job and choose "Properties"
   from the context menu. On the "Notifications" tab, check "Email" and choose an operator from the list.
   Then, choose to see an email on failure, on success or just on completion. 
*/
 

