using System;
using System.Data;
using Microsoft.SqlServer.Dts.Runtime;
using System.Windows.Forms;
using Microsoft.SharePoint.Client;
using System.IO;
using DocumentFormat.OpenXml.Packaging;
using DocumentFormat.OpenXml.Spreadsheet;
using System.Collections.Generic;
using System.Linq;
using DocumentFormat.OpenXml;
using System.Data.SqlClient;
using System.Text;
using System.Text.RegularExpressions;
using System.Net;
using System.Threading.Tasks;
using System.Configuration;
using System.Security;
using System.Xml.Linq;

namespace SPOExcelFile2SQL
{
    class Program
    {
        static string[,] nameTypeMap;
        static int numExcelColumns;
        static string[][] excelColumnNameLetterMap;
        static string colFromThisAppNotExcel;
        static string colFromExcel;
        static string colFromExcelWillBeInDB;
        static int excelColSkip;

        static void Main(string[] args)
        {
            string fileName = string.Empty;
            string sheet = string.Empty;
            bool willTruncateTable = false;

            try
            {
                string spNames = "|ITShowcaseFY17Budget|FY16VendorBudgetUp|FY17VendorBudget|";
                if (args.Length == 0)
                {
                    System.Console.WriteLine("No parameter specified. Choose one of these for the first parameter: " + spNames.Replace("|", ","));
                    Environment.Exit(0);
                }
                if (spNames.IndexOf(args[0]) < 0)
                {
                    System.Console.WriteLine("Invalid parameter provided. Choose one of these for the first parameter: " + spNames.Replace("|", ","));
                    Environment.Exit(0);
                }
                if (args.Length == 1)
                {
                    System.Console.WriteLine("No second parameter provided. Can only specify 'truncate' or 'no-truncate' for second parameter.");
                    Environment.Exit(0);
                }
                if (args.Length > 1)
                {
                    if (args[1] != "truncate" && args[1] != "no-truncate")
                    {
                        System.Console.WriteLine("Invalid second parameter provided. Can only specify 'truncate' or 'no-truncate' for second parameter.");
                        Environment.Exit(0);
                    }
                    if (args[1] == "truncate")
                    {
                        willTruncateTable = true;
                    }
                    else
                    {
                        willTruncateTable = false;
                    }
                }
                if (args.Length > 2)
                {
                    if (args[2] != "manual")
                    {
                        System.Console.WriteLine("Invalid third parameter provided. Can only specify 'manual'");
                        Environment.Exit(0);
                    }
                }
                if (args.Length > 3)
                {
                    System.Console.WriteLine("Too many parameters provided");
                    Environment.Exit(0);
                }

                DateTime startTime = DateTime.Now;

                string param = args[0];

                string excelFilePath = ConfigurationManager.AppSettings.Get(param + "_ExcelFilePath");
                int excelRowSkip = Convert.ToInt32(ConfigurationManager.AppSettings.Get(param + "_ExcelRowsSkip"));
                excelColSkip = Convert.ToInt32(ConfigurationManager.AppSettings.Get(param + "_ExcelColsSkip"));
                string excelSheet = ConfigurationManager.AppSettings.Get(param + "_ExcelSheet");
                string DBTable = ConfigurationManager.AppSettings.Get(param + "_DBTable");
                string O365UserName = ConfigurationManager.AppSettings.Get("O365UserName");
                string O365Password = ConfigurationManager.AppSettings.Get("O365Password");

                nameTypeMap = new string[,] { };

                // Configure each file 
                switch (param)
                {
                    case "ITShowcaseFY17Budget":
                        GetITShowcaseFY17Budget_NameTypeMap();
                        break;
                    case "FY16VendorBudgetUp":
                        GetFY16VendorBudgetUp_NameTypeMap();
                        break;
                    case "FY17VendorBudget":
                        GetFY17VendorBudget_NameTypeMap();
                        break;
                }

                WorksheetPart excelData = GetExcelFileData(excelFilePath, excelSheet); 

                // Fill Data Table
                DataTable dt = FillDataTable(excelData, excelRowSkip, excelColSkip);

                // Insert data into DB
                FillTable(DBTable, dt, willTruncateTable);

                if (args.Length > 2)
                {
                    if (args[2] == "manual")
                    {
                        System.Console.WriteLine("");
                        System.Console.WriteLine("<Press Enter key to end application run>");
                        System.Console.ReadLine();
                    }
                }
                System.Console.WriteLine();
                System.Console.WriteLine("This run took " + DateTime.Now.Subtract(startTime).Seconds.ToString() + " seconds");
            }
            catch (Exception ex)
            {
                System.Console.WriteLine(ex.Message);            
            }
        }

        public static string TrimBorderSpace(string value)
        {
            char[] c = new char[2];
            c[0] = ' ';
            c[1] = '\u0009';
            return value.Trim(c);
        }
        
