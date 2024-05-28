create function account_category_report_summary(input json)
    returns TABLE
            (
                closing  float,
                credit   float,
                debit    float,
                category json
            )
    language plpgsql
AS
$account_category_report_summary$
declare
    from_date  date   := (input ->> 'from_date')::date;
    to_date    date   := (input ->> 'to_date')::date;
    br_ids     int[]  := (select array_agg(j::int)
                          from json_array_elements_text((input ->> 'branches')::json) as j);
    grp_by     text[] := (select array_agg(j)
                          from json_array_elements_text((input ->> 'group_by')::json) as j);
    total_rows int    := 0;
    q          text   := '';
    qc         text   := '';
    qg         text[];
    acc_cat    text   := '';
begin
    select count(1)::int
    into total_rows
    from category as c
    where category_type = 'ACCOUNT'
      and c.category is not null
      and id = any (grp_by)
      and active = true;

    if total_rows = 0 or array_length(grp_by, 1) <> total_rows then
        raise exception 'Invalid/Unassigned category';
    end if;

    q = 'select sum("amount")::float as "closing",
	sum(CASE when "amount" < 0 then "amount" * -1 else 0 end) as "credit",
    sum(CASE when "amount" > 0 then "amount" else 0 end) as "debit"';

    qc = ' from acc_cat_txn
	where ("date" between $1 and $2)
	and (case when coalesce((array_length($3,1) > 0),false) then branch = any($3) else true end)
	and "is_memo" = false ';

    for i in 1..5
        loop
            acc_cat = format('ACC_CAT%s', i);
            if i = 1 then
                q = q || ', json_build_object(';
            end if;
            if acc_cat = any (grp_by) then
                q = q || '''category' || i || ''',"category' || i || '"';
                qc = qc || 'and "category' || i || '" is not null ';
                qg = array_append(qg, '"category' || i || '"');
            else
                q = q || '''category' || i || ''', cast(null as int)';
            end if;
            if i < 5 then
                q = q || ',';
            else
                q = q || ') as "category"';
            end if;
        end loop;

    q = q || qc || 'group by ' || array_to_string(qg, ',');
    q = q || ' order by "closing" desc';

    q = q || ';';

    return query
        execute q
        USING from_date, to_date, br_ids;
end;
$account_category_report_summary$;
--##
create function account_category_report_by_group(input json)
    returns TABLE
            (
                "particulars" date,
                "amount"      float
            )
    language plpgsql
AS
$account_category_report_by_group$
declare
    from_date date  := (input ->> 'from_date')::date;
    to_date   date  := (input ->> 'to_date')::date;
    br_ids    int[] := (select array_agg(j::int)
                        from json_array_elements_text((input ->> 'branches')::json) as j);
    ac_ids    int[] := (select array_agg(j::int)
                        from json_array_elements_text((input ->> 'accounts')::json) as j);
    grp_by    text  := (input ->> 'group')::text; -- 'Day' / 'Month'
    cat1      int   := (input ->> 'category1')::int;
    cat2      int   := (input ->> 'category2')::int;
    cat3      int   := (input ->> 'category3')::int;
    cat4      int   := (input ->> 'category4')::int;
    cat5      int   := (input ->> 'category5')::int;
begin
    if grp_by is null or grp_by not in ('Day', 'Month') then
        grp_by = 'Day';
    end if;

    return query
        select date_trunc(grp_by, "date")::date                      as "part",
               ROUND(sum("acc_cat_txn"."amount")::numeric, 2)::float as "amt"
        from "acc_cat_txn"
        where ("date" between from_date and to_date)
          and "is_memo" = false
          and (case when array_length(br_ids, 1) > 0 then "branch" = any (br_ids) else true end)
          and (case when array_length(ac_ids, 1) > 0 then "account" = any (ac_ids) else true end)
          and (case when cat1 is null then true else "category1" = cat1 end)
          and (case when cat2 is null then true else "category2" = cat2 end)
          and (case when cat3 is null then true else "category3" = cat3 end)
          and (case when cat4 is null then true else "category4" = cat4 end)
          and (case when cat5 is null then true else "category5" = cat5 end)
        group by "part"
        order by "part" asc;
