-- select * from sale_summary_by_inventory(
-- from_date := '2024-05-01'::date, to_date := '2024-06-01'::date,
-- br_ids := ARRAY [1]::integer[],
-- div_ids := ARRAY []::integer[],
-- inv_ids := ARRAY []::integer[],
-- man_ids := ARRAY []::integer[]
-- );
create function sale_summary_by_inventory(
    from_date date,
    to_date date,
    br_ids int[] default '{}'::int[],
    div_ids int[] default '{}'::int[],
    inv_ids int[] default '{}'::int[],
    man_ids int[] default '{}'::int[]
)
returns table
(
    id             int,
    name           text,
    asset_value    float,
    sold           float,
    sale_value     float
)
AS
$$
begin
    return query
    select
        inventory,
        min(inventory_name) as inventory_name,
        round(sum(asset_amount)::numeric, 2)::float as asset_value,
        round(sum("outward")::numeric, 4)::float as sold,
        round(sum("taxable_amount")::numeric, 2)::float as sale_value
    from inv_txn
    where base_voucher_type='SALE'
    and (date between from_date and to_date)
    and (case when array_length(br_ids, 1) > 0 then branch = any (br_ids) else true end)
    and (case when array_length(div_ids, 1) > 0 then division = any (div_ids) else true end)
    and (case when array_length(inv_ids, 1) > 0 then inventory = any (inv_ids) else true end)
    and (case when array_length(man_ids, 1) > 0 then manufacturer = any (man_ids) else true end)
    group by inventory
    order by inventory, sold;

end;
$$ language plpgsql;
--##
-- select * from sale_summary_by_manufacturer(
-- from_date := '2024-05-01'::date, to_date := '2024-06-01'::date,
-- br_ids := ARRAY [1]::integer[],
-- div_ids := ARRAY []::integer[],
-- inv_ids := ARRAY []::integer[],
-- man_ids := ARRAY []::integer[]
-- );
create function sale_summary_by_manufacturer(
    from_date date,
    to_date date,
    br_ids int[] default '{}'::int[],
    div_ids int[] default '{}'::int[],
    inv_ids int[] default '{}'::int[],
    man_ids int[] default '{}'::int[]
)
returns table
(
    id             int,
    name           text,
    asset_value    float,
    sold           float,
    sale_value     float
)
AS
$$
begin
    return query
    select
        manufacturer,
        min(manufacturer_name) as manufacturer_name,
        round(sum(asset_amount)::numeric, 2)::float as asset_value,
        round(sum("outward")::numeric, 4)::float as sold,
        round(sum("taxable_amount")::numeric, 2)::float as sale_value
    from inv_txn
    where base_voucher_type='SALE'
    and (date between from_date and to_date)
    and (case when array_length(br_ids, 1) > 0 then branch = any (br_ids) else true end)
    and (case when array_length(div_ids, 1) > 0 then division = any (div_ids) else true end)
    and (case when array_length(inv_ids, 1) > 0 then inventory = any (inv_ids) else true end)
    and (case when array_length(man_ids, 1) > 0 then manufacturer = any (man_ids) else true end)
    group by manufacturer
    order by manufacturer, sold;

end;
$$ language plpgsql;
--##
-- select * from sale_summary_by_division(
-- from_date := '2024-05-01'::date, to_date := '2024-06-01'::date,
-- br_ids := ARRAY [1]::integer[],
-- div_ids := ARRAY []::integer[],
-- inv_ids := ARRAY []::integer[],
-- man_ids := ARRAY []::integer[]
-- );
create function sale_summary_by_division(
    from_date date,
    to_date date,
    br_ids int[] default '{}'::int[],
    div_ids int[] default '{}'::int[],
    inv_ids int[] default '{}'::int[],
    man_ids int[] default '{}'::int[]
)
returns table
(
    id             int,
    name           text,
    asset_value    float,
    sold           float,
    sale_value     float
)
AS
$$
begin
    return query
    select
        division,
        min(division_name) as division_name,
        round(sum(asset_amount)::numeric, 2)::float as asset_value,
        round(sum("outward")::numeric, 4)::float as sold,
        round(sum("taxable_amount")::numeric, 2)::float as sale_value
    from inv_txn
    where base_voucher_type='SALE'
    and (date between from_date and to_date)
    and (case when array_length(br_ids, 1) > 0 then branch = any (br_ids) else true end)
    and (case when array_length(div_ids, 1) > 0 then division = any (div_ids) else true end)
    and (case when array_length(inv_ids, 1) > 0 then inventory = any (inv_ids) else true end)
    and (case when array_length(man_ids, 1) > 0 then manufacturer = any (man_ids) else true end)
    group by division
    order by division, sold;

end;
$$ language plpgsql;
--##
-- select * from sale_summary_by_branch(
-- from_date := '2024-05-01'::date, to_date := '2024-06-01'::date,
-- br_ids := ARRAY [1]::integer[],
-- div_ids := ARRAY []::integer[],
-- inv_ids := ARRAY []::integer[],
-- man_ids := ARRAY []::integer[]
-- );
create function sale_summary_by_branch(
    from_date date,
    to_date date,
    br_ids int[] default '{}'::int[],
    div_ids int[] default '{}'::int[],
    inv_ids int[] default '{}'::int[],
    man_ids int[] default '{}'::int[]
)
returns table
(
    id             int,
    name           text,
    asset_value    float,
    sold           float,
    sale_value     float
)
AS
$$
begin
    return query
    select
        branch,
        min(branch_name) as branch_name,
        round(sum(asset_amount)::numeric, 2)::float as asset_value,
        round(sum("outward")::numeric, 4)::float as sold,
        round(sum("taxable_amount")::numeric, 2)::float as sale_value
    from inv_txn
    where base_voucher_type='SALE'
    and (date between from_date and to_date)
    and (case when array_length(br_ids, 1) > 0 then branch = any (br_ids) else true end)
    and (case when array_length(div_ids, 1) > 0 then division = any (div_ids) else true end)
    and (case when array_length(inv_ids, 1) > 0 then inventory = any (inv_ids) else true end)
    and (case when array_length(man_ids, 1) > 0 then manufacturer = any (man_ids) else true end)
    group by branch
    order by branch, sold;

end;
$$ language plpgsql;