        public static WorksheetPart GetExcelFileData(string excelFilePath,string excelSheet)
        {
            WorksheetPart wsp = null;
            Worksheet ws = null;

            try
            {
                string O365UserName = ConfigurationManager.AppSettings.Get("O365UserName");
                string O365Password = ConfigurationManager.AppSettings.Get("O365Password");
                var securePassword = new SecureString();
                foreach (var c in O365Password) { securePassword.AppendChar(c); }
                SharePointOnlineCredentials cred = new SharePointOnlineCredentials(O365UserName, securePassword);

                Uri filePath = new Uri(excelFilePath);
                System.Console.WriteLine("filePath:" + filePath.ToString()); 
                string serverPath = filePath.AbsoluteUri.Replace(filePath.AbsolutePath, "");
                System.Console.WriteLine("serverPath:" + serverPath); 
                string serverRelativePath = filePath.AbsolutePath;
                System.Console.WriteLine("server rel path:" + serverRelativePath);
                System.Console.WriteLine("");

                ClientContext clientContext = new ClientContext(serverPath);
                clientContext.Credentials = cred;
                FileInformation fileInfo = Microsoft.SharePoint.Client.File.OpenBinaryDirect(clientContext, serverRelativePath);

                var memoryStream = new MemoryStream();
                using (var networkStream = fileInfo.Stream)
                {
                    if (networkStream != null)
                    {
                        // Copy the network stream to an in-memory variable
                        networkStream.CopyTo(memoryStream);
                        // Move the position of the stream to the beginning
                        memoryStream.Seek(0, SeekOrigin.Begin);
                    }
                }

                SpreadsheetDocument document = SpreadsheetDocument.Open(memoryStream, false);

                wsp = GetWorksheetPartByName(document, excelSheet);
            }
            catch(Exception ex)
            {
                System.Console.WriteLine(ex.Message);
                if(ex.InnerException != null)
                {
                    System.Console.WriteLine(ex.InnerException.Message);
                }
            }

            return wsp;
        }

        public static CookieContainer GetAuthCookies(Uri webUri, string userName, string password)
        {
            var securePassword = new SecureString();
            foreach (var c in password) { securePassword.AppendChar(c); }
            var credentials = new SharePointOnlineCredentials(userName, securePassword);
            var authCookie = credentials.GetAuthenticationCookie(webUri);
            var cookieContainer = new CookieContainer();
            cookieContainer.SetCookies(webUri, authCookie);
            return cookieContainer;
        }

