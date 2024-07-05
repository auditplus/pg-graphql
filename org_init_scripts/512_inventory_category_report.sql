create function inventory_category_report_summary(input json)
    returns TABLE
            (
                inward   float,
                outward  float,
                category json
            )
    language plpgsql
AS
$inventory_category_report_summary$
declare
    from_date  date   := (input ->> 'from_date')::date;
    to_date    date   := (input ->> 'to_date')::date;
    br_ids     bigint[]  := (select array_agg(j::bigint)
                          from json_array_elements_text((input ->> 'branches')::json) as j);
    grp_by     text[] := (select array_agg(j)
                          from json_array_elements_text((input ->> 'group_by')::json) as j);
    total_rows int    := 0;
    q          text   := '';
    qc         text   := '';
    qg         text[];
    inv_cat    text   := '';
begin
    select count(1)::int
    into total_rows
    from category as c
    where category_type = 'INVENTORY'
      and c.category is not null
      and id = any (grp_by)
      and active = true;

    if total_rows = 0 or array_length(grp_by, 1) <> total_rows then
        raise exception 'Invalid/Unassigned category';
    end if;

    q = 'select
	sum("inward") as "inward",
    sum("outward") as "outward"';

    qc = ' from "inv_txn"
	where ("date" between $1 and $2)
	and (case when coalesce((array_length($3,1) > 0),false) then branch = any($3) else true end)';

    for i in 1..10
        loop
            inv_cat = format('INV_CAT%s', i);
            if i = 1 then
                q = q || ', json_build_object(';
            end if;
            if inv_cat = any (grp_by) then
                q = q || '''category' || i || ''',"category' || i || '"';
                qc = qc || 'and "category' || i || '" is not null ';
                qg = array_append(qg, '"category' || i || '"');
            else
                q = q || '''category' || i || ''', cast(null as int)';
            end if;
            if i < 10 then
                q = q || ',';
            else
                q = q || ') as "category"';
            end if;
        end loop;

    q = q || qc || 'group by ' || array_to_string(qg, ',');
    q = q || ' order by "inward" desc';

    q = q || ';';

    return query
        execute q
        USING from_date, to_date, br_ids;
end;
$inventory_category_report_summary$;
--##
create function inventory_category_report_by_group(input json)
    returns TABLE
            (
                "particulars" date,
                "inward"      float,
                "outward"     float,
                "closing"     float
            )
    language plpgsql
AS
$inventory_category_report_by_group$
declare
    from_date date  := (input ->> 'from_date')::date;
    to_date   date  := (input ->> 'to_date')::date;
    br_ids    bigint[] := (select array_agg(j::bigint)
                        from json_array_elements_text((input ->> 'branches')::json) as j);
    inv_ids   bigint[] := (select array_agg(j::bigint)
                        from json_array_elements_text((input ->> 'inventories')::json) as j);
    grp_by    text  := (input ->> 'group')::text; -- 'Day' / 'Month'
    cat1      bigint   := (input ->> 'category1')::bigint;
    cat2      bigint   := (input ->> 'category2')::bigint;
    cat3      bigint   := (input ->> 'category3')::bigint;
    cat4      bigint   := (input ->> 'category4')::bigint;
    cat5      bigint   := (input ->> 'category5')::bigint;
    cat6      bigint   := (input ->> 'category6')::bigint;
    cat7      bigint   := (input ->> 'category7')::bigint;
    cat8      bigint   := (input ->> 'category8')::bigint;
    cat9      bigint   := (input ->> 'category9')::bigint;
    cat10     bigint   := (input ->> 'category10')::bigint;
