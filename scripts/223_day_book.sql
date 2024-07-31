-- select * from daybook('{"from_date": "2024-07-01", "to_date": "2024-08-01", "view_type":"INVENTORY", "branches":[1]}'::json);
-- create or replace function daybook(input json)
--     returns table
--             (
--                 voucher_id        int,
--                 voucher_no        text,
--                 voucher_mode      text,
--                 ref_type          text,
--                 base_voucher_type text,
--                 ref_no            text,
--                 amount            float,
--                 branch_id         int
--             )
-- as
-- $$
-- declare
--     from_date date  := (input ->> 'from_date')::date;
--     to_date date  := (input ->> 'to_date')::date;
--     view_type text := coalesce(upper(($1 ->> 'view_type')::text), 'ACCOUNT');
--     br_ids     int[] := (select array_agg(j::text)
--                          from json_array_elements((input ->> 'branches')::json) as j);
--     base_vtypes int[] := (select array_agg(j::text)
--                          from json_array_elements((input ->> 'base_voucher_types')::json) as j);
-- begin
--     if view_type not in ('ACCOUNT', 'INVENTORY') then
--         raise exception 'view_type must be ACCOUNT / INVENTORY';
--     end if;

--     if view_type='INVENTORY' then
--         return query
--         select voucher_id,
--                min(outward) as credit,
--                min(inward) as debit,
--                min(inventory_name) as particular,
--                min(base_voucher_type) as base_voucher_type
--         from (
--             select voucher_id, base_voucher_type,
--                    first_value(outward) over (partition by voucher_id) as outward,
--                    first_value(inward) over (partition by voucher_id) as inward,
--                    first_value(inventory_name) over (partition by voucher_id) as inventory_name
--             from inv_txn
--             where date between from_date and to_date
--             and (case when coalesce(array_length(br_ids, 1), 0) > 0 then branch_id = any (br_ids) else true end)
--             ) x
--         group by voucher_id;
--     end if;
--     if view_type='ACCOUNT' then
--         return query
--         select voucher_id,
--                min(credit) as credit,
--                min(debit) as debit,
--                min(account_name) as particular,
--                min(base_voucher_type) as base_voucher_type
--         from (
--             select voucher_id, base_voucher_type,
--                    first_value(credit) over (partition by voucher_id) as credit,
--                    first_value(debit) over (partition by voucher_id) as debit,
--                    first_value(account_name) over (partition by voucher_id) as account_name
--             from ac_txn
--             where date between from_date and to_date
--             and (case when coalesce(array_length(br_ids, 1), 0) > 0 then branch_id = any (br_ids) else true end)
--             ) x
--         group by voucher_id;
--     end if;
-- end;
-- $$ immutable language plpgsql security definer;

create function day_summary(input_data json)
    returns table
            (
                base_voucher_type text,
                voucher_count     int,
                amount            float
            )
as
$$
declare
    branches int[] := (select array_agg(j::int)
                       from json_array_elements_text(($1 ->> 'branches')::json) as j);
begin
    return query
        select a.base_voucher_type, count(1)::int, round(sum(coalesce(a.amount, 0))::numeric, 2)::float
        from voucher a
        where a.date = ($1 ->> 'date')::date
          and case when array_length(branches, 1) > 0 then a.branch_id = any (branches) else true end
        group by a.base_voucher_type
        order by a.base_voucher_type;
end;
$$ language plpgsql security definer;