        public static DataTable FillDataTable(WorksheetPart excelData, int excelRowSkip, int excelColSkip)
        {
            DataTable dt = new DataTable();
            int excelColCnt = 0;
            
            int hasInvalidDataTypeCnt = 0;

            GetColFromThisAppNotExcel();

            GetColFromExcel();

            GetColFromExcelWillBeInDB();

            try
            { 
                // Get Excel column names
                var rows = excelData.Worksheet.GetFirstChild<SheetData>().Elements<Row>();
                if(excelRowSkip > 0)
                {
                    rows = rows.Skip(excelRowSkip);
                }
                Row headerRow = rows.FirstOrDefault();

                string colName = "";

                if (headerRow != null)
                {
                    var cells = headerRow.Elements<Cell>();

                    // Below code is not needed because the cells variable knows to not include empty columns that precede the table
                    /*
                    if (excelColSkip > 0)
                    {
                        cells = cells.Skip(excelColSkip);
                    }
                    */

                    // Note if any Excel column names do not exist in configuration
                    foreach (var cell in cells)
                    {
                        colName = GetCellValue(cell);

                        // Skip if a non-column added at the end
                        if (colName.Trim() == "")
                        {
                            continue;
                        }

                        // Column in DB does not exist in Excel. It is generated in this app.
                        if(colFromThisAppNotExcel.IndexOf(colName) >= 0)
                        {
                            continue;
                        }

                        System.Console.WriteLine("Checking if [" + colName + "] Excel file column is in config file.");
                        System.Console.WriteLine("");

                        if (colFromExcel.IndexOf(colName) >= 0)
                        {
                            System.Console.WriteLine(colName + " column in Excel file exists in the SPOExcelFile2SQL.exe configuration.");
                        }
                        else
                        {
                            System.Console.WriteLine(colName + " column in Excel file does not exist in the SPOExcelFile2SQL.exe configuration.");
                        }

                        System.Console.WriteLine("");
                    }

                    // Note if any configuration column names do not exist in Excel
                    for (int i = 0; i < nameTypeMap.GetLength(0); i++)
                    {
                        // Excluded from DB table
                        if (nameTypeMap[i, 7] == "true")
                        {
                            continue;
                        }

                        System.Console.WriteLine("Checking if [" + nameTypeMap[i,0] + "] config Excel file column is in Excel file.");
                        System.Console.WriteLine("");

                        bool inExcel = false;
                        foreach (var cell in cells)
                        {
                            if (nameTypeMap[i, 0] == GetCellValue(cell))
                            {
                                inExcel = true;
                                excelColCnt = excelColCnt + 1;
                                break;// Exit this loop after finding match
                            }
                        }

                        if (!inExcel)
                        {
                            System.Console.WriteLine(nameTypeMap[i, 0] + " column in SPOExcelFile2SQL.exe configuration does not exist in the Excel file.");
                            System.Console.WriteLine("");
                        }
                        else
                        {
                            System.Console.WriteLine(nameTypeMap[i, 0] + " column in SPOExcelFile2SQL.exe configuration exists in the Excel file.");
                            System.Console.WriteLine("");
                        }
                    }

                    // Create DataTable structure
                    foreach (var cell in cells)
                    {
                        colName = GetCellValue(cell);

                        // Skip if column name is not an Excel column and ending up in the DB.
                        if(colFromExcelWillBeInDB.IndexOf(colName) < 0)
                        {
                            continue;
                        }

                        System.Console.WriteLine("Looping through column names in Excel file: " + colName);
                        System.Console.WriteLine("");

                        for(int i = 0; i < nameTypeMap.GetLength(0);i++)
                        {
                            // Excluded from DB table
                            if (nameTypeMap[i, 7] == "true")
                            {
                                continue;
                            }

                            if (colName == nameTypeMap[i,0])
                            {
                                dt.Columns.Add(colName, GetDTDataType(nameTypeMap[i,2]));
                                System.Console.WriteLine("Created [" + colName + "] column in DataTable");
                                System.Console.WriteLine("");
                                break;// Exit this loop after finding match
                            }
                        }
                    }
                }

                // Add ID column to DataTable
                DataColumn dc = dt.Columns.Add("SPOExcelFile2SQL_ID", typeof(int));
                dc.AutoIncrement = true;
                dc.AutoIncrementSeed = 1;
                dc.AutoIncrementStep = 1;
                System.Console.WriteLine("Created [SPOExcelFile2SQL_ID] column in DataTable");
                System.Console.WriteLine("");

                // Get mapping of Excel column name and Excel column letter
                GetExcelColumnNameLetterMap();

                // Get number of columns that come from Excel
                GetNumExcelColumns();

                // Put data into DataTable
                colName = "";
                string colVal = "";
                int excelRowPos = 0;

                // Skip header row when looping through the Excel rows
                foreach (var row in rows.Skip(1))
                {
                    DataRow dr = dt.NewRow();
                    excelRowPos = excelRowPos + 1;

                    var cells = GetCellsFromRowIncludingEmptyCells(row);

                    // Skip empty columns that precede the table
                    if (excelColSkip > 0)
                    {
                        cells = cells.Skip(excelColSkip);
                    }

                    // Loop through cells in Excel row
                    bool isEmptyRow = true;
                       
                    foreach (var cell in cells)
                    {
                        // Skip null cell. They can exist in the cells collection.
                        if(cell == null)
                        {
                            continue; 
                        }

                        // Get column name and cell value
                        colName = GetExcelLetterColumnNameMap(Regex.Replace(cell.CellReference.Value, @"[\d-]", string.Empty));
                        colVal = GetCellValue(cell);

                        // Skip if column name is not an Excel column and ending up in the DB
                        if (colFromExcelWillBeInDB.IndexOf(colName) < 0)
                        {
                            continue;
                        }

                        // Skip column if it is on the right side of the Excel table
                        if(colName == "")
                        {
                            continue; 
                        }

                        bool hasInvalidDataType = false;

                        // See if there is a non-null, non-zero, valid value in the cell
                        if (!(colVal == null || Regex.Matches(colVal, @"[a-zA-Z1-9]").Count == 0 || colVal == "0"))
                        {


                            // If any column has a value, then flag the row as not empty
                            isEmptyRow = false;

                            // If Excel formula did not resolve and leave just the result, get only the result on the right side. 
                            int resultPos = colVal.LastIndexOf("))");
                            if (resultPos > 0)
                            {
                                resultPos = resultPos + 2;
                                colVal = colVal.Substring(resultPos, colVal.Length - resultPos);
                                System.Console.WriteLine("Had to fix unresolved Excel formula for this column.");
                            }
                        }

                        try
                        { 
                            // If there is a null value in Excel be sure to put a non-null, blank value into DataTable
                            if(colVal == "" || colVal == null)
                            {
                                for (int t = 0; t < nameTypeMap.GetLength(0); t++)
                                {
                                    // Excluded from DB table
                                    if (nameTypeMap[t, 7] == "true")
                                    {
                                        continue;
                                    }

                                    if (colName == nameTypeMap[t, 0])
                                    {
                                        dr[colName] = GetNullDBReplacement(nameTypeMap[t, 2]);
                                        break;// Exit loop after finding match
                                    }
                                }
                            }
                            else
                            {
                                // Trim white space off of value before inserting into DataTable
                                dr[colName] = TrimBorderSpace(colVal);
                            }
                        }
                        catch(Exception ex)
                        {
                            for (int t = 0; t < nameTypeMap.GetLength(0); t++)
                            {
                                // Excluded from DB table
                                if (nameTypeMap[t, 7] == "true")
                                {
                                    continue;
                                }

                                if (colName == nameTypeMap[t, 0])
                                {
                                    dr[colName] = GetNullDBReplacement(nameTypeMap[t, 2]);
                                    break;// Exit loop after finding match
                                }
                            }

                            hasInvalidDataType = true;
                            hasInvalidDataTypeCnt = hasInvalidDataTypeCnt + 1;

                            System.Console.WriteLine("Possible bad data type in Excel that will not go into the [" + colName + "] column in DataTable. See error below: ");
                            System.Console.WriteLine(ex.Message);
                            System.Console.WriteLine("");

                            System.Console.WriteLine("colName:" + colName);
                            System.Console.WriteLine("colVal:" + dr[colName]);
                            System.Console.WriteLine("row #: " + excelRowPos.ToString());
                            if(hasInvalidDataType)
                            { 
                                System.Console.WriteLine("Has values in Excel that will have invalid data type in DB table. These values have been set to zero or blank in the DB until the columns can be reconfigured.");
                            }
                            System.Console.WriteLine("");

                            continue; 
                        }

                        System.Console.WriteLine("colName:" + colName);
                        System.Console.WriteLine("colVal:" + colVal);
                        System.Console.WriteLine("row #: " + excelRowPos.ToString());
                        if (hasInvalidDataType)
                        {
                            System.Console.WriteLine("Has values in Excel that will have invalid data type in DB table. These values have been set to zero or blank in the DB until the columns can be reconfigured.");
                        }
                        System.Console.WriteLine("");
                    }

                    // Do not include rows that have no data
                    if (isEmptyRow)
                    {
                        System.Console.WriteLine("Empty row for the columns noted above");
                    }
                    else // Add row to DataTable
                    {
                        dt.Rows.Add(dr);
                    }
                    System.Console.WriteLine(cells.Count().ToString() + " columns in row " + excelRowPos.ToString() + " noted above.");
                    System.Console.WriteLine("");

                }

                System.Console.WriteLine(excelRowPos.ToString() + " rows in Excel data");
                System.Console.WriteLine(excelColCnt.ToString() + " columns in Excel data");
                System.Console.WriteLine("");

                System.Console.WriteLine(dt.Rows.Count.ToString() + " rows in DataTable");
                System.Console.WriteLine(dt.Columns.Count.ToString() + " columns in DataTable");
                System.Console.WriteLine("Invalid data type count:" + hasInvalidDataTypeCnt.ToString());
                System.Console.WriteLine("");
            }
            catch(Exception ex)
            {
                System.Console.WriteLine(ex.Message);
                if(ex.InnerException != null)
                {
                    System.Console.WriteLine(ex.InnerException.Message);
                }
            }
            return dt;
        }