end;
$account_category_report_by_group$;
--##
create function account_category_report_detail(input json)
    returns table
            (
                id                UUID,
                ac_txn            UUID,
                date              date,
                account           int,
                account_name      TEXT,
                account_type      TEXT,
                branch            int,
                branch_name       TEXT,
                amount            float,
                voucher           int,
                voucher_no        TEXT,
                voucher_type      int,
                base_voucher_type TEXT,
                voucher_mode      TEXT,
                is_memo           BOOLEAN,
                ref_no            TEXT,
                category1         int,
                category1_name    TEXT,
                category2         int,
                category2_name    TEXT,
                category3         int,
                category3_name    TEXT,
                category4         int,
                category4_name    TEXT,
                category5         int,
                category5_name    TEXT
            )
    language plpgsql
AS
$account_category_report_detail$
declare
    from_date date  := (input ->> 'from_date')::date;
    to_date   date  := (input ->> 'to_date')::date;
    br_ids    int[] := (select array_agg(j::int)
                        from json_array_elements_text((input ->> 'branches')::json) as j);
    ac_ids    int[] := (select array_agg(j::int)
                        from json_array_elements_text((input ->> 'accounts')::json) as j);
    cat1      int   := (input ->> 'category1')::int;
    cat2      int   := (input ->> 'category2')::int;
    cat3      int   := (input ->> 'category3')::int;
    cat4      int   := (input ->> 'category4')::int;
    cat5      int   := (input ->> 'category5')::int;
begin

    return query
        select x.id,
               x.ac_txn,
               x.date,
               x.account,
               x.account_name,
               x.account_type,
               x.branch,
               x.branch_name,
               x.amount,
               x.voucher,
               x.voucher_no,
               x.voucher_type,
               x.base_voucher_type::text,
               x.voucher_mode::text,
               x.is_memo,
               x.ref_no,
               x.category1,
               x.category1_name,
               x.category2,
               x.category2_name,
               x.category3,
               x.category3_name,
               x.category4,
               x.category4_name,
               x.category5,
               x.category5_name
        from "acc_cat_txn" as x
        where ("x"."date" between from_date and to_date)
          and "x"."is_memo" = false
          and (case when array_length(br_ids, 1) > 0 then "x"."branch" = any (br_ids) else true end)
          and (case when array_length(ac_ids, 1) > 0 then "x"."account" = any (ac_ids) else true end)
          and (case when cat1 is null then true else "x"."category1" = cat1 end)
          and (case when cat2 is null then true else "x"."category2" = cat2 end)
          and (case when cat3 is null then true else "x"."category3" = cat3 end)
          and (case when cat4 is null then true else "x"."category4" = cat4 end)
          and (case when cat5 is null then true else "x"."category5" = cat5 end)
        order by "x"."date" asc, "x"."base_voucher_type" asc;

end;
$account_category_report_detail$;
--##
create function account_category_report_detail_summary(input json)
    returns float
    language plpgsql
AS
$account_category_report_detail_summary$
declare
    from_date date  := (input ->> 'from_date')::date;
    to_date   date  := (input ->> 'to_date')::date;
    br_ids    int[] := (select array_agg(j::int)
                        from json_array_elements_text((input ->> 'branches')::json) as j);
    ac_ids    int[] := (select array_agg(j::int)
                        from json_array_elements_text((input ->> 'accounts')::json) as j);
    cat1      int   := (input ->> 'category1')::int;
    cat2      int   := (input ->> 'category2')::int;
    cat3      int   := (input ->> 'category3')::int;
    cat4      int   := (input ->> 'category4')::int;
    cat5      int   := (input ->> 'category5')::int;
    amt       float := 0;
