-- select * from stock_summary_by_inventory(
-- as_on_date := '2024-06-01'::date,
-- br_ids := ARRAY [1]::integer[],
-- div_ids := ARRAY []::integer[],
-- inv_ids := ARRAY []::integer[],
-- man_ids := ARRAY []::integer[],
-- vend_ids := ARRAY []::integer[]
-- );
create function stock_summary_by_inventory(
    as_on_date date,
    br_ids int[] default '{}'::int[],
    div_ids int[] default '{}'::int[],
    inv_ids int[] default '{}'::int[],
    man_ids int[] default '{}'::int[],
    vend_ids int[] default '{}'::int[]
)
returns table (
    id            int,
    name          text,
    cost_value    float,
    nlc_value     float,
    landing_value float,
    closing       float
)
AS
$$
begin

    return query
    with s1 as (
        select
            min(it.inventory) as s1id,
            min(it.inventory_name) as s1name,
            coalesce(min(b.p_rate), 0) as s1p_rate,
            coalesce(min(b.nlc), 0) as s1nlc,
            coalesce(min(b.landing_cost), 0) as s1landing_cost,
            coalesce(sum(it.inward - it.outward)::float, 0) as s1closing
        from inv_txn as it left join public.batch b on b.id = it.batch
        where it.date <= as_on_date
        and (case when array_length(br_ids, 1) > 0 then it.branch = any (br_ids) else true end)
        and (case when array_length(div_ids, 1) > 0 then it.division = any (div_ids) else true end)
        and (case when array_length(inv_ids, 1) > 0 then it.inventory = any (inv_ids) else true end)
        and (case when array_length(man_ids, 1) > 0 then it.manufacturer = any (man_ids) else true end)
        and (case when array_length(vend_ids, 1) > 0 then it.vendor = any (vend_ids) else true end)
        group by it.batch
    ),
    s2 as (
        select s1id as s2id,
               s1name as s2name,
               s1closing as s2closing,
               (s1p_rate * s1closing)::float as s2cost_value,
               (s1nlc * s1closing)::float as s2nlc_value,
               (s1landing_cost * s1closing)::float as s2landing_value
        from s1
        where s1closing <> 0
    )
    select s2id as id,
           min(s2name) as name,
           round(sum(s2cost_value)::numeric,4)::float as cost_value,
           round(sum(s2nlc_value)::numeric,4)::float as nlc_value,
           round(sum(s2landing_value)::numeric,4)::float as landing_value,
           sum(s2closing)::float as closing
    from s2
    group by id
    order by closing, name;

end;
$$ language plpgsql;
--##
-- select * from stock_summary_by_manufacturer(
-- as_on_date := '2024-06-01'::date,
-- br_ids := ARRAY [1]::integer[],
-- div_ids := ARRAY []::integer[],
-- inv_ids := ARRAY []::integer[],
-- man_ids := ARRAY []::integer[],
-- vend_ids := ARRAY []::integer[]
-- );
create function stock_summary_by_manufacturer(
    as_on_date date,
    br_ids int[] default '{}'::int[],
    div_ids int[] default '{}'::int[],
    inv_ids int[] default '{}'::int[],
    man_ids int[] default '{}'::int[],
    vend_ids int[] default '{}'::int[]
)
returns table (
    id            int,
    name          text,
    cost_value    float,
    nlc_value     float,
    landing_value float,
    closing       float
)
AS
$$
begin

    return query
    with s1 as (
        select
            min(it.manufacturer) as s1id,
            min(it.manufacturer_name) as s1name,
            coalesce(min(b.p_rate), 0) as s1p_rate,
            coalesce(min(b.nlc), 0) as s1nlc,
            coalesce(min(b.landing_cost), 0) as s1landing_cost,
            coalesce(sum(it.inward - it.outward)::float, 0) as s1closing
        from inv_txn as it left join public.batch b on b.id = it.batch
        where it.date <= as_on_date
        and (case when array_length(br_ids, 1) > 0 then it.branch = any (br_ids) else true end)
        and (case when array_length(div_ids, 1) > 0 then it.division = any (div_ids) else true end)
        and (case when array_length(inv_ids, 1) > 0 then it.inventory = any (inv_ids) else true end)
        and (case when array_length(man_ids, 1) > 0 then it.manufacturer = any (man_ids) else true end)
        and (case when array_length(vend_ids, 1) > 0 then it.vendor = any (vend_ids) else true end)
        group by it.batch
    ),
    s2 as (
        select s1id as s2id,
               s1name as s2name,
               s1closing as s2closing,
               (s1p_rate * s1closing)::float as s2cost_value,
               (s1nlc * s1closing)::float as s2nlc_value,
               (s1landing_cost * s1closing)::float as s2landing_value
        from s1
        where s1closing <> 0
    )
    select s2id as id,
           min(s2name) as name,
           round(sum(s2cost_value)::numeric,4)::float as cost_value,
           round(sum(s2nlc_value)::numeric,4)::float as nlc_value,
           round(sum(s2landing_value)::numeric,4)::float as landing_value,
           sum(s2closing)::float as closing
    from s2
    group by id
    order by closing, name;

