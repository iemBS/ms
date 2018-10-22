Use TempDB;

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
)
Go

If Exists(Select * From Information_Schema.Tables Where Table_Name = 'EmployeeSource')
Begin
	Drop Table EmployeeSource
End
Go

Create Table EmployeeSource
(
	EmployeeNumber Varchar(10)
	,FirstName Varchar(50)
	,LastName Varchar(50)
	,Position Varchar(50)
)
Go

Insert Into
	EmployeeSource
Select '1','John','Doe','King of the World'
Union All
Select '2','Jane','Doe','Queen of the Sea'
Union All
Select '3','Xander','McGyver','Almost MacGyver'
Go

----------------------------
-- how to to without merge
----------------------------
If Exists(Select * From Information_Schema.Routines Where Routine_Name = 'p_ProcessEmployeeWithoutMerge')
Begin
	Drop Procedure p_ProcessEmployeeWithoutMerge
End
Go

Create Procedure p_ProcessEmployeeWithoutMerge
As

-- add record to mapping table
Insert Into
	Employee 
	(
		EmployeeNumber
		,FirstName
		,LastName
		,Position
	)
Select
	EmployeeNumber
	,FirstName
	,LastName
	,Position
From
	EmployeeSource
Where
	EmployeeNumber Not In
	(
		Select
			EmployeeNumber
		From
			Employee
	)
			
-- update record in map table
Update
	e
Set
	FirstName = es.FirstName
	,LastName = es.LastName
	,Position = es.Position
From
	Employee e
	Inner Join EmployeeSource es On
		e.EmployeeNumber = es.EmployeeNumber
Go
	
Execute p_ProcessEmployeeWithoutMerge
Go

Select
	*
From
	Employee
Go

--------------------------
-- how to do with merge
--------------------------

If Exists(Select * From Information_Schema.Routines Where Routine_Name = 'p_ProcessEmployeeWithMerge')
Begin
	Drop Procedure p_ProcessEmployeeWithMerge
End
Go

Create Procedure p_ProcessEmployeeWithMerge
As

Merge 
	Employee As Target -- mapping table we want to update
Using
	
	(
		-- Source of our updates. Even though this is required to be a table source just naming a table is not allowed.
		Select 
			*
		From
			EmployeeSource
	) As Source
	(
		-- Fields we will be using in the source to update the mapping table
		EmployeeNumber
		,FirstName
		,LastName
		,Position
	) 
On
	-- Field in the source and mapping table that we want to use to determine if the entry exists in the mapping table.
	Target.EmployeeNumber = Source.EmployeeNumber
When Matched 
Then
	-- If the EmployeeNumber exists in the mapping table then update the other fields.
	Update
	Set
		FirstName = Source.FirstName
		,LastName = Source.LastName
		,Position = Source.Position
When Not Matched
Then
	-- If the EmployeeNumber does not exist in the mapping table then add it and as many of the employee attributes that I have.
	Insert 
	(
		EmployeeNumber
		,FirstName
		,LastName
		,Position
	)
	Values
	(
		Source.EmployeeNumber
		,Source.FirstName
		,Source.LastName
		,Source.Position
	)
; -- semi-colon is required to end a merge
Go

Execute p_ProcessEmployeeWithMerge
Go

Select
	*
From
	Employee
Go

---------------------------
-- Why use Merge?
---------------------------

/*
Point 1:
Instead of having three statements (insert, update, delete) to update
a mapping table you can use one (merge). So, the bigger the mapping table
that needs to be updated the bigger the performance boost. When comparing the 
non-merge and merge methods the performance boost may be big percentage wise, but
I do not know if the performance boost in general is something that is big. Only 
regular usage and actually comparing the two methods will tell me if merge is 
something I want to use on a regular basis.

Point 2:
The merge also lets us specify the source of our updates in a single location (the Using part of the Merge).
*/