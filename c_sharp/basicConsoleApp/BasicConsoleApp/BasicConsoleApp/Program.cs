using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace BasicConsoleApp
{
    class Program
    {
        static void Main(string[] args)
        {
            // Guideance for creating this came from 
            // http://msdn.microsoft.com/en-us/library/42ste2f3(v=vs.90).aspx

            // Log entries will be written in the "Application" event log in the "Windows Logs" folder.

            System.Diagnostics.EventLog appLog = new System.Diagnostics.EventLog();

            // Note the name of the app that is creating this log entry. 
            //
            // If this source does not already have at least one entry in the Application log special access is needed to 
            // add an entry to the log. Every other Application log entry after that and for the same source will not have an issue
            // with writing (using my own login) to the Application log. 
            //
            // To deal with the initial security issue do the following
            /*
             
                Manually Create New Event Source Entry in the Registry

                If you are unable to create an event source at installation time, and you are in deployment, the administrator should manually create a new event source entry beneath the following registry key

                HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Eventlog\Application

                To manually create a new event source entry beneath this registry key 
                    1. Start the Registry Editor tool Regedit.exe. 
                    2. Using the Application Event log, expand the outline list in the left panel to locate the following registry subkey: 
                        HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Eventlog\Application 
                    3. Right-click the Application subkey, point to New, and then click Key. 
                    4. Type a new event source name for the key name and press Enter. 
        
                The Network Service account can use the new event source for writing events. 

                Note You should not grant write permission to the ASP.NET process account (or any impersonated account if your application uses impersonation) on the HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Eventlog\ registry key. If you allow write access to this key and the account is compromised, the attacker can modify any log-related setting, including access control to the log, for any log on the system.
            */
            appLog.Source = "Scott's Basic Console App";

            // Write a log entry to the log
            appLog.WriteEntry("App Log Entry written at " + DateTime.Now);

            /*
             Look into the following URLs for understanding the account that may be accessing the event log for IIS
                http://www.codeproject.com/Articles/18072/Allow-your-ASP-NET-to-Access-your-Resources
                http://msdn.microsoft.com/en-us/library/windows/desktop/aa363658(v=vs.85).aspx
                http://msdn.microsoft.com/en-us/library/windows/desktop/aa363648(v=vs.85).aspx
                http://technet.microsoft.com/en-us/library/cc179801.aspx
                http://superuser.com/questions/248315/list-of-hidden-virtual-windows-user-accounts
            */
        }
    }
}