begin

    select coalesce(sum("x"."amount"), 0)::float
    into amt
    from "acc_cat_txn" as x
    where ("x"."date" between from_date and to_date)
      and "x"."is_memo" = false
      and (case when array_length(br_ids, 1) > 0 then "x"."branch" = any (br_ids) else true end)
      and (case when array_length(ac_ids, 1) > 0 then "x"."account" = any (ac_ids) else true end)
      and (case when cat1 is null then true else "x"."category1" = cat1 end)
      and (case when cat2 is null then true else "x"."category2" = cat2 end)
      and (case when cat3 is null then true else "x"."category3" = cat3 end)
      and (case when cat4 is null then true else "x"."category4" = cat4 end)
      and (case when cat5 is null then true else "x"."category5" = cat5 end);

    return amt;
end;
$account_category_report_detail_summary$;
--##
create function account_category_breakup(input json)
    returns table
            (
                "account"      int,
                "account_name" text,
                "account_type" text,
                "debit"        float,
                "credit"       float,
                "closing"      float
            )
    language plpgsql
AS
$account_category_breakup$
declare
    from_date date  := (input ->> 'from_date')::date;
    to_date   date  := (input ->> 'to_date')::date;
    br_ids    int[] := (select array_agg(j::int)
                        from json_array_elements_text((input ->> 'branches')::json) as j);
    ac_type   text  := (input ->> 'account_type')::text;
    cat1      int   := (input ->> 'category1')::int;
    cat2      int   := (input ->> 'category2')::int;
    cat3      int   := (input ->> 'category3')::int;
    cat4      int   := (input ->> 'category4')::int;
    cat5      int   := (input ->> 'category5')::int;
    grp_by    text  := (input ->> 'group')::text; -- 'account'/'account_type'
begin
    if grp_by = 'account' then
        return query
            (select "x"."account",
                    min("x"."account_name"),
                    min("x"."account_type"),
                    sum(case when "x"."amount" > 0 then "x"."amount" else 0 end)::float,
                    sum(case when "x"."amount" < 0 then "x"."amount" * -1 else 0 end)::float,
                    sum("x"."amount")::float
             from "acc_cat_txn" as "x"
             where ("x"."date" between from_date and to_date)
               and "x"."is_memo" = false
               and (case when array_length(br_ids, 1) > 0 then "x"."branch" = any (br_ids) else true end)
               and (case when ac_type is null then true else "x"."account_type" = ac_type end)
               and (case when cat1 is null then true else "x"."category1" = cat1 end)
               and (case when cat2 is null then true else "x"."category2" = cat2 end)
               and (case when cat3 is null then true else "x"."category3" = cat3 end)
               and (case when cat4 is null then true else "x"."category4" = cat4 end)
               and (case when cat5 is null then true else "x"."category5" = cat5 end)
             group by "x"."account");

    else
        return query
            (select null::int,
                    null::text,
                    "x"."account_type",
                    sum(case when "x"."amount" > 0 then ("x"."amount") else 0 end)::float,
                    sum(case when "x"."amount" < 0 then ("x"."amount" * -1) else 0 end)::float,
                    sum("x"."amount")::float
             from "acc_cat_txn" as "x"
             where ("x"."date" between from_date and to_date)
               and "x"."is_memo" = false
               and (case when array_length(br_ids, 1) > 0 then "x"."branch" = any (br_ids) else true end)
               and (case when ac_type is null then true else "x"."account_type" = ac_type end)
               and (case when cat1 is null then true else "x"."category1" = cat1 end)
               and (case when cat2 is null then true else "x"."category2" = cat2 end)
               and (case when cat3 is null then true else "x"."category3" = cat3 end)
               and (case when cat4 is null then true else "x"."category4" = cat4 end)
               and (case when cat5 is null then true else "x"."category5" = cat5 end)
             group by "x"."account_type");
    end if;

end;
$account_category_breakup$;