        public static Type GetDTDataType(string DBDataType)
        {
            switch (DBDataType)
            {
                case "datetime":
                    return typeof(DateTime);
                case "float":
                    return typeof(float);
                case "nvarchar":
                    return typeof(string);
                default:
                    return typeof(string);
            }
        }

        public static Object GetNullDataTableReplacement(string DataTableDataType)
        {
            switch (DataTableDataType)
            {
                case "DateTime":
                    return DBNull.Value;
                case "float":
                    return 0;
                case "string":
                    return DBNull.Value;
                default:
                    return DBNull.Value;
            }
        }

        public static Object GetNullDBReplacement(string DBDataType)
        {
            switch (DBDataType)
            {
                case "datetime":
                    return DBNull.Value;
                case "float":
                    return 0;
                case "nvarchar":
                    return DBNull.Value;
                default:
                    return DBNull.Value;
            }
        }

        public static string GetExcelColumnNameLetterMap(string excelColumnName)
        {
            if (excelColumnNameLetterMap.GetLength(0) == 0)
            {
                GetExcelColumnNameLetterMap();
            }

            for (int i = 0; i < excelColumnNameLetterMap[0].Length;i++)
            { 
                if(excelColumnNameLetterMap[0][i] == excelColumnName)
                {
                    return excelColumnNameLetterMap[1][i];
                }
            }
            return "";
        }

        public static string GetExcelLetterColumnNameMap(string letter)
        {
            if(excelColumnNameLetterMap.GetLength(0) == 0)
            {
                GetExcelColumnNameLetterMap();
            }

            for (int i = 0; i < excelColumnNameLetterMap[0].Length; i++)
            {
                if (excelColumnNameLetterMap[1][i] == letter)
                {
                    return excelColumnNameLetterMap[0][i];
                }
            }
            return "";
        }

        public static void GetExcelColumnNameLetterMap()
        {

            string[] mapColName = new string[100];
            string[] mapColLetter = new string[100];

            for (int i = 0; i < nameTypeMap.GetLength(0);i++)
            {
                // Not exist in Excel file and generated in this app
                if(nameTypeMap[i, 5] == "false")
                {
                    continue; 
                }
                mapColName[i] = nameTypeMap[i,0];
                mapColLetter[i] = GetLetter(i + 1 + excelColSkip).ToUpper();
            }

            Array.Resize(ref mapColName, nameTypeMap.GetLength(0));
            Array.Resize(ref mapColLetter, nameTypeMap.GetLength(0));

            excelColumnNameLetterMap = new string[2][]
            {
                mapColName,
                mapColLetter
            };
        }

        public static string GetLetter(int num)
        {
            if(num <= 0)
            {
                return "";
            }

            string sentence = "";
            string alpha = "abcdefghijklmnopqrstuvwxyz";

            int block = Convert.ToInt32(Math.Ceiling(Convert.ToDouble(num) / 26.0));

            if (block == 1)
            {
                sentence = alpha.Substring(num-1, 1); 
            }
            else
            {
                sentence = alpha.Substring(block - 1, 1) + alpha.Substring((num - (26 * (block-1))) - 1, 1);
            }

            return sentence;
        }

