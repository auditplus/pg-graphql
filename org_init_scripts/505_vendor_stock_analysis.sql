create function vendor_stock_analysis(input json)
    returns table
            (
                id             bigint,
                entry_date     date,
                closing        float,
                unit_conv      float,
                unit_id        bigint,
                unit_name      text,
                branch         bigint,
                branch_name    text,
                inventory      bigint,
                inventory_name text,
                vendor         bigint,
                batch_no       text,
                mrp            float,
                s_rate         float,
                p_rate         float,
                landing_cost   float,
                nlc            float,
                category       json
            )
    language plpgsql
AS
$vendor_stock_analysis$
declare
    vend_id bigint   := (input ->> 'vendor')::bigint;
    br_ids  bigint[] := (select array_agg(j::text::bigint)
                      from json_array_elements((input ->> 'branches')::json) as j);
    div_ids bigint[] := (select array_agg(j::text::bigint)
                      from json_array_elements((input ->> 'divisions')::json) as j);
    inv_ids bigint[] := (select array_agg(j::text::bigint)
                      from json_array_elements((input ->> 'inventories')::json) as j);
    man_ids bigint[] := (select array_agg(j::text::bigint)
                      from json_array_elements((input ->> 'manufacturers')::json) as j);
    cat1    bigint   := (input ->> 'category1')::bigint;
    cat2    bigint   := (input ->> 'category2')::bigint;
    cat3    bigint   := (input ->> 'category3')::bigint;
    cat4    bigint   := (input ->> 'category4')::bigint;
    cat5    bigint   := (input ->> 'category5')::bigint;
    cat6    bigint   := (input ->> 'category6')::bigint;
    cat7    bigint   := (input ->> 'category7')::bigint;
    cat8    bigint   := (input ->> 'category8')::bigint;
    cat9    bigint   := (input ->> 'category9')::bigint;
    cat10   bigint   := (input ->> 'category10')::bigint;
begin
    if vend_id is null then
        raise exception 'Choose Vendor';
    end if;

    return query
        select "b"."id",
               "b"."entry_date",
               round(("b"."inward" - "b"."outward")::numeric, 4)::float as "closing",
               "b"."unit_conv",
               "b"."unit_id",
               "u"."name"                                               as "unit_name",
               "b"."branch_id",
               "b"."branch_name",
               "b"."inventory_id",
               "b"."inventory_name",
               "b"."vendor_id",
               "b"."batch_no",
               "b"."mrp"::float,
               "b"."s_rate"::float,
               "b"."p_rate"::float,
               "b"."landing_cost"::float,
               "b"."nlc"::float,
               json_build_object(
                       'category1', "b"."category1_id",
                       'category2', "b"."category2_id",
                       'category3', "b"."category3_id",
                       'category4', "b"."category4_id",
                       'category5', "b"."category5_id",
                       'category6', "b"."category6_id",
                       'category7', "b"."category7_id",
                       'category8', "b"."category8_id",
                       'category9', "b"."category9_id",
                       'category10', "b"."category10_id"
               )
        from "batch" as "b"
                 left join "unit" as "u" ON "b"."unit_id" = "u"."id"
        where "b"."vendor_id" = vend_id
          and ("b"."inward" - "b"."outward")::float > 0
          and (case when array_length(br_ids, 1) > 0 then "b"."branch_id" = any (br_ids) else true end)
          and (case when array_length(div_ids, 1) > 0 then "b"."division_id" = any (div_ids) else true end)
          and (case when array_length(inv_ids, 1) > 0 then "b"."inventory_id" = any (inv_ids) else true end)
          and (case when array_length(man_ids, 1) > 0 then "b"."manufacturer_id" = any (man_ids) else true end)
          and (case when cat1 is null then true else "b"."category1_id" = cat1 end)
          and (case when cat2 is null then true else "b"."category2_id" = cat2 end)
          and (case when cat3 is null then true else "b"."category3_id" = cat3 end)
          and (case when cat4 is null then true else "b"."category4_id" = cat4 end)
          and (case when cat5 is null then true else "b"."category5_id" = cat5 end)
          and (case when cat6 is null then true else "b"."category6_id" = cat6 end)
          and (case when cat7 is null then true else "b"."category7_id" = cat7 end)
          and (case when cat8 is null then true else "b"."category8_id" = cat8 end)
          and (case when cat9 is null then true else "b"."category9_id" = cat9 end)
          and (case when cat10 is null then true else "b"."category10_id" = cat10 end)
        order by "b"."entry_date", "closing";
end;
$vendor_stock_analysis$;