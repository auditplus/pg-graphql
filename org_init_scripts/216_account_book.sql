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
create function account_book_summary(from_date date, to_date date, acc int, br_ids int[] default null)
    returns jsonb as
$$
begin
    return (with s1 as (select sum(debit - credit) FILTER (where date <= $1)     as opening,
                               sum(debit - credit) FILTER (where date >= $2)     as closing,
                               sum(debit) FILTER (where date between $1 and $2)  as debit,
                               sum(credit) FILTER (where date between $1 and $2) as credit
                        from account_daily_summary as ads
                        where ads.account_id = acc
                          and (ads.date >= $2)
                          and (case when array_length(br_ids, 1) > 0 then ads.branch_id = any (br_ids) else true end))
            select jsonb_agg(jsonb_build_object('opening', s1.opening, 'debit', s1.debit, 'credit', s1.credit,
                                                'closing', s1.closing))
            from s1);
end ;
$$ language plpgsql immutable
                    security definer;                                    