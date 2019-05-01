using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Configuration;
using System.Security;
using Microsoft.SharePoint.Client;
using System.Net;
using System.Xml.Linq;
using System.IO;
using System.Data;
using System.Collections;
using System.Data.SqlClient;
using System.Text.RegularExpressions;

namespace SPOList2SQL
{
    class Program
    {
        static string[,] nameTypeMap;

        static void Main(string[] args)
        {
            try
            {
                string spNames = "|PI_Channels|PI_Promotions|PI|";
                if(args.Length == 0)
                {
                    System.Console.WriteLine("No parameter specified. Choose one of these: " + spNames.Replace("|", ","));
                    Environment.Exit(0);
                }
                if (spNames.IndexOf(args[0]) < 0)
                {
                    System.Console.WriteLine("Invalid parameter provided. Choose one of these: " + spNames.Replace("|",","));
                    Environment.Exit(0);
                }
                if(args.Length > 1)
                {
                    if (args[1] != "manual")
                    {
                        System.Console.WriteLine("Invalid second parameter provided. Can only specify 'manual'");
                        Environment.Exit(0);
                    }
                }
                if(args.Length > 2)
                {
                    System.Console.WriteLine("Too many parameters provided");
                    Environment.Exit(0);
                }

                DateTime startTime = DateTime.Now;

                string param = args[0];
                SPWSLists.Lists proxy = new SPOList2SQL.SPWSLists.Lists();
                string SPHostURL = ConfigurationManager.AppSettings.Get(param + "_SPHostURL");
                string O365UserName = ConfigurationManager.AppSettings.Get("O365UserName");
                string O365Password = ConfigurationManager.AppSettings.Get("O365Password");
                string actualSPListName = ConfigurationManager.AppSettings.Get(param + "_SPListName");
                proxy.CookieContainer = SharedStuff.GetAuthCookies(new Uri(SPHostURL), O365UserName, O365Password);
                proxy.Url = GenUtil.CombineUrls(SPHostURL, XMLConsts.AsmxSuffix_Lists);

                nameTypeMap = new string[,]{};

                // Get flag, SP Internal column name, SP internal type, DB table column name
                switch (param)
                {
                    case "PI_Channels":
                        GetPI_Channels_NameTypeMap();
                        break;
                    case "PI_Promotions":
                        GetPI_Promotions_NameTypeMap();
                        break;
                    case "PI":
                        GetPI_NameTypeMap();
                        break;
                }

                string strQuery = GenUtil.RemoveWhiteSpace(@"<OrderBy><FieldRef Name='ID'/></OrderBy>");
                strQuery = GenUtil.WrapWSQuery(strQuery);

                StringReader rdrQuery = new StringReader(strQuery);
                XElement xQuery = XElement.Load(rdrQuery);

                //
                string rowLimit = "5000";
                //
                string webID = "";

                //
                StringReader rdrQueryOptions = null;
                rdrQueryOptions = new StringReader("<QueryOptions><IncludeMandatoryColumns>FALSE</IncludeMandatoryColumns></QueryOptions>");
                XElement xQueryOptions = XElement.Load(rdrQueryOptions);

                //
                String[] strViewFields = new string[] { };

                switch (param)
                {
                    case "PI_Channels":
                        strViewFields = GetQuery(actualSPListName, xQuery, xQueryOptions, proxy, 1);
                        break;
                    case "PI_Promotions":
                        strViewFields = GetQuery(actualSPListName, xQuery, xQueryOptions, proxy, 1);
                        break;
                    case "PI":
                        strViewFields = GetQuery(actualSPListName,xQuery,xQueryOptions,proxy, 3);
                        break;
                }

                DataSet ds = new DataSet("ds");
                DataTable dt = null;
                // Loop through each query to pull data from a SharePoint list. Some lists may have more than one query. 
                for (int i = 0; i < strViewFields.Length; i++)
                {
                    System.Console.WriteLine("Query " + (i+1).ToString() + ":");
                    System.Console.WriteLine(strViewFields[i]);
                    System.Console.WriteLine("");
                    StringReader rdrViewFields = new StringReader(GenUtil.RemoveWhiteSpace(strViewFields[i].Trim()));
                    XElement xViewFields = null;
                    xViewFields = XElement.Load(rdrViewFields);

                    //
                    String viewName = "";

                    //
                    XElement results = proxy.GetListItems(
                        actualSPListName,
                        viewName,
                        xQuery.GetXmlNode(),
                        xViewFields.GetXmlNode(),
                        rowLimit,
                        xQueryOptions.GetXmlNode(),
                        webID).GetXElement();

                    dt = FillDataTable(results, strViewFields[i]);
                    ds.Tables.Add(dt);
                }

                // Merge DataTables together
                dt = MergeDataTables(ds);

                // Copy data to relational DB
                string tableName = ConfigurationManager.AppSettings.Get(param + "_TableName");
                SQLStuff.FillTable(tableName,dt,param,nameTypeMap);
                
                if(args.Length > 1)
                {
                    if (args[1] == "manual")
                    {
                        System.Console.WriteLine("");
                        System.Console.WriteLine("<Press Enter key to end application run>");
                        System.Console.ReadLine();
                    }
                }
                System.Console.WriteLine();
                System.Console.WriteLine("This run took " + DateTime.Now.Subtract(startTime).Seconds.ToString() + " seconds");
            }
            catch (Exception Ex)
            {
                System.Console.Write(Ex.Message);
                if(Ex.InnerException != null)
                {
                    System.Console.WriteLine(Ex.InnerException.Message);
                }
                System.Console.WriteLine(Ex.StackTrace);
            }
        }

        public static DataTable FillDataTable(XElement results,string strViewFields)
        {
            DataTable dt = null;
            dt = new DataTable();

            // Get column name
            string colName = "";
            string colName_wo_prefix = "";
            string colName_wo_prefix_w_quote = "";
            int colAddCnt = 0;
            foreach (XElement xRow in results.Descendants(XMLConsts.z + "row"))// Columns that have no data in the response will not be returned
            {
                foreach (XAttribute xAttr in xRow.Attributes())
                {
                    colName = xAttr.Name.ToString();
                    if (colName.IndexOf("ows_") == 0)
                    {
                        colName_wo_prefix = colName.Remove(0, 4);
                    }
                    else
                    {
                        colName_wo_prefix = colName;
                    }

                    colName_wo_prefix_w_quote = "'" + colName_wo_prefix + "'";

                    // limit to the columns that exist in the query and only add to DataTable once
                    if (!dt.Columns.Contains(colName_wo_prefix) && strViewFields.Contains(colName_wo_prefix_w_quote))
                    {
                        dt.Columns.Add(colName_wo_prefix, typeof(string));// Columns that have no data in the response will not be returned and will not be added to the DataTable.
                        colAddCnt = colAddCnt + 1;
                    }
                }
                // I would break out of this foreach loop after the first row but not all the columns may exist in the first row. 
            }

            System.Console.WriteLine(colAddCnt.ToString() + " columns " + results.Descendants(XMLConsts.z + "row").Count().ToString() + " rows were received from SP list.");
            System.Console.WriteLine("");

            // Set Data Type
            dt.Columns["ID"].DataType = typeof(Int32);

            // Add value
            foreach (XElement xRow in results.Descendants(XMLConsts.z + "row"))
            {
                DataRow dr = dt.NewRow();

                foreach (XAttribute xAttr in xRow.Attributes())
                {
                    colName = xAttr.Name.ToString();
                    colName_wo_prefix = colName.Remove(0, 4);
                    colName_wo_prefix_w_quote = "'" + colName_wo_prefix + "'";

                    // limit to the columns that exist in the query
                    if (strViewFields.Contains(colName_wo_prefix_w_quote))
                    {
                        string colVal = "";
                        string colType = "";
                        for(int i = 0; i < nameTypeMap.GetLength(0);i++)
                        {
                            if (nameTypeMap[i,1] == colName_wo_prefix)
                            {
                                colType = nameTypeMap[i,2];
                                break;
                            }
                        }

                        if (colType == "" && colName_wo_prefix == "ID")
                        {
                            colType = "Counter";
                        }

                        if (colType == "Text")
                        {
                            colVal = xAttr.Value;
                            dr[colName_wo_prefix] = colVal;
                        }

                        else if (colType == "URL")
                        {
                            colVal = xAttr.Value;
                            colVal = colVal.Remove(colVal.IndexOf(", "));
                            dr[colName_wo_prefix] = colVal;
                        }

                        else if (colType == "UserMulti")
                        {
                            colVal = xAttr.Value;
                            dr[colName_wo_prefix] = colVal;
                        }

                        else if (colType == "Number")
                        {
                            colVal = xAttr.Value;
                            dr[colName_wo_prefix] = colVal;
                        }

                        else if (colType == "Calculated")
                        {
                            colVal = xAttr.Value.Replace("string;#", "");
                            colVal = colVal.Replace("float;#", "");
                            if (colVal.Contains("error;#"))
                            {
                                colVal = null;
                            }
                            dr[colName_wo_prefix] = colVal;
                        }

                        else if (colType == "Lookup")
                        {
                            colVal = xAttr.Value;
                            colVal = colVal.Remove(0, colVal.IndexOf(";#") + 2);
                            dr[colName_wo_prefix] = colVal;
                        }

                        else if (colType == "Counter")
                        {
                            colVal = xAttr.Value;
                            dr[colName_wo_prefix] = colVal;
                        }

                        else if (colType == "MultiChoice")
                        {
                            colVal = xAttr.Value.Replace(";#", ";");
                            if (colVal.IndexOf(";") == 0)
                            {
                                colVal = colVal.Remove(0, 1);
                            }

                            if (colVal.LastIndexOf(";") == colVal.Length - 1)
                            {
                                colVal = colVal.Remove(colVal.Length - 1, 1);
                            }
                            dr[colName_wo_prefix] = colVal;
                        }

                        else if (colType == "DateTime")
                        {
                            colVal = xAttr.Value;
                            colVal = DateTime.Parse(colVal).ToShortDateString();
                            dr[colName_wo_prefix] = colVal;
                        }

                        else if (colType == "User")
                        {
                            colVal = xAttr.Value;
                            colVal = colVal.Remove(0, colVal.IndexOf(";#") + 2);
                            dr[colName_wo_prefix] = colVal;
                        }

                        else if (colType == "Boolean")
                        {
                            colVal = xAttr.Value;
                            if (colVal == "1")
                            {
                                colVal = "TRUE";
                            }
                            else
                            {
                                colVal = "FALSE";
                            }
                            dr[colName_wo_prefix] = colVal;
                        }

                        else if (colType == "Choice")
                        {
                            colVal = xAttr.Value;
                            dr[colName_wo_prefix] = colVal;
                        }

                        else if (colType == "LookupMulti")
                        {
                            colVal = xAttr.Value;
                            dr[colName_wo_prefix] = colVal;
                        }

                        else if (colType == "Computed")
                        {
                            colVal = xAttr.Value;
                            dr[colName_wo_prefix] = colVal;
                        }

                        else if (colType == "Note")
                        {
                            colVal = xAttr.Value;
                            dr[colName_wo_prefix] = colVal;
                        }

                        else if (colType == "Currency")
                        {
                            colVal = xAttr.Value;
                            dr[colName_wo_prefix] = colVal;
                        }

                        else if (colType == "TaxonomyFieldTypeMulti")
                        {
                            colVal = xAttr.Value;
                            dr[colName_wo_prefix] = colVal;
                        }

                        else if (colType == "TaxonomyFieldType")
                        {
                            colVal = xAttr.Value;
                            dr[colName_wo_prefix] = colVal;
                        }

                        else if (colType == "WorkflowStatus")
                        {
                            colVal = xAttr.Value;
                            dr[colName_wo_prefix] = colVal;
                        }

                        else
                        {
                            System.Console.WriteLine(String.Concat(colName_wo_prefix," is a '", colType, "' SharePoint column type that is not handled"));
                            System.Console.WriteLine("");
                        }
                    }
                }

                dt.Rows.Add(dr);
            }

            return dt;
        }

