create function stock_analysis_by_inventory(input_data json)
    returns table
            (
                id            int,
                name          text,
                cost_value    float,
                nlc_value     float,
                landing_value float,
                closing       float
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
        with s1 as (select min(b.inventory_id)                             as s1id,
                           min(b.inventory_name)                           as s1name,
                           coalesce(min(b.p_rate), 0)                      as s1p_rate,
                           coalesce(min(b.nlc), 0)                         as s1nlc,
                           coalesce(min(b.landing_cost), 0)                as s1landing_cost,
                           coalesce(sum(it.inward - it.outward)::float, 0) as s1closing
                    from inv_txn as it
                             left join batch b on b.id = it.batch_id
                    where it.date <= ($1 ->> 'as_on_date')::date
                      and (case when array_length(branches, 1) > 0 then it.branch_id = any (branches) else true end)
                      and (case when array_length(divisions, 1) > 0 then it.division_id = any (divisions) else true end)
                      and (case
                               when array_length(inventories, 1) > 0 then it.inventory_id = any (inventories)
                               else true end)
                      and (case
                               when array_length(manufacturers, 1) > 0 then it.manufacturer_id = any (manufacturers)
                               else true end)
                      and (case when array_length(vendors, 1) > 0 then it.party_id = any (vendors) else true end)
                    group by it.batch_id),
             s2 as (select s1id                       as s2id,
                           s1name                     as s2name,
                           s1closing                  as s2closing,
                           s1p_rate * s1closing       as s2cost_value,
                           s1nlc * s1closing          as s2nlc_value,
                           s1landing_cost * s1closing as s2landing_value
                    from s1
                    where s1closing <> 0)
        select s2id                                           as id,
               min(s2name)                                    as name,
               round(sum(s2cost_value)::numeric, 4)::float    as cost_value,
               round(sum(s2nlc_value)::numeric, 4)::float     as nlc_value,
               round(sum(s2landing_value)::numeric, 4)::float as landing_value,
               round(sum(s2closing)::numeric, 4)::float       as closing
        from s2
        group by id
        order by closing, name;
end;
$$ language plpgsql security definer;
--##
create function stock_analysis_by_manufacturer(input_data json)
    returns table
            (
                id            int,
                name          text,
                cost_value    float,
                nlc_value     float,
                landing_value float,
                closing       float
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
        with s1 as (select min(b.manufacturer_id)                          as s1id,
                           min(b.manufacturer_name)                        as s1name,
                           coalesce(min(b.p_rate), 0)                      as s1p_rate,
                           coalesce(min(b.nlc), 0)                         as s1nlc,
                           coalesce(min(b.landing_cost), 0)                as s1landing_cost,
                           coalesce(sum(it.inward - it.outward)::float, 0) as s1closing
                    from inv_txn as it
                             left join batch b on b.id = it.batch_id
                    where it.date <= ($1 ->> 'as_on_date')::date
                      and (case when array_length(branches, 1) > 0 then it.branch_id = any (branches) else true end)
                      and (case when array_length(divisions, 1) > 0 then it.division_id = any (divisions) else true end)
                      and (case
                               when array_length(inventories, 1) > 0 then it.inventory_id = any (inventories)
                               else true end)
                      and (case
                               when array_length(manufacturers, 1) > 0 then it.manufacturer_id = any (manufacturers)
                               else true end)
                      and (case when array_length(vendors, 1) > 0 then it.party_id = any (vendors) else true end)
                    group by it.batch_id),
             s2 as (select s1id                       as s2id,
                           s1name                     as s2name,
                           s1closing                  as s2closing,
                           s1p_rate * s1closing       as s2cost_value,
                           s1nlc * s1closing          as s2nlc_value,
                           s1landing_cost * s1closing as s2landing_value
                    from s1
                    where s1closing <> 0)
        select s2id                                           as id,
               min(s2name)                                    as name,
               round(sum(s2cost_value)::numeric, 4)::float    as cost_value,
               round(sum(s2nlc_value)::numeric, 4)::float     as nlc_value,
               round(sum(s2landing_value)::numeric, 4)::float as landing_value,
               round(sum(s2closing)::numeric, 4)::float       as closing
        from s2
        group by id
        order by closing, name;
end;
$$ language plpgsql security definer;
--##
create function stock_analysis_by_division(input_data json)
    returns table
            (
                id            int,
                name          text,
                cost_value    float,
                nlc_value     float,
                landing_value float,
                closing       float
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
        with s1 as (select min(b.division_id)                              as s1id,
                           min(b.division_name)                            as s1name,
                           coalesce(min(b.p_rate), 0)                      as s1p_rate,
                           coalesce(min(b.nlc), 0)                         as s1nlc,
                           coalesce(min(b.landing_cost), 0)                as s1landing_cost,
                           coalesce(sum(it.inward - it.outward)::float, 0) as s1closing
                    from inv_txn as it
                             left join batch b on b.id = it.batch_id
                    where it.date <= ($1 ->> 'as_on_date')::date
                      and (case when array_length(branches, 1) > 0 then it.branch_id = any (branches) else true end)
                      and (case when array_length(divisions, 1) > 0 then it.division_id = any (divisions) else true end)
                      and (case
                               when array_length(inventories, 1) > 0 then it.inventory_id = any (inventories)
                               else true end)
                      and (case
                               when array_length(manufacturers, 1) > 0 then it.manufacturer_id = any (manufacturers)
                               else true end)
                      and (case when array_length(vendors, 1) > 0 then it.party_id = any (vendors) else true end)
                    group by it.batch_id),
             s2 as (select s1id                       as s2id,
                           s1name                     as s2name,
                           s1closing                  as s2closing,
                           s1p_rate * s1closing       as s2cost_value,
                           s1nlc * s1closing          as s2nlc_value,
                           s1landing_cost * s1closing as s2landing_value
                    from s1
                    where s1closing <> 0)
        select s2id                                           as id,
               min(s2name)                                    as name,
               round(sum(s2cost_value)::numeric, 4)::float    as cost_value,
               round(sum(s2nlc_value)::numeric, 4)::float     as nlc_value,
               round(sum(s2landing_value)::numeric, 4)::float as landing_value,
               round(sum(s2closing)::numeric, 4)::float       as closing
        from s2
        group by id
        order by closing, name;
end;
$$ language plpgsql security definer;
--##
create function stock_analysis_by_branch(input_data json)
    returns table
            (
                id            int,
                name          text,
                cost_value    float,
                nlc_value     float,
                landing_value float,
                closing       float
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
        with s1 as (select min(b.branch_id)                                as s1id,
                           min(b.branch_name)                              as s1name,
                           coalesce(min(b.p_rate), 0)                      as s1p_rate,
                           coalesce(min(b.nlc), 0)                         as s1nlc,
                           coalesce(min(b.landing_cost), 0)                as s1landing_cost,
                           coalesce(sum(it.inward - it.outward)::float, 0) as s1closing
                    from inv_txn as it
                             left join batch b on b.id = it.batch_id
                    where it.date <= ($1 ->> 'as_on_date')::date
                      and (case when array_length(branches, 1) > 0 then it.branch_id = any (branches) else true end)
                      and (case when array_length(divisions, 1) > 0 then it.division_id = any (divisions) else true end)
                      and (case
                               when array_length(inventories, 1) > 0 then it.inventory_id = any (inventories)
                               else true end)
                      and (case
                               when array_length(manufacturers, 1) > 0 then it.manufacturer_id = any (manufacturers)
                               else true end)
                      and (case when array_length(vendors, 1) > 0 then it.party_id = any (vendors) else true end)
                    group by it.batch_id),
             s2 as (select s1id                       as s2id,
                           s1name                     as s2name,
                           s1closing                  as s2closing,
                           s1p_rate * s1closing       as s2cost_value,
                           s1nlc * s1closing          as s2nlc_value,
                           s1landing_cost * s1closing as s2landing_value
                    from s1
                    where s1closing <> 0)
        select s2id                                           as id,
               min(s2name)                                    as name,
               round(sum(s2cost_value)::numeric, 4)::float    as cost_value,
               round(sum(s2nlc_value)::numeric, 4)::float     as nlc_value,
               round(sum(s2landing_value)::numeric, 4)::float as landing_value,
               round(sum(s2closing)::numeric, 4)::float       as closing
        from s2
        group by id
        order by closing, name;
end;
$$ language plpgsql security definer;
--##
create function stock_analysis_by_vendor(input_data json)
    returns table
            (
                id            int,
                name          text,
                cost_value    float,
                nlc_value     float,
                landing_value float,
                closing       float
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
        with s1 as (select min(b.vendor_id)                                as s1id,
                           min(b.vendor_name)                              as s1name,
                           coalesce(min(b.p_rate), 0)                      as s1p_rate,
                           coalesce(min(b.nlc), 0)                         as s1nlc,
                           coalesce(min(b.landing_cost), 0)                as s1landing_cost,
                           coalesce(sum(it.inward - it.outward)::float, 0) as s1closing
                    from inv_txn as it
                             left join batch b on b.id = it.batch_id
                    where it.date <= ($1 ->> 'as_on_date')::date
                      and (case when array_length(branches, 1) > 0 then it.branch_id = any (branches) else true end)
                      and (case when array_length(divisions, 1) > 0 then it.division_id = any (divisions) else true end)
                      and (case
                               when array_length(inventories, 1) > 0 then it.inventory_id = any (inventories)
                               else true end)
                      and (case
                               when array_length(manufacturers, 1) > 0 then it.manufacturer_id = any (manufacturers)
                               else true end)
                      and (case when array_length(vendors, 1) > 0 then it.party_id = any (vendors) else true end)
                    group by it.batch_id),
             s2 as (select s1id                       as s2id,
                           s1name                     as s2name,
                           s1closing                  as s2closing,
                           s1p_rate * s1closing       as s2cost_value,
                           s1nlc * s1closing          as s2nlc_value,
                           s1landing_cost * s1closing as s2landing_value
                    from s1
                    where s1closing <> 0)
        select s2id                                           as id,
               min(s2name)                                    as name,
               round(sum(s2cost_value)::numeric, 4)::float    as cost_value,
               round(sum(s2nlc_value)::numeric, 4)::float     as nlc_value,
               round(sum(s2landing_value)::numeric, 4)::float as landing_value,
               round(sum(s2closing)::numeric, 4)::float       as closing
        from s2
        group by id
        order by closing, name;
end;
$$ language plpgsql security definer;