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
                id          int,
                name        text,
                asset_value float,
                sold        float,
                sale_value  float
            )
AS
$$
begin
    return query
        select inventory_id,
               min(inventory_name)                             as inventory_name,
               round(sum(asset_amount)::numeric, 2)::float     as asset_value,
               round(sum("outward")::numeric, 4)::float        as sold,
               round(sum("taxable_amount")::numeric, 2)::float as sale_value
        from inv_txn
        where base_voucher_type = 'SALE'
          and (date between from_date and to_date)
          and (case when array_length(br_ids, 1) > 0 then branch_id = any (br_ids) else true end)
          and (case when array_length(div_ids, 1) > 0 then division_id = any (div_ids) else true end)
          and (case when array_length(inv_ids, 1) > 0 then inventory_id = any (inv_ids) else true end)
          and (case when array_length(man_ids, 1) > 0 then manufacturer_id = any (man_ids) else true end)
        group by inventory_id
        order by inventory_id, sold;

end;
$$ language plpgsql;
--##
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
                id          int,
                name        text,
                asset_value float,
                sold        float,
                sale_value  float
            )
AS
$$
begin
    return query
        select manufacturer_id,
               min(manufacturer_name)                          as manufacturer_name,
               round(sum(asset_amount)::numeric, 2)::float     as asset_value,
               round(sum("outward")::numeric, 4)::float        as sold,
               round(sum("taxable_amount")::numeric, 2)::float as sale_value
        from inv_txn
        where base_voucher_type = 'SALE'
          and (date between from_date and to_date)
          and (case when array_length(br_ids, 1) > 0 then branch_id = any (br_ids) else true end)
          and (case when array_length(div_ids, 1) > 0 then division_id = any (div_ids) else true end)
          and (case when array_length(inv_ids, 1) > 0 then inventory_id = any (inv_ids) else true end)
          and (case when array_length(man_ids, 1) > 0 then manufacturer_id = any (man_ids) else true end)
        group by manufacturer_id
        order by manufacturer_id, sold;

end;
$$ language plpgsql;
--##
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
                id          int,
                name        text,
                asset_value float,
                sold        float,
                sale_value  float
            )
AS
$$
begin
    return query
        select division_id,
               min(division_name)                              as division_name,
               round(sum(asset_amount)::numeric, 2)::float     as asset_value,
               round(sum("outward")::numeric, 4)::float        as sold,
               round(sum("taxable_amount")::numeric, 2)::float as sale_value
        from inv_txn
        where base_voucher_type = 'SALE'
          and (date between from_date and to_date)
          and (case when array_length(br_ids, 1) > 0 then branch_id = any (br_ids) else true end)
          and (case when array_length(div_ids, 1) > 0 then division_id = any (div_ids) else true end)
          and (case when array_length(inv_ids, 1) > 0 then inventory_id = any (inv_ids) else true end)
          and (case when array_length(man_ids, 1) > 0 then manufacturer_id = any (man_ids) else true end)
        group by division_id
        order by division_id, sold;

end;
$$ language plpgsql;
--##
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
                id          int,
                name        text,
                asset_value float,
                sold        float,
                sale_value  float
            )
AS
$$
begin
    return query
        select branch_id,
               min(branch_name)                                as branch_name,
               round(sum(asset_amount)::numeric, 2)::float     as asset_value,
               round(sum("outward")::numeric, 4)::float        as sold,
               round(sum("taxable_amount")::numeric, 2)::float as sale_value
        from inv_txn
        where base_voucher_type = 'SALE'
          and (date between from_date and to_date)
          and (case when array_length(br_ids, 1) > 0 then branch_id = any (br_ids) else true end)
          and (case when array_length(div_ids, 1) > 0 then division_id = any (div_ids) else true end)
          and (case when array_length(inv_ids, 1) > 0 then inventory_id = any (inv_ids) else true end)
          and (case when array_length(man_ids, 1) > 0 then manufacturer_id = any (man_ids) else true end)
        group by branch_id
        order by branch_id, sold;

end;
$$ language plpgsql;
