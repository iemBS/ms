Drop Temp Table
Main Success Scenario:
  1. 
	If OBJECT_ID('tempdb..#who3') Is Not Null
	Begin
		Drop Table #who3
	End
Alternatives:
  1a. Make script smaller
    1a1. DROP TABLE IF EXISTS tempdb..#who3
  1b. Use EXISTS and SELECT 
    1b1. 
	IF EXISTS(SELECT OBJECT_ID('tempdb..#someTable')) 
	BEGIN 
		print 'second version'
	END
