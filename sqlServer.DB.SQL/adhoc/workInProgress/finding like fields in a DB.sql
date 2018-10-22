Use EPGROB
Go

/*
	Search for "DATABASE SPECIFIC" to to find parts of query that are 
	specific to the database
*/

--- Find columns with same name, type, size
Select 'Find columns with same name, type, size' As CheckType

Select
	a.FieldId
	,a.Column_Name
	,a.Data_Type
	,a.Character_Maximum_Length
	,a.Numeric_Precision
	,a.Numeric_Scale
	,b.Table_Name
	,b.Table_Schema
Into
	#SameNameTypeSize
From
(
	Select Distinct  
		Column_Name
		,Data_Type
		,IsNull(Character_Maximum_Length,0) As Character_Maximum_Length
		,IsNull(Numeric_Precision,0) As Numeric_Precision
		,IsNull(Numeric_Scale,0) As Numeric_Scale
		,Dense_Rank() Over (Order By Column_Name,Data_Type,IsNull(Character_Maximum_Length,0),IsNull(Numeric_Precision,0),IsNull(Numeric_Scale,0)) As FieldId
	From
		Information_Schema.Columns
) a
Inner Join Information_Schema.Columns b On 
	a.Column_Name = b.Column_Name
	And
	a.Data_Type = b.Data_Type
	And
	a.Character_Maximum_Length = IsNull(b.Character_Maximum_Length,0)
	And
	a.Numeric_Precision = IsNull(b.Numeric_Precision,0)
	And
	a.Numeric_Scale = IsNull(b.Numeric_Scale,0)
Order By
	a.Column_Name
	,a.FieldId
	,b.Table_Name
	,b.Table_Schema

Select * From #SameNameTypeSize

-- Find columns with same name, same type
Select
	a.FieldId
	,a.Column_Name
	,a.Data_Type
	,b.Table_Name
Into
	#SameNameType
From
(
	Select Distinct  
		Column_Name
		,Data_Type
		,Dense_Rank() Over (Order By Column_Name,Data_Type) As FieldId
	From
		Information_Schema.Columns
) a
Inner Join Information_Schema.Columns b On 
	a.Column_Name = b.Column_Name
	And
	a.Data_Type = b.Data_Type
Order By
	a.Column_Name
	,a.FieldId
	,b.Table_Name

-- Find columns with the same name
Select
	a.FieldId
	,a.Column_Name
	,b.Table_Name
Into
	#SameName
From
(
	Select Distinct  
		Column_Name
		,Dense_Rank() Over (Order By Column_Name) As FieldId
	From
		Information_Schema.Columns
) a
Inner Join Information_Schema.Columns b On 
	a.Column_Name = b.Column_Name
Order By
	a.Column_Name
	,a.FieldId
	,b.Table_Name
	
-- Find columns with same name & type, but diff size
Select 'Find columns with same name & type, but diff size' As CheckType
	
	-- strings
	Select Distinct
		a.Column_Name
		,a.Data_Type
		,a.Character_Maximum_Length
		,a.Numeric_Precision
		,a.Numeric_Scale
		,b.FieldId
	From
		(
			Select
				Column_Name
				,Data_Type
			From
				#SameNameTypeSize
			Group By
				Column_Name
				,Data_Type
			Having
				Count(Distinct Character_Maximum_Length) > 1
		) x
		Inner Join #SameNameTypeSize a On 
			x.Column_Name = a.Column_Name
			And
			x.Data_Type = a.Data_Type
		Inner Join #SameNameType b On 
			a.Column_Name = b.Column_Name
			And
			a.Data_Type = b.Data_Type
		
	Union All
	
	-- numbers
	Select Distinct
		a.Column_Name
		,a.Data_Type
		,a.Character_Maximum_Length
		,a.Numeric_Precision
		,a.Numeric_Scale
		,b.FieldId
	From
		(
			Select
				Column_Name
				,Data_Type
			From
				#SameNameTypeSize
			Group By
				Column_Name
				,Data_Type
			Having
				Count(Distinct Numeric_Precision) > 1
				Or
				Count(Distinct Numeric_Scale) > 1
		) x
		Inner Join #SameNameTypeSize a On 
			x.Column_Name = a.Column_Name
			And
			x.Data_Type = a.Data_Type
		Inner Join #SameNameType b On 
			a.Column_Name = b.Column_Name
			And
			a.Data_Type = b.Data_Type
	Order By
		b.FieldId
		,a.Column_Name
		,a.Data_Type
		,a.Character_Maximum_Length
		,a.Numeric_Precision
		,a.Numeric_Scale


-- Find columns with same name & diff type
Select 'Find columns with same name & diff type' As CheckType

Select Distinct
	a.Column_Name
	,a.Data_Type
	,b.FieldId
