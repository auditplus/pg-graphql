create view account_pending as
(
with s1 as (select *
            from bill_allocation
            where ref_type = 'NEW'),
     s2 as (select sum(amount) as closing, pending
            from bill_allocation
            where ref_type <> 'ON_ACC'
            group by pending)
select s1.*, s2.closing, ac.due_based_on, ac.due_days
from s1
         join s2 on s1.pending = s2.pending
         join account ac on s1.account_id = ac.id
    );
--##
comment on view account_pending is e'@graphql({"primary_key_columns": ["id"]})';