        public static void TruncateTable(string tableName)
        {
            string sqlConnStr = Properties.Settings.Default.SQLConnStr;
            SqlConnection conn = new SqlConnection(sqlConnStr);

            try
            {
                string sqlQueryStr = "Truncate Table ";
                sqlQueryStr = String.Concat(sqlQueryStr, tableName);

                conn.Open();
                
                SqlCommand cmd = new SqlCommand(sqlQueryStr, conn);
                cmd.CommandType = CommandType.Text;
                cmd.CommandTimeout = 10;
                cmd.ExecuteNonQuery();
            }
            catch (Exception Ex)
            {
                System.Console.WriteLine("Trouble truncating destination DB table. See error message below:");
                System.Console.WriteLine(Ex.Message);
            }
            finally
            {
                conn.Close();
            }
        }

        public static void GetNumExcelColumns()
        {
            // Get number of columns that come from Excel
            numExcelColumns = 0;
            for (int k = 0; k < nameTypeMap.GetLength(0); k++)
            {
                // Excluded from DB table
                if (nameTypeMap[k, 7] == "true")
                {
                    continue;
                }

                if (nameTypeMap[k, 5] == "true")
                {
                    numExcelColumns = numExcelColumns + 1;
                }
            }
        }

        public static void FillTable(string tableName, DataTable dt, bool willTruncateTable)
        {
            string sqlConnStr = Properties.Settings.Default.SQLConnStr;
            SqlConnection conn = new SqlConnection(sqlConnStr);
            SqlBulkCopy bulkCopy = new SqlBulkCopy(conn, SqlBulkCopyOptions.KeepIdentity, null);

            try
            {
                bulkCopy.DestinationTableName = tableName;

                // Map Excel columns to DB columns 
                for (int i = 0; i < numExcelColumns; i++)
                {
                    // Excluded from DB table
                    if (nameTypeMap[i, 7] == "true")
                    {
                        continue;
                    }

                    bulkCopy.ColumnMappings.Add(nameTypeMap[i,0], nameTypeMap[i,1]);
                }

                // Truncate value coming from Excel file if it is larger than the DB column size
                //dt = TruncateColumnSize(dt, bulkCopy, dtc);

                // Remove null values in DataTable because bulk copy cannot handle nulls
                dt = RemoveNullValue(dt);

                // Truncate DB table
                if (willTruncateTable)
                { 
                    TruncateTable(tableName);
                }

                // Get Max and Min values from ID column for each 1000 rows
                double finalRowCnt = dt.Rows.Count;
                int numInsert = Convert.ToInt32(Math.Ceiling(finalRowCnt / Convert.ToDouble(1000)));
                int[,] range = new int[numInsert, 2];
                int idxInsert = numInsert - 1;

                for (int i = 0; i < dt.Rows.Count; i = i + 1000)
                {
                    // Set start of range
                    range[idxInsert, 0] = Convert.ToInt32(dt.Rows[i]["SPOExcelFile2SQL_ID"]);

                    // Set end of range
                    int j = 0;
                    if ((i + 999) > (dt.Rows.Count - 1))
                    {
                        j = dt.Rows.Count - 1;
                    }
                    else
                    {
                        j = i + 999;
                    }
                    range[idxInsert, 1] = Convert.ToInt32(dt.Rows[j]["SPOExcelFile2SQL_ID"]);

                    idxInsert = idxInsert - 1;
                }

                // Add file specific column
                for (int j = 0; j < nameTypeMap.GetLength(0); j++)
                {
                    // Excluded from DB table
                    if (nameTypeMap[j, 7] == "true")
                    {
                        continue;
                    }

                    if (nameTypeMap[j, 5] == "false")
                    {
                        dt.Columns.Add(nameTypeMap[j, 0], typeof(string));
                        for (int k = 0; k < dt.Rows.Count; k++)
                        {
                            dt.Rows[k][nameTypeMap[j, 0]] = nameTypeMap[j, 6];
                        }
                    }
                }

                // Incrementally insert data into relational DB table 1000 rows at a time
                System.Console.WriteLine("");
                conn.Open();
                for (int i = 0; i < numInsert; i++)
                {
                    DataTable dt2 = dt.Select("SPOExcelFile2SQL_ID >= " + range[i, 0] + " and SPOExcelFile2SQL_ID <= " + range[i, 1]).CopyToDataTable();// grab up to 1000 records at a time.
                    dt2.Columns.Remove("SPOExcelFile2SQL_ID"); // Remove the temp column that was added in this application.

                    bulkCopy.WriteToServer(dt2);
                    System.Console.WriteLine("Copy " + dt2.Rows.Count.ToString() + " rows and " + dt2.Columns.Count.ToString() + " columns from DataTable to relational DB table.");
                }
            }
            catch (Exception Ex)
            {
                System.Console.WriteLine("Below error occured when attempting to insert the data into the DB:");
                System.Console.WriteLine(Ex.StackTrace);
                System.Console.WriteLine(Ex.Message);
            }
            finally
            {
                conn.Close();
            }
        }