From
	(
		Select
			Column_Name
		From
			#SameNameType
		Group By
			Column_Name
		Having
			Count(Distinct Data_Type) > 1
	) x
	Inner Join #SameNameType a On 
		x.Column_Name = a.Column_Name
	Inner Join #SameName b On 
		a.Column_Name = b.Column_Name
Order By
	b.FieldId
	,a.Column_Name
	,a.Data_Type
	
-- Select Pick list Columns that will be used in the analysis below this
-- (DATABASE SPECIFIC)
Select 'Select Pick list Columns that will be used in the analysis below this' As CheckType

Select Distinct 
	Column_Name
Into
	#Column_Name
From
	#SameNameTypeSize
Where
	Column_Name In 
	(
		'Area'
		,'Area Name'
	)
	
	Select * From #Column_Name
	

-- Find possible values of selected columns with same name, type, size
Select 'Find possible values of selected columns with same name, type, size' As CheckType

Select  
	b.Column_Name
	,b.Table_Name
	,'Select Distinct ''' + b.Column_Name +  ''' As Column_Name,''' + b.Table_Schema + '.' + b.Table_Name  + ''' As Table_Name,[' + b.Column_Name + '] From [' + b.Table_Schema + '].[' + b.Table_Name + '] Order By [' + b.Column_Name + '] ' As QueryToRun
From
(
	Select
		FieldId
	From
		#SameNameTypeSize
	Where
		Column_Name In (Select Column_Name From #Column_Name)
	Group By
		FieldId
	Having
		Count(Distinct Table_Name) > 1
) a
Inner Join #SameNameTypeSize b On 
	a.FieldId = b.FieldId
Order By
	b.Column_Name
	,b.Table_Name
	
-- Find possible values of selected columns with same name, type
	-- need to fill in

-- Find possible values of selected columns with same name
	-- need to fill in


-- Select Columns that have the same possible values but diff name
-- (DATABASE SPECIFIC)
Select 'Select Columns that have the same possible values but diff name' As CheckType

Select
	(
		Case
			When b.Table_Name = 'xxx' And a.Column_Name = 'xxx' Then 1
			When b.Table_Name = 'xxx' And a.Column_Name = 'xxx' Then 1
			When b.Table_Name = 'xxx' And a.Column_Name = 'xxx' Then 2
			Else 0
		End
	) As FieldId
	,a.Column_Name
	,b.Table_Name
Into
	#DiffNameSamePossibleValue
From
	#Column_Name a
	Inner Join #SameNameTypeSize b On 
		a.Column_Name = b.Column_Name
	
Select * From #DiffNameSamePossibleValue Where FieldId > 0


-- Select ID Columns that will be used in the analysis below this
-- (DATABASE SPECIFIC)
Select 'Select ID Columns that will be used in the analysis below this' As CheckType

Select Distinct 
	Column_Name
Into
	#Column_Name_Id
From
	#SameNameTypeSize
Where
	Column_Name In 
	(
		'AccountId'
	)
	
	Select * From #Column_Name_Id
	
	
-- Distinct and non-Distinct ID counts
Select 'Distinct and non-Distinct ID counts' As CheckType

Select
	b.Column_Name
	,b.Table_Name
	,'Select ''' + b.Column_Name + ''' As Column_Name,''' + b.Table_Name+ ''' As Table_Name,Count(Distinct [' + b.Column_Name + ']) As DistinctCnt, Count([' + b.Column_Name + ']) As Cnt From [' + b.Table_Schema + '].[' + b.Table_Name + ']' As QueryToRun
From
	#Column_Name_Id a
	Inner Join #SameNameTypeSize b On 
		a.Column_Name = b.Column_Name
	
-- See what Ids exist in another table
-- (DATABASE SPECIFIC)

	-- work on this


-- Select Time Period Columns that will be used in the analysis below this
-- (DATABASE SPECIFIC)
Select 'Select Time Period Columns that will be used in the analysis below this' As CheckType

Select Distinct 
	Column_Name
Into
	#Column_Name_Time
From
	#SameNameTypeSize
Where
	Column_Name In 
	(
		'DueDate'
	)
	
	Select * From #Column_Name_Time

-- Distinct and non-Distinct Time Period counts

Select 'Distinct and non-Distinct Time Period counts' As CheckType

Select
	b.Column_Name
	,b.Table_Name
	,'Select ''' + b.Column_Name + ''' As Column_Name,''' + b.Table_Name+ ''' As Table_Name,Count(Distinct [' + b.Column_Name + ']) As DistinctCnt, Count([' + b.Column_Name + ']) As Cnt From [' + b.Table_Schema + '].[' + b.Table_Name + ']' As QueryToRun
From
	#Column_Name_Time a
	Inner Join #SameNameTypeSize b On 
		a.Column_Name = b.Column_Name
		
	