        static DataTable MergeDataTables(DataSet ds)
        {   
            // only one DataTable 
            if(ds.Tables.Count == 1)
            {
                return ds.Tables[0];
            }

            // More than one DataTable

            // Set primary key for each DataTable
            for (int i = 0;i < ds.Tables.Count; i++)
            {
                ds.Tables[i].PrimaryKey = new DataColumn[] { ds.Tables[i].Columns["ID"] };
            }

            // Create a final DataTable structure
            ds.Tables.Add("dtFinal");

            // Loop through each parent DataTable
            for (int i = 0; i < ds.Tables.Count; i++)
            {
                //System.Console.WriteLine(ds.Tables[i].TableName + " DataTable");//test

                if (ds.Tables[i].TableName == "dtFinal")
                {
                    continue;
                }

                if (i == 0)
                {
                    foreach (DataColumn c in ds.Tables[i].Columns)
                    {
                        //System.Console.WriteLine(c.ColumnName + " column from " + ds.Tables[i].TableName + " DataTable");//test

                        // Add new column to final DataTable
                        ds.Tables["dtFinal"].Columns.Add(new DataColumn(c.ColumnName, c.DataType));
                    }
                    continue;
                }

                // Loop through each column in current DataTable
                foreach (DataColumn c in ds.Tables[i].Columns)
                {
                    //System.Console.WriteLine(c.ColumnName + " column from " + ds.Tables[i].TableName + " DataTable");//test

                    // Skip "ID" column
                    if (c.ColumnName == "ID")
                    {
                        continue;
                    }

                    // Add new column to final DataTable
                    ds.Tables["dtFinal"].Columns.Add(new DataColumn(c.ColumnName, c.DataType));
                }
            }

            // Fill the ID column in the final DataTable
            foreach (DataRow dr in ds.Tables[0].Rows)
            {
                DataRow newRow = ds.Tables["dtFinal"].NewRow();
                newRow["ID"] = dr["ID"];
                ds.Tables["dtFinal"].Rows.Add(newRow);
            }

            // Set relations between DataTables and final DataTable
            for (int i = 0; i < ds.Tables.Count; i++)
            {
                if(ds.Tables[i].TableName == "dtFinal")
                {
                    continue; 
                }

                // parent : child
                string relationName = "dt" + i.ToString();
                DataRelation drel = new DataRelation(relationName, ds.Tables[i].Columns["ID"], ds.Tables["dtFinal"].Columns["ID"]);
                ds.Relations.Add(drel);
            }

            // Fill the final DataTable

            // Loop through DataTables
            for (int i = 0; i < ds.Tables.Count; i++)
            {
                // Skip dtFinal table
                if(ds.Tables[i].TableName == "dtFinal")
                {
                    continue;
                }

                System.Console.WriteLine("Adding " + ds.Tables[i].TableName + " DataTable to final DataTable.");
                System.Console.WriteLine("");

                // Loop through rows in final DataTable
                bool showMessage = true;
                foreach (DataRow dr in ds.Tables["dtFinal"].Rows)
                {
                    string relationName = "dt" + i.ToString();
                    DataRow pdr = dr.GetParentRow(relationName);

                    // Skip attempt to get columns from parent row if parent row does not exist. 
                    if (pdr == null)
                    {
                        if (showMessage)
                        {
                            System.Console.WriteLine("At least one parent row does not exist in '" + ds.Relations[relationName].ParentTable.TableName + "' DataTable");
                            System.Console.WriteLine("");
                            showMessage = false;
                        }
                        continue;
                    }

                    // Get number of columns in parent DataTable
                    int parentLen = pdr.ItemArray.Length - 1;

                    // Loop through columns in parent DataTable
                    string pColName = "";
                    for (int j = 0;j < parentLen; j++)
                    {
                        // Get column name from parent DataTable
                        pColName = ds.Relations[relationName].ParentTable.Columns[j].ColumnName;

                        //System.Console.WriteLine(pColName + " column in " + ds.Tables[i].TableName + " DataTable");//test

                        // Skip "ID" column
                        if (pColName == "ID")
                        {
                            continue;
                        }

                        // Assign value to cell in final DataTable
                        dr[pColName] = pdr[pColName];
                    }
                }
            }

            return ds.Tables["dtFinal"];
        }

