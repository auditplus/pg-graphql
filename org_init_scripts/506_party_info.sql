create function party_info(b_id int)
    returns table
            (
                "party"         int,
                "party_name"    text,
                "closing"       float,
                "landing_value" float,
                "cost_value"    float,
                "nlc_value"     float
            )
as
$$
declare
    land_val numeric;
    cost_val numeric;
    nlc_val  numeric;
begin
    select coalesce("landing_cost", 0)::numeric, coalesce("p_rate", 0)::numeric, coalesce("nlc", 0)::numeric
    into land_val, cost_val, nlc_val
    from batch
    where batch.id = $1;
    return query
        select coalesce("customer_id", "vendor_id")                           as "party",
               coalesce(min("customer_name"), min("vendor_name"))             as "party_name",
               ROUND(sum("inward" - "outward")::numeric, 4)::float            as "closing",
               ROUND(sum("inward" - "outward")::numeric * land_val, 2)::float as "landing_value",
               ROUND(sum("inward" - "outward")::numeric * cost_val, 2)::float as "cost_value",
               ROUND(sum("inward" - "outward")::numeric * nlc_val, 2)::float  as "nlc_value"
        from "inv_txn"
        where inv_txn.batch_id = $1
        group by "party"
        order by "closing" DESC, "party_name";
end;
$$ language plpgsql;