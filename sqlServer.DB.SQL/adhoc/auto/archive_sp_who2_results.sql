/* 
This query was written for a server that does not allow remote procedures calls (RPC) against it. 

This will archive the sp_who2 results for a specific alias. In this case, for the "johnd" alias in the "seattle" domain.
*/

use workArea;

if not exists(select * from INFORMATION_SCHEMA.tables where table_name = 'johnd_sg_sp_who2_results')
begin
	create table workArea.[seattle\johnd].johnd_sg_sp_who2_results 
	(
		spid INT  
		,[status] VARCHAR(1000) NULL  
		,[login] SYSNAME NULL  
		,hostName SYSNAME NULL  
		,blkBy SYSNAME NULL  
		,dBName SYSNAME NULL  
		,command VARCHAR(1000) NULL  
		,cpuTime INT NULL  
		,diskIO INT NULL  
		,lastBatch VARCHAR(1000) NULL  
		,programName VARCHAR(1000) NULL  
		,spid2 INT
		,requestId INT
		,archiveDate datetime
	)
end

create table #sg_sp_who2_results 
(
	spid INT  
	,[status] VARCHAR(1000) NULL  
	,[login] SYSNAME NULL  
	,hostName SYSNAME NULL  
	,blkBy SYSNAME NULL  
	,dBName SYSNAME NULL  
	,command VARCHAR(1000) NULL  
	,cpuTime INT NULL  
	,diskIO INT NULL  
	,lastBatch VARCHAR(1000) NULL  
	,programName VARCHAR(1000) NULL  
	,spid2 INT
	,requestId INT
)

insert into
	#sg_sp_who2_results 
exec MSSALES.dbo.sp_who2

insert into	
	workArea.[seattle\johnd].johnd_sg_sp_who2_results 
select
	*
	,getdate() as archiveDate
from
	#sg_sp_who2_results

/*
-- test the results of this
select
	*
from
	workArea.[seattle\johnd].johnd_sg_sp_who2_results 
where
	login in ('seattle\johnd')
*/	
	
drop table #sg_sp_who2_results 

