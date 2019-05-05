-- Step: Server level permissions
USE master;
GO

If Exists(select Name from master.dbo.syslogins where name = 'REDMOND\v-rreddy')
Begin
	DROP LOGIN [redmond\v-rreddy];
End
GO

CREATE LOGIN [REDMOND\v-rreddy] FROM WINDOWS WITH DEFAULT_LANGUAGE=[us_english]
GO

DENY VIEW ANY DATABASE TO [redmond\v-rreddy]; 
GO

DENY VIEW SERVER STATE TO [redmond\v-rreddy]; 
GO

GRANT CONNECT SQL TO [redmond\v-rreddy]; 
GO

-- step: DB level permissions

	-- CnO_BI_PowerPivot_External
	Use [CnO_BI_PowerPivot_External];
	Go

	If Exists(SELECT * FROM CnO_BI_PowerPivot_External.sys.database_principals WHERE name = 'REDMOND\v-rreddy')
	Begin
		DROP USER [redmond\v-rreddy];
	End
	Go

	CREATE USER [redmond\v-rreddy] FOR LOGIN [redmond\v-rreddy]
	Go

	Use master;
	Go

	Exec sp_defaultdb @loginame='redmond\v-rreddy', @defdb='CnO_BI_PowerPivot_External'
	Go

	Use [CnO_BI_PowerPivot_External];
	Go

	GRANT SELECT ON [dbo].[vRptRevenueAppNexus] to [redmond\v-rreddy];
	Go 

	DENY VIEW DEFINITION ON [dbo].[rptRevenueAppNexus] TO [redmond\v-rreddy];
	GO

	DENY SELECT ON [dbo].[rptRevenueAppNexus] TO [redmond\v-rreddy];
	GO

	-- CnO_BI_PowerPivot_Dev_Geo (this table is used in the vRptRevenueAppNexus view)
	Use CnO_BI_PowerPivot_Dev_Geo;
	Go

	If Exists(SELECT * FROM CnO_BI_PowerPivot_Dev_Geo.sys.database_principals WHERE name = 'REDMOND\v-rreddy')
	Begin
		DROP USER [redmond\v-rreddy];
	End
	Go

	CREATE USER [redmond\v-rreddy] FOR LOGIN [redmond\v-rreddy]
	Go

	GRANT SELECT ON [dbo].OpsCubeRoleMembership to [redmond\v-rreddy];
	Go 