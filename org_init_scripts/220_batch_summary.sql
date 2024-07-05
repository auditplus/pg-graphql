create function non_movement_analysis_summary(input_date json)
    returns table
            (
                value   float,
                closing float
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
    vendors       int[] := (select array_agg(j::int)
                               from json_array_elements_text(($1 ->> 'vendors')::json) as j);
begin
    return query
        select coalesce(round(sum(b.closing * b.nlc)::numeric, 4)::float, 0)::float,
               coalesce(round(sum(b.closing)::numeric, 4)::float, 0)::float
        from batch b
        where b.closing > 0
          and b.entry_date < coalesce(($1 ->> 'entry_date')::date, current_date)
          and case when array_length(branches, 1) > 0 then b.branch_id = any (branches) else true end
          and case when array_length(divisions, 1) > 0 then b.division_id = any (divisions) else true end
          and case when array_length(inventories, 1) > 0 then b.inventory_id = any (inventories) else true end
          and case when array_length(manufacturers, 1) > 0 then b.manufacturer_id = any (manufacturers) else true end
          and case when array_length(vendors, 1) > 0 then b.vendor_id = any (vendors) else true end
          and case
                  when $1 ->> 'category1_id' is null then true
                  else b.category1_id = ($1 ->> 'category1_id')::int end
          and case
                  when $1 ->> 'category2_id' is null then true
                  else b.category2_id = ($1 ->> 'category2_id')::int end
          and case
                  when $1 ->> 'category3_id' is null then true
                  else b.category3_id = ($1 ->> 'category3_id')::int end
          and case
                  when $1 ->> 'category4_id' is null then true
                  else b.category4_id = ($1 ->> 'category4_id')::int end
          and case
                  when $1 ->> 'category5_id' is null then true
                  else b.category5_id = ($1 ->> 'category5_id')::int end
          and case
                  when $1 ->> 'category6_id' is null then true
                  else b.category6_id = ($1 ->> 'category6_id')::int end
          and case
                  when $1 ->> 'category7_id' is null then true
                  else b.category7_id = ($1 ->> 'category7_id')::int end
          and case
                  when $1 ->> 'category8_id' is null then true
                  else b.category8_id = ($1 ->> 'category8_id')::int end
          and case
                  when $1 ->> 'category9_id' is null then true
                  else b.category9_id = ($1 ->> 'category9_id')::int end
          and case
                  when $1 ->> 'category10_id' is null then true
                  else b.category10_id = ($1 ->> 'category10_id')::int end;
end;
$$ language plpgsql security definer
                    immutable;
--##
create function negative_stock_analysis_summary(input_date json)
    returns table
            (
                value   float,
                closing float
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
    vendors       int[] := (select array_agg(j::int)
                               from json_array_elements_text(($1 ->> 'vendors')::json) as j);
begin
    return query
        select coalesce(round(sum(b.closing * b.nlc)::numeric, 4)::float, 0)::float,
               coalesce(round(sum(b.closing)::numeric, 4)::float, 0)::float
        from batch b
        where b.closing < 0
          and case when array_length(branches, 1) > 0 then b.branch_id = any (branches) else true end
          and case when array_length(divisions, 1) > 0 then b.division_id = any (divisions) else true end
          and case when array_length(inventories, 1) > 0 then b.inventory_id = any (inventories) else true end
          and case when array_length(manufacturers, 1) > 0 then b.manufacturer_id = any (manufacturers) else true end
          and case when array_length(vendors, 1) > 0 then b.vendor_id = any (vendors) else true end
          and case
                  when $1 ->> 'category1_id' is null then true
                  else b.category1_id = ($1 ->> 'category1_id')::int end
          and case
                  when $1 ->> 'category2_id' is null then true
                  else b.category2_id = ($1 ->> 'category2_id')::int end
          and case
                  when $1 ->> 'category3_id' is null then true
                  else b.category3_id = ($1 ->> 'category3_id')::int end
          and case
                  when $1 ->> 'category4_id' is null then true
                  else b.category4_id = ($1 ->> 'category4_id')::int end
          and case
                  when $1 ->> 'category5_id' is null then true
                  else b.category5_id = ($1 ->> 'category5_id')::int end
          and case
                  when $1 ->> 'category6_id' is null then true
                  else b.category6_id = ($1 ->> 'category6_id')::int end
          and case
                  when $1 ->> 'category7_id' is null then true
                  else b.category7_id = ($1 ->> 'category7_id')::int end
          and case
                  when $1 ->> 'category8_id' is null then true
                  else b.category8_id = ($1 ->> 'category8_id')::int end
          and case
                  when $1 ->> 'category9_id' is null then true
                  else b.category9_id = ($1 ->> 'category9_id')::int end
          and case
                  when $1 ->> 'category10_id' is null then true
                  else b.category10_id = ($1 ->> 'category10_id')::int end;
end;
$$ language plpgsql security definer
                    immutable;
--##
create function expiry_stock_analysis_summary(input_date json)
    returns table
            (
                value   float,
                closing float
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
    vendors       int[] := (select array_agg(j::int)
                               from json_array_elements_text(($1 ->> 'vendors')::json) as j);
begin
    return query
        select coalesce(round(sum(b.closing * b.nlc)::numeric, 4)::float, 0)::float,
               coalesce(round(sum(b.closing)::numeric, 4)::float, 0)::float
        from batch b
        where b.closing > 0
          and b.expiry <= ($1 ->> 'to_date')::date
          and case when $1 ->> 'from_date' is not null then b.expiry >= ($1 ->> 'from_date')::date else true end
          and case when array_length(branches, 1) > 0 then b.branch_id = any (branches) else true end
          and case when array_length(divisions, 1) > 0 then b.division_id = any (divisions) else true end
          and case when array_length(inventories, 1) > 0 then b.inventory_id = any (inventories) else true end
          and case when array_length(manufacturers, 1) > 0 then b.manufacturer_id = any (manufacturers) else true end
          and case when array_length(vendors, 1) > 0 then b.vendor_id = any (vendors) else true end
          and case
                  when $1 ->> 'category1_id' is null then true
                  else b.category1_id = ($1 ->> 'category1_id')::int end
          and case
                  when $1 ->> 'category2_id' is null then true
                  else b.category2_id = ($1 ->> 'category2_id')::int end
          and case
                  when $1 ->> 'category3_id' is null then true
                  else b.category3_id = ($1 ->> 'category3_id')::int end
          and case
                  when $1 ->> 'category4_id' is null then true
                  else b.category4_id = ($1 ->> 'category4_id')::int end
          and case
                  when $1 ->> 'category5_id' is null then true
                  else b.category5_id = ($1 ->> 'category5_id')::int end
          and case
                  when $1 ->> 'category6_id' is null then true
                  else b.category6_id = ($1 ->> 'category6_id')::int end
          and case
                  when $1 ->> 'category7_id' is null then true
                  else b.category7_id = ($1 ->> 'category7_id')::int end
          and case
                  when $1 ->> 'category8_id' is null then true
                  else b.category8_id = ($1 ->> 'category8_id')::int end
          and case
                  when $1 ->> 'category9_id' is null then true
                  else b.category9_id = ($1 ->> 'category9_id')::int end
          and case
                  when $1 ->> 'category10_id' is null then true
                  else b.category10_id = ($1 ->> 'category10_id')::int end;
end;
$$ language plpgsql security definer
                    immutable;                    