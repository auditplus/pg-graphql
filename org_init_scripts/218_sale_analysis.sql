create function sale_analysis_by_inventory(input_data json)
    returns table
            (
                id          int,
                name        text,
                asset_value float,
                sold        float,
                sale_value  float
            )
as
$$
declare
    branches      int[] := (select array_agg(j::int)
                            from json_array_elements_text(($1 ->> 'branches')::json) as j);
    inventories   int[] := (select array_agg(j::int)
                            from json_array_elements_text(($1 ->> 'inventories')::json) as j);
    divisions     int[] := (select array_agg(j::int)
                            from json_array_elements_text(($1 ->> 'divisions')::json) as j);
    manufacturers int[] := (select array_agg(j::int)
                            from json_array_elements_text(($1 ->> 'manufacturers')::json) as j);
    customers     int[] := (select array_agg(j::int)
                            from json_array_elements_text(($1 ->> 'customers')::json) as j);
begin
    return query
        select inventory_id,
               min(inventory_name)                    as inventory_name,
               round(sum(asset_amount)::numeric, 2)::float,
               round(sum(outward)::numeric, 4)::float as sold,
               round(sum(taxable_amount)::numeric, 2)::float
        from inv_txn
        where base_voucher_type = 'SALE'
          and (date between ($1 ->> 'from_date')::date and ($1 ->> 'to_date')::date)
          and (case when array_length(branches, 1) > 0 then branch_id = any (branches) else true end)
          and (case when array_length(divisions, 1) > 0 then division_id = any (divisions) else true end)
          and (case when array_length(inventories, 1) > 0 then inventory_id = any (inventories) else true end)
          and (case when array_length(manufacturers, 1) > 0 then manufacturer_id = any (manufacturers) else true end)
          and (case when array_length(customers, 1) > 0 then party_id = any (customers) else true end)
        group by inventory_id
        order by inventory_name, sold;

end;
$$ language plpgsql security definer
                    immutable;
--##
create function sale_analysis_by_manufacturer(
    input_data json
)
    returns table
            (
                id          int,
                name        text,
                asset_value float,
                sold        float,
                sale_value  float
            )
as
$$
declare
    branches      int[] := (select array_agg(j::int)
                            from json_array_elements_text(($1 ->> 'branches')::json) as j);
    inventories   int[] := (select array_agg(j::int)
                            from json_array_elements_text(($1 ->> 'inventories')::json) as j);
    divisions     int[] := (select array_agg(j::int)
                            from json_array_elements_text(($1 ->> 'divisions')::json) as j);
    manufacturers int[] := (select array_agg(j::int)
                            from json_array_elements_text(($1 ->> 'manufacturers')::json) as j);
    customers     int[] := (select array_agg(j::int)
                            from json_array_elements_text(($1 ->> 'customers')::json) as j);
begin
    return query
        select manufacturer_id,
               min(manufacturer_name)                 as manufacturer_name,
               round(sum(asset_amount)::numeric, 2)::float,
               round(sum(outward)::numeric, 4)::float as sold,
               round(sum(taxable_amount)::numeric, 2)::float
        from inv_txn
        where base_voucher_type = 'SALE'
          and (date between ($1 ->> 'from_date')::date and ($1 ->> 'to_date')::date)
          and (case when array_length(branches, 1) > 0 then branch_id = any (branches) else true end)
          and (case when array_length(divisions, 1) > 0 then division_id = any (divisions) else true end)
          and (case when array_length(inventories, 1) > 0 then inventory_id = any (inventories) else true end)
          and (case when array_length(manufacturers, 1) > 0 then manufacturer_id = any (manufacturers) else true end)
          and (case when array_length(customers, 1) > 0 then party_id = any (customers) else true end)
        group by manufacturer_id
        order by manufacturer_name nulls first, sold;

end;
$$ language plpgsql security definer
                    immutable;
--##
create function sale_analysis_by_division(
    input_data json
)
    returns table
            (
                id          int,
                name        text,
                asset_value float,
                sold        float,
                sale_value  float
            )
as
$$
declare
    branches      int[] := (select array_agg(j::int)
                            from json_array_elements_text(($1 ->> 'branches')::json) as j);
    inventories   int[] := (select array_agg(j::int)
                            from json_array_elements_text(($1 ->> 'inventories')::json) as j);
    divisions     int[] := (select array_agg(j::int)
                            from json_array_elements_text(($1 ->> 'divisions')::json) as j);
    manufacturers int[] := (select array_agg(j::int)
                            from json_array_elements_text(($1 ->> 'manufacturers')::json) as j);
    customers     int[] := (select array_agg(j::int)
                            from json_array_elements_text(($1 ->> 'customers')::json) as j);