begin
    if grp_by is null or grp_by not in ('Day', 'Month') then
        grp_by = 'Day';
    end if;

    return query
        select date_trunc(grp_by, "date")::date                                        as "part",
               ROUND(sum("inv_txn"."inward")::numeric, 4)::float                       as "in",
               ROUND(sum("inv_txn"."outward")::numeric, 4)::float                      as "out",
               ROUND(sum("inv_txn"."inward" - "inv_txn"."outward")::numeric, 4)::float as "close"
        from "inv_txn"
        where ("date" between from_date and to_date)
          and (case when array_length(br_ids, 1) > 0 then "branch_id" = any (br_ids) else true end)
          and (case when array_length(inv_ids, 1) > 0 then "inventory_id" = any (inv_ids) else true end)
          and (case when cat1 is null then true else "category1_id" = cat1 end)
          and (case when cat2 is null then true else "category2_id" = cat2 end)
          and (case when cat3 is null then true else "category3_id" = cat3 end)
          and (case when cat4 is null then true else "category4_id" = cat4 end)
          and (case when cat5 is null then true else "category5_id" = cat5 end)
          and (case when cat6 is null then true else "category6_id" = cat6 end)
          and (case when cat7 is null then true else "category7_id" = cat7 end)
          and (case when cat8 is null then true else "category8_id" = cat8 end)
          and (case when cat9 is null then true else "category9_id" = cat9 end)
          and (case when cat10 is null then true else "category10_id" = cat10 end)
        group by "part"
        order by "part", "close";


end;
$inventory_category_report_by_group$;
--##
create function inventory_category_report_detail(input json)
    returns TABLE
            (
                id                   uuid,
                date                 date,
                batch                bigint,
                branch               bigint,
                branch_name          text,
                division             bigint,
                division_name        text,
                warehouse            bigint,
                warehouse_name       text,
                inventory            bigint,
                reorder_inventory    bigint,
                inventory_name       text,
                inventory_hsn        text,
                customer             bigint,
                customer_name        text,
                vendor               bigint,
                vendor_name          text,
                manufacturer         bigint,
                manufacturer_name    text,
                inward               float,
                outward              float,
                closing              float,
                ref_no               text,
                voucher_no           text,
                base_voucher_type    text,
                voucher_type         bigint,
                voucher              bigint,
                inventory_voucher_id bigint,
                asset_amount         float,
                taxable_amount       float,
                cgst_amount          float,
                sgst_amount          float,
                igst_amount          float,
                cess_amount          float,
                nlc                  float,
                cost                 float,
                is_opening           boolean,
                category1            bigint,
                category2            bigint,
                category3            bigint,
                category4            bigint,
                category5            bigint,
                category6            bigint,
                category7            bigint,
                category8            bigint,
                category9            bigint,
                category10           bigint
            )
    language plpgsql
AS
$inventory_category_report_detail$
declare
    from_date date  := (input ->> 'from_date')::date;
    to_date   date  := (input ->> 'to_date')::date;
    br_ids    bigint[] := (select array_agg(j::bigint)
                        from json_array_elements_text((input ->> 'branches')::json) as j);
    inv_ids   bigint[] := (select array_agg(j::bigint)
                        from json_array_elements_text((input ->> 'inventories')::json) as j);
    cat1      bigint   := (input ->> 'category1')::bigint;
    cat2      bigint   := (input ->> 'category2')::bigint;
    cat3      bigint   := (input ->> 'category3')::bigint;
    cat4      bigint   := (input ->> 'category4')::bigint;
    cat5      bigint   := (input ->> 'category5')::bigint;
    cat6      bigint   := (input ->> 'category6')::bigint;
    cat7      bigint   := (input ->> 'category7')::bigint;
    cat8      bigint   := (input ->> 'category8')::bigint;
    cat9      bigint   := (input ->> 'category9')::bigint;
    cat10     bigint   := (input ->> 'category10')::bigint;
