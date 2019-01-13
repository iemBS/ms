
create table #daisyChain
(
	ID int identity(1,1),
	child varchar(2),
	parent varchar(2)
)

insert into
	#daisyChain
Select
	'a','b'
union
select 'b','c'
union
select 'c','d'
union
select 'd','e'

declare @daisyChain varchar(300)
declare @parent varchar(1)
declare @child varchar(1)
set @child = 'a'
set @daisyChain = @child 

while exists(Select parent From #daisyChain Where child = @child)
begin
	Select
		@parent = parent	
	From
		#daisyChain 
	Where
		child = @child

	set @daisyChain = @daisyChain + ' < ' + isnull(@parent,'')
	set @child = @parent 
end

select @daisyChain


