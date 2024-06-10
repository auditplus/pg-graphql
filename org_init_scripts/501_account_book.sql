create or replace function account_book_detail(
    from_date date,
    to_date date,
    acc int,
    br_ids int[] default '{}'::int[]
)
returns json
AS
$$
declare
    res json;
begin
        with s1 as (select min(at.date) as date,
               min(at.alt_account_name) as alt_account_name,
               min(at.ref_no) as ref_no,
               min(at.voucher_type_id) as voucher_type_id,
               min(at.base_voucher_type)::TEXT as base_voucher_type,
               at.voucher_id as voucher_id,
               min(at.voucher_mode)::text as voucher_mode,
               min(at.voucher_no) as voucher_no,
               ROUND(sum(at.debit)::numeric, 2)::float as debit,
               ROUND(sum(at.credit)::numeric, 2)::float as credit,
               min(at.branch_id) as branch_id,
               min(at.branch_name) as branch_name
        from ac_txn as at
        where at.account_id = acc
          and at.is_memo = FALSE
          and (at.date BETWEEN from_date and to_date)
          and (case when array_length(br_ids, 1) > 0 then at.branch_id = any (br_ids) else true end)
        group by at.voucher_id
        order by date, at.voucher_id
        ),
        s2 as (select json_build_object('date', s1.date,
            'alt_account_name', s1.alt_account_name,
            'ref_no', s1.ref_no,
            'voucher_type_id', s1.voucher_type_id,
            'base_voucher_type', s1.base_voucher_type,
            'voucher_id', s1.voucher_id,
            'voucher_mode', s1.voucher_mode,
            'voucher_no', s1.voucher_no,
            'debit', s1.debit,
            'credit', s1.credit,
            'branch_id', s1.branch_id,
            'branch_name', s1.branch_name) as data
            from s1
        )
        select json_agg(s2.*) into res from s2;

    return coalesce(res,'[]'::json);
end;
$$ language plpgsql immutable security definer;
--##
create function account_closing(
    as_on_date date,
    acc int,
    br_ids int[] default '{}'::int[]
)
    returns float
AS
$$
declare
    closing float := 0.0;
begin
    select sum(debit - credit)::float
    into closing
    from account_daily_summary
    where account_id = acc
      and date <= as_on_date
      and (case when array_length(br_ids, 1) > 0 then branch_id = any (br_ids) else true end);

    return coalesce(closing, 0.0);
end;
$$ language plpgsql immutable security definer;
--##
create or replace function account_book_group(
    from_date date,
    to_date date,
    acc int,
    group_by text,
    br_ids int[] default '{}'::int[]
)
returns json
AS
$$
declare
    res json;
begin
    with s1 as (select cast(date_trunc(group_by, "date") as date)            as "particulars",
               cast(ROUND(cast(sum("ads"."debit") as numeric), 2) as float)  as "debit",
               cast(ROUND(cast(sum("ads"."credit") as numeric), 2) as float) as "credit"
    from "account_daily_summary" as "ads"
    where "ads"."account_id" = acc
      and ("ads"."date" BETWEEN from_date and to_date)
      and (case when array_length(br_ids, 1) > 0 then ads.branch_id = any (br_ids) else true end)
    group by "particulars"
    order by "particulars"),
    s2 as (select json_build_object('particulars', s1.particulars,
        'debit', s1.debit,
        'credit', s1.credit) as data
    from s1)
    select json_agg(s2.data) into res from s2;

    return coalesce(res,'[]'::json);
end;
$$ language plpgsql immutable security definer;