end;
$$ language plpgsql;
--##
-- select * from stock_summary_by_division(
-- as_on_date := '2024-06-01'::date,
-- br_ids := ARRAY [1]::integer[],
-- div_ids := ARRAY []::integer[],
-- inv_ids := ARRAY []::integer[],
-- man_ids := ARRAY []::integer[],
-- vend_ids := ARRAY []::integer[]
-- );
create function stock_summary_by_division(
    as_on_date date,
    br_ids int[] default '{}'::int[],
    div_ids int[] default '{}'::int[],
    inv_ids int[] default '{}'::int[],
    man_ids int[] default '{}'::int[],
    vend_ids int[] default '{}'::int[]
)
returns table (
    id            int,
    name          text,
    cost_value    float,
    nlc_value     float,
    landing_value float,
    closing       float
)
AS
$$
begin

    return query
    with s1 as (
        select
            min(it.division) as s1id,
            min(it.division_name) as s1name,
            coalesce(min(b.p_rate), 0) as s1p_rate,
            coalesce(min(b.nlc), 0) as s1nlc,
            coalesce(min(b.landing_cost), 0) as s1landing_cost,
            coalesce(sum(it.inward - it.outward)::float, 0) as s1closing
        from inv_txn as it left join public.batch b on b.id = it.batch
        where it.date <= as_on_date
        and (case when array_length(br_ids, 1) > 0 then it.branch = any (br_ids) else true end)
        and (case when array_length(div_ids, 1) > 0 then it.division = any (div_ids) else true end)
        and (case when array_length(inv_ids, 1) > 0 then it.inventory = any (inv_ids) else true end)
        and (case when array_length(man_ids, 1) > 0 then it.manufacturer = any (man_ids) else true end)
        and (case when array_length(vend_ids, 1) > 0 then it.vendor = any (vend_ids) else true end)
        group by it.batch
    ),
    s2 as (
        select s1id as s2id,
               s1name as s2name,
               s1closing as s2closing,
               (s1p_rate * s1closing)::float as s2cost_value,
               (s1nlc * s1closing)::float as s2nlc_value,
               (s1landing_cost * s1closing)::float as s2landing_value
        from s1
        where s1closing <> 0
    )
    select s2id as id,
           min(s2name) as name,
           round(sum(s2cost_value)::numeric,4)::float as cost_value,
           round(sum(s2nlc_value)::numeric,4)::float as nlc_value,
           round(sum(s2landing_value)::numeric,4)::float as landing_value,
           sum(s2closing)::float as closing
    from s2
    group by id
    order by closing, name;