        static void GetFY16VendorBudgetUp_NameTypeMap()
        {
            try
            {
                // Excel (& DataTable) column name, DB column name, DataTable type, DB type, DB string column length, comes from Excel and not this app, value from this app if field comes from this app, excluded from DB table
                nameTypeMap = new string[13, 8]{
                   {"Team","Team","string","nvarchar(255)","","true","","false"},
                   {"IO","IO","string","nvarchar(255)","","true","","false"},
                   {"IO Desc","IO Desc","string","nvarchar(255)","","true","","false"},
                   {"Purpose","Purpose","string","nvarchar(255)","","true","","false"},
                   {"Vendor","Vendor","string","nvarchar(255)","","true","","false"},
                   {"PI","PI","string","nvarchar(255)","","true","","false"},
                   {"PO Number","PO Number","string","nvarchar(255)","","true","","false"},
                   {"Invoice Month","Invoice Month","float","float","","true","","false"},
                   {"Month","Month","string","nvarchar(255)","","true","","false"},
                   {"Current Fcast","Current Fcast","float","true","","true","","false"},
                   {"Actual","Actual","float","float","","true","","false"},
                   {"Act Or Fcst","Act Or Fcst","float","float","","true","","false"},
                   { "FiscalYear","FiscalYear","string","nvarchar(4)","","false","FY16","false"}
                };

                SetDBStringColLengthInMap();
            }
            catch(Exception ex)
            {
                System.Console.WriteLine("Error occurred when creating name & type map:");
                System.Console.WriteLine(ex.Message);
                System.Console.WriteLine("");
            }
        }

        static void GetITShowcaseFY17Budget_NameTypeMap()
        {
            try
            {
                // Excel (& DataTable) column name, DB column name, DataTable type, DB type, DB string column length, comes from Excel and not this app,value from this app if field comes from this app, excluded from DB table
                nameTypeMap = new string[16, 8]{
               {"Fiscal Year","Fiscal Year","string","nvarchar(255)","","true","","false"},
               {"Fiscal Quarter","Fiscal Quarter","string","nvarchar(255)","","true","","false"},
               {"Exec Function Summary","Exec Function Summary","string","nvarchar(255)","","true","","false"},
               {"IO No. & Description","IO No# & Description","string","nvarchar(255)","","true","","false"},
               {"CC No. & Description","CC No# & Description","string","nvarchar(255)","","true","","false"},
               {"Account No. & Description","Account No# & Description","string","nvarchar(255)","","true","","false"},
               {"Line Item","Line Item","string","nvarchar(255)","","true","","false"},
               {"Class","Class","string","nvarchar(255)","","true","","false"},
               {"Forecast Version","Forecast Version","string","nvarchar(255)","","true","","false"},
               {"Fiscal Month","Fiscal Month","string","nvarchar(255)","","true","","false"},
               {"Sub Class","Sub Class","string","nvarchar(255)","","true","","false"},
               {"Exec Function","Exec Function","string","nvarchar(255)","","true","","false"},
               {"Actual","Actual","float","float","","true","","false"},
               {"Budget","Budget","float","float","","true","","false"},
               {"Profit Center SEC Func Area","Profit Center SEC Func Area","string","nvarchar(255)","","true","","false"},
               {"Forecast","Forecast","float","float","","true","","false"}
               };

               SetDBStringColLengthInMap();
            }
            catch (Exception ex)
            {
                System.Console.WriteLine("Error occurred when creating name & type map:");
                System.Console.WriteLine(ex.Message);
                System.Console.WriteLine("");
            }
        }

        static void GetFY17VendorBudget_NameTypeMap()
        {
            try
            {
                // Excel (& DataTable) column name, DB column name, DataTable type, DB type, DB string column length, comes from Excel and not this app, value from this app if field comes from this app, excluded from DB table
                nameTypeMap = new string[14, 8]{
                   {"Team","Team","string","nvarchar(255)","","true","","false"},
                   {"IO","IO","string","nvarchar(255)","","true","","false"},
                   {"IO Desc","IO Desc","string","nvarchar(255)","","true","","false"},
                   {"Purpose","Purpose","string","nvarchar(255)","","true","","false"},
                   {"Vendor","Vendor","string","nvarchar(255)","","true","","false"},
                   {"PI","PI","string","nvarchar(255)","","true","","false"},
                   {"Owner","Owner","string","","","true","","true"},
                   {"PO Number","PO Number","string","nvarchar(255)","","true","","false"},
                   {"Invoice Month","Invoice Month","float","float","","true","","false"},
                   {"Month","Month","string","nvarchar(255)","","true","","false"},
                   {"Current Fcast","Current Fcast","float","true","","true","","false"},
                   {"Actual","Actual","float","float","","true","","false"},
                   {"Act Or Fcst","Act Or Fcst","float","float","","true","","false"},
                   { "FiscalYear","FiscalYear","string","nvarchar(4)","","false","FY17","false"}
                };

                SetDBStringColLengthInMap();
            }
            catch(Exception ex)
            {
                System.Console.WriteLine("Error occurred when creating name & type map:");
                System.Console.WriteLine(ex.Message);
                System.Console.WriteLine("");
            }

        }

