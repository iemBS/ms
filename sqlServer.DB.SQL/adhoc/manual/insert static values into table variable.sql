Declare @xyz table(
abc varchar(10),
pqr varchar(10)
)

insert into @xyz(abc, pqr)
select abc, pqr
from (VALUES
    ('a1', 'p1'),
    ('a2', 'p2'),
    ('a3', 'p3')
)t(abc, pqr)

select * from @xyz

