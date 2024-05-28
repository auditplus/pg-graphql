create function stock_journal_register_group(input json)
returns table (
    particular date,
    amount     float
)
as
$$
declare
    br_ids    int[]  := (select array_agg(j::int)
                         from json_array_elements_text((input ->> 'branches')::json) as j);
    v_types   text[] := COALESCE(
            (select array_agg(j::text)
             from json_array_elements_text((input ->> 'stock_journal_modes')::json) as j),
            ARRAY ['MATERIAL_CONVERSION', 'STOCK_DEDUCTION', 'STOCK_ADJUSTMENT', 'STOCK_ADDITION']
            );
begin
    return query
    select date_trunc((input ->> 'group')::text, date)::date as particular,
           round(sum(stock_journal_detail.amount)::numeric,2)::float
    from stock_journal_detail
    where (date between (input ->> 'from_date')::date and (input ->> 'to_date')::date)
     and (CASE when array_length(br_ids,1) > 0 then branch = ANY(br_ids) else true end)
     and (CASE when array_length(v_types,1) > 0 then base_voucher_type = ANY(v_types) else true end)
    group by particular order by particular;
end;
$$ language plpgsql;