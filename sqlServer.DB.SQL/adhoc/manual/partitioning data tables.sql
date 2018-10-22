Use TempDB;
Go

--------------------------------
-- create partition function
-------------------------------

Create Partition Function Employee_PartFunc
(
	Varchar(10)
)
As Range Right -- if an EmployeeNumber is 3, 8, or 12 it will go into the range to the right of the boundary.
For Values
(
	3
	,8
	,12
)
Go

--------------------------------
-- create partition scheme
-------------------------------

Create Partition Scheme Employee_PartScheme
As
Partition Employee_PartFunc
To
( -- These are file groups and they need to exist before this can run.
	e1
	,e2
	,e3
	,e4
)
Go

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
) On Employee_PartScheme(EmployeeNumber) -- making use of the partition scheme 
Go

Insert Into
	Employee
Select '1','John', 'Doe','King of the World'
Union All
Select '4','Jane','Doe','Queen of the Sea'
Union All
Select '10','Zander','McGyver','Almost MacGyver'
Go
