create view purchase_register_detail
as
select id,
       date,
       branch_id,
       branch_name,
       vendor_id,
       vendor_name,
       voucher_id,
       voucher_no,
       voucher_type_id,
       base_voucher_type,
       ref_no,
       purchase_mode,
       amount
from purchase_bill
union all
select id,
       date,
       branch_id,
       branch_name,
       vendor_id,
       vendor_name,
       voucher_id,
       voucher_no,
       voucher_type_id,
       base_voucher_type,
       ref_no,
       purchase_mode,
       amount * -1
from debit_note;
--##
comment on view purchase_register_detail is e'@graphql({"primary_key_columns": ["voucher_id"]})';
--##
create function purchase_register_group(input_data json)
    returns table
            (
                particular  date,
                branch_id   int,
                branch_name text,
                amount      float
            )
as
$$
declare
    branches int[]                 := (select array_agg(j::int)
                                       from json_array_elements_text(($1 ->> 'branches')::json) as j);
    vendors  int[]                 := (select array_agg(j::int)
                                       from json_array_elements_text(($1 ->> 'vendors')::json) as j);
    view     typ_base_voucher_type := ($1 ->> 'view')::typ_base_voucher_type;
begin
    if upper($1 ->> 'group_by') not in ('MONTH', 'DAY') then
        raise exception 'invalid group_by value';
    end if;
    if view not in ('PURCHASE', 'DEBIT_NOTE') then
        raise exception 'invalid view';
    end if;
    if ($1 ->> 'group_by_branch')::bool then
        return query
            select date_trunc(($1 ->> 'group_by')::text, a.date)::date as particulars,
                   a.branch_id,
                   min(a.branch_name),
                   sum(a.amount)
            from purchase_register_detail a
            where a.date between ($1 ->> 'from_date')::date and ($1 ->> 'to_date')::date
              and case when view is not null then a.base_voucher_type = view else true end
              and case when array_length(branches, 1) > 0 then a.branch_id = any (branches) else true end
              and case when array_length(vendors, 1) > 0 then a.vendor_id = any (vendors) else true end
              and case
                      when ($1 ->> 'purchase_mode')::typ_purchase_mode is not null
                          then a.purchase_mode = ($1 ->> 'purchase_mode')::typ_purchase_mode
                      else true end
            group by particulars, a.branch_id
            order by particulars;
    else
        return query
            select date_trunc(($1 ->> 'group_by')::text, a.date)::date as particulars,
                   null::int,
                   null::text,
                   sum(a.amount)
            from purchase_register_detail a
            where a.date between ($1 ->> 'from_date')::date and ($1 ->> 'to_date')::date
              and case when view is not null then a.base_voucher_type = view else true end
              and case when array_length(branches, 1) > 0 then a.branch_id = any (branches) else true end
              and case when array_length(vendors, 1) > 0 then a.vendor_id = any (vendors) else true end
              and case
                      when ($1 ->> 'purchase_mode')::typ_purchase_mode is not null
                          then a.purchase_mode = ($1 ->> 'purchase_mode')::typ_purchase_mode
                      else true end
            group by particulars
            order by particulars;
    end if;
end;
$$ language plpgsql security definer;
--##

create function purchase_register_summary(input_data json)
    returns float as
$$
declare
    branches int[]                 := (select array_agg(j::int)
                                       from json_array_elements_text(($1 ->> 'branches')::json) as j);
    vendors  int[]                 := (select array_agg(j::int)
                                       from json_array_elements_text(($1 ->> 'vendors')::json) as j);
    view     typ_base_voucher_type := ($1 ->> 'view')::typ_base_voucher_type;
begin
    if view not in ('PURCHASE', 'DEBIT_NOTE') then
        raise exception 'invalid view';
    end if;
    return
        (select coalesce(sum(a.amount), 0)
         from purchase_register_detail a
         where date between ($1 ->> 'from_date')::date and ($1 ->> 'to_date')::date
           and case when view is not null then a.base_voucher_type = view else true end
           and case when array_length(branches, 1) > 0 then a.branch_id = any (branches) else true end
           and case when array_length(vendors, 1) > 0 then a.vendor_id = any (vendors) else true end
           and case
                   when ($1 ->> 'purchase_mode')::typ_purchase_mode is not null
                       then a.purchase_mode = ($1 ->> 'purchase_mode')::typ_purchase_mode
                   else true end);
end;
$$ language plpgsql security definer;