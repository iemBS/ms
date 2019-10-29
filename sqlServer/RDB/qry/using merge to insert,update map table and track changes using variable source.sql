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

Insert Into
	Employee
Select '1','John','Doe','King of the World'
Union All
Select '2','Jane','Doe','Queen of the Sea'
Union All
Select '3','Xander','McGyver','Almost MacGyver'
Go


If Exists(Select * From Information_Schema.Tables Where Table_Name = 'EmployeeChangeTracking')
Begin
	Drop Table EmployeeChangeTracking
End
Go

Create Table EmployeeChangeTracking
(
	EmployeeNumber Varchar(10)
	,PreviousFirstName Varchar(50)
	,FirstName Varchar(50)
	,PreviousLastName Varchar(50)
	,LastName Varchar(50)
	,PreviousPosition Varchar(50)
	,Position Varchar(50)
)
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
	@EmployeeNumber Varchar(10)
	,@FirstName Varchar(50)
	,@LastName Varchar(50)
	,@Position Varchar(50)
As

If Not Exists
(
	Select
		'X'
	From
		Employee
	Where
		EmployeeNumber = @EmployeeNumber
)
Begin
	-- add record to mapping table
	Insert Into
		Employee
		(
			EmployeeNumber
			,FirstName
			,LastName
			,Position
		)
		Output
			Inserted.EmployeeNumber
			,''
			,Inserted.FirstName
			,''
			,Inserted.LastName
			,''
			,Inserted.Position
		Into
			EmployeeChangeTracking
		Values
		(
			@EmployeeNumber
			,@FirstName
			,@LastName
			,@Position
		)
End
Else
Begin
	-- update record in map table
	Update
		Employee
	Set
		FirstName = @FirstName
		,LastName = @LastName
		,Position = @Position
	Output
		Inserted.EmployeeNumber
		,Deleted.FirstName
		,Inserted.FirstName
		,Deleted.LastName
		,Inserted.LastName
		,Deleted.Position
		,Inserted.Position
	Into
		EmployeeChangeTracking
	Where
		EmployeeNumber = @EmployeeNumber	

End
Go
	
Execute p_ProcessEmployeeWithoutMerge 'ABC123','John','Smith','Vice President'
Go

Select
	*
From
	Employee
Go

Select
	*
From
	EmployeeChangeTracking
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
	@EmployeeNumber Varchar(10)
	,@FirstName Varchar(50)
	,@LastName Varchar(50)
	,@Position Varchar(50)
As

Merge 
	Employee As Target -- map table we want to update
Using
	(
		-- Source of our updates. In this case these are input variables to the stored procedure.
		Select
			@EmployeeNumber
			,@FirstName
			,@LastName
			,@Position
	) As Source
	(
		-- This section does not make sense when using input variables as the source, but when using
		-- an actual table as the Source this section is similiar to when you specify the columns you want
		-- to insert into when you have an insert statement are specifying specific columns you will be 
		-- inserting values into.
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
Output
	Inserted.EmployeeNumber
	,Deleted.FirstName
	,Inserted.FirstName
	,Deleted.LastName
	,Inserted.LastName
	,Deleted.Position
	,Inserted.Position
Into
	EmployeeChangeTracking
; -- semi-colon is required to end a merge
Go

Execute p_ProcessEmployeeWithMerge 'ABC123','John','Smith','Vice President'
Go

Select
	*
From
	Employee
Go

Select
	*
From
	EmployeeChangeTracking
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

Point 3: 
When using the Inserted and Deleted system tables to track the changes to your mapping
table the inserting into your tracking table can be done at the end of a Merge statement
making the query easier to read and your are only inserting into that tracking table
once instead of up to three times (insert, update, delete parts of a merge)
*/
