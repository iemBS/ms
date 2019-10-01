/*
purpose: Finds and removes characters that are not needed
parameter: 
	first parameter - specify 1 or 2. 1) remove all unneeded characters, 2) remove some uneeded characters but keep better readability
	second parameter - query to remove unneeded characters from, if query cannot contain /n or /n/r be sure to indicate their positions with |LFCR| instead
return: query without unneeded characters
note: PatternID is an ID and also the order in which the patterns needs to be applied
*/

declare @query varchar(8000)
Set @query = '[myDB].[dbo].[TransformDMIFormFactor].|QUERY START| |LFCR|  |LFCR| |LFCR| |LFCR|--DROP VIEW [dbo].[TransformFormFactor] |LFCR|CREATE VIEW [dbo].[TransformDMIFormFactor] AS  |LFCR| |LFCR|WITH CTE1 AS |LFCR|( |LFCR|   SELECT DISTINCT [FormFactor] |LFCR|   FROM DMIOEM.[DMIFull] |LFCR|   UNION |LFCR|   SELECT DISTINCT FormFactor |LFCR|   FROM Fusion.FusionFull  |LFCR|)  |LFCR| |LFCR|  |LFCR|SELECT FormFactor = ROW_NUMBER() OVER(ORDER BY FormFactor),  |LFCR|       FF_Description = FormFactor |LFCR|FROM CTE1 |LFCR| |LFCR| |LFCR| |LFCR| |LFCR| |LFCR| |LFCR| |LFCR||QUERY END|'

declare @patternType int
set @patternType = 2

-- collect patterns
If OBJECT_ID('tempdb..#patternReplace') Is Not Null
Begin
	Drop Table #patternReplace
End

select
	9 As patternID, 2 as patternType,'2 spaces' As patternName,char(32)+char(32) As pattern,char(32) As patternStart,char(32) As patternEnd,char(32) As replacement,1 As hasSetLength
Into
	#patternReplace
Union All
Select 1,2,'multi-line comment','/*%*/','/*','*/','',0
Union All
Select 2,2,'left parenthesis followed by space','(' + CHAR(32),'(',char(32),'(',1
Union All
Select 3,2,'comma followed by space',','+CHAR(32),',',CHAR(32),',',1
Union All
Select 4,2,'tab',CHAR(9),CHAR(9),'',Char(32),1
Union All
Select 6,2,'single line comment ending w line feed','--%'+CHAR(10),'--',CHAR(10),'|LFCR|',0
Union All
Select 7,2,'single line comment ending w carriage return','--%'+CHAR(13),'--',CHAR(13),'|LFCR|',0
Union All
Select 8 As patternID, 2 as patternType,'10 spaces' As patternName,char(32)+char(32)+char(32)+char(32)+char(32)+char(32)+char(32)+char(32)+char(32)+char(32),char(32),char(32),char(32),1
Union All
Select 5,2,'single line comment ending w /n & /r','--%'+char(10)+char(13),'--',char(10)+char(13),'|LFCR|',0
Union All
Select 10,2,'single line comment ending w vertical tab','--%'+CHAR(11),'--%',CHAR(11),char(32),0
Union All
Select 11,2,'single line comment ending w form feed','--%'+CHAR(12),'--%',CHAR(12),Char(32),0
Union All
Select 12,2,'single line comment ending w |LFCR|','--%|LFCR|','--%','|LFCR|',char(32),0
Union All
Select 14,2,'2 |LFCR|','|LFCR||LFCR|','|LFCR|','|LFCR|',char(32),1
Union All
Select 13,2,'|LFCR| space |LFCR|','|LFCR|' + CHAR(32) + '|LFCR|','|LFCR|','|LFCR|',char(32),1
Union All
Select 15,2,'space followed by |LFCR|',char(32)+'|LFCR|',char(32),'|LFCR|',char(32),1
Union All
Select 16,2,'space = space',char(32)+'='+char(32),char(32),char(32),'=',1
Union All
Select 17,2,'1 |LFCR|','|LFCR|','|LFCR|','',char(32),1
Union All
Select 18,2,'2 spaces again',char(32)+char(32),char(32),char(32),char(32),1
Union All
Select 19,2,'space followed by right parenthesis',CHAR(32)+')',char(32),')',')',1

