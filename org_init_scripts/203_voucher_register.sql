create view voucher_register_detail
as
select id,
       date,
       ref_no,
       voucher_type_id,
       base_voucher_type,
       mode,
       voucher_no,
       branch_id,
       branch_name,
       party_id,
       party_name,
       credit,
       debit,
       amount
from voucher;
--##
comment on view voucher_register_detail is e'@graphql({"primary_key_columns": ["id"]})';
--##
create function voucher_register_summary(input json)
    returns setof json as
$$
declare
    br_ids     int[]                   := (select array_agg(j::int)
                                           from json_array_elements_text((input ->> 'branches')::json) as j);
    base_types typ_base_voucher_type[] := (select array_agg(j::typ_base_voucher_type)
                                           from json_array_elements_text((input ->> 'baseVoucherTypes')::json) as j);
begin
    return query
        with s1 as (select date_trunc((input ->> 'group')::text, date)::date as particulars,
                           count(1)                                         as c
                    from voucher_register_detail
                    where (date between (input ->> 'fromDate')::date and (input ->> 'toDate')::date)
                      and (case when array_length(br_ids, 1) > 0 then branch_id = ANY (br_ids) else true end)
                      and (case
                               when array_length(base_types, 1) > 0 then base_voucher_type = ANY (base_types)
                               else true end)
                      and (case
                               when input ->> 'mode' is not null then mode = (input ->> 'mode')::typ_voucher_mode
                               else true end)
                    group by particulars
                    order by particulars)
        select json_build_object('particular', particulars, 'voucherCount', c)
        from s1;
end;
$$ language plpgsql immutable
                    security definer;