end;
$$ language plpgsql;
--##
-- select * from stock_summary_by_branch(
-- as_on_date := '2024-06-01'::date,
-- br_ids := ARRAY [1]::integer[],
-- div_ids := ARRAY []::integer[],
-- inv_ids := ARRAY []::integer[],
-- man_ids := ARRAY []::integer[],
-- vend_ids := ARRAY []::integer[]
-- );
create function stock_summary_by_branch(
    as_on_date date,
    br_ids int[] default '{}'::int[],
    div_ids int[] default '{}'::int[],
    inv_ids int[] default '{}'::int[],
    man_ids int[] default '{}'::int[],
    vend_ids int[] default '{}'::int[]
)
returns table (
    id            int,
    name          text,
    cost_value    float,
    nlc_value     float,
    landing_value float,
    closing       float
)
AS
$$
begin

    return query
    with s1 as (
        select
            min(it.branch) as s1id,
            min(it.branch_name) as s1name,
            coalesce(min(b.p_rate), 0) as s1p_rate,
            coalesce(min(b.nlc), 0) as s1nlc,
            coalesce(min(b.landing_cost), 0) as s1landing_cost,
            coalesce(sum(it.inward - it.outward)::float, 0) as s1closing
        from inv_txn as it left join public.batch b on b.id = it.batch
        where it.date <= as_on_date
        and (case when array_length(br_ids, 1) > 0 then it.branch = any (br_ids) else true end)
        and (case when array_length(div_ids, 1) > 0 then it.division = any (div_ids) else true end)
        and (case when array_length(inv_ids, 1) > 0 then it.inventory = any (inv_ids) else true end)
        and (case when array_length(man_ids, 1) > 0 then it.manufacturer = any (man_ids) else true end)
        and (case when array_length(vend_ids, 1) > 0 then it.vendor = any (vend_ids) else true end)
        group by it.batch
    ),
    s2 as (
        select s1id as s2id,
               s1name as s2name,
               s1closing as s2closing,
               (s1p_rate * s1closing)::float as s2cost_value,
               (s1nlc * s1closing)::float as s2nlc_value,
               (s1landing_cost * s1closing)::float as s2landing_value
        from s1
        where s1closing <> 0
    )
    select s2id as id,
           min(s2name) as name,
           round(sum(s2cost_value)::numeric,4)::float as cost_value,
           round(sum(s2nlc_value)::numeric,4)::float as nlc_value,
           round(sum(s2landing_value)::numeric,4)::float as landing_value,
           sum(s2closing)::float as closing
    from s2
    group by id
    order by closing, name;

end;
$$ language plpgsql;
--##
-- select * from stock_summary_by_vendor(
-- as_on_date := '2024-06-01'::date,
-- br_ids := ARRAY [1]::integer[],
-- div_ids := ARRAY []::integer[],
-- inv_ids := ARRAY []::integer[],
-- man_ids := ARRAY []::integer[],
-- vend_ids := ARRAY []::integer[]
-- );
create function stock_summary_by_vendor(
    as_on_date date,
    br_ids int[] default '{}'::int[],
    div_ids int[] default '{}'::int[],
    inv_ids int[] default '{}'::int[],
    man_ids int[] default '{}'::int[],
    vend_ids int[] default '{}'::int[]
)
returns table (
    id            int,
    name          text,
    cost_value    float,
    nlc_value     float,
    landing_value float,
    closing       float
)
AS
$$
begin

    return query
    with s1 as (
        select
            min(it.vendor) as s1id,
            min(it.vendor_name) as s1name,
            coalesce(min(b.p_rate), 0) as s1p_rate,
            coalesce(min(b.nlc), 0) as s1nlc,
            coalesce(min(b.landing_cost), 0) as s1landing_cost,
            coalesce(sum(it.inward - it.outward)::float, 0) as s1closing
        from inv_txn as it left join public.batch b on b.id = it.batch
        where it.date <= as_on_date
        and (case when array_length(br_ids, 1) > 0 then it.branch = any (br_ids) else true end)
        and (case when array_length(div_ids, 1) > 0 then it.division = any (div_ids) else true end)
        and (case when array_length(inv_ids, 1) > 0 then it.inventory = any (inv_ids) else true end)
        and (case when array_length(man_ids, 1) > 0 then it.manufacturer = any (man_ids) else true end)
        and (case when array_length(vend_ids, 1) > 0 then it.vendor = any (vend_ids) else true end)
        group by it.batch
    ),
    s2 as (
        select s1id as s2id,
               s1name as s2name,
               s1closing as s2closing,
               (s1p_rate * s1closing)::float as s2cost_value,
               (s1nlc * s1closing)::float as s2nlc_value,
               (s1landing_cost * s1closing)::float as s2landing_value
        from s1
        where s1closing <> 0
    )
    select s2id as id,
           min(s2name) as name,
           round(sum(s2cost_value)::numeric,4)::float as cost_value,
           round(sum(s2nlc_value)::numeric,4)::float as nlc_value,
           round(sum(s2landing_value)::numeric,4)::float as landing_value,
           sum(s2closing)::float as closing
    from s2
    group by id
    order by closing, name;

end;
$$ language plpgsql;