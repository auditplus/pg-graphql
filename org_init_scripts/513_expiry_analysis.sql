create function expiry_analysis(input json)
    returns table
            (
                id                int,
                entry_date        date,
                expiry            date,
                closing           float,
                unit_conv         float,
                unit_id           int,
                unit_name         text,
                branch            int,
                branch_name       text,
                inventory         int,
                inventory_name    text,
                division          int,
                division_name     text,
                manufacturer      int,
                manufacturer_name text,
                vendor            int,
                batch_no          text,
                mrp               float,
                s_rate            float,
                p_rate            float,
                landing_cost      float,
                nlc               float,
                category          json
            )
    language plpgsql
AS
$expiry_analysis$
declare
    from_date date  := (input ->> 'from_date')::date;
    to_date   date  := (input ->> 'to_date')::date;
    br_ids    int[] := (select array_agg(j::int)
                        from json_array_elements_text((input ->> 'branches')::json) as j);
    div_ids   int[] := (select array_agg(j::int)
                        from json_array_elements_text((input ->> 'divisions')::json) as j);
    inv_ids   int[] := (select array_agg(j::int)
                        from json_array_elements_text((input ->> 'inventories')::json) as j);
    man_ids   int[] := (select array_agg(j::int)
                        from json_array_elements_text((input ->> 'manufacturers')::json) as j);
    cat1      int   := (input ->> 'category1')::int;
    cat2      int   := (input ->> 'category2')::int;
    cat3      int   := (input ->> 'category3')::int;
    cat4      int   := (input ->> 'category4')::int;
    cat5      int   := (input ->> 'category5')::int;
    cat6      int   := (input ->> 'category6')::int;
    cat7      int   := (input ->> 'category7')::int;
    cat8      int   := (input ->> 'category8')::int;
    cat9      int   := (input ->> 'category9')::int;
    cat10     int   := (input ->> 'category10')::int;
begin

    return query
        with "b" as
                 (select *, round(("batch"."inward" - "batch"."outward")::numeric, 4)::float as "closing"
                  from "batch"
                  where ("batch"."inward" - "batch"."outward")::float > 0
                    and "batch"."expiry" <= to_date
                    and (case when from_date is not null then "batch"."expiry" >= from_date else true end)
                    and (case when array_length(br_ids, 1) > 0 then "batch"."branch" = any (br_ids) else true end)
                    and (case when array_length(div_ids, 1) > 0 then "batch"."division" = any (div_ids) else true end)
                    and (case
                             when array_length(inv_ids, 1) > 0 then "batch"."inventory" = any (inv_ids)
                             else true end)
                    and (case
                             when array_length(man_ids, 1) > 0 then "batch"."manufacturer" = any (man_ids)
                             else true end)
                    and (case when cat1 is null then true else "batch"."category1" = cat1 end)
                    and (case when cat2 is null then true else "batch"."category2" = cat2 end)
                    and (case when cat3 is null then true else "batch"."category3" = cat3 end)
                    and (case when cat4 is null then true else "batch"."category4" = cat4 end)
                    and (case when cat5 is null then true else "batch"."category5" = cat5 end)
                    and (case when cat6 is null then true else "batch"."category6" = cat6 end)
                    and (case when cat7 is null then true else "batch"."category7" = cat7 end)
                    and (case when cat8 is null then true else "batch"."category8" = cat8 end)
                    and (case when cat9 is null then true else "batch"."category9" = cat9 end)
                    and (case when cat10 is null then true else "batch"."category10" = cat10 end)
                  order by "batch"."expiry" ASC, "batch"."id" ASC)
        select "b"."id",
               "b"."entry_date",
               "b"."expiry",
               "b"."closing",
               "b"."unit_conv",
               "b"."unit_id",
               "u"."name" as "unit_name",
               "b"."branch",
               "b"."branch_name",
               "b"."inventory",
               "b"."inventory_name",
               "b"."division",
               "b"."division_name",
               "b"."manufacturer",
               "b"."manufacturer_name",
               "b"."vendor",
               "b"."batch_no",
               "b"."mrp"::float,
               "b"."s_rate"::float,
               "b"."p_rate"::float,
               "b"."landing_cost"::float,
               "b"."nlc"::float,
               json_build_object(
                       'category1', "b"."category1",
                       'category2', "b"."category2",
                       'category3', "b"."category3",
                       'category4', "b"."category4",
                       'category5', "b"."category5",
                       'category6', "b"."category6",
                       'category7', "b"."category7",
                       'category8', "b"."category8",
                       'category9', "b"."category9",
                       'category10', "b"."category10"
               )
        from "b"
                 left join "unit" as "u" ON "b"."unit_id" = "u"."id";

end;
$expiry_analysis$;