        static string[] GetQuery(string actualSPListName, XElement xQuery, XElement xQueryOptions, SPWSLists.Lists proxy, int numQueries)
        {
            // Types that need to be checked
            string strType =
            "|MultiChoice|" +
            "|DateTime|" +
            "|UserMulti|" +
            "|Lookup|" +
            "|WorkflowStatus|" +
            "|TaxonomyFieldTypeMulti|" +
            "|Note|";

            System.Console.WriteLine("SharePoint list column types checked to see if they can be pulled:");
            System.Console.WriteLine(strType);
            System.Console.WriteLine("");

            string[] strFullQueries = new string[numQueries];
            string strFieldQuery = "";

            // Number of columns in each query
            double possibleColCnt = nameTypeMap.GetLength(0);
            for (int i = 0; i < nameTypeMap.GetLength(0);i++)
            {
                if(nameTypeMap[i,1] == "ID")
                {
                    possibleColCnt = possibleColCnt - 1; // Remove ID column from the count. 
                }
                if(nameTypeMap[i,0] == "2")
                {
                    possibleColCnt = possibleColCnt - 1; // Remove extra mappings so that column only pulled once from SP List.
                }
            }

            double aColCntPerQuery = possibleColCnt / Convert.ToDouble(numQueries);

            double colCntPerQuery = Math.Floor(aColCntPerQuery);

            double[] columnCnt = new double[numQueries];

            double runningCnt = 0;
            for(int i = 0;i < numQueries;i++)
            {
                runningCnt = runningCnt + colCntPerQuery;

                if(i == (numQueries - 1) && colCntPerQuery < aColCntPerQuery)
                {
                    runningCnt = runningCnt + Math.Ceiling(numQueries * (aColCntPerQuery - colCntPerQuery));
                }
                columnCnt[i] = runningCnt;

                System.Console.WriteLine("Would like to pull " + (columnCnt[i] - (i > 0 ? columnCnt[i-1] : 0)).ToString() + " SP List columns with Query " + (i + 1).ToString() + ". ID column not included in count.");
                System.Console.WriteLine("");
            }

            // Loop through fields
            System.Console.WriteLine("Query 1 of " + numQueries.ToString() + " being created.");
            System.Console.WriteLine("");

            int queryNum = 0;
            int loopCnt = 1;
            for (int i = 0; i < nameTypeMap.GetLength(0); i++)
            {
                // Skip ID column. It will be included later.
                if(nameTypeMap[i, 1] == "ID")
                {
                    nameTypeMap[i,0] = "1";
                    continue; 
                }

                // Skip instances that are mapped more than once to a DB table
                if(nameTypeMap[i,0] == "2")
                {
                    continue;
                }

                // Create field specific query string
                strFieldQuery = "<FieldRef Name = '"+ nameTypeMap[i, 1] + "' />"; 

                // Add fields to full query that do not need to be checked
                if (strType.IndexOf(nameTypeMap[i, 2]) < 0)
                {
                    strFullQueries[queryNum] = strFullQueries[queryNum] + strFieldQuery;
                    nameTypeMap[i,0] = "1";

                    // Update the query number that is being used
                    loopCnt = loopCnt + 1;
                    if (loopCnt > columnCnt[queryNum] && (loopCnt - 1) == columnCnt[queryNum])
                    {
                        queryNum = queryNum + 1;
                        if(numQueries > 1)
                        { 
                            System.Console.WriteLine("Query " + (queryNum + 1).ToString() + " of " + numQueries.ToString() + " being created.");
                            System.Console.WriteLine("");
                        }
                    }
                    continue;
                }
                else
                {
                    try
                    {
                        StringReader rdrViewFields = new StringReader("<ViewFields>" + strFieldQuery + "</ViewFields>");
                        XElement xViewFields = XElement.Load(rdrViewFields);

                        // Check field
                        XElement results = proxy.GetListItems(
                            actualSPListName,
                            "",
                            xQuery.GetXmlNode(),
                            xViewFields.GetXmlNode(),
                            "5000",
                            xQueryOptions.GetXmlNode(),
                            "").GetXElement();

                        // Add fields to query that successfully pass the check
                        strFullQueries[queryNum] = strFullQueries[queryNum] + strFieldQuery;
                        nameTypeMap[i,0] = "1";

                        // Update the query number that is being used
                        loopCnt = loopCnt + 1;
                        if (loopCnt > columnCnt[queryNum] && (loopCnt - 1) == columnCnt[queryNum])
                        {
                            queryNum = queryNum + 1;
                            if (numQueries > 1)
                            {
                                System.Console.WriteLine("Query " + (queryNum + 1).ToString() + " of " + numQueries.ToString() + " being created.");
                                System.Console.WriteLine("");
                            }
                        }
                    }
                    catch (System.InvalidOperationException Ex)
                    {
                        nameTypeMap[i,0] = "0";
                        System.Console.WriteLine(nameTypeMap[i,1] + " SharePoint column cannot be pulled because it likely has an invalid character in the XML response of the GetListItems method. Error shown below.");
                        if (Ex.InnerException != null)
                        {
                            System.Console.WriteLine(Ex.InnerException.Message);// Show the invalid character
                        }
                        System.Console.WriteLine("");

                        // Update the query number that is being used
                        loopCnt = loopCnt + 1;
                        if (loopCnt > columnCnt[queryNum] && (loopCnt - 1) == columnCnt[queryNum])
                        {
                            queryNum = queryNum + 1;
                            if (numQueries > 1)
                            {
                                System.Console.WriteLine("Query " + (queryNum + 1).ToString() + " of " + numQueries.ToString() + " being created.");
                                System.Console.WriteLine("");
                            }
                        }
                        continue;
                    }
                    catch (Exception Ex)
                    {
                        nameTypeMap[i,0] = "0";

                        // Do not add the field to the full query if not successful
                        System.Console.WriteLine(nameTypeMap[i, 1] + " SharePoint column cannot be pulled for a reason other than an invalid character. Error shown below.");
                        System.Console.WriteLine(Ex.StackTrace);
                        System.Console.WriteLine("");

                        // Update the query number that is being used
                        loopCnt = loopCnt + 1;
                        if (loopCnt > columnCnt[queryNum] && (loopCnt - 1) == columnCnt[queryNum])
                        {
                            queryNum = queryNum + 1;
                            if (numQueries > 1)
                            {
                                System.Console.WriteLine("Query " + (queryNum + 1).ToString() + " of " + numQueries.ToString() + " being created.");
                                System.Console.WriteLine("");
                            }
                        }
                        continue;
                    }
                }
            }

            // Flag extra column mappings as not usable if the first one cannot be pulled from SharePoint
            for(int i = 0;i < nameTypeMap.GetLength(0);i++)
            {
                // Find extra column mapping
                if(nameTypeMap[i,0] == "2")
                {
                    for(int j = 0; j < nameTypeMap.GetLength(0);j++)
                    {
                        // Find first column mapping that has the same SP List column name and has been flagged to not be included.
                        if(nameTypeMap[i, 1] == nameTypeMap[j,1] && nameTypeMap[j, 0] == "0")
                        {
                            nameTypeMap[i, 0] = "0";
                        }
                    }
                }
            }

            // Finish each query
            for(int i = 0; i < numQueries;i++)
            {
                strFullQueries[i] = "<FieldRef Name = 'ID' />" + strFullQueries[i]; // Make sure ID is in each query. This is used to join the data when there is more than one data pull for a SP list.
                strFullQueries[i] = "<ViewFields>" + strFullQueries[i] + "</ViewFields>";
                int getInQCnt = strFullQueries[i].Split(new string[1] { "<FieldRef Name" }, StringSplitOptions.RemoveEmptyEntries).Length - 1;
                System.Console.WriteLine("Will pull " + getInQCnt.ToString() + " SP List columns with Query " + (i + 1).ToString() + ". This count includes ID column.");
                System.Console.WriteLine("");
            }

            return strFullQueries;
        }

        static void GetPI_Channels_NameTypeMap()
        {
            nameTypeMap = new string[7, 4]{
            {"0","Title", "Text","Channel"},
            {"0","Channel_x0020_Link", "URL","Channel Link"},
            {"0","Channel_x0020_Owner_x0028_s_x002", "UserMulti","Channel Owner(s)"},
            {"0","Reach", "Number","Reach"},
            {"0","Tier", "Calculated","Tier"},
            {"0","FSObjType", "Lookup","Item Type"},
            {"0","FileDirRef", "Lookup","Path"}
            };
        }

        static void GetPI_Promotions_NameTypeMap()
        {
            nameTypeMap = new string[27, 4]{
            {"0","Pi_x0020_ID", "Text","Pi ID"},
            {"0","Actual_x0020_Publish_x0020_Date", "DateTime","Actual Publish Date"},
            {"0","Link", "URL","Link"},
            {"0","Alias", "Text","Alias"},
            {"0","AppAuthor", "Lookup","App Created By"}, 
            {"0","AppEditor", "Lookup","App Modified By"},
            {"0","ContentType", "Computed","Content Type"},
            {"0","Created", "DateTime","Created"},
            {"0","Author", "User","Created By"},
            {"0","Desired_x0020_Go_x002d_Live_x002", "DateTime","Desired Go-Live Date"},
            {"0","Event", "Text","Event"},
            {"0","FolderChildCount", "Lookup","Folder Child Count"},
            {"0","ID", "Counter","ID"},
            {"0","InQueueLogic", "Text","InQueueLogic"},
            {"0","InQueueNotification", "URL","InQueueNotification"},
            {"0","Is_x0020_Go_x002d_Live_x0020_Dat", "Boolean","Is Go-Live Date Flexible?"},
            {"0","Is_x0020_this_x0020_Promotion_x0", "Boolean","Is this Promotion tied to an event?"},
            {"0","ItemChildCount", "Lookup","Item Child Count"},
            {"0","Title", "Text","ITSC Content Title"},
            {"0","Modified", "DateTime","Modified"},
            {"0","Editor", "User","Modified By"},
            {"0","Requestor", "User","Requestor"},
            {"0","Status", "Choice","Status"},
            {"0","SubmissionAcknowledgement", "URL","SubmissionAcknowledgement"},
            {"0","FSObjType", "Lookup","Item Type"},
            {"0","FileDirRef", "Lookup","Path"},
            {"0","Channel_x0028_s_x0029_", "LookupMulti","Channel"}
            };
        }

