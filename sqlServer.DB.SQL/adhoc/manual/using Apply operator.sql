Use TempDB;
Go

-- prep
If Exists(Select * From Information_Schema.Tables Where Table_Name = 'Employees')
Begin
	Drop Table Employees
End
Go

CREATE TABLE Employees
(
    empid   int         NOT NULL
    ,mgrid   int         NULL
    ,empname varchar(25) NOT NULL
    ,salary  money       NOT NULL
    CONSTRAINT PK_Employees PRIMARY KEY(empid)
);
GO
INSERT INTO Employees VALUES(1 , NULL, 'Nancy'   , $10000.00);
INSERT INTO Employees VALUES(2 , 1   , 'Andrew'  , $5000.00);
INSERT INTO Employees VALUES(3 , 1   , 'Janet'   , $5000.00);
INSERT INTO Employees VALUES(4 , 1   , 'Margaret', $5000.00);
INSERT INTO Employees VALUES(5 , 2   , 'Steven'  , $2500.00);
INSERT INTO Employees VALUES(6 , 2   , 'Michael' , $2500.00);
INSERT INTO Employees VALUES(7 , 3   , 'Robert'  , $2500.00);
INSERT INTO Employees VALUES(8 , 3   , 'Laura'   , $2500.00);
INSERT INTO Employees VALUES(9 , 3   , 'Ann'     , $2500.00);
INSERT INTO Employees VALUES(10, 4   , 'Ina'     , $2500.00);
INSERT INTO Employees VALUES(11, 7   , 'David'   , $2000.00);
INSERT INTO Employees VALUES(12, 7   , 'Ron'     , $2000.00);
INSERT INTO Employees VALUES(13, 7   , 'Dan'     , $2000.00);
INSERT INTO Employees VALUES(14, 11  , 'James'   , $1500.00);
GO

If Exists(Select * From Information_Schema.Tables Where Table_Name = 'Departments')
Begin
	Drop Table Departments
End
Go

CREATE TABLE Departments
(
    deptid    INT NOT NULL PRIMARY KEY
    ,deptname  VARCHAR(25) NOT NULL
    ,deptmgrid INT NULL REFERENCES Employees
);
GO
INSERT INTO Departments VALUES(1, 'HR',           2);
INSERT INTO Departments VALUES(2, 'Marketing',    7);
INSERT INTO Departments VALUES(3, 'Finance',      8);
INSERT INTO Departments VALUES(4, 'R&D',          9);
INSERT INTO Departments VALUES(5, 'Training',     4);
INSERT INTO Departments VALUES(6, 'Gardening', NULL);
Go

If Exists(Select * From Information_Schema.Routines Where Routine_Name = 'fn_getsubtree')
Begin
	Drop Function fn_getsubtree
End
Go

CREATE FUNCTION dbo.fn_getsubtree(@empid AS INT) 
    RETURNS @TREE TABLE
(
    empid   INT NOT NULL
    ,empname VARCHAR(25) NOT NULL
    ,mgrid   INT NULL
    ,lvl     INT NOT NULL
)
AS
BEGIN
  WITH Employees_Subtree(empid, empname, mgrid, lvl)
  AS
  ( 
    -- Anchor Member (AM)
    SELECT empid, empname, mgrid, 0
    FROM Employees
    WHERE empid = @empid

    UNION all
    
    -- Recursive Member (RM)
    SELECT e.empid, e.empname, e.mgrid, es.lvl+1
    FROM Employees AS e
      JOIN Employees_Subtree AS es
        ON e.mgrid = es.empid
  )
  INSERT INTO @TREE
    SELECT * FROM Employees_Subtree;

  RETURN
END
GO


/* using Cross Apply 
	- No record is returned where the DeptMgrId field is null. So no Gardening dept records.
	- This is like an inner join between two tables. 
*/
Select 
	D.deptid
	,D.deptname
	,D.deptmgrid
From 
	Departments d
	
Select 
	D.deptid
	,D.deptname
	,D.deptmgrid
    ,ST.empid
    ,ST.empname
    ,ST.mgrid
From 
	Departments d
	Cross Apply fn_getsubtree(d.DeptMgrId) st;


/* using Outer Apply
	- A record is returned where the DeptMgrId field is null but the columns coming from
	  the function are null. This is occuring for the Gardening department.
	- This is like a full outer join between two tables. 
*/
Select 
	D.deptid
	,D.deptname
	,D.deptmgrid
From 
	Departments d
	
Select 
	D.deptid
	,D.deptname
	,D.deptmgrid
    ,ST.empid
    ,ST.empname
    ,ST.mgrid
From 
	Departments d
	Outer Apply fn_getsubtree(d.DeptMgrId) st;



