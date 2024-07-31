create function tds_on_voucher_section_break_up(input_data json)
    returns table
            (
                section                      text,
                total                        float,
                total_tax_deducted_at_source float,
                total_after_tds_deduction    float
            )
as
$$
declare
    branches int[] := (select array_agg(j::int)
                       from json_array_elements_text(($1 ->> 'branches')::json) as j);
begin
    return query
        select a.tds_section,
               round(sum(a.amount)::numeric, 2)::float,
               round(sum(a.tds_amount)::numeric, 2)::float,
               round(sum(a.amount - a.tds_amount)::numeric, 2)::float
        from tds_on_voucher a
        where a.date between ($1 ->> 'from_date')::date and ($1 ->> 'to_date')::date
          and case
                  when array_length(branches, 1) > 0 then a.branch_id = any (branches)
                  else true end
        group by a.tds_section
        order by a.tds_section;
end;
$$ language plpgsql;