create view inventory_book
as
select id,
       inventory_id,
       date,
       party_name as particular,
       ref_no,
       voucher_type_id,
       base_voucher_type,
       inventory_voucher_id,
       voucher_id,
       voucher_no,
       branch_id,
       branch_name,
       inward,
       outward
from inv_txn
where not is_opening;
--##
comment on view inventory_book is e'@graphql({"primary_key_columns": ["id"]})';
--##
create function inventory_book_group(input_data json)
    returns table
            (
                particulars date,
                inward      float,
                outward     float
            )
as
$$
declare
    branches int[] := (select array_agg(j::int)
                       from json_array_elements_text(($1 ->> 'branches')::json) as j);
begin
    if upper(($1 ->> 'group_by')::text) not in ('MONTH', 'DAY') then
        raise exception 'invalid group_by value';
    end if;
    return query
        select (date_trunc(($1 ->> 'group_by')::text, a.date)::date) as particulars,
               coalesce(round((sum(a.inward)::numeric), 4)::float, 0),
               coalesce(round((sum(a.outward)::numeric), 4)::float, 0)
        from inv_txn a
        where a.inventory_id = ($1 ->> 'inventory_id')::int
          and (a.date between ($1 ->> 'from_date')::date and ($1 ->> 'to_date')::date)
          and (case when array_length(branches, 1) > 0 then a.branch_id = any (branches) else true end)
        group by particulars
        order by particulars;
end;
$$ language plpgsql immutable
                    security definer;
--##
create function inventory_book_summary(input_data json)
    returns table
            (
                opening float,
                closing float,
                inward  float,
                outward float
            )
as
$$
declare
    branches int[] := (select array_agg(j::int)
                       from json_array_elements_text(($1 ->> 'branches')::json) as j);
begin
    return query
        with b as (select sum(a.inward - a.outward) filter (where a.date < ($1 ->> 'from_date')::date)          as opening,
                          sum(a.inward - a.outward)                                                             as closing,
                          sum(a.inward)
                          filter (where a.date between ($1 ->> 'from_date')::date and ($1 ->> 'to_date')::date) as inward,
                          sum(a.outward)
                          filter (where a.date between ($1 ->> 'from_date')::date and ($1 ->> 'to_date')::date) as outward
                   from inv_txn a
                   where a.inventory_id = ($1 ->> 'inventory_id')::int
                     and a.date <= ($1 ->> 'to_date')::date
                     and case when array_length(branches, 1) > 0 then a.branch_id = any (branches) else true end)
        select coalesce(round(b.opening::numeric, 4), 0)::float,
               coalesce(round(b.closing::numeric, 4), 0)::float,
               coalesce(round(b.inward::numeric, 4), 0)::float,
               coalesce(round(b.outward::numeric, 4), 0)::float
        from b;
end;
$$ language plpgsql immutable
                    security definer;