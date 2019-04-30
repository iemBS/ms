


use tempdb;
go

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

create PROC [dbo].[dataTrace_getCharacterPermutationsAroundTableName] 
AS
BEGIN


/*
purpose: Provides the permutations of characters that can occur on the left and right of a table, view, and UDF (returns table) name within a query. 
         These characters help to search queries for tables, views, and UDFs. 
parameter: none 
return: Table with permutations of characters that can occur on the left and right of a table, view, and UDF (returns table) name within a query.
*/

-- clean up
IF OBJECT_ID('tempdb..##CharBorderOnTablePermutation') IS NOT NULL
    DROP TABLE ##CharBorderOnTablePermutation

-- note the possible characters that can be on either side
select	
	CHAR(32) as [char] -- space
into
	#char
union
select CHAR(10) -- line feed
union
select CHAR(13) -- carriage return
union
select CHAR(9) -- tab

-- note the possible characters that can be on the left side
Select
	[char]
into
	#left
From
	#char

-- note the possible characters that can be on the right side
Select
	[char]
into
	#right
From
	#char
union
select CHAR(41) -- right parenthesis

-- get all permutations of left and right characters
Select
	l.[char] as leftChar,
	r.[char] as rightChar
into
	##CharBorderOnTablePermutation
From
	#left l
	Cross Join #right r

-- clean up
IF OBJECT_ID('tempdb..#char') IS NOT NULL
    DROP TABLE #char

IF OBJECT_ID('tempdb..#left') IS NOT NULL
    DROP TABLE #left

IF OBJECT_ID('tempdb..#right') IS NOT NULL
    DROP TABLE #right

Select
	*
From
	##CharBorderOnTablePermutation

END
GO

