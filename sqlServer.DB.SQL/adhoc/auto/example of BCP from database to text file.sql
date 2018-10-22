USE [AcctDB]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE proc [dbo].[p_output_feedexport]
as

declare @yyyymmdd varchar(8)
select @yyyymmdd = cast(year(getdate()) as varchar(4)) + substring('0' + cast(month(getdate()) as varchar(2)),len(cast(month(getdate()) as varchar(2))),2) + substring('0' + cast(day(getdate()) as varchar(2)),len(cast(day(getdate()) as varchar(2))),2)

declare @commandText varchar(500)

set @commandText = 'bcp "select * from AcctDB.dbo.output_feed where rowNameID = 103310" queryout C:\SHARE\AcctDB\outboundFlatFile\103310-PADNumerator-' + @yyyymmdd + '.txt -S ' + @@serverName + ' -T -c'
exec master..xp_cmdshell @commandText
set @commandText = 'bcp "select * from AcctDB.dbo.output_feed where rowNameID = 103411" queryout C:\SHARE\AcctDB\outboundFlatFile\103411-PLSRNumerator-' + @yyyymmdd + '.txt -S ' + @@serverName + ' -T -c'
exec master..xp_cmdshell @commandText
set @commandText = 'bcp "select * from AcctDB.dbo.output_feed where rowNameID = 103412" queryout C:\SHARE\AcctDB\outboundFlatFile\103412-PLSRDenominator-' + @yyyymmdd + '.txt -S ' + @@serverName + ' -T -c'
exec master..xp_cmdshell @commandText


/*

bcp "select * from AcctDB.dbo.output_feed where rowNameID = 103310" queryout C:\outboundFlatFile\SMSP_FY09\103310-PADNumerator-20080707.txt -S montreal2 -T -c
bcp "select * from AcctDB.dbo.output_feed where rowNameID = 103411" queryout C:\outboundFlatFile\SMSP_FY09\103310-PLSRNumerator-20080707.txt -S montreal2 -T -c
bcp "select * from AcctDB.dbo.output_feed where rowNameID = 103412" queryout C:\outboundFlatFile\SMSP_FY09\103310-PLSRDenominator-20080707.txt -S montreal2 -T -c


bcp "select * from AcctDB.dbo.output_feed where rowNameID = 103310" queryout 103310-PADNumerator-20080707.txt -S montreal2 -T -c
bcp "select * from AcctDB.dbo.output_feed where rowNameID = 103411" queryout 103411-PLSRNumerator-20080707.txt -S montreal2 -T -c
bcp "select * from AcctDB.dbo.output_feed where rowNameID = 103412" queryout 103412-PLSRDenominator-20080707.txt -S montreal2 -T -c


*/


GO


