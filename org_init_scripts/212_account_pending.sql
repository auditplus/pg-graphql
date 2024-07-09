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
--select * from account_pending_breakup('{"as_on_date": "2024-07-06","account":101,"branches":[],"pending":"6d65b020-ac2e-106d-a9f0-67624b41714c"}'::json);
create function account_pending_breakup(input json)
    returns table
            (
                voucher_id        int,
                voucher_no        text,
                voucher_mode      text,
                ref_type          text,
                base_voucher_type text,
                ref_no            text,
                amount            float,
                branch_id         int
            )
as
$$
declare
    as_on_date date  := (input ->> 'as_on_date')::date;
    acc_id     int   := (input ->> 'account')::int;
    pend_id    uuid  := (input ->> 'pending')::uuid;
    br_ids     int[] := (select array_agg(j::text)
                         from json_array_elements((input ->> 'branches')::json) as j);
begin
    return query
        select ba.voucher_id,
               ba.voucher_no,
               ba.voucher_mode,
               ba.ref_type,
               ba.base_voucher_type,
               ba.ref_no,
               ba.amount,
               ba.branch_id
        from bill_allocation as ba
        where ba.account_id = acc_id
          and ba.date <= as_on_date
          and (case when coalesce(array_length(br_ids, 1), 0) > 0 then ba.branch_id = any (br_ids) else true end)
          and (case when pend_id is not null then ba.pending = pend_id else true end);
end;
$$ immutable language plpgsql security definer;
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