        static void GetPI_NameTypeMap()
        {
            nameTypeMap = new string[172, 4]{
                {"0","ID", "Counter","ID"},
                {"0","Project_x0020_Insight_x0020_Fami", "Lookup","Project Name"},
                {"0","IT_x0020_Marcom_x0020_Function", "Choice","Functional Area"},
                {"0","Deliverable", "Choice","Deliverable"},
                {"0","IT_x0020_Showcase_x0020_Content_", "Text","ITSC Content Title"},
                {"0","Project_x0020_Name", "Note","Deliverable Description"},
                {"0","IT_x0020_MarCom_x0020_PM_x0020_L", "User","Project Owner"},
                {"0","Deliverable_x0020_Owner", "User","Deliverable Owner"},
                {"0","Project_x0020_Status", "Choice","Status"},
                {"0","StartDate", "DateTime","Anticipated Start Date"},
                {"0","Delivery_x0020_Quarter", "Choice","Delivery Quarter"},
                {"0","Lead_x0020_Time_x0020_Issue", "Choice","Lead Time Issue"},
                {"0","MS_x0020_IT_x0020_Sponsor", "Choice","CIO Direct Report"},
                {"0","Products", "Choice","Microsoft Product(s)"},
                {"0","Resources", "UserMulti","Supporting IT Marcom Resources"},
                {"0","Is_x0020_Funding_x0020_Needed_x00", "Choice","Is Funding Needed?"},
                {"0","Funder_x0020_1", "Choice","Funder 1"},
                {"0","Funder_x0020_2", "Choice","Funder 2"},
                {"0","Funder_x0020__x0024__x0020_Amoun", "Currency","Funder 1 $ Amount"},
                {"0","Funder_x0020__x0024__x0020_Amoun0", "Currency","Funder 2 $ Amount"},
                {"0","Pub_x0020_to_x0020_Primary_x0020", "DateTime","Pub to Primary_Date"},
                {"0","Pub_Accepted_x0020_for_x0020_Rel", "DateTime","Accepted for Pub"},
                {"0","Opp_x0020_Start", "DateTime","Opp Start"},
                {"0","Plan_x0020_Start", "DateTime","Plan Start"},
                {"0","Ready_x0020_for_x0020_Dev_x002c_", "DateTime","Ready for Dev, Forecast"},
                {"0","Notes_x003a__x0020_PM_x0020_to_x", "Note","Notes: PM to Dev Hand-off"},
                {"0","Notes_x003a__x0020_Dev_x0020_to_", "Note","Notes: Dev to PM Hand-off"},
                {"0","Notes_x003a__x0020_PM_x0020_to_x0", "Note","Notes: CDM to Pubs Hand-off"},
                {"0","Notes_x003a__x0020_Pubs_x0020_to", "Note","Notes: Pubs to PM Hand-off"},
                {"0","Request_x0020_accepted_x0020_by_", "DateTime","Request accepted by CDM"},
                {"0","Content_x0020_delivered_x0020_to", "DateTime","Content delivered to PM"},
                {"0","Content_x0020_accepted_x0020_by_", "DateTime","Content accepted by PM"},
                {"0","Submit_x0020_for_x0020_Pub_x002c", "DateTime","Submit for Pub, Actual"},
                {"0","Delivery_x0020_End_x0020_Date_x0", "DateTime","Delivery End Date, Dev SLA"},
                {"0","Academy_x0020_URL_x0020_NEW", "URL","Academy URL NEW"},
                {"0","Funder1IO", "Text","Funder 1 - IO"},
                {"0","Funder2IO", "Text","Funder 2 - IO"},
                {"0","TechTrend", "TaxonomyFieldTypeMulti","Tech Trend"},
                {"0","ITTopic", "TaxonomyFieldTypeMulti","IT Topic"},
                {"0","ITSPrimaryProduct", "TaxonomyFieldTypeMulti","ITS Product"},
                {"0","Previous_x0020_Published_x0020_L", "URL","Previous Published Location"},
                {"0","SubmitHandoff", "MultiChoice","SubmitHandoff"},
                {"0","SubmitHandoffActual", "DateTime","SubmitHandoffActual"},
                {"0","NotesHandoff", "Note","NotesHandoff"},
                {"0","ITSCURL", "URL","ITSC Portal URL"},
                {"0","ITSCPubDate", "DateTime","ITSC Portal Pub Date"},
                {"0","Program", "Choice","Program"},
                {"0","Benefits", "Note","Benefits"},
                {"0","SME_x0020_Notes", "Note","SME Notes"},
                {"0","Deliverable_x0020_Status", "Choice","Deliverable Status"},
                {"0","Vendor", "Choice","Vendor"},
                {"0","LeadOwner", "Choice","LeadOwner"},
                {"0","LeadAmount", "Currency","LeadAmount"},
                {"0","Internal_x0020__x002f__x0020_Ext", "Choice","Internal / External"},
                {"0","Gold_x0020_Copy_x0020_Location", "URL","Gold Copy Location"},
                {"0","Publication_x0020_Location", "URL","Publication Location"},
                {"0","Secondary_x0020_Publication_x002", "URL","Secondary Publication Location"},
                {"0","Publication_x0020_Location_x0020", "Choice","Publication Location Type"},
                {"0","Secondary_x0020_Publication_x0020", "Choice","Secondary Publication Location Type"},
                {"0","New_x0020__x002f__x0020_Update", "Choice","Action Requested"},
                {"0","Gold_x0020_Location", "Note","Gold Location"},
                {"0","Publication_x0020_Location_x00200", "Note","Publication Location Text"},
                {"0","Secondary_x0020_Publication_x0021", "Note","Secondary Publication Location Text"},
                {"0","Solution", "Note","Solution"},
                {"0","Pub_x0020_SLA", "DateTime","Pub SLA"},
                {"0","Content_x0020_PM", "User","Content PM"},
                {"0","Link_x0020_to_x0020_doc", "URL","Project Documents"},
                {"0","Publication_x0020_SLA", "Choice","Publication SLA"},
                {"0","Publication_x0020_Date0", "DateTime","Publication Date"},
                {"0","SLA_x0020_Timeframe", "Choice","SLA Timeframe"},
                {"0","I_x0020_want_x0020_to_x0020_lear", "Choice","I want to learn about…"},
                {"0","Readiness_x0020_Tag_x0020_Device", "Choice","Readiness Tag Devices"},
                {"0","Readiness_x0020_Tag_x0020_LOB", "Choice","Readiness Tag LOB"},
                {"0","Readiness_x0020_Tag_x0020_Produc", "Choice","Readiness Tag Products"},
                {"0","Readiness_x0020_Tag_x0020_Servic", "Choice","Readiness Tag Services"},
                {"0","Readiness_x0020_Tag_x0020_Window", "Choice","Readiness Tag Windows"},
                {"0","Sync_x0020_Pub", "URL","Sync Pub"},
                {"0","Infopedia_x0020_Doc_x0020_ID", "Text","Infopedia Doc ID"},
                {"0","Anticipated_x0020_Hand_x002d_off", "DateTime","Est# Submit to Pub date"},
                {"0","Localization", "Note","Localization"},
                {"0","CRBApproved", "Boolean","CRB Approved"},
                {"0","AlignedtoPPS", "Choice","Aligned to PPS"},
                {"0","AlignedtoMEPs", "Choice","Aligned to MEPs"},
                {"0","MicrosoftAmbitions", "Choice","Microsoft Ambitions"},
                {"0","ProjectDocs", "Note","Project Document"},
                {"0","CustomerPromises", "Lookup","Customer Promises"},
                {"0","CustomerPromises_x003a_VSO_x0020", "Lookup","Customer Promises: VSO ID"},
                {"0","MEPS_x0020_USER_x0020_STORY_x003", "Text","MEPS USER STORY: VSO ID"},
                {"0","_x0023__x0020_Days_x0020_to_x002", "Text","# Days to Pub"},
                {"0","Academy_x0020_Pub_x0020_Date", "DateTime","Academy Pub Date"},
                {"0","Academy_x0020_URL", "Note","Academy URL"},
                {"0","Other_x0020_Stakeholders", "UserMulti","Additional SMEs"},
                {"0","Aligned_x0020_to_x0020_Field", "Choice","Aligned to subsidiary scorecard"},
                {"0","Any_x0020_Special_x0020_Instruct", "Note","Any Special Instructions When Publishing?"},
                {"0","Archive_x0020_Date", "DateTime","Archive Date"},
                {"0","Archive_x0020_Reason", "Text","Archive Reason"},
                {"0","Are_x0020_There_x0020_Any_x0020_", "Choice","Are There Any Graphic Files?"},
                {"0","Ch9_x0020_Pub_x0020_Date", "DateTime","Ch9 Pub Date"},
                {"0","Ch9_x0020_URL", "URL","Ch9 URL"},
                {"0","Channel_x0020_9_x0020_GUID", "Text","Channel 9 GUID"},
                {"0","ContentType", "Computed","Content Type"},
                {"0","Created", "DateTime","Created"},
                {"0","Author", "User","Created By"},
                {"0","Download_x0020_Center_x0020_Pub_", "DateTime","Download Center Pub Date"},
                {"0","Download_x0020_Center_x0020_URL", "URL","Download Center URL"},// This source column is mapped to two destination columns
                {"2","Download_x0020_Center_x0020_URL", "URL","DownloadCenterURLdecoded"},
                {"0","File_x0020_Name", "Text","File Name"},
                {"0","FolderChildCount", "Lookup","Folder Child Count"},
                {"0","Folder_x0020_Name", "Text","Folder Name"},
                {"0","Funding_x0020_Comments", "Note","Funding Comments"},
                {"0","Today", "DateTime","Handoff Date"},
                {"0","Knowledge_x0020_Center_x0020_ID", "Text","Infopedia Doc Set ID"},
                {"0","Knowledge_x0020_Center_x0020_Pub", "DateTime","Infopedia Pub Date"},
                {"0","Is_x0020_There_x0020_Any_x0020_C", "Note","Is There Any Content That Needs To Be Retired?"},
                {"0","IT_x0020_Web_x0020__x0020_URL", "URL","IT Web  URL"},
                {"0","IT_x0020_Web_x0020_Pub_x0020_Dat", "DateTime","IT Web Pub Date"},
                {"0","ItemChildCount", "Lookup","Item Child Count"},
                {"0","Audience", "MultiChoice","ITSC Audience"},
                {"0","ITSC_x0020_Content_x0020_Abstrac", "Note","ITSC Content Abstract"},
                {"0","Abstract", "Note","ITSC Family Abstract"},
                {"0","IT_x0020_Showcase_x0020_Family", "Lookup","ITSC Family Title"},
                {"0","Project_x0020_Stage", "Choice","ITSC Project Stage"},
                {"0","Technical_x0020_Level", "Choice","ITSC Technical Level"},
                {"0","Video_x0020_Keywords", "Note","Keywords"},
                {"0","M_x0026_O_x0020_Scenario", "TaxonomyFieldType","M&O Scenario"},
                {"0","Publication_x0020_Date", "DateTime","Promotion Date"},
                {"0","Promotion", "Choice","Promotion"},
                {"0","Megatrends", "Choice","Megatrends"},
                {"0","Modified", "DateTime","Modified"},
                {"0","Editor", "User","Modified By"},
                {"0","Notes", "Note","Notes"},
                {"0","Notified_x0020_Producer_x0020_Da", "DateTime","Notice of Pub sent to PM"},
                {"0","Primary_x0020_Clients", "UserMulti","Primary SME"},
                {"0","Project_x0020_Name_x003a_ID", "Lookup","Project Name:ID"},
                {"0","Pub_x0020_by_x0020_Day", "Calculated","Pub - Age in Days"},
                {"0","Pub_x0020_by_x0020_Month", "Calculated","Pub - Age in Months"},
                {"0","Pub_x0020_Delay_x0020_Reasons", "Text","Pub Delay Reasons"},
                {"0","Pub_x0020_Primary_x0020_Channel_", "Choice","Pub Primary Channel Name"},
                {"0","Repub_x0020_Date", "DateTime","Repub Date"},
                {"0","Repub_x0020_Reason", "Note","Repub Reason"},
                {"0","RM_x0020_Comments", "Note","RM Comments"},
                {"0","SetProje0", "WorkflowStatus","Set Project Insight ID (1)"},
                {"0","SetFields_x0020__x0028_System_x0", "Text","SetFields (System Field)"},
                {"0","Issues_x002c__x0020_Risks_x0020_", "Note","Situation"},
                {"0","Solution_x0020_Area_x0028_s_x002", "MultiChoice","Solution Area(s)"},
                {"0","Submitfo", "WorkflowStatus","Submit for Dev"},
                {"0","Ready_x0020_for_x0020_Publicatio", "Choice","Submit for Dev Choice"},
                {"0","Submi_x0020_for_x0020_Dev_x002c_", "DateTime","Submit for Dev, Actual"},
                {"0","Submitfo0", "WorkflowStatus","Submit for Plan"},
                {"0","Submitfo1", "WorkflowStatus","Submit for Pub"},
                {"0","Ready_x0020_to_x0020_Publish_x00", "MultiChoice","Submit for Pub Choice"},
                {"0","Sys_Dev_Submit_Lock", "Text","Sys_Dev_Submit_Lock"},
                {"0","Sys_Pub_Submit_Lock", "Text","Sys_Pub_Submit_Lock"},
                {"0","IT_x0020_Showcase_x0020_Family_x", "Text","System ID ISF"},
                {"0","Project_x0020_Insight_x0020_ID_x", "Number","System ID REF"},
                {"0","TechNet_x0020_Edge_x0020_Pub_x00", "DateTime","TechNet Edge Pub Date"},
                {"0","TechNet_x0020_Edge_x0020_URL", "URL","TechNet Edge URL"},
                {"0","TechNet_x0020_Pub_x0020_Date", "DateTime","TechNet Pub Date"},
                {"0","TechNet_x0020_URL", "URL","TechNet URL"},
                {"0","Title", "Text","Title (1)"}, //This source column is mapped to two destination columns. 
                {"2","Title", "Text","Title"},
                {"0","Webcast_x0020_Date", "DateTime","Webcast Date"},
                {"0","Webcast_x0020_URL", "URL","Webcast URL"},
                {"0","YouTube_x0020_Pub_x0020_Date", "DateTime","YouTube Pub Date"},
                {"0","YouTube_x0020_URL", "URL","YouTube URL"},
                {"0","FSObjType", "Lookup","Item Type (1)"}, //This source column is mapped to two destination columns. 
                {"2","FSObjType", "Lookup","Item Type"},
                {"0","FileDirRef", "Lookup","Path (1)"},//This source column is mapped to two destination columns. 
                {"2","FileDirRef", "Lookup","Path"},
                {"0","_EndDate", "DateTime","Delivery End Date, Planning (1)"}, // From "Delivery End Date, Planning" in display SP column. This source column is mapped to two destination columns. 
                {"2","_EndDate", "DateTime","Delivery End Date, Planning"},
                {"0","Writer_x0020_Embedded_x0020_Yes_", "Boolean","Writer Embedded"} // From "Writer Embedded Yes/No" in display SP column
            };
        }
    }

