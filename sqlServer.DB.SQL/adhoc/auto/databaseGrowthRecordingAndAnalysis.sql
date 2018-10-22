use DBGrowth

/*
	Data and Log File size recording
*/

If Not Exists(Select * From DBGrowth.Information_Schema.Tables Where TABLE_NAME = 'DatabaseSize')
Begin
	Create Table DBGrowth.dbo.DatabaseSize
	(
		ServerName varchar(30)
		,DatabaseName varchar(30)
		,[FileName] varchar(50)
		,FilePath nvarchar(300)
		,FileSizeInMB int 
		,ArchiveDate datetime
	)
End

declare @ArchiveDate datetime
set @ArchiveDate = GETDATE()

If Exists(select * from tempdb.INFORMATION_SCHEMA.TABLES where TABLE_NAME like '#database%')
Begin
	Begin Try
		Drop Table #Database
	End Try
	Begin Catch
		
	End Catch
End

create table #Database
(
	DatabaseName sysname
	,DatabaseSize nvarchar(13)
	,DatabaseOwner sysname
	,DatabaseId smallint
	,DatabaseCreatedDate nvarchar(11)
	,DatabaseStatus nvarchar(600)
	,SQLVersionCompatibility tinyint
)

Insert Into
	#Database
exec sp_helpdb


Declare @DatabaseName varchar(30)

Select Top 1
	@DatabaseName = DatabaseName
From
	#Database

Declare @Query varchar(500)
	