        public static void SetDBStringColLengthInMap()
        {
            // String length of string columns
            for (int i = 0; i < nameTypeMap.GetLength(0); i++)
            {
                // Excluded from DB table
                if (nameTypeMap[i, 7] == "true")
                {
                    continue;
                }

                string[] s = new string[1] { "(" };
                string type = nameTypeMap[i, 3].Split(s, StringSplitOptions.None)[0];
                string[] s2 = new string[1] { ")" };
                string size = "";
                switch (type)
                {
                    case "varchar":
                        switch (size)
                        {
                            case "max":
                                nameTypeMap[i, 4] = "8000";
                                break;
                            default:
                                size = nameTypeMap[i, 3].Split(s, StringSplitOptions.None)[1].Split(s2, StringSplitOptions.None)[0];
                                nameTypeMap[i, 4] = size;
                                break;
                        }
                        break;
                    case "nvarchar":
                        switch (size)
                        {
                            case "max":
                                nameTypeMap[i, 4] = "4000";
                                break;
                            default:
                                size = nameTypeMap[i, 3].Split(s, StringSplitOptions.None)[1].Split(s2, StringSplitOptions.None)[0];
                                nameTypeMap[i, 4] = size;
                                break;
                        }
                        break;
                }
            }
        }


        public static DataTable RemoveNullValue(DataTable dt)
        {
            try
            { 
                for(int i = 0; i < numExcelColumns; i++)
                {
                    // Excluded from DB table
                    if (nameTypeMap[i, 7] == "true")
                    {
                        continue;
                    }

                    DataRow[] nullRow = null;
                    if(nameTypeMap[i, 5] == "true")
                    { 
                        nullRow = dt.Select("[" + nameTypeMap[i,0] + "] is null");
                    }

                    // Skip column if no null values found
                    if (nullRow == null || nullRow.Length == 0)
                    {
                        System.Console.WriteLine("[" + nameTypeMap[i, 0] + "] column has no null values in DataTable");
                        System.Console.WriteLine("");
                        continue;
                    }

                    System.Console.WriteLine("[" + nameTypeMap[i, 0] + "] column has " + nullRow.Length.ToString() + " null values in DataTable");
                    System.Console.WriteLine("");

                    // Set value blank instead of null
                    for (int j = 0; j < nullRow.Length; j++)
                    {
                        nullRow[j][nameTypeMap[i, 0]] = GetNullDataTableReplacement(nameTypeMap[i,2]);
                    }
                }
            }
            catch(Exception ex)
            {
                System.Console.WriteLine("Below error occurred when removing null values:");
                System.Console.WriteLine(ex.Message);
                System.Console.WriteLine("");
            }
            return dt;
        }

        public static DataTable TruncateColumnSize(DataTable dt, SqlBulkCopy bulkCopy, DataTable dtc)
        {
            string dbColName = "";
            int dbColLen = 0;
            string dtColName = "";
            int dtColLen = 0;
            bool colTruncated = false;

            try
            {
                // Loop through all the string column names in the database
                System.Console.Write("Columns truncated in DataTable:");
                foreach (DataRow r in dtc.Rows)
                {
                    // Skip if DB column data type not varchar or nvarchar
                    if ("|varchar|nvarchar|".IndexOf(r[2].ToString()) == -1)
                    {
                        continue;
                    }

                    dbColName = r[0].ToString();
                    dbColLen = Convert.ToInt32(r[1].ToString());

                    SqlBulkCopyColumnMappingCollection colMapColl = bulkCopy.ColumnMappings;
                    foreach (SqlBulkCopyColumnMapping colMap in colMapColl)
                    {

                        // See if DB column name found in the DataTable to DB column name mapping
                        if (colMap.DestinationColumn == dbColName)
                        {
                            dtColName = colMap.SourceColumn;
                            dtColLen = Convert.ToInt32(dt.AsEnumerable().Max(row => row[dtColName].ToString().Length));

                            // See if the column length in DataTable is greater than that in DB
                            if (dtColLen > dbColLen)
                            {
                                // Loop through all rows in the column
                                foreach (DataRow row in dt.Rows)
                                {
                                    // See if length of specific row is too big
                                    if (row[dtColName].ToString().Length > dbColLen)
                                    {
                                        // Truncate data in DataTable
                                        row[dtColName] = row[dtColName].ToString().Substring(0, dbColLen);
                                        colTruncated = true;
                                    }
                                }
                                System.Console.WriteLine(dtColName);
                            }

                            // Stop trying to find the matching column in the DataTable since already found
                            break;
                        }
                    }
                }

                // Order DataTable by ID column. The SP query includes an order by ID but it is not working. 
                DataView dv = dt.DefaultView;
                dv.Sort = "SPOExcelFile2SQL_ID asc";
                dt = dv.ToTable();

                return dt;
            }
            catch (Exception Ex)
            {
                System.Console.WriteLine("Error in when truncating column in Data Table");
                System.Console.WriteLine(Ex.StackTrace);
                System.Console.WriteLine(Ex.Message);
                return null;
            }
            finally
            {
                if (!colTruncated)
                {
                    System.Console.WriteLine("  No columns were truncated");
                }
            }
        }