    public class SharedStuff
    {
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
    }

    public class SQLStuff
    {
        static string sqlConnStr = null;
        static SqlConnection conn = null;
        static SqlCommand cmd = null;
        static string sqlQueryStr = "";
        public static void TruncateTable(string tableName)
        {
            try
            {
                sqlQueryStr = "Truncate Table ";
                sqlQueryStr = String.Concat(sqlQueryStr, tableName);

                cmd = new SqlCommand(sqlQueryStr, conn);
                cmd.CommandType = CommandType.Text;
                cmd.CommandTimeout = 10;
                cmd.ExecuteNonQuery();
            }
            catch(Exception Ex)
            {
                System.Console.WriteLine("Trouble truncating destination DB table. See error message below:");
                System.Console.WriteLine(Ex.Message);
            }
        }

        public static DataTable TruncateColumnSize(DataTable dt,SqlBulkCopy bulkCopy, DataTable dtc)
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
                        if("|varchar|nvarchar|".IndexOf(r[2].ToString()) == -1)
                        { 
                            continue;
                        }

                        dbColName = r[0].ToString();
                        dbColLen = Convert.ToInt32(r[1].ToString());
                        SqlBulkCopyColumnMappingCollection colMapColl = bulkCopy.ColumnMappings;
                        foreach(SqlBulkCopyColumnMapping colMap in colMapColl)
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
                                    foreach(DataRow row in dt.Rows)
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
                dv.Sort = "ID asc";
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
                if(!colTruncated)
                {
                    System.Console.WriteLine("  No columns were truncated");
                }
            }
        }

        public static void FillTable(string tableName, DataTable dt, string param, string[,] nameTypeMap)
        {
            sqlConnStr = Properties.Settings.Default.SQLConnStr;
            conn = new SqlConnection(sqlConnStr);
            SqlBulkCopy bulkCopy = new SqlBulkCopy(conn, SqlBulkCopyOptions.KeepIdentity, null);

            try
            {
                conn.Open();

                bulkCopy.DestinationTableName = tableName;

                System.Console.WriteLine("SP column to DB column mapping:");
                for (int i = 0; i < nameTypeMap.GetLength(0); i++)
                {
                    // Only map columns that can be pulled from SP list
                    if (nameTypeMap[i, 0] == "1" || nameTypeMap[i, 0] == "2")
                    {
                        // Only map columns that exist in DataTable. Columns that can be pulled but have no data for any row do not get returned in the SP List response. 
                        if(dt.Columns.Contains(nameTypeMap[i,1]))
                        { 
                            bulkCopy.ColumnMappings.Add(nameTypeMap[i, 1], nameTypeMap[i, 3]);
                            System.Console.WriteLine("'" + nameTypeMap[i, 1] + "' to '" + nameTypeMap[i, 3] + "'");
                        }
                        else
                        {
                            nameTypeMap[i, 0] = "0";
                            System.Console.WriteLine("");
                            System.Console.WriteLine(nameTypeMap[i, 1] + " SharePoint list column will not be included because no data existed for any row.");
                            System.Console.WriteLine("");
                        }
                    }
                }
                System.Console.WriteLine("");

                DataTable dtc = GetAllowedColumnsInDBTable(tableName);

                ValidateMapping(dtc,nameTypeMap);

                dt = TruncateColumnSize(dt,bulkCopy,dtc);

                    //dt = dt.Rows.Cast<System.Data.DataRow>().Take(5000).CopyToDataTable();//test

                // Truncate DB table
                TruncateTable(tableName);

                // Get Max and Min values from ID column for each 1000 rows
                double finalRowCnt = dt.Rows.Count;
                int numInsert = Convert.ToInt32(Math.Ceiling(finalRowCnt / Convert.ToDouble(1000)));
                int[,] range = new int[numInsert, 2];
                int idxInsert = numInsert - 1; 

                for(int i = 0; i < dt.Rows.Count;i = i + 1000)
                {
                    // Set start of range
                    range[idxInsert, 0] = Convert.ToInt32(dt.Rows[i]["ID"]);

                    // Set end of range
                    int j = 0;
                    if((i + 999) > (dt.Rows.Count - 1))
                    {
                        j = dt.Rows.Count - 1;
                    }
                    else
                    {
                        j = i + 999;
                    }
                    range[idxInsert, 1] = Convert.ToInt32(dt.Rows[j]["ID"]);

                    idxInsert = idxInsert - 1;
                }

                // Incrementally insert data into relational DB table 1000 rows at a time
                System.Console.WriteLine("");
                for (int i = 0; i < numInsert; i++)
                {
                    DataTable dt2 = dt.Select("ID >= " + range[i, 0] + " and ID <= " + range[i, 1]).CopyToDataTable();
                    bulkCopy.WriteToServer(dt2);
                    System.Console.WriteLine("Copy " + dt2.Rows.Count.ToString() + " DataTable rows to relational DB table.");
                }            
            }
            catch(Exception Ex)
            {
                System.Console.WriteLine(Ex.StackTrace);
                System.Console.WriteLine(Ex.Message);
            }
            finally
            {
                conn.Close();
            }
        }

        static void ValidateMapping(DataTable dtc, string[,] nameTypeMap)
        {
            // Loop through DB column names
            for (int i = 0; i < nameTypeMap.GetLength(0); i++)
            {
                // Skip the columns that will not be pulled for other reasons. 
                if(nameTypeMap[i,0] == "0")
                {
                    continue; 
                }

                // See if column names exist in the DB table
                if (dtc.Select("colName = '" + nameTypeMap[i,3] + "'").GetLength(0) == 0)
                {
                    System.Console.WriteLine(nameTypeMap[i,3] + " is an invalid DB column name in the mapping.");
                }
            }
        }

        static DataTable GetAllowedColumnsInDBTable(string tableName)
        {
            string sqlQueryStr =
            @"Select
                    Column_Name As colName,
                    Case
                        When Data_Type = 'varchar' And Character_Maximum_Length = -1 Then 8000
                        When Data_Type = 'nvarchar' And Character_Maximum_Length = -1 Then 4000
		                else Character_Maximum_Length
                    End As colLen,
                    Data_Type As colType
                From
                    Information_Schema.Columns
                Where
                    Table_name = '[TABLE_NAME]'";
            sqlQueryStr = sqlQueryStr.Replace("[TABLE_NAME]", tableName);
            cmd = new SqlCommand(sqlQueryStr, conn);
            cmd.CommandType = CommandType.Text;
            cmd.CommandTimeout = 10;
            SqlDataReader rdr = cmd.ExecuteReader();
            DataTable dtc = new DataTable("dtc");
            dtc.Load(rdr);
            rdr.Close();
            return dtc;
        }

        //static SqlBulkCopy GetPI_Channels_BulkCopyMap(SqlBulkCopy bulkCopy)
        //{
        //    bulkCopy.ColumnMappings.Add("Title", "Channel");
        //    bulkCopy.ColumnMappings.Add("Channel_x0020_Link", "Channel Link");
        //    bulkCopy.ColumnMappings.Add("Channel_x0020_Owner_x0028_s_x002", "Channel Owner(s)");
        //    bulkCopy.ColumnMappings.Add("Reach", "Reach");
        //    bulkCopy.ColumnMappings.Add("Tier", "Tier");
        //    bulkCopy.ColumnMappings.Add("FSObjType", "Item Type");
        //    bulkCopy.ColumnMappings.Add("FileDirRef", "Path");
        //    return bulkCopy;
        //}

        //static SqlBulkCopy GetPI_Promotions_BulkCopyMap(SqlBulkCopy bulkCopy)
        //{
        //    bulkCopy.ColumnMappings.Add("Pi_x0020_ID", "Pi ID");
        //    bulkCopy.ColumnMappings.Add("Actual_x0020_Publish_x0020_Date", "Actual Publish Date");
        //    bulkCopy.ColumnMappings.Add("Link", "Link");
        //    bulkCopy.ColumnMappings.Add("Alias", "Alias");
        //    /*bulkCopy.ColumnMappings.Add("AppAuthor", "App Created By"); was pulled out becaues columns with no data in SharePoint cannot be pulled */
        //    bulkCopy.ColumnMappings.Add("AppEditor", "App Modified By");
        //    bulkCopy.ColumnMappings.Add("ContentType", "Content Type");
        //    bulkCopy.ColumnMappings.Add("Created", "Created");
        //    bulkCopy.ColumnMappings.Add("Author", "Created By");
        //    bulkCopy.ColumnMappings.Add("Desired_x0020_Go_x002d_Live_x002", "Desired Go-Live Date");
        //    bulkCopy.ColumnMappings.Add("Event", "Event");
        //    bulkCopy.ColumnMappings.Add("FolderChildCount", "Folder Child Count");
        //    bulkCopy.ColumnMappings.Add("ID", "ID");
        //    bulkCopy.ColumnMappings.Add("InQueueLogic", "InQueueLogic");
        //    bulkCopy.ColumnMappings.Add("InQueueNotification", "InQueueNotification");
        //    bulkCopy.ColumnMappings.Add("Is_x0020_Go_x002d_Live_x0020_Dat", "Is Go-Live Date Flexible?");
        //    bulkCopy.ColumnMappings.Add("Is_x0020_this_x0020_Promotion_x0", "Is this Promotion tied to an event?");
        //    bulkCopy.ColumnMappings.Add("ItemChildCount", "Item Child Count");
        //    bulkCopy.ColumnMappings.Add("Title", "ITSC Content Title");
        //    bulkCopy.ColumnMappings.Add("Modified", "Modified");
        //    bulkCopy.ColumnMappings.Add("Editor", "Modified By");
        //    bulkCopy.ColumnMappings.Add("Requestor", "Requestor");
        //    bulkCopy.ColumnMappings.Add("Status", "Status");
        //    bulkCopy.ColumnMappings.Add("SubmissionAcknowledgement", "SubmissionAcknowledgement");
        //    bulkCopy.ColumnMappings.Add("FSObjType", "Item Type");
        //    bulkCopy.ColumnMappings.Add("FileDirRef", "Path");
        //    bulkCopy.ColumnMappings.Add("Channel_x0028_s_x0029_", "Channel");
        //    return bulkCopy;
        //}

        //static SqlBulkCopy GetPI_BulkCopyMap(SqlBulkCopy bulkCopy)
        //{

            //bulkCopy.ColumnMappings.Add("ID", "ID");
            //bulkCopy.ColumnMappings.Add("Project_x0020_Insight_x0020_Fami", "Project Name");
            //bulkCopy.ColumnMappings.Add("IT_x0020_Marcom_x0020_Function", "Functional Area");
            //bulkCopy.ColumnMappings.Add("Deliverable", "Deliverable");
            //bulkCopy.ColumnMappings.Add("IT_x0020_Showcase_x0020_Content_", "ITSC Content Title");
            //bulkCopy.ColumnMappings.Add("Title", "Title");//This source column is mapped to two destination columns. 
            //bulkCopy.ColumnMappings.Add("Project_x0020_Name", "Deliverable Description");
            //bulkCopy.ColumnMappings.Add("IT_x0020_MarCom_x0020_PM_x0020_L", "Project Owner");
            //bulkCopy.ColumnMappings.Add("Deliverable_x0020_Owner", "Deliverable Owner");
            //bulkCopy.ColumnMappings.Add("Project_x0020_Status", "Status");
            //bulkCopy.ColumnMappings.Add("StartDate", "Anticipated Start Date");
            //bulkCopy.ColumnMappings.Add("_EndDate", "Delivery End Date, Planning");// "_EndDate" source column is mapped to two destination columns
            //bulkCopy.ColumnMappings.Add("Delivery_x0020_Quarter", "Delivery Quarter");
            //bulkCopy.ColumnMappings.Add("Lead_x0020_Time_x0020_Issue", "Lead Time Issue");
            //bulkCopy.ColumnMappings.Add("MS_x0020_IT_x0020_Sponsor", "CIO Direct Report");
            //bulkCopy.ColumnMappings.Add("Products", "Microsoft Product(s)");
            //bulkCopy.ColumnMappings.Add("Resources", "Supporting IT Marcom Resources");
            //bulkCopy.ColumnMappings.Add("Is_x0020_Funding_x0020_Needed_x00", "Is Funding Needed?");
            //bulkCopy.ColumnMappings.Add("Funder_x0020_1", "Funder 1");
            //bulkCopy.ColumnMappings.Add("Funder_x0020_2", "Funder 2");
            //bulkCopy.ColumnMappings.Add("Funder_x0020__x0024__x0020_Amoun", "Funder 1 $ Amount");
            //bulkCopy.ColumnMappings.Add("Funder_x0020__x0024__x0020_Amoun0", "Funder 2 $ Amount");
            //bulkCopy.ColumnMappings.Add("Pub_x0020_to_x0020_Primary_x0020", "Pub to Primary_Date");
            //bulkCopy.ColumnMappings.Add("Pub_Accepted_x0020_for_x0020_Rel", "Accepted for Pub");
            //bulkCopy.ColumnMappings.Add("Opp_x0020_Start", "Opp Start");
            //bulkCopy.ColumnMappings.Add("Plan_x0020_Start", "Plan Start");
            //bulkCopy.ColumnMappings.Add("Ready_x0020_for_x0020_Dev_x002c_", "Ready for Dev, Forecast");
            //bulkCopy.ColumnMappings.Add("Notes_x003a__x0020_PM_x0020_to_x", "Notes: PM to Dev Hand-off");
            //bulkCopy.ColumnMappings.Add("Notes_x003a__x0020_Dev_x0020_to_", "Notes: Dev to PM Hand-off");
            //bulkCopy.ColumnMappings.Add("Notes_x003a__x0020_PM_x0020_to_x0", "Notes: CDM to Pubs Hand-off");
            //bulkCopy.ColumnMappings.Add("Notes_x003a__x0020_Pubs_x0020_to", "Notes: Pubs to PM Hand-off");
            //bulkCopy.ColumnMappings.Add("Request_x0020_accepted_x0020_by_", "Request accepted by CDM");
            //bulkCopy.ColumnMappings.Add("Content_x0020_delivered_x0020_to", "Content delivered to PM");
            //bulkCopy.ColumnMappings.Add("Content_x0020_accepted_x0020_by_", "Content accepted by PM");
            //bulkCopy.ColumnMappings.Add("Submit_x0020_for_x0020_Pub_x002c", "Submit for Pub, Actual");
            //bulkCopy.ColumnMappings.Add("Delivery_x0020_End_x0020_Date_x0", "Delivery End Date, Dev SLA");
            //bulkCopy.ColumnMappings.Add("SetProje0", "Set Project Insight ID");// There are two with the same SP display name. I confirmed by viewing the source of the HTML for the pi01 SP view.
            //bulkCopy.ColumnMappings.Add("Academy_x0020_URL_x0020_NEW", "Academy URL NEW");
            //bulkCopy.ColumnMappings.Add("Funder1IO", "Funder 1 - IO");
            //bulkCopy.ColumnMappings.Add("Funder2IO", "Funder 2 - IO");
            //bulkCopy.ColumnMappings.Add("TechTrend", "Tech Trend");
            //bulkCopy.ColumnMappings.Add("ITTopic", "IT Topic");
            //bulkCopy.ColumnMappings.Add("ITSPrimaryProduct", "ITS Product");
            //bulkCopy.ColumnMappings.Add("Previous_x0020_Published_x0020_L", "Previous Published Location");
            //bulkCopy.ColumnMappings.Add("SubmitHandoff", "SubmitHandoff");
            //bulkCopy.ColumnMappings.Add("SubmitHandoffActual", "SubmitHandoffActual");
            //bulkCopy.ColumnMappings.Add("NotesHandoff", "NotesHandoff");
            //bulkCopy.ColumnMappings.Add("ITSCURL", "ITSC Portal URL");
            //bulkCopy.ColumnMappings.Add("ITSCPubDate", "ITSC Portal Pub Date");
            //bulkCopy.ColumnMappings.Add("xxx", "Submit for Handoff"); Leave out because matching SharePoint column cannot be found in SP list or view. 
            //bulkCopy.ColumnMappings.Add("Program", "Program");
            //bulkCopy.ColumnMappings.Add("Benefits", "Benefits");
            //bulkCopy.ColumnMappings.Add("SME_x0020_Notes", "SME Notes");
            //bulkCopy.ColumnMappings.Add("Deliverable_x0020_Status", "Deliverable Status");
            //bulkCopy.ColumnMappings.Add("Vendor", "Vendor");
            //bulkCopy.ColumnMappings.Add("LeadOwner", "LeadOwner");
            //bulkCopy.ColumnMappings.Add("LeadAmount", "LeadAmount");
            //bulkCopy.ColumnMappings.Add("xxx", "SendHandoffDoc");// SendHandOffDoc is in PI_01 SP view but not a SP list display name.
            //bulkCopy.ColumnMappings.Add("Internal_x0020__x002f__x0020_Ext", "Internal / External");
            //bulkCopy.ColumnMappings.Add("Gold_x0020_Copy_x0020_Location", "Gold Copy Location");
            //bulkCopy.ColumnMappings.Add("Publication_x0020_Location", "Publication Location");
            //bulkCopy.ColumnMappings.Add("Secondary_x0020_Publication_x002", "Secondary Publication Location");
            //bulkCopy.ColumnMappings.Add("Publication_x0020_Location_x0020", "Publication Location Type");
            //bulkCopy.ColumnMappings.Add("Secondary_x0020_Publication_x0020", "Secondary Publication Location Type");
            //bulkCopy.ColumnMappings.Add("New_x0020__x002f__x0020_Update", "Action Requested");
            //bulkCopy.ColumnMappings.Add("Gold_x0020_Location", "Gold Location");
            //bulkCopy.ColumnMappings.Add("Publication_x0020_Location_x00200", "Publication Location Text");
            //bulkCopy.ColumnMappings.Add("Secondary_x0020_Publication_x0021", "Secondary Publication Location Text");
            //bulkCopy.ColumnMappings.Add("Solution", "Solution");
            //bulkCopy.ColumnMappings.Add("Pub_x0020_SLA", "Pub SLA");
            //bulkCopy.ColumnMappings.Add("Content_x0020_PM", "Content PM");
            //bulkCopy.ColumnMappings.Add("Link_x0020_to_x0020_doc", "Project Documents");
            //bulkCopy.ColumnMappings.Add("Publication_x0020_SLA", "Publication SLA");
            //bulkCopy.ColumnMappings.Add("Publication_x0020_Date0", "Publication Date");
            //bulkCopy.ColumnMappings.Add("SLA_x0020_Timeframe", "SLA Timeframe");
            //bulkCopy.ColumnMappings.Add("I_x0020_want_x0020_to_x0020_lear", "I want to learn about…");
            //bulkCopy.ColumnMappings.Add("Readiness_x0020_Tag_x0020_Device", "Readiness Tag Devices");
            //bulkCopy.ColumnMappings.Add("Readiness_x0020_Tag_x0020_LOB", "Readiness Tag LOB");
            //bulkCopy.ColumnMappings.Add("Readiness_x0020_Tag_x0020_Produc", "Readiness Tag Products");
            //bulkCopy.ColumnMappings.Add("Readiness_x0020_Tag_x0020_Servic", "Readiness Tag Services");
            //bulkCopy.ColumnMappings.Add("Readiness_x0020_Tag_x0020_Window", "Readiness Tag Windows");
            //bulkCopy.ColumnMappings.Add("Sync_x0020_Pub", "Sync Pub");
            //bulkCopy.ColumnMappings.Add("Infopedia_x0020_Doc_x0020_ID", "Infopedia Doc ID");
            //bulkCopy.ColumnMappings.Add("Anticipated_x0020_Hand_x002d_off", "Est# Submit to Pub date"); // There is a "Est. Submit to Pub date" display name in SP list but not the SP view. So, will map to this for now. 
            //bulkCopy.ColumnMappings.Add("Localization", "Localization");
            //bulkCopy.ColumnMappings.Add("xxx", "HOLD");// HOLD may be an SP view display name. It is not found as an SP list name. 
            //bulkCopy.ColumnMappings.Add("CRBApproved", "CRB Approved");
            //bulkCopy.ColumnMappings.Add("AlignedtoPPS", "Aligned to PPS");
            //bulkCopy.ColumnMappings.Add("AlignedtoMEPs", "Aligned to MEPs");
            //bulkCopy.ColumnMappings.Add("MicrosoftAmbitions", "Microsoft Ambitions");
            //bulkCopy.ColumnMappings.Add("ProjectDocs", "Project Document");
            //bulkCopy.ColumnMappings.Add("CustomerPromises", "Customer Promises");
            //bulkCopy.ColumnMappings.Add("CustomerPromises_x003a_VSO_x0020", "Customer Promises: VSO ID");
            //bulkCopy.ColumnMappings.Add("MEPS_x0020_USER_x0020_STORY_x003", "MEPS USER STORY: VSO ID");
            //bulkCopy.ColumnMappings.Add("FSObjType", "Item Type");// "FSObjType" source column is mapped to two destination columns
            //bulkCopy.ColumnMappings.Add("FileDirRef", "Path");// "FileDirRef" source column is mapped to two destination columns
            //bulkCopy.ColumnMappings.Add("_x0023__x0020_Days_x0020_to_x002", "# Days to Pub");
            //bulkCopy.ColumnMappings.Add("Academy_x0020_Pub_x0020_Date", "Academy Pub Date");
            //bulkCopy.ColumnMappings.Add("Academy_x0020_URL", "Academy URL");
            //bulkCopy.ColumnMappings.Add("Other_x0020_Stakeholders", "Additional SMEs");
            //bulkCopy.ColumnMappings.Add("Aligned_x0020_to_x0020_Field", "Aligned to subsidiary scorecard");
            //bulkCopy.ColumnMappings.Add("Any_x0020_Special_x0020_Instruct", "Any Special Instructions When Publishing?");
            //bulkCopy.ColumnMappings.Add("Archive_x0020_Date", "Archive Date");
            //bulkCopy.ColumnMappings.Add("Archive_x0020_Reason", "Archive Reason");
            //bulkCopy.ColumnMappings.Add("Are_x0020_There_x0020_Any_x0020_", "Are There Any Graphic Files?");
            //bulkCopy.ColumnMappings.Add("Ch9_x0020_Pub_x0020_Date", "Ch9 Pub Date");
            //bulkCopy.ColumnMappings.Add("Ch9_x0020_URL", "Ch9 URL");
            //bulkCopy.ColumnMappings.Add("Channel_x0020_9_x0020_GUID", "Channel 9 GUID");
            //bulkCopy.ColumnMappings.Add("ContentType", "Content Type");
            //bulkCopy.ColumnMappings.Add("Created", "Created");
            //bulkCopy.ColumnMappings.Add("Author", "Created By");
            //bulkCopy.ColumnMappings.Add("Download_x0020_Center_x0020_Pub_", "Download Center Pub Date");
            //bulkCopy.ColumnMappings.Add("Download_x0020_Center_x0020_URL", "Download Center URL");
            //bulkCopy.ColumnMappings.Add("Download_x0020_Center_x0020_URL", "DownloadCenterURLdecoded");// This is "Download Center URL" display name in SP with white space trimmed off the left and right.  
            //bulkCopy.ColumnMappings.Add("File_x0020_Name", "File Name");// There are two "File Name" display names in SP list. I confirmed the column name in the HTML source of the pi02 view. 
            //bulkCopy.ColumnMappings.Add("FolderChildCount", "Folder Child Count");
            //bulkCopy.ColumnMappings.Add("Folder_x0020_Name", "Folder Name");
            //bulkCopy.ColumnMappings.Add("Funding_x0020_Comments", "Funding Comments");
            //bulkCopy.ColumnMappings.Add("Today", "Handoff Date");
            //bulkCopy.ColumnMappings.Add("Knowledge_x0020_Center_x0020_ID", "Infopedia Doc Set ID");
            //bulkCopy.ColumnMappings.Add("Knowledge_x0020_Center_x0020_Pub", "Infopedia Pub Date");
            //bulkCopy.ColumnMappings.Add("Is_x0020_There_x0020_Any_x0020_C", "Is There Any Content That Needs To Be Retired?");
            //bulkCopy.ColumnMappings.Add("IT_x0020_Web_x0020__x0020_URL", "IT Web  URL");
            //bulkCopy.ColumnMappings.Add("IT_x0020_Web_x0020_Pub_x0020_Dat", "IT Web Pub Date");
            //bulkCopy.ColumnMappings.Add("ItemChildCount", "Item Child Count");
            //bulkCopy.ColumnMappings.Add("Audience", "ITSC Audience");
            //bulkCopy.ColumnMappings.Add("ITSC_x0020_Content_x0020_Abstrac", "ITSC Content Abstract");
            //bulkCopy.ColumnMappings.Add("Abstract", "ITSC Family Abstract");
            //bulkCopy.ColumnMappings.Add("IT_x0020_Showcase_x0020_Family", "ITSC Family Title");
            //bulkCopy.ColumnMappings.Add("Project_x0020_Stage", "ITSC Project Stage");
            //bulkCopy.ColumnMappings.Add("Technical_x0020_Level", "ITSC Technical Level");
            //bulkCopy.ColumnMappings.Add("Video_x0020_Keywords", "Keywords");
            //bulkCopy.ColumnMappings.Add("M_x0026_O_x0020_Scenario", "M&O Scenario");
            //bulkCopy.ColumnMappings.Add("Publication_x0020_Date", "Promotion Date");
            //bulkCopy.ColumnMappings.Add("Promotion", "Promotion");
            //bulkCopy.ColumnMappings.Add("Megatrends", "Megatrends");
            //bulkCopy.ColumnMappings.Add("Modified", "Modified");
            //bulkCopy.ColumnMappings.Add("Editor", "Modified By");
            //bulkCopy.ColumnMappings.Add("Notes", "Notes");
            //bulkCopy.ColumnMappings.Add("Notified_x0020_Producer_x0020_Da", "Notice of Pub sent to PM");
            //bulkCopy.ColumnMappings.Add("Primary_x0020_Clients", "Primary SME");
            //bulkCopy.ColumnMappings.Add("Project_x0020_Name_x003a_ID", "Project Name:ID");
            //bulkCopy.ColumnMappings.Add("Pub_x0020_by_x0020_Day", "Pub - Age in Days");
            //bulkCopy.ColumnMappings.Add("Pub_x0020_by_x0020_Month", "Pub - Age in Months");
            //bulkCopy.ColumnMappings.Add("Pub_x0020_Delay_x0020_Reasons", "Pub Delay Reasons");
            //bulkCopy.ColumnMappings.Add("Pub_x0020_Primary_x0020_Channel_", "Pub Primary Channel Name");
            //bulkCopy.ColumnMappings.Add("Repub_x0020_Date", "Repub Date");
            //bulkCopy.ColumnMappings.Add("Repub_x0020_Reason", "Repub Reason");
            //bulkCopy.ColumnMappings.Add("RM_x0020_Comments", "RM Comments");
            //bulkCopy.ColumnMappings.Add("SetProje0", "Set Project Insight ID (1)"); // SP Display name is "Set Project Insight ID" in list and view. There are two "Set Project Insight ID" display names in SP list.
            //bulkCopy.ColumnMappings.Add("SetFields_x0020__x0028_System_x0", "SetFields (System Field)");
            //bulkCopy.ColumnMappings.Add("Issues_x002c__x0020_Risks_x0020_", "Situation");
            //bulkCopy.ColumnMappings.Add("Solution_x0020_Area_x0028_s_x002", "Solution Area(s)");
            //bulkCopy.ColumnMappings.Add("Submitfo", "Submit for Dev");
            //bulkCopy.ColumnMappings.Add("Ready_x0020_for_x0020_Publicatio", "Submit for Dev Choice");
            //bulkCopy.ColumnMappings.Add("Submi_x0020_for_x0020_Dev_x002c_", "Submit for Dev, Actual");
            //bulkCopy.ColumnMappings.Add("Submitfo0", "Submit for Plan");
            //bulkCopy.ColumnMappings.Add("Submitfo1", "Submit for Pub");
            //bulkCopy.ColumnMappings.Add("Ready_x0020_to_x0020_Publish_x00", "Submit for Pub Choice");
            //bulkCopy.ColumnMappings.Add("Sys_Dev_Submit_Lock", "Sys_Dev_Submit_Lock");
            //bulkCopy.ColumnMappings.Add("Sys_Pub_Submit_Lock", "Sys_Pub_Submit_Lock");
            //bulkCopy.ColumnMappings.Add("IT_x0020_Showcase_x0020_Family_x", "System ID ISF");
            //bulkCopy.ColumnMappings.Add("Project_x0020_Insight_x0020_ID_x", "System ID REF");
            //bulkCopy.ColumnMappings.Add("TechNet_x0020_Edge_x0020_Pub_x00", "TechNet Edge Pub Date");
            //bulkCopy.ColumnMappings.Add("TechNet_x0020_Edge_x0020_URL", "TechNet Edge URL");
            //bulkCopy.ColumnMappings.Add("TechNet_x0020_Pub_x0020_Date", "TechNet Pub Date");
            //bulkCopy.ColumnMappings.Add("TechNet_x0020_URL", "TechNet URL");
            //bulkCopy.ColumnMappings.Add("Title", "Title (1)"); // "Title" display SP name in view and list. This source column is mapped to two destination columns. 
            //bulkCopy.ColumnMappings.Add("Webcast_x0020_Date", "Webcast Date");
            //bulkCopy.ColumnMappings.Add("Webcast_x0020_URL", "Webcast URL");
            //bulkCopy.ColumnMappings.Add("YouTube_x0020_Pub_x0020_Date", "YouTube Pub Date");
            //bulkCopy.ColumnMappings.Add("YouTube_x0020_URL", "YouTube URL");
            //bulkCopy.ColumnMappings.Add("FSObjType", "Item Type (1)");// From "Item Type" displayed SP column in list and view. "FSObjType" source column is mapped to two destination columns
            //bulkCopy.ColumnMappings.Add("FileDirRef", "Path (1)"); // From "Path" displayed SP column in list and view. "FileDirRef" source column is mapped to two destination columns
            //bulkCopy.ColumnMappings.Add("_EndDate", "Delivery End Date, Planning (1)");// "_EndDate" source column is mapped to two destination columns
            //bulkCopy.ColumnMappings.Add("Writer_x0020_Embedded_x0020_Yes_", "Writer Embedded");// From "Writer Embedded Yes/No" in display SP column

            //Remove columns from the SP List to DB table mapping if they do not exist in the DataTable

            //Loop through columns in DataTable.Columns in DataTable are a subset of the SP List to DB mappings.
            //string[,] idx = new string[bulkCopy.ColumnMappings.Count, 3];
            //for (int i = 0; i < bulkCopy.ColumnMappings.Count; i++)
            //{
            //    See if mapping column exists in the DataTable
            //    if (dt.Columns.IndexOf(bulkCopy.ColumnMappings[i].SourceColumn) >= 0)
            //    {
            //        idx[i, 0] = "0";
            //    }
            //    else
            //    {
            //        Flag mappings to remove
            //        idx[i, 0] = "1";
            //        idx[i, 1] = bulkCopy.ColumnMappings[i].SourceColumn;
            //        idx[i, 2] = bulkCopy.ColumnMappings[i].DestinationColumn;
            //        System.Console.WriteLine(bulkCopy.ColumnMappings[i].SourceColumn + " column was flagged to be removed from SP List to DB mapping");
            //    }
            //}

            //System.Console.WriteLine("# of bulkCopy mappings: " + bulkCopy.ColumnMappings.Count.ToString());//test

            //Remove the flagged mappings
            //for (int i = 0; i < idx.GetLength(0); i++)
            //{
            //    if (idx[i, 0] == "1")
            //    {
            //        bulkCopy.ColumnMappings.Remove(new SqlBulkCopyColumnMapping(idx[i, 1], idx[i, 2]));
            //        System.Console.WriteLine("Removed SP List to DB mapping for '" + idx[i, 1] + "' since it cannot be pulled from SP List");
            //        System.Console.WriteLine("# of bulkCopy mappings: " + bulkCopy.ColumnMappings.Count.ToString());//test
            //    }
            //}

        //    return bulkCopy;
        //}
    }
}
