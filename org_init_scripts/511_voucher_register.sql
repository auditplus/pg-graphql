create function voucher_register(input json)
    returns table
            (
                voucher           int,
                date              date,
                particular        text,
                ref_no            text,
                voucher_type      int,
                base_voucher_type text,
                voucher_mode      text,
                voucher_no        text,
                credit            float,
                debit             float,
                branch            int,
                branch_name       text
            )
    language plpgsql
AS
$voucher_register$
declare
    br_ids     int[]                   := (select array_agg(j::int)
                                           from json_array_elements_text((input ->> 'branches')::json) as j);
    base_types typ_base_voucher_type[] := (select array_agg(j::typ_base_voucher_type)
                                           from json_array_elements_text((input ->> 'base_voucher_types')::json) as j);
begin
    return query
        select voucher.id,
               voucher.date,
               account.name,
               voucher.ref_no,
               voucher.voucher_type,
               voucher.base_voucher_type::text,
               voucher.mode::text,
               voucher.voucher_no,
               COALESCE((voucher.ac_trns[0] ->> 'debit')::float, voucher.amount, 0),
               COALESCE((voucher.ac_trns[0] ->> 'credit')::float, 0),
               voucher.branch,
               voucher.branch_name
        from voucher
                 left join account ON ((voucher.ac_trns[0] ->> 'account')::int) = account.id
        where (voucher.date BETWEEN (input ->> 'from_date')::date and (input ->> 'to_date')::date)
          and (CASE when array_length(br_ids, 1) > 0 then voucher.branch = ANY (br_ids) else true end)
          and (CASE
                   when array_length(base_types, 1) > 0 then voucher.base_voucher_type = ANY (base_types)
                   else true end)
          and (CASE
                   when input ->> 'mode' is not null then voucher.mode = (input ->> 'mode')::typ_voucher_mode
                   else true end)
        order by date ASC, id ASC;
end;
$voucher_register$;
--##
create function voucher_register_summary(input json)
    returns table
            (
                particular    date,
                voucher_count bigint
            )
    language plpgsql
AS
$voucher_register_summary$
declare
    br_ids     int[]                   := (select array_agg(j::int)
                                           from json_array_elements_text((input ->> 'branches')::json) as j);
    base_types typ_base_voucher_type[] := (select array_agg(j::typ_base_voucher_type)
                                           from json_array_elements_text((input ->> 'base_voucher_types')::json) as j);
begin
    return query
        select date_trunc((input ->> 'group')::text, date)::date as particular,
               COUNT(id)
        from voucher
        where (voucher.date BETWEEN (input ->> 'from_date')::date and (input ->> 'to_date')::date)
          and (CASE when array_length(br_ids, 1) > 0 then voucher.branch = ANY (br_ids) else true end)
          and (CASE
                   when array_length(base_types, 1) > 0 then voucher.base_voucher_type = ANY (base_types)
                   else true end)
          and (CASE
                   when input ->> 'mode' is not null then voucher.mode = (input ->> 'mode')::typ_voucher_mode
                   else true end)
        group by particular
        order by particular ASC;
end;
$voucher_register_summary$;