        private static WorksheetPart GetWorksheetPartByName(SpreadsheetDocument document, string sheetName)
        {
            IEnumerable<Sheet> sheets =
               document.WorkbookPart.Workbook.GetFirstChild<Sheets>().
               Elements<Sheet>().Where(s => s.Name == sheetName);

            if (sheets.Count() == 0)
            {
                // The specified worksheet does not exist.

                return null;
            }

            string relationshipId = sheets.First().Id.Value;
            WorksheetPart worksheetPart = (WorksheetPart)
                 document.WorkbookPart.GetPartById(relationshipId);
            return worksheetPart;

        }

        public static string GetCellValue(Cell cell)
        {
            if (cell == null)
                return null;
            if (cell.DataType == null && cell.CellValue != null)
                return cell.CellValue.Text;
            if (cell.DataType == null && cell.CellValue == null)
                return cell.InnerText;

            string value = cell.InnerText;
            switch (cell.DataType.Value)
            {
                case CellValues.SharedString:
                    // For shared strings, look up the value in the shared strings table.
                    // Get worksheet from cell
                    OpenXmlElement parent = cell.Parent;
                    while (parent.Parent != null && parent.Parent != parent
                            && string.Compare(parent.LocalName, "worksheet", true) != 0)
                    {
                        parent = parent.Parent;
                    }
                    if (string.Compare(parent.LocalName, "worksheet", true) != 0)
                    {
                        throw new Exception("Unable to find parent worksheet.");
                    }

                    Worksheet ws = parent as Worksheet;
                    SpreadsheetDocument ssDoc = ws.WorksheetPart.OpenXmlPackage as SpreadsheetDocument;
                    SharedStringTablePart sstPart = ssDoc.WorkbookPart.GetPartsOfType<SharedStringTablePart>().FirstOrDefault();

                    // lookup value in shared string table
                    if (sstPart != null && sstPart.SharedStringTable != null)
                    {
                        value = sstPart.SharedStringTable.ElementAt(int.Parse(value)).InnerText;
                    }
                    break;

                //this case within a case is copied from msdn. 
                case CellValues.Boolean:
                    switch (value)
                    {
                        case "0":
                            value = "FALSE";
                            break;
                        default:
                            value = "TRUE";
                            break;
                    }
                    break;
            }
            return value.Trim();
        }

        private static IEnumerable<Cell> GetCellsFromRowIncludingEmptyCells(Row row)
        {
            int currentCount = 0;
            // row is a class level variable representing the current
            foreach (DocumentFormat.OpenXml.Spreadsheet.Cell cell in
                row.Descendants<DocumentFormat.OpenXml.Spreadsheet.Cell>())
            {
                string columnName = GetColumnName(cell.CellReference);
                int currentColumnIndex = ConvertColumnNameToNumber(columnName);
                //Return null for empty cells
                for (; currentCount < currentColumnIndex; currentCount++)
                {
                    yield return null;
                }
                yield return cell;
                currentCount++;
            }
        }

        public static string GetColumnName(string cellReference)
        {
            // Match the column name portion of the cell name.
            Regex regex = new Regex("[A-Za-z]+");
            Match match = regex.Match(cellReference);

            return match.Value;
        }

        public static void GetColFromThisAppNotExcel()
        {
            colFromThisAppNotExcel = "";

            for (int i = 0; i < nameTypeMap.GetLength(0);i++)
            {
                if(nameTypeMap[i,5] == "false")
                { 
                    if (colFromThisAppNotExcel.Length == 0)
                    {
                        colFromThisAppNotExcel = nameTypeMap[i, 0];
                    }
                    else
                    {
                        colFromThisAppNotExcel = colFromThisAppNotExcel + "|" + nameTypeMap[i, 0];
                    }
                }
            }
        }

        public static void GetColFromExcel()
        {
            colFromExcel = "";

            for (int i = 0; i < nameTypeMap.GetLength(0); i++)
            {
                if (nameTypeMap[i, 5] == "true")
                {
                    if (colFromExcel.Length == 0)
                    {
                        colFromExcel = nameTypeMap[i, 0];
                    }
                    else
                    {
                        colFromExcel = colFromExcel + "|" + nameTypeMap[i, 0];
                    }
                }
            }
        }

        public static void GetColFromExcelWillBeInDB()
        {
            colFromExcelWillBeInDB = "";

            for (int i = 0; i < nameTypeMap.GetLength(0); i++)
            {
                if (nameTypeMap[i, 5] == "true" && nameTypeMap[i,7] == "false")
                {
                    if (colFromExcelWillBeInDB.Length == 0)
                    {
                        colFromExcelWillBeInDB = nameTypeMap[i, 0];
                    }
                    else
                    {
                        colFromExcelWillBeInDB = colFromExcelWillBeInDB + "|" + nameTypeMap[i, 0];
                    }
                }
            }
        }

        static int ConvertColumnNameToNumber(string columnName)
        {
            Regex alpha = new Regex("^[A-Z]+$");
            if (!alpha.IsMatch(columnName)) throw new ArgumentException();

            char[] colLetters = columnName.ToCharArray();
            Array.Reverse(colLetters);

            int convertedValue = 0;
            for (int i = 0; i < colLetters.Length; i++)
            {
                char letter = colLetters[i];
                int current = i == 0 ? letter - 65 : letter - 64; // ASCII 'A' = 65
                convertedValue += current * (int)Math.Pow(26, i);
            }

            return convertedValue;
        }
    }
}
