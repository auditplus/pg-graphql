create view provisional_profit
as
select id, date, branch_id, branch_name,
       vendor_id, first_value(vendor_name) over (partition by vendor_id order by id desc) as vendor_name,
       ref_no, voucher_id, voucher_no,
       coalesce(amount,0) as amount,
       coalesce(profit_percentage,0) as profit_percentage,
       coalesce(sale_value,0) as sale_value,
       coalesce(profit_value,0) as profit_value,
       coalesce(nlc_value,0) as nlc_value
from purchase_bill;
--##
comment on view pending_approval_voucher is e'@graphql({"primary_key_columns": ["id"]})';
--##
--select * from provisional_profit_summary('{"from_date": "2024-05-01","to_date": "2024-07-01","branches":[],"vendors":[]}');
create function provisional_profit_summary(input json)
    returns table
            (
                amount            float,
                profit_percentage float,
                sale_value        float,
                profit_value      float,
                nlc_value         float
            )
AS
$$
declare
    from_date date     := (input ->> 'from_date')::date;
    to_date   date     := (input ->> 'to_date')::date;
    br_ids    bigint[] := (select array_agg(j::text::bigint)
                           from json_array_elements((input ->> 'branches')::json) as j);
    vend_ids  bigint[] := (select array_agg(j::text::bigint)
                           from json_array_elements((input ->> 'vendors')::json) as j);
begin
    return query
        select coalesce(round(sum(p.amount)::numeric,2)::float, 0),
               coalesce(round(avg(p.profit_percentage)::numeric,2)::float, 0),
               coalesce(round(sum(p.sale_value)::numeric,2)::float, 0),
               coalesce(round(sum(p.profit_value)::numeric,2)::float, 0),
               coalesce(round(sum(p.nlc_value)::numeric,2)::float, 0)
        from provisional_profit as p
        where (p.date between from_date and to_date)
          and (case when coalesce(array_length(br_ids, 1), 0) > 0 then p.branch_id = any (br_ids) else true end)
          and (case
                   when coalesce(array_length(vend_ids, 1), 0) > 0 then p.vendor_id = any (vend_ids)
                   else true end);

end
$$ immutable language plpgsql security definer;
--##
-- select * from provisional_profit_by_group('{"from_date": "2024-05-01","to_date": "2024-07-01","branches":[],"vendors":[], "group_by": "branch"}'::json);
create function provisional_profit_by_group(input json)
    returns table
            (
                id                int,
                name              text,
                profit_percentage float,
                sale_value        float,
                profit_value      float,
                nlc_value         float
            )
AS
$$
declare
    from_date date     := ($1 ->> 'from_date')::date;
    to_date   date     := ($1 ->> 'to_date')::date;
    br_ids    bigint[] := (select array_agg(j::text::bigint)
                           from json_array_elements(($1 ->> 'branches')::json) as j);
    vend_ids  bigint[] := (select array_agg(j::text::bigint)
                           from json_array_elements(($1 ->> 'vendors')::json) as j);
    group_by  text  := coalesce(upper(($1 ->> 'group_by')::text), 'BRANCH');
begin
    if group_by not in ('BRANCH', 'VENDOR') then
        raise exception 'group_by must be BRANCH / VENDOR';
    end if;
    return query
        select (case
                    when group_by = 'BRANCH' then p.branch_id
                    when group_by = 'VENDOR' then p.vendor_id end) as group_id,
               min(case
                   when group_by = 'BRANCH' then p.branch_name
                   when group_by = 'VENDOR' then p.vendor_name
               end) as group_name,
               coalesce(round(avg(p.profit_percentage)::numeric,2)::float, 0),
               coalesce(round(sum(p.sale_value)::numeric,2)::float, 0),
               coalesce(round(sum(p.profit_value)::numeric,2)::float, 0),
               coalesce(round(sum(p.nlc_value)::numeric,2)::float, 0)
        from provisional_profit as p
        where (p.date between from_date and to_date)
          and (case when coalesce(array_length(br_ids, 1), 0) > 0 then p.branch_id = any (br_ids) else true end)
          and (case
                   when coalesce(array_length(vend_ids, 1), 0) > 0 then p.vendor_id = any (vend_ids)
                   else true end)
        group by group_id
        order by group_name nulls first, group_id;

end
$$ immutable language plpgsql security definer;
--##