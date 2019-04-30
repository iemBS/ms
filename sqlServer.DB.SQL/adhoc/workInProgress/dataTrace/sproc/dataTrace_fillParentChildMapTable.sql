

-- create if not exist
create table ##parentChildMap
(
	child varchar(100),
	parent varchar(100),
	childType varchar(25),
	parentType varchar(25)
)

/*


    childType & parentType column values
    ------------------------------------
    table, sproc, UDF, package.task, package.task.src, package.task.destination

    child & parent column formats
    -------------------------------
    if table then [db].[schema].[object]
*/