begin
    return query
        select division_id,
               min(division_name)                     as division_name,
               round(sum(asset_amount)::numeric, 2)::float,
               round(sum(outward)::numeric, 4)::float as sold,
               round(sum(taxable_amount)::numeric, 2)::float
        from inv_txn
        where base_voucher_type = 'SALE'
          and (date between ($1 ->> 'from_date')::date and ($1 ->> 'to_date')::date)
          and (case when array_length(branches, 1) > 0 then branch_id = any (branches) else true end)
          and (case when array_length(divisions, 1) > 0 then division_id = any (divisions) else true end)
          and (case when array_length(inventories, 1) > 0 then inventory_id = any (inventories) else true end)
          and (case when array_length(manufacturers, 1) > 0 then manufacturer_id = any (manufacturers) else true end)
          and (case when array_length(customers, 1) > 0 then party_id = any (customers) else true end)
        group by division_id
        order by division_name, sold;

end;
$$ language plpgsql security definer
                    immutable;
--##
create function sale_analysis_by_branch(input_data json)
    returns table
            (
                id          int,
                name        text,
                asset_value float,
                sold        float,
                sale_value  float
            )
as
$$
declare
    branches      int[] := (select array_agg(j::int)
                            from json_array_elements_text(($1 ->> 'branches')::json) as j);
    inventories   int[] := (select array_agg(j::int)
                            from json_array_elements_text(($1 ->> 'inventories')::json) as j);
    divisions     int[] := (select array_agg(j::int)
                            from json_array_elements_text(($1 ->> 'divisions')::json) as j);
    manufacturers int[] := (select array_agg(j::int)
                            from json_array_elements_text(($1 ->> 'manufacturers')::json) as j);
    customers     int[] := (select array_agg(j::int)
                            from json_array_elements_text(($1 ->> 'customers')::json) as j);
begin
    return query
        select branch_id,
               min(branch_name)                       as branch_name,
               round(sum(asset_amount)::numeric, 2)::float,
               round(sum(outward)::numeric, 4)::float as sold,
               round(sum(taxable_amount)::numeric, 2)::float
        from inv_txn
        where base_voucher_type = 'SALE'
          and (date between ($1 ->> 'from_date')::date and ($1 ->> 'to_date')::date)
          and (case when array_length(branches, 1) > 0 then branch_id = any (branches) else true end)
          and (case when array_length(divisions, 1) > 0 then division_id = any (divisions) else true end)
          and (case when array_length(inventories, 1) > 0 then inventory_id = any (inventories) else true end)
          and (case when array_length(manufacturers, 1) > 0 then manufacturer_id = any (manufacturers) else true end)
          and (case when array_length(customers, 1) > 0 then party_id = any (customers) else true end)
        group by branch_id
        order by branch_name, sold;
end;
$$ language plpgsql security definer
                    immutable;
--##
create function sale_analysis_by_customer(input_data json)
    returns table
            (
                id          int,
                name        text,
                asset_value float,
                sold        float,
                sale_value  float
            )
as
$$
declare
    branches      int[] := (select array_agg(j::int)
                            from json_array_elements_text(($1 ->> 'branches')::json) as j);
    inventories   int[] := (select array_agg(j::int)
                            from json_array_elements_text(($1 ->> 'inventories')::json) as j);
    divisions     int[] := (select array_agg(j::int)
                            from json_array_elements_text(($1 ->> 'divisions')::json) as j);
    manufacturers int[] := (select array_agg(j::int)
                            from json_array_elements_text(($1 ->> 'manufacturers')::json) as j);
    customers     int[] := (select array_agg(j::int)
                            from json_array_elements_text(($1 ->> 'customers')::json) as j);
begin
    return query
        select party_id,
               min(party_name)                        as party_name,
               round(sum(asset_amount)::numeric, 2)::float,
               round(sum(outward)::numeric, 4)::float as sold,
               round(sum(taxable_amount)::numeric, 2)::float
        from inv_txn
        where base_voucher_type = 'SALE'
          and (date between ($1 ->> 'from_date')::date and ($1 ->> 'to_date')::date)
          and (case when array_length(branches, 1) > 0 then branch_id = any (branches) else true end)
          and (case when array_length(divisions, 1) > 0 then division_id = any (divisions) else true end)
          and (case when array_length(inventories, 1) > 0 then inventory_id = any (inventories) else true end)
          and (case when array_length(manufacturers, 1) > 0 then manufacturer_id = any (manufacturers) else true end)
          and (case when array_length(customers, 1) > 0 then party_id = any (customers) else true end)
        group by party_id
        order by party_name nulls first, sold;
end;
$$ language plpgsql security definer
                    immutable;