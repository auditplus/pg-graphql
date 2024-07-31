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
from ac_txn
where not is_memo
  and not is_opening;
--##
create function account_book_group(input_data json)
    returns table
            (
                particulars date,
                debit       float,
                credit      float
            )
as
$$
declare
    branches int[] := (select array_agg(j::int)
                       from json_array_elements_text(($1 ->> 'branches')::json) as j);
begin
    if upper($1 ->> 'group_by') not in ('MONTH', 'DAY') then
        raise exception 'invalid group_by value';
    end if;
    return query
        select (date_trunc(($1 ->> 'group_by')::text, a.date)::date) as particulars,
               round(sum(a.debit)::numeric, 2)::float,
               round(sum(a.credit)::numeric, 2)::float
        from account_daily_summary as a
        where a.account_id = ($1 ->> 'account_id')::int
          and a.date between ($1 ->> 'from_date')::date and ($1 ->> 'to_date')::date
          and case when array_length(branches, 1) > 0 then a.branch_id = any (branches) else true end
        group by particulars
        order by particulars;
end;
$$ language plpgsql immutable
                    security definer;
--##
create function account_closing(input_data json)
    returns float as
$$
declare
    branches int[] := (select array_agg(j::int)
                       from json_array_elements_text(($1 ->> 'branches')::json) as j);
begin
    return (select coalesce(round(sum(debit - credit)::numeric, 2)::float, 0)
            from account_daily_summary
            where account_id = ($1 ->> 'account_id')::int
              and date <= ($1 ->> 'as_on_date')::date
              and case when array_length(branches, 1) > 0 then branch_id = any (branches) else true end);
end;
$$ language plpgsql immutable
                    security definer;
--##                    
create function account_summary(input_data json)
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
declare
    branches int[] := (select array_agg(j::int)
                       from json_array_elements_text(($1 ->> 'branches')::json) as j);
    accounts int[] := (select array_agg(j::int)
                       from json_array_elements_text(($1 ->> 'accounts')::json) as j);
begin
    return query
        with b as (select a.account_id,
                          sum(a.debit - a.credit) filter (where a.date < ($1 ->> 'from_date')::date)            as opening,
                          sum(a.debit - a.credit)                                                               as closing,
                          sum(a.debit)
                          filter (where a.date between ($1 ->> 'from_date')::date and ($1 ->> 'to_date')::date) as debit,
                          sum(a.credit)
                          filter (where a.date between ($1 ->> 'from_date')::date and ($1 ->> 'to_date')::date) as credit
                   from account_daily_summary as a
                   where case when array_length(accounts, 1) > 0 then a.account_id = any (accounts) else true end
                     and case when array_length(branches, 1) > 0 then a.branch_id = any (branches) else true end
                     and a.date <= ($1 ->> 'to_date')::date
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
--##
create function memo_closing(input_data json)
    returns float as
$$
declare
    branches int[] := (select array_agg(j::int)
                       from json_array_elements_text(($1 ->> 'branches')::json) as j);
begin
    return (select coalesce(round(sum(a.debit - a.credit)::numeric, 2)::float, 0)
            from ac_txn a
            where date <= ($1 ->> 'as_on_date')::date
              and a.account_id = ($1 ->> 'account_id')::int
              and a.is_memo
              and case when array_length(branches, 1) > 0 then a.branch_id = any (branches) else true end);
end;
$$ language plpgsql immutable
                    security definer;
--##
create function difference_in_opening_balance(branches int[] default null)
    returns float as
$$
begin
    return (select coalesce(round(sum(a.debit - a.credit)::numeric, 2)::float, 0)
            from ac_txn a
            where a.is_opening
              and (case when array_length($1, 1) > 0 then a.branch_id = any ($1) else true end));
end;
$$ language plpgsql immutable
                    security definer;