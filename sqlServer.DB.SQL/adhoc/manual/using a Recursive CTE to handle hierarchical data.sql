Use TempDB;
Go

-----------
-- prep
-----------
If Exists(Select * From Information_Schema.Tables Where Table_Name = 'Employee')
Begin
	Drop Table Employee
End
Go

Create Table Employee
(
	EmployeeNumber Varchar(10)
	,FirstName Varchar(50)
	,LastName Varchar(50)
	,Position Varchar(50)
	,ManagerEmployeeNumber Varchar(10)
	,EmployeeLevel Int
)
Go

Insert Into
	Employee
Select '1','John','Doe','King of the World',null,0
Union All
Select '2','Jane','Doe','Queen of the Sea','1',1
Union All
Select '3','Xander','McGyver','Almost MacGyver','2',2
Go


-- create the CTE
With Employee_CTE -- name and columns for the CTE
(
	EmployeeNumber
	,FirstName
	,LastName
	,Position
	,ManagerEmployeeNumber
	,EmployeeLevel
)
As 
(
	-- anchor part of CTE definition
	Select
		EmployeeNumber
		,FirstName
		,LastName
		,Position
		,ManagerEmployeeNumber
		,EmployeeLevel
	From
		Employee
	Where
		ManagerEmployeeNumber Is Null
		
	Union All
	-- Recursive part of CTE definition. Joins to CTE.
	Select
		e.EmployeeNumber
		,e.FirstName
		,e.LastName
		,e.Position
		,e.ManagerEmployeeNumber
		,e.EmployeeLevel + 1
	From
		Employee e
		Inner Join Employee_CTE cte On
			e.ManagerEmployeeNumber = cte.EmployeeNumber
)

-- using the CTE
Select
	*
From
	Employee_CTE
Go

---------------------------
-- Why use a CTE?
---------------------------

/*
Point 1:
Is temporary and only exists with the scope of a single select, insert, delete, or create view statement.

Point 2: 
Using a CTE might provide better performance than an a query or a sub query. Only a comparison between a 
non-CTE method and a CTE method will show you if a CTE is better to use.

*/