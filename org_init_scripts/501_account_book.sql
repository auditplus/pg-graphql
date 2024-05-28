create function account_book_detail(
    from_date date,
    to_date date,
    acc int,
    br_ids int[] default '{}'::int[]
)
    returns table
            (
                "date"            date,
                particulars       text,
                ref_no            text,
                voucher_type      int,
                base_voucher_type text,
                voucher           int,
                voucher_mode      text,
                voucher_no        text,
                debit             float,
                credit            float,
                branch            int,
                branch_name       text
            )
AS
$$
begin
    return query
        select min(at.date) as date,
               min(at.alt_account_name),
               min(at.ref_no),
               min(at.voucher_type),
               min(at.base_voucher_type)::TEXT,
               at.voucher,
               min(at.voucher_mode)::text,
               min(at.voucher_no),
               ROUND(sum(at.debit)::numeric, 2)::float,
               ROUND(sum(at.credit)::numeric, 2)::float,
               min(at.branch),
               min(at.branch_name)
        from ac_txn as at
        where at.account = acc
          and at.is_memo = FALSE
          and (at.date BETWEEN from_date and to_date)
          and (case when array_length(br_ids, 1) > 0 then at.branch = any (br_ids) else true end)
        group by at.voucher
        order by date,
                 at.voucher;

end;
$$ language plpgsql;
--##
create function account_closing(
    as_on_date date,
    acc int,
    br_ids int[] default '{}'::int[]
)
    returns float
    language plpgsql
AS
$account_closing$
declare
    closing float := 0.0;
begin
    select sum(debit - credit)::float
    into closing
    from account_daily_summary
    where account = acc
      and date <= as_on_date
      and (case when array_length(br_ids, 1) > 0 then branch = any (br_ids) else true end);

    return coalesce(closing, 0.0);
end;
$account_closing$;
--##
create function account_book_group(
    from_date date,
    to_date date,
    acc int,
    group_by text,
    br_ids int[] default '{}'::int[]
)
    returns table
            (
                particulars date,
                debit       float,
                credit      float
            )
    language plpgsql
AS
$account_book_group$
begin
    return query
        select cast(date_trunc(group_by, "date") as date)                    as "particulars",
               cast(ROUND(cast(sum("ads"."debit") as numeric), 2) as float)  as "debit",
               cast(ROUND(cast(sum("ads"."credit") as numeric), 2) as float) as "credit"
        from "account_daily_summary" as "ads"
        where "ads"."account" = acc
          and ("ads"."date" BETWEEN from_date and to_date)
        group by "particulars"
        order by "particulars" asc;
end;
$account_book_group$;