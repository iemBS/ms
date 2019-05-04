
-- just date
Create Table #tableA
(
	theDate date
)

Declare @theDate date
Declare @endDate date
Set @theDate = '2005-01-01'
Set @endDate = '2019-12-31'
While (@theDate <= @endDate)
Begin
	Insert Into 
		#tableA
	Select
		@theDate

	Set @theDate = DateAdd(day,1,@theDate)
End

-- just date week later
Create Table #tableB
(
	theDate date,
	dateWkLater date,
	instanceInWeek Int
)

Insert Into
	#tableB
Select
	theDate,
	CONVERT(date,dateadd(week,1,theDate)),
	datepart(dw,theDate)
From
	#tableA

-- just date month later and year later
create table #tableC1
(
	theDate date,
	dayInWeek Int,
	instanceInMonth int,
	monthInYear int,
	year int
)

Insert Into
	#tableC1
Select
	theDate,
	DatePart(dw,theDate) As DayInWeek,
	Case 
		When DatePart(m,DateAdd(day,-7,theDate))  = (Case DatePart(m,theDate) - 1 When 0 Then 12 Else DatePart(m,theDate) - 1 End)  Then 1
		When DatePart(m,DateAdd(day,-14,theDate)) = (Case DatePart(m,theDate) - 1 When 0 Then 12 Else DatePart(m,theDate) - 1 End)  Then 2
		When DatePart(m,DateAdd(day,-21,theDate)) = (Case DatePart(m,theDate) - 1 When 0 Then 12 Else DatePart(m,theDate) - 1 End)  Then 3
		When DatePart(m,DateAdd(day,-28,theDate)) = (Case DatePart(m,theDate) - 1 When 0 Then 12 Else DatePart(m,theDate) - 1 End)  Then 4
		When DatePart(m,DateAdd(day,-35,theDate)) = (Case DatePart(m,theDate) - 1 When 0 Then 12 Else DatePart(m,theDate) - 1 End)  Then 5
	End As InstanceInMonth,
	DatePart(m,theDate) as MonthInYear,
	datePart(yyyy,theDate) As Year
From
	#TableA

create table #tableC2
(
	theDate date,
	dayInWeek Int,
	instanceInMonth int,
	monthPosition int,
	year int,
	yearPosition int
)

Insert Into
	#tableC2
Select
	theDate,
	dayInWeek,
	instanceInMonth,
	(monthInYear + (12 * (year - DatePart(YEAR,(Select min(theDate) From #tableA))))) as monthPosition,
	year,
	(year - 1950) As yearPosition
From
	#tableC1


create table #tableC
(
	theDate date,
	instanceInWeek int,
	instanceInMonth int,
	monthPosition int,
	dateWkLater date,
	dateMthLater date,
	dateYrLater date
)

Insert Into 
	#tableC
Select
	b.theDate,
	b.instanceInWeek,
	cx.instanceInMonth,
	cx.monthPosition,
	b.dateWkLater,
	cy.theDate As dateMthLater,
	cz.theDate as dateYrLater
From
	#tableB b
	Inner Join #tableC2 cx On 
		b.theDate = cx.theDate
	Left Outer Join #tableC2 cy On 
		cx.dayInWeek = cy.dayInWeek
		And
		cx.instanceInMonth = cy.instanceInMonth
		And
		cx.monthPosition + 1 = cy.monthPosition
	Left Outer Join #tableC2 cz On 
		cx.dayInWeek = cz.dayInWeek
		And
		cx.instanceInMonth = cz.instanceInMonth
		And
		cx.monthPosition + 12 = cz.monthPosition
		--And
		--cx.yearPosition + 1 = cz.yearPosition


-- Fill in dateMthLaterNxt where dateMthLater does not exist
create table #tableD
(
	theDate date,
	dateWkLater date,
	dateMthLater date,
	dateMthLaterNxt date,
	dateYrLater date,
	dyInstInMth int,
	dyPosInWk int
)

Insert Into 
	#tableD
Select
	a.theDate,
	a.dateWkLater,
	a.dateMthLater,
	(Select min(theDate) From #tableC Where monthPosition > a.monthPosition And instanceInMonth = a.instanceInMonth And instanceInWeek = a.instanceInWeek) As dateMthLaterNxt,
	a.dateYrLater,
	a.instanceInMonth As dyInstInMth,
	a.instanceInWeek As dyPosInWk
From
	#tableC a
Where
	a.dateMthLater Is Null

Union All

Select
	a.theDate,
	a.dateWkLater,
	a.dateMthLater,
	Null As dateMthLaterNxt,
	a.dateYrLater,
	a.instanceInMonth As dyInstInMth,
	a.instanceInWeek As dyPosInWk
From
	#tableC a
Where
	a.dateMthLater Is Not Null

-- Create db.time.insert statement for MongoDB
Select
	'db.time.insert({' + theDate + dateWkLater + dateMthLater + dateMthLaterNxt + dateYrLater + dyPosInWk + dyInstInMth + yr + mth + '});'
From
	(
		Select
			'date:new Date("' + cast(theDate As varchar) + '")' As theDate,
			',dateWkLater:new Date("' + cast(dateWkLater As varchar) + '")' As dateWkLater,
			Case 
				When dateMthLater Is Not Null Then ',dateMthLater:new Date("' + cast(dateMthLater As varchar) + '")' 
				Else '' 
			End As dateMthLater,
			Case 
				When dateMthLaterNxt Is Not Null Then ',dateMthLaterNxt:new Date("' + cast(dateMthLaterNxt As varchar) + '")' 
				Else '' 
			End As dateMthLaterNxt,
			Case 
				When dateYrLater Is Not Null Then ',dateYrLater:new Date("' + cast(dateYrLater As varchar) + '")' 
				Else '' 
			End As dateYrLater,
			',dyPosInWk:' + cast(dyPosInWk as Varchar) As dyPosInWk,
			',dyInstInMth:' + cast(dyInstInMth as Varchar) As dyInstInMth,
			',mth:' + cast(datepart(MONTH,theDate) as varchar) As mth,
			',yr:' + cast(datepart(YEAR,theDate) as varchar) As yr
		From
			#tableD
	) t
Order By
	theDate


