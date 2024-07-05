create view stock_journal_detail
as
select id,
       date,
       branch_id,
       branch_name,
       ref_no,
       amount,
       voucher_id,
       voucher_no,
       voucher_type_id,
       base_voucher_type
from material_conversion
union all
select id,
       date,
       branch_id,
       branch_name,
       ref_no,
       amount,
       voucher_id,
       voucher_no,
       voucher_type_id,
       base_voucher_type
from stock_deduction
union all
select id,
       date,
       branch_id,
       branch_name,
       ref_no,
       amount,
       voucher_id,
       voucher_no,
       voucher_type_id,
       base_voucher_type
from stock_adjustment
union all
select id,
       date,
       branch_id,
       branch_name,
       ref_no,
       amount,
       voucher_id,
       voucher_no,
       voucher_type_id,
       base_voucher_type
from stock_addition;
--##
comment on view stock_journal_detail is e'@graphql({"primary_key_columns": ["voucher_id"]})';
--##
create function stock_journal_register_group(input_data json)
    returns table
            (
                particulars date,
                amount      float
            )
as
$$
declare
    branches            int[] := (select array_agg(j::int)
                                     from json_array_elements_text(($1 ->> 'branches')::json) as j);
    stock_journal_types text[]   := (select array_agg(j::text)
                                     from json_array_elements_text(($1 ->> 'stock_journal_modes')::json) as j);
begin
    if upper($1 ->> 'group_by') not in ('MONTH', 'DAY') then
        raise exception 'invalid group_by value';
    end if;
    if not (stock_journal_types <@
            array ['STOCK_ADJUSTMENT','STOCK_DEDUCTION','STOCK_ADDITION','MATERIAL_CONVERSION']::text[]) then
        raise exception 'invalid stock journal type';
    end if;
    return query
        select date_trunc(($1 ->> 'group_by')::text, a.date)::date as particulars, sum(a.amount)
        from stock_journal_detail a
        where a.date between ($1 ->> 'from_date')::date and ($1 ->> 'to_date')::date
          and case when array_length(branches, 1) > 0 then a.branch_id = any (branches) else true end
          and case
                  when array_length(stock_journal_types, 1) > 0 then a.base_voucher_type = any (stock_journal_types)
                  else true end
        group by particulars
        order by particulars;
end;
$$ language plpgsql security definer
                    immutable;
--##
create function stock_journal_register_summary(input_data json)
    returns float as
$$
declare
    branches            int[] := (select array_agg(j::int)
                                     from json_array_elements_text(($1 ->> 'branches')::json) as j);
    stock_journal_types text[]   := (select array_agg(j::text)
                                     from json_array_elements_text(($1 ->> 'stock_journal_modes')::json) as j);
begin
    if not (stock_journal_types <@
            array ['STOCK_ADJUSTMENT','STOCK_DEDUCTION','STOCK_ADDITION','MATERIAL_CONVERSION']::text[]) then
        raise exception 'invalid stock journal type';
    end if;
    return
        (select coalesce(sum(a.amount), 0)
         from stock_journal_detail a
         where a.date between ($1 ->> 'from_date')::date and ($1 ->> 'to_date')::date
           and case when array_length(branches, 1) > 0 then a.branch_id = any (branches) else true end
           and case
                   when array_length(stock_journal_types, 1) > 0 then a.base_voucher_type = any (stock_journal_types)
                   else true end);
end;
$$ language plpgsql security definer
                    immutable;