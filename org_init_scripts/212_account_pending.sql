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
--##
create function on_account_balance(input_data json)
    returns float as
$$
declare
    branches bigint[] := (select array_agg(j::bigint)
                          from json_array_elements_text(($1 ->> 'branches')::json) as j);
begin
    return (select coalesce(round(sum(amount)::numeric, 2)::float, 0)
            from bill_allocation
            where ref_type = 'ON_ACC'
              and date <= ($1 ->> 'as_on_date')::date
              and not is_memo
              and account_id = ($1 ->> 'account_id')::bigint
              and case when array_length(branches, 1) > 0 then branch_id = any (branches) else true end);
end;
$$ language plpgsql security definer
                    immutable;