begin

    return query
        select "it"."id",
               "it"."date",
               "it"."batch_id",
               "it"."branch_id",
               "it"."branch_name",
               "it"."division",
               "it"."division_name",
               "it"."warehouse_id",
               "it"."warehouse_name",
               "it"."inventory_id",
               "it"."reorder_inventory_id",
               "it"."inventory_name",
               "it"."inventory_hsn",
               "it"."customer_id",
               "it"."customer_name",
               "it"."vendor_id",
               "it"."vendor_name",
               "it"."manufacturer_id",
               "it"."manufacturer_name",
               "it"."inward",
               "it"."outward",
               ("it"."inward" - "it"."outward") as "closing",
               "it"."ref_no",
               "it"."voucher_no",
               "it"."base_voucher_type"::text,
               "it"."voucher_type_id",
               "it"."voucher_id",
               "it"."inventory_voucher_id",
               "it"."asset_amount",
               "it"."taxable_amount",
               "it"."cgst_amount",
               "it"."sgst_amount",
               "it"."igst_amount",
               "it"."cess_amount",
               "it"."nlc",
               "it"."cost",
               "it"."is_opening",
               "it"."category1",
               "it"."category2",
               "it"."category3",
               "it"."category4",
               "it"."category5",
               "it"."category6",
               "it"."category7",
               "it"."category8",
               "it"."category9",
               "it"."category10"
        from "inv_txn" as "it"
        where ("it"."date" between from_date and to_date)
          and (case when array_length(br_ids, 1) > 0 then "it"."branch_id" = any (br_ids) else true end)
          and (case when array_length(inv_ids, 1) > 0 then "it"."inventory_id" = any (inv_ids) else true end)
          and (case when cat1 is null then true else "it"."category1_id" = cat1 end)
          and (case when cat2 is null then true else "it"."category2_id" = cat2 end)
          and (case when cat3 is null then true else "it"."category3_id" = cat3 end)
          and (case when cat4 is null then true else "it"."category4_id" = cat4 end)
          and (case when cat5 is null then true else "it"."category5_id" = cat5 end)
          and (case when cat6 is null then true else "it"."category6_id" = cat6 end)
          and (case when cat7 is null then true else "it"."category7_id" = cat7 end)
          and (case when cat8 is null then true else "it"."category8_id" = cat8 end)
          and (case when cat9 is null then true else "it"."category9_id" = cat9 end)
          and (case when cat10 is null then true else "it"."category10_id" = cat10 end)
        order by "it"."date", "it"."base_voucher_type";

end;
$inventory_category_report_detail$;
--##
create function inventory_category_report_detail_summary(input json)
    returns TABLE
            (
                "inward"  float,
                "outward" float,
                "closing" float
            )
    language plpgsql
AS
$inventory_category_report_detail_summary$
declare
    from_date date  := (input ->> 'from_date')::date;
    to_date   date  := (input ->> 'to_date')::date;
    br_ids    bigint[] := (select array_agg(j::bigint)
                        from json_array_elements_text((input ->> 'branches')::json) as j);
    inv_ids   bigint[] := (select array_agg(j::bigint)
                        from json_array_elements_text((input ->> 'inventories')::json) as j);
    cat1      bigint   := (input ->> 'category1')::bigint;
    cat2      bigint   := (input ->> 'category2')::bigint;
    cat3      bigint   := (input ->> 'category3')::bigint;
    cat4      bigint   := (input ->> 'category4')::bigint;
    cat5      bigint   := (input ->> 'category5')::bigint;
    cat6      bigint   := (input ->> 'category6')::bigint;
    cat7      bigint   := (input ->> 'category7')::bigint;
    cat8      bigint   := (input ->> 'category8')::bigint;
    cat9      bigint   := (input ->> 'category9')::bigint;
    cat10     bigint   := (input ->> 'category10')::bigint;
begin

    return query
        select round(sum("it"."inward")::numeric, 4)::float,
               round(sum("it"."outward")::numeric, 4)::float,
               round(sum("it"."inward" - "it"."outward")::numeric, 4)::float as "closing"
        from "inv_txn" as "it"
        where ("it"."date" between from_date and to_date)
          and (case when array_length(br_ids, 1) > 0 then "it"."branch_id" = any (br_ids) else true end)
          and (case when array_length(inv_ids, 1) > 0 then "it"."inventory_id" = any (inv_ids) else true end)
          and (case when cat1 is null then true else "it"."category1_id" = cat1 end)
          and (case when cat2 is null then true else "it"."category2_id" = cat2 end)
          and (case when cat3 is null then true else "it"."category3_id" = cat3 end)
          and (case when cat4 is null then true else "it"."category4_id" = cat4 end)
          and (case when cat5 is null then true else "it"."category5_id" = cat5 end)
          and (case when cat6 is null then true else "it"."category6_id" = cat6 end)
          and (case when cat7 is null then true else "it"."category7_id" = cat7 end)
          and (case when cat8 is null then true else "it"."category8_id" = cat8 end)
          and (case when cat9 is null then true else "it"."category9_id" = cat9 end)
          and (case when cat10 is null then true else "it"."category10_id" = cat10 end);
end;
$inventory_category_report_detail_summary$;