While LEN(@DatabaseName) > 0
Begin		
	Set @Query = 
	'Insert Into
		DatabaseSize
	Select
		@@SERVERNAME as ServerName
		,''@DatabaseName'' as DatabaseName
		,Name as [FileName] 
		,[FileName]  as FilePath
		,cast(Str(Convert(Dec(17,0),Size) / 128,10,0) as int) as FileSizeInMB
		,@ArchiveDate as RecordDate
	From 
		 [@DatabaseName].dbo.SysFiles'
		 
	Set @Query = Replace(REPLACE(@Query,'@DatabaseName',@DatabaseName),'@ArchiveDate','''' + Cast(@ArchiveDate as Varchar) + '''')
	
	Exec(@Query)
	
	Delete
		#Database
	Where
		DatabaseName = @DatabaseName
		
	Set @DatabaseName = ''
		
	Select Top 1
		@DatabaseName = DatabaseName
	From
		#Database
End

/*
	Analysis of Data and Log File growth
*/

-- Current and Previous Refresh


declare @PreviousArchiveDate datetime

Select
	@ArchiveDate = MAX(ArchiveDate)
From
	DBGrowth.dbo.DatabaseSize

Select
	@PreviousArchiveDate = MAX(ArchiveDate)
From
	DBGrowth.dbo.DatabaseSize
Where
	ArchiveDate != @ArchiveDate
	
If Exists(Select * From INFORMATION_SCHEMA.TABLES Where TABLE_NAME = 'DatabaseSize_CurrentAndPreviousRefresh')
Begin
	Drop Table DatabaseSize_CurrentAndPreviousRefresh
End
		
Select
	ISNULL(p.ServerName,c.ServerName) as ServerName
	,ISNULL(p.DatabaseName,c.DatabaseName) as DatabaseName
	,ISNULL(p.[FileName],c.[FileName]) as [FileName]
	,@PreviousArchiveDate as PreviousArchiveDate
	,IsNull(p.FileSizeInMB,0) as PreviousFileSizeInMB
	,@ArchiveDate as CurrentArchiveDate
	,IsNull(c.FileSizeInMB,0) as CurrentFileSizeInMB
	,Round(((Cast(IsNull(c.FileSizeInMB,0) as Float) - Cast(IsNull(p.FileSizeInMB,0) as Float))/Cast(IsNull(p.FileSizeInMB,0) as Float)) * 100.00,1)  as PercentChange
Into
	DatabaseSize_CurrentAndPreviousRefresh
From
	DBGrowth.dbo.DatabaseSize p
	Full Outer Join DBGrowth.dbo.DatabaseSize c on
		p.DatabaseName = c.DatabaseName
	And	
		p.[FileName] = c.[FileName]
Where
	p.ArchiveDate = @PreviousArchiveDate
And
	c.ArchiveDate = @ArchiveDate
And
	IsNull(p.FileSizeInMB,0) > 0 
			
			
-- Average Growth Per Refresh

declare @CurrentArchiveDate datetime

Set @CurrentArchiveDate = @ArchiveDate

If Exists(select * from tempdb.INFORMATION_SCHEMA.TABLES where TABLE_NAME like '#DatabaseDiff%')
Begin
	Begin Try
		Drop Table #DatabaseDiff
	End Try
	Begin Catch
		
	End Catch
End

create table #DatabaseDiff
(
		ServerName varchar(30)
		,DatabaseName varchar(30)
		,[FileName] varchar(50)
		,PreviousArchiveDate datetime
		,PreviousFileSizeInMB int 
		,FileSizeChangeInMB int
		,FirstArchiveDate datetime
)

While (@PreviousArchiveDate != '')
Begin

	Insert Into	
		#DatabaseDiff
	Select
		ISNULL(p.ServerName,c.ServerName) as ServerName
		,ISNULL(p.DatabaseName,c.DatabaseName) as DatabaseName
		,ISNULL(p.[FileName],c.[FileName]) as [FileName]
		,@PreviousArchiveDate as PreviousArchiveDate
		,IsNull(p.FileSizeInMB,0) as PreviousFileSizeInMB
		,(IsNull(c.FileSizeInMB,0) - IsNull(p.FileSizeInMB,0)) as FileSizeChangeInMB
		,(Select MIN(f.ArchiveDate) From DBGrowth.dbo.DatabaseSize f Where f.ServerName = c.ServerName And f.DatabaseName = c.DatabaseName And f.[FileName] = c.[FileName]) as FirstArchiveDate
			From
				DBGrowth.dbo.DatabaseSize p
				Full Outer Join DBGrowth.dbo.DatabaseSize c on
					p.ServerName = c.ServerName
				And
					p.DatabaseName = c.DatabaseName
				And	
					p.[FileName] = c.[FileName]
			Where
				p.ArchiveDate = @PreviousArchiveDate
			And
				c.ArchiveDate = @ArchiveDate

	Set @ArchiveDate  = @PreviousArchiveDate
	
	Set @PreviousArchiveDate = ''
	
	Select
		@PreviousArchiveDate = MAX(ArchiveDate)
	From
		DBGrowth.dbo.DatabaseSize
	Where
		ArchiveDate < @ArchiveDate

End

If Exists(Select * From INFORMATION_SCHEMA.TABLES Where TABLE_NAME = 'DatabaseSize_AverageGrowthPerRefresh')
Begin
	Drop Table DatabaseSize_AverageGrowthPerRefresh
End

Select
	ServerName
	,DatabaseName
	,[FileName]
	,FirstArchiveDate
	,Avg(FileSizeChangeInMB) as AverageFileGrowthInMB
	,Round(Avg((cast(FileSizeChangeInMB as float)/cast(PreviousFileSizeInMB as float)) * 100.00),1) as AveragePercentChange
Into
	DatabaseSize_AverageGrowthPerRefresh
From
	#DatabaseDiff
Group By
	ServerName
	,DatabaseName
	,[FileName]
	,FirstArchiveDate
Order By
	Abs(Round(Avg((cast(FileSizeChangeInMB as float)/cast(PreviousFileSizeInMB as float)) * 100.00),1)) desc

-- Average Growth Per Month


If Exists(select * from tempdb.INFORMATION_SCHEMA.TABLES where TABLE_NAME like '#LastArchivePerMonth%')
Begin
	Begin Try
		Drop Table #LastArchivePerMonth
	End Try
	Begin Catch
		
	End Catch
End

Select
	dbs.ServerName
	,dbs.DatabaseName
	,dbs.[FileName]
	,f.FiscalMonthName
	,MAX(dbs.ArchiveDate) as LastArchiveDateForMonth
Into
	#LastArchivePerMonth
From
	DBGrowth.dbo.DatabaseSize dbs 
	Inner Join EAFSQLSG.dbo.ext_ir_vwdfiscaldate f on
		CONVERT(datetime, CONVERT(varchar,dbs.ArchiveDate,101)) = CONVERT(datetime, CONVERT(varchar,f.FiscalDate,101))
Group By
	dbs.ServerName
	,dbs.DatabaseName
	,dbs.[FileName]
	,f.FiscalMonthName


Set @ArchiveDate = @CurrentArchiveDate

Select
	@PreviousArchiveDate = MAX(LastArchiveDateForMonth)
From
	#LastArchivePerMonth
Where
	LastArchiveDateForMonth < @ArchiveDate

Delete #DatabaseDiff

While (@PreviousArchiveDate != '')
Begin

	Insert Into	
		#DatabaseDiff
	Select
		ISNULL(p.ServerName,c.ServerName) as ServerName
		,ISNULL(p.DatabaseName,c.DatabaseName) as DatabaseName
		,ISNULL(p.[FileName],c.[FileName]) as [FileName]
		,@PreviousArchiveDate as PreviousArchiveDate
		,IsNull(p.FileSizeInMB,0) as PreviousFileSizeInMB
		,(IsNull(c.FileSizeInMB,0) - IsNull(p.FileSizeInMB,0)) as FileSizeChangeInMB
		,(Select MIN(f.ArchiveDate) From DBGrowth.dbo.DatabaseSize f Where f.ServerName = c.ServerName And f.DatabaseName = c.DatabaseName And f.[FileName] = c.[FileName]) as FirstArchiveDate
			From
				(
					Select	
						p1.*
					From
						DBGrowth.dbo.DatabaseSize p1
						Inner Join #LastArchivePerMonth p2 on
								p1.ServerName = p2.ServerName
							And
								p1.DatabaseName = p2.DatabaseName
							And
								p1.[FileName] = p2.[FileName]
							And
								p1.ArchiveDate = p2.LastArchiveDateForMonth
				) p
				Full Outer Join 
				(
					Select	
						c1.*
					From
						DBGrowth.dbo.DatabaseSize c1
						Inner Join #LastArchivePerMonth c2 on
								c1.ServerName = c2.ServerName
							And
								c1.DatabaseName = c2.DatabaseName
							And
								c1.[FileName] = c2.[FileName]
							And
								c1.ArchiveDate = c2.LastArchiveDateForMonth
				) c on
					p.ServerName = c.ServerName
				And
					p.DatabaseName = c.DatabaseName
				And	
					p.[FileName] = c.[FileName]
			Where
				p.ArchiveDate = @PreviousArchiveDate
			And
				c.ArchiveDate = @ArchiveDate

	Set @ArchiveDate  = @PreviousArchiveDate
	
	Set @PreviousArchiveDate = ''
	
	Select
		@PreviousArchiveDate = MAX(LastArchiveDateForMonth)
	From
		#LastArchivePerMonth
	Where
		LastArchiveDateForMonth < @ArchiveDate

End

If Exists(Select * From INFORMATION_SCHEMA.TABLES Where TABLE_NAME = 'DatabaseSize_AverageGrowthPerMonth')
Begin
	Drop Table DatabaseSize_AverageGrowthPerMonth
End

Select
	ServerName
	,DatabaseName
	,[FileName]
	,FirstArchiveDate
	,Avg(FileSizeChangeInMB) as AverageFileGrowthInMB
	,Round(Avg((cast(FileSizeChangeInMB as float)/cast(PreviousFileSizeInMB as float)) * 100.00),1) as AveragePercentChange
Into
	DatabaseSize_AverageGrowthPerMonth
From
	#DatabaseDiff
Group By
	ServerName
	,DatabaseName
	,[FileName]
	,FirstArchiveDate
Order By
	Abs(Round(Avg((cast(FileSizeChangeInMB as float)/cast(PreviousFileSizeInMB as float)) * 100.00),1)) desc
	
	
