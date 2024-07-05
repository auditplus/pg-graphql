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
    returns table
            (
                particulars   date,
                voucher_count bigint
            )
as
$$
declare
    branches   bigint[]                   := (select array_agg(j::bigint)
                                           from json_array_elements_text((input ->> 'branches')::json) as j);
    base_types base_voucher_type[] := (select array_agg(j::base_voucher_type)
                                           from json_array_elements_text((input ->> 'base_voucher_types')::json) as j);
begin
    if upper($1 ->> 'group_by') not in ('MONTH', 'DAY') then
        raise exception 'invalid group_by value';
    end if;
    return query
        select date_trunc((input ->> 'group_by')::text, date)::date as particulars,
               count(1)
        from voucher_register_detail
        where (date between (input ->> 'from_date')::date and (input ->> 'to_date')::date)
          and (case when array_length(branches, 1) > 0 then branch_id = ANY (branches) else true end)
          and (case
                   when array_length(base_types, 1) > 0 then base_voucher_type = ANY (base_types)
                   else true end)
          and (case
                   when input ->> 'mode' is not null then mode = (input ->> 'mode')::typ_voucher_mode
                   else true end)
        group by particulars
        order by particulars;
end;
$$ language plpgsql immutable
                    security definer;
--##
create function eligible_approval_states(mid bigint, vtype_id bigint)
    returns int[]
as
$$
declare
    _tags bigint[] := coalesce((select array_agg(id) from approval_tag where $1=any(members)),array[]::bigint[]);
    _vtype voucher_type := (select voucher_type from voucher_type where id=$2);
    _states int[] = array[]::int[];
begin
    if _vtype.approve1_id = any (_tags) then
        _states[coalesce(array_length(_states, 1), 0)] = 1;
    end if;
    if _vtype.approve2_id = any (_tags) then
        _states[coalesce(array_length(_states, 1), 0)] = 2;
    end if;
    if _vtype.approve3_id = any (_tags) then
        _states[coalesce(array_length(_states, 1), 0)] = 3;
    end if;
    if _vtype.approve4_id = any (_tags) then
        _states[coalesce(array_length(_states, 1), 0)] = 4;
    end if;
    if _vtype.approve5_id = any (_tags) then
        _states[coalesce(array_length(_states, 1), 0)] = 5;
    end if;
    return _states;
end
$$ language plpgsql security definer;
--##
create view pending_approval_voucher as
select id,
       voucher_no,
       base_voucher_type::text as base_voucher_type,
       date,
       mode::text              as mode,
       amount,
       ref_no,
       approval_state,
       voucher_type_id
from voucher
where require_no_of_approval > 0
and approval_state=any(eligible_approval_states((current_setting('my.claims')::json->>'id')::bigint, voucher.voucher_type_id));
--##
comment on view pending_approval_voucher is e'@graphql({"primary_key_columns": ["id"]})';
