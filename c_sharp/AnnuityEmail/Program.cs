using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Net.Mail;
using System.Net;
using System.Data.SqlClient;
using System.Data;
using System.Data.SqlTypes;

namespace AnnuityEmail
{
    class Program
    {
        /*
         *  This application only accepts the following parameters:
         *      Parameter 1: SendEmailType 
         *      Parameter 2: SendEmailLevelName
         *      Parameter 3: ProductionOnly
         *      Parameter 4: SummarySegment
        */

        static private String Parameter3;

        static int Main(string[] args)
        {
            int Status = 0;
            bool ProductionOnly;

            if (args.Length < 3)
            {
                ProductionOnly = false;
            }
            else
            {
                if (args[2].Equals("ProductionOnly"))
                {
                    ProductionOnly = true;
                }
                else
                {
                    ProductionOnly = false;
                }
            }

            if (args.Length < 4)
            {
                Console.WriteLine("Must provide 4 parameters");
                return 1;
            }

            Parameter3 = args[2].ToString();

            // Get current date
            DateTime CurrentDateTime = DateTime.Now;



            SqlConnection conn2 = new SqlConnection("Data Source=(local);Integrated Security=SSPI;Initial Catalog=EATDW;Connection Timeout=120");
            conn2.Open();
            SqlCommand cmd2 = conn2.CreateCommand();
            cmd2.CommandTimeout = 120;
            SqlCommand cmd3 = conn2.CreateCommand();
            cmd3.CommandTimeout = 120;

            SqlCommand cmd4 = conn2.CreateCommand();
            cmd4.CommandTimeout = 120;

            // Validate Email EXE parameters
            String ParametersValid;
            cmd3.CommandText = "sp_Email_ValidateExeParameters";
            cmd3.CommandType = CommandType.StoredProcedure;
            cmd3.Parameters.Add("@SendEmailType", SqlDbType.VarChar);
            cmd3.Parameters["@SendEmailType"].Value = args[0];
            cmd3.Parameters.Add("@SendEmailLevelName", SqlDbType.VarChar);
            cmd3.Parameters["@SendEmailLevelName"].Value = args[1];
            cmd3.Parameters.Add("@SummarySegment", SqlDbType.VarChar);
            cmd3.Parameters["@SummarySegment"].Value = args[3];
            ParametersValid = cmd3.ExecuteScalar().ToString();

            if (ParametersValid == "0")
            {
                Console.WriteLine("Invalid input parameters");
                return 1;
            }
            
            // Create Email Identifier
            String EmailIdentifier;
            cmd3.CommandText = "sp_Email_CreateEmailIdentifier";
            cmd3.CommandType = CommandType.StoredProcedure;
            cmd3.Parameters.Add("@SendAttemptDateTime", SqlDbType.DateTime);
            cmd3.Parameters["@SendAttemptDateTime"].Value = CurrentDateTime;
            EmailIdentifier = cmd3.ExecuteScalar().ToString();

            // Archive Emails to be sent
            cmd3.CommandType = CommandType.Text;
            cmd3.CommandText = "exec sp_Email_SendEmail_Archive_Load @SendEmailType='" + args[0] + "', @SendEmailLevelName='" + args[1] + "', @CurrentDateTime = '" + CurrentDateTime + "', @SummarySegment = '" + args[3] +  "',@IsProductionFlag = '"+ProductionOnly+"'";;
            cmd3.ExecuteNonQuery();

            //Console.WriteLine("done with archiving emails"); //test

            // Note which emails cannot be sent because they have no EmailTo
            cmd3.CommandText = "Update Email_SendEmail_Archive Set SendStatus = 'Fail - No EmailTo' Where EmailTo = '' And SendEmailType='" + args[0] + "' And SendEmailLevelName='" + args[1] + "' And SendAttemptDateTime = '" + CurrentDateTime + "' And SendStatus Not Like 'Fail%'";
            cmd3.ExecuteNonQuery();

            //Console.WriteLine("done with marking what emails have no EmailTo"); //test

            // Note which emails cannot be sent because of an invalid alias
            cmd3.CommandText = "exec sp_Email_ValidateAlias @SendEmailType='" + args[0] + "', @SendEmailLevelName='" + args[1] + "', @CurrentDateTime = '" + CurrentDateTime + "'";
            cmd3.ExecuteNonQuery();

            int EmailCount = GetTobesentEmailCount(cmd4, args, CurrentDateTime);
            int EmailCountSent = GetSentEmailCount(cmd4, args, CurrentDateTime);

            //if the cumulative count of Sent Items in Past hour and the to be sent Items is more than 900, wait for an Hour
            if (EmailCount + EmailCountSent > 900)
            {
                System.Threading.Thread.Sleep(3600000);
            }
  
            if (EmailCount > 900) //Limit to the number of Emails to be sent for the specified period
            {
                while (EmailCount > 0)
                {
                    Status = LoadEmail(ProductionOnly, args, cmd2, CurrentDateTime, EmailIdentifier);
                    // Get the count of No of Emails pending to be sent 
                    cmd4.CommandText = "Select COUNT(1) From Email_SendEmail_Archive Where SendEmailType = '" + args[0] + "' And SendEmailLevelName = '" + args[1] + "' And SendAttemptDateTime = '" + CurrentDateTime + "' And SendStatus = 'Not Sent' And SummarySegment = '" + args[3] + "'";
                    EmailCount = Convert.ToInt32(cmd4.ExecuteScalar());
                    if (EmailCount > 0)
                    {
                        System.Threading.Thread.Sleep(3600000); //Wait for 1hr before sending next set of Emails.
                    }
                }
                
            }
            else
            {
                Status = LoadEmail(ProductionOnly, args, cmd2, CurrentDateTime, EmailIdentifier);
                
            }
            cmd2.CommandType = CommandType.Text;
            cmd2.CommandText = "exec sp_Email_SendEmail_Archive_Received_Load @SendEmailType='" + args[0] + "', @SendEmailLevelName='" + args[1] + "', @CurrentDateTime = '" + CurrentDateTime + "', @SummarySegment = '" + args[3] + "'";
            cmd2.ExecuteNonQuery();
            conn2.Close();
            return Status;

        }
        //To get the count of Emails to be sent based on the passed arguments
        static int GetTobesentEmailCount(SqlCommand cmd4, string[] args, DateTime CurrentDateTime)
        {
            // Get the count of No of Emails pending to be sent 
            cmd4.CommandText = "Select COUNT(1) From Email_SendEmail_Archive Where SendEmailType = '" + args[0] + "' And SendEmailLevelName = '" + args[1] + "' And SendAttemptDateTime = '" + CurrentDateTime + "' And SendStatus = 'Not Sent' And SummarySegment = '" + args[3] + "'";
            int EmailCount = Convert.ToInt32(cmd4.ExecuteScalar());
            return EmailCount;
        }
        //To Get the count of Emails that have been sent already in the past hour
        static int GetSentEmailCount(SqlCommand cmd4, string[] args, DateTime CurrentDateTime)
        {
            // Get the count of No of Emails sent in the past hour
            cmd4.CommandText = "Select COUNT(1) From Email_SendEmail_Archive Where  SendAttemptDateTime >= DATEADD(HOUR,-1,GETDATE()) And SendStatus = 'Success'";
            int EmailCountSent = Convert.ToInt32(cmd4.ExecuteScalar());
            return EmailCountSent;
        }
        static int LoadEmail(bool ProductionOnly, string[] args, SqlCommand cmd2, DateTime CurrentDateTime, string EmailIdentifier)
        {
            int Status =0;
            // Create a database connection
            SqlConnection conn = new SqlConnection("Data Source=(local);Integrated Security=SSPI;Initial Catalog=EATDW;Connection Timeout=120");
            conn.Open();
            SqlCommand cmd = conn.CreateCommand();
            // Retrieve emails from the database.
            cmd.CommandText = "Select Top 900 SendEmailId,EmailTo,EmailCC,EmailSubject,EmailBodyText,EmailBodyDataTableHeader,EmailBodyDataTable,EmailBodyDataTableFooter From Email_SendEmail_Archive Where SendEmailType = '" + args[0] + "' And SendEmailLevelName = '" + args[1] + "' And SendAttemptDateTime = '" + CurrentDateTime + "' And SendStatus = 'Not Sent' And SummarySegment = '" + args[3] + "'";

            SqlDataReader reader = cmd.ExecuteReader();

            String SendEmailId = "";
            String EmailTo;
            String EmailCC;
            String EmailSubject;
            String EmailBody;
            String EmailBodyText;
            String EmailBodyDataTableHeader;
            String EmailBodyDataTable;
            String EmailBodyDataTableFooter;

            try
            {
                while (reader.Read())
                {
                    SendEmailId = reader["SendEmailId"].ToString();
                    EmailTo = reader["EmailTo"].ToString();
                    EmailCC = reader["EmailCC"].ToString();
                    EmailSubject = reader["EmailSubject"].ToString();
                    EmailBodyText = reader["EmailBodyText"].ToString();
                    EmailBodyDataTableHeader = reader["EmailBodyDataTableHeader"].ToString();
                    EmailBodyDataTable = reader["EmailBodyDataTable"].ToString();
                    EmailBodyDataTableFooter = reader["EmailBodyDataTableFooter"].ToString();

                    // Prep the email for sending
                    EmailTo = EmailTo.Replace(";", "@microsoft.com,");
                    if (EmailTo != "")
                    {
                        EmailTo = EmailTo.Substring(0, EmailTo.Length - 1);
                    }

                    EmailCC = EmailCC.Replace(";", "@microsoft.com,");
                    if (EmailCC != "")
                    {
                        EmailCC = EmailCC.Substring(0, EmailCC.Length - 1);
                    }


                    EmailBody = EmailBodyText;
                    if (!ProductionOnly)
                    {
                        EmailBody = EmailBody.Replace("<tr><td><img src=\"http://annuity/emailbanner.jpg\"/><br/></td></tr>", "<tr><td>To: [EmailTo]</td></tr><tr><td>CC: [EmailCC]</td></tr><tr><td><img src=\"http://annuity/emailbanner.jpg\"/><br/></td></tr>");
                        EmailBody = EmailBody.Replace("[EmailTo]", EmailTo);
                        EmailBody = EmailBody.Replace("[EmailCC]", EmailCC);
                    }
                    EmailBody = EmailBody.Replace("[EmailBodyDataTableHeader]", EmailBodyDataTableHeader);
                    EmailBody = EmailBody.Replace("[EmailBodyDataTable]", EmailBodyDataTable);
                    EmailBody = EmailBody.Replace("[EmailBodyDataTableFooter]", EmailBodyDataTableFooter);
                    EmailBody = EmailBody.Replace("[EmailIdentifier]", EmailIdentifier);
                    

                    
 


                    //Console.WriteLine("done setting parameters for: " + SendEmailId);//test

                    //Console.WriteLine("EmailTo:" + EmailTo);//test
                    //Console.WriteLine("EmailCC:" + EmailCC);//test

                    // Send Email
                    try
                    {
                        SendEmail(EmailTo, EmailCC, EmailSubject, EmailBody, SendEmailId, ProductionOnly);

                        //Console.WriteLine("done sending email for: " + SendEmailId);//test
                        

                        cmd2.CommandType = CommandType.Text;
                        cmd2.CommandText = "Update Email_SendEmail_Archive Set SendStatus = 'Success' Where SendEmailId = " + SendEmailId + " And SendAttemptDateTime = '" + CurrentDateTime + "'";
                    }
                    catch (Exception ex)
                    {
                        String ErrorMessage = ex.Message;
                        //Console.WriteLine(ErrorMessage);//test
                        //Console.ReadLine();//test

                        cmd2.CommandType = CommandType.Text;
                        cmd2.CommandText = "Update Email_SendEmail_Archive Set SendStatus = 'Fail - App Error' Where SendEmailId = " + SendEmailId + " And SendAttemptDateTime = '" + CurrentDateTime + "'";
                        Status = 1;
                    }

                    cmd2.ExecuteNonQuery();

                    //Console.WriteLine("done setting email send status for: " + SendEmailId);//test
                }

            }
            catch (Exception ex2)
            {
                String ErrorMessage = ex2.Message;
                //Console.WriteLine(ErrorMessage);//test
                //Console.ReadLine();//test

                cmd2.CommandType = CommandType.Text;
                cmd2.CommandText = "Update Email_SendEmail_Archive Set SendStatus = 'Fail - App Error' Where SendEmailId = " + SendEmailId + " And SendAttemptDateTime = '" + CurrentDateTime + "'";
                cmd2.ExecuteNonQuery();
                Status = 1;

                //Console.WriteLine("done setting email app failure for: " + SendEmailId);//test
            }

            reader.Close();
            conn.Close();
            return Status;
        }
        static void SendEmail(String EmailTo, String EmailCC, String EmailSubject, String EmailBody, String SendEmailId, bool ProductionOnly)
        {
            // Send the email
            MailMessage Mail = new MailMessage();
            Mail.From = new MailAddress("dfct@microsoft.com");
            //Mail.ReplyTo = new MailAddress("dfhelp@microsoft.com");
            Mail.ReplyToList.Add("dfhelp@microsoft.com");
            Mail.ReplyToList.Add("annuity@microsoft.com");
            if (ProductionOnly)
            {
                Mail.To.Add(EmailTo);
                if (EmailCC != "")
                {
                    Mail.CC.Add(EmailCC);
                }
                Mail.Bcc.Add("annuity@microsoft.com");
            }
            else
            {
                Mail.To.Add(GetTestEmailTo());
            }
            Mail.SubjectEncoding = Encoding.UTF8;
            Mail.Subject = EmailSubject;
            Mail.IsBodyHtml = true;
            Mail.BodyEncoding = Encoding.UTF8;
            Mail.Body = EmailBody;

            SmtpClient MailServer = new SmtpClient("smtphost.redmond.corp.microsoft.com", 25);
            MailServer.Credentials = CredentialCache.DefaultNetworkCredentials; //  new System.Net.NetworkCredential("username", "password"); 

            //Console.WriteLine("EmailTo:" + Mail.To[0].ToString()); //test
            //Console.WriteLine("EmailCC:" + Mail.CC[0].ToString()); //test
            //Console.WriteLine("EmailBCC:" + Mail.Bcc[0].ToString()); //test

            MailServer.Send(Mail);
        }

        static private String GetTestEmailTo()
        {
            // Create a database connection
            SqlConnection conn = new SqlConnection("Data Source=(local);Integrated Security=SSPI;Initial Catalog=EATDW;Connection Timeout=120");
            conn.Open();
            SqlCommand cmd = conn.CreateCommand();
            //cmd.CommandText = "Select Count(1) From EATDW.dbo.Email_Map_NameAlias Where Alias = '" + Parameter3 + "'";
            cmd.CommandText = "Select Count(1) From EATDW.dbo.Email_Map_AnnuityTeamAlias Where Alias = '" + Parameter3 + "'"; //added to  limit third parameter of AnnuityEmail.exe to only members of annuity team
            String TestEmailTo = "";
            if(cmd.ExecuteScalar().Equals(0))
            {
                TestEmailTo = "ckent@microsoft.com";
            }
            else
            {
                TestEmailTo = Parameter3 + "@microsoft.com";
            }
            conn.Close();
            return TestEmailTo;
        }
    }
}