declare @match varchar(5000)
declare @replacement varchar(10)
declare @PatternID int
declare @maxPatternID int
declare @PatternName varchar(50)
declare @PatternInstanceFound int
declare @LengthBefore int

Set @PatternID = 1
Select @maxPatternID = max(PatternID) From #patternReplace

-- loop through patterns
While (@PatternID <= @maxPatternID)
Begin
  select @PatternName = PatternName From #patternReplace Where PatternType >= @PatternType And PatternID = @PatternID

  if(@PatternName = '')
  Begin
	Select @PatternID = @PatternID + 1
	Continue 
  End

  print 'pattern:' + @PatternName
  Set @PatternInstanceFound = 0

  -- loop through instances of pattern found in query
  while exists(
			select
				1
			From
				(
					select 
						q.query,
						c.pattern
					From 
						(select @query As query) q,#patternReplace c
					Where
						c.patternID = @PatternID
				) t
			Where
				patindex('%'+pattern+'%',query) > 0
  )
  begin
	Select @PatternInstanceFound = @PatternInstanceFound + 1

	Select
		@match = substring(
		           query,
				   patternStartPosition,
				   patternLength
				 ),
		@replacement = replacement
	From
		(
			Select
				query,
				patternStartPosition,
				case 
					when patternEndLength > 0 then
						charindex(
						  patternEnd,
						  queryFromPatternStart,
						  case 
							When hasSetLength = 1 And patternStartLength = 1 And patternLength > 1 then 2 
							When hasSetLength = 1 And patternStartLength > 1 then (patternLength - patternEndLength) 
							When hasSetLength = 0 then patternStartLength + 1
							else patternStartLength + 1
						  end 
						) 
					when patternEndLength = 0 then 0
				end
				+ 
				case 
					when patternEndLength > 0 then 
						case
							when hasSetLength = 1 And patternLength = (patternStartLength + patternEndLength) then patternEndLength-1
							when hasSetLength = 1 And patternLength > (patternStartLength + patternEndLength) then patternEndLength-1
							when hasSetLength = 0 then patternEndLength-1 
							else patternEndLength-1
						end
					when patternEndLength = 0 then 
						case
							when hasSetLength = 1 And patternLength = 1 then 1
							when hasSetLength = 1 And patternLength > 1 then patternLength
							else patternLength-1
						end 
				end As patternLength,
				patternEnd,
				patternEndLength,
				patternName,
				replacement
			From
				(
					select
						query,
						pattern,
						patternStartPosition,
						substring(query,patternStartPosition,8000) As queryFromPatternStart,
						patternEnd,
						patternName,
						replacement,
						hasSetLength,
						dataLength(pattern) As patternLength,
						patternStartLength,
						dataLength(patternEnd) As patternEndLength
					from
						(
							select
								query,
								pattern,
								patindex('%'+pattern+'%',query) As patternStartPosition,
								dataLength(patternStart) As patternStartLength,
								patternEnd,
								patternName,
								replacement,
								hasSetLength
							From
								(
									select 
										q.query,
										c.pattern,
										c.patternStart,
										c.patternEnd,
										c.patternName,
										c.replacement,
										c.hasSetLength
									From 
										(select @query As query) q,#patternReplace c
									Where
										c.patternID = @PatternID
								) t
						) t2
					Where
						patternStartPosition > 0
				) t3
		) t4

    print '  pattern instance found:' + cast(@PatternInstanceFound as varchar) + ', |' + @match + '|, length = ' + cast(dataLength(@match) as varchar)

	Select @LengthBefore = DATALENGTH(@query)
	Select @query = replace(@query,@match,@replacement)
	if(@LengthBefore = DATALENGTH(@query))
	Begin
		print '  pattern instance not replaced :('
	End
	else
	Begin
		print '  pattern instance replaced :)'
	End
	Set @match = ''
  End
  Select @PatternID = @PatternID + 1
  Set @PatternName = ''
  Set @replacement = ''
End 

Select @query


