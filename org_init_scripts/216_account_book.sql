create or replace view account_book
as
select id,
       account_id,
       date,
       alt_account_name as particular,
       ref_no,
       voucher_type_id,
       base_voucher_type,
       voucher_mode,
       voucher_no,
       voucher_id,
       branch_id,
       branch_name,
       credit,
       debit
from ac_txn where not is_memo;
--##
comment on view account_book is e'@graphql({"primary_key_columns": ["id"]})';
--##
create function account_book_group(from_date date, to_date date, acc int, group_by text, br_ids int[] default null)
    returns jsonb as
$$
begin
    return (with s1 as (select (date_trunc(group_by, ads.date)::date)                    as particulars,
                               cast(round(cast(sum(ads.debit) as numeric), 2) as float)  as debit,
                               cast(round(cast(sum(ads.credit) as numeric), 2) as float) as credit
                        from account_daily_summary as ads
                        where ads.account_id = acc
                          and (ads.date between from_date and to_date)
                          and (case when array_length(br_ids, 1) > 0 then ads.branch_id = any (br_ids) else true end)
                        group by particulars
                        order by particulars)
            select jsonb_agg(jsonb_build_object('particulars', s1.particulars, 'debit', s1.debit, 'credit', s1.credit))
            from s1);
end;
$$ language plpgsql immutable
                    security definer;
--##
create function account_closing(as_on_date date, acc int, br_ids int[] default null)
    returns float as
$$
begin
    return (select sum(debit - credit)
            from account_daily_summary
            where account_id = acc
              and date <= as_on_date
              and (case when array_length(br_ids, 1) > 0 then branch_id = any (br_ids) else true end));
end;
$$ language plpgsql immutable
                    security definer;
--##
create function account_summary(from_date date, to_date date, accounts int[] default null,
                                           branches int[] default null)
    returns table
            (
                account_id int,
                opening    float,
                closing    float,
                debit      float,
                credit     float
            )
as
$$
begin
    return query
        with b as (select a.account_id,
                          sum(a.debit - a.credit) filter (where a.date < $1)    as opening,
                          sum(a.debit - a.credit)                               as closing,
                          sum(a.debit) filter (where a.date between $1 and $2)  as debit,
                          sum(a.credit) filter (where a.date between $1 and $2) as credit
                   from account_daily_summary as a
                   where (case when array_length($3, 1) > 0 then a.account_id = any ($3) else true end)
                     and (case when array_length($4, 1) > 0 then a.branch_id = any ($4) else true end)
                     and (a.date <= $2)
                   group by a.account_id)
        select b.account_id,
               coalesce(round(b.opening::numeric, 2), 0)::float,
               coalesce(round(b.closing::numeric, 2), 0)::float,
               coalesce(round(b.debit::numeric, 2), 0)::float,
               coalesce(round(b.credit::numeric, 2), 0)::float
        from b;

end
$$ language plpgsql immutable
                    security definer;                                  