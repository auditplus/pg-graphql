create view inventory_book
as
select id,
       inventory_id,
       date,
       party_name as particular,
       ref_no,
       voucher_type_id,
       base_voucher_type,
       inventory_voucher_id,
       voucher_id,
       voucher_no,
       branch_id,
       branch_name,
       inward,
       outward
from inv_txn where not is_opening;
--##
comment on view inventory_book is e'@graphql({"primary_key_columns": ["id"]})';
--##
create function inventory_book_group(from_date date, to_date date, inventory_id int, group_by text,
                                     branches int[] default null)
    returns jsonb as
$$
begin
    return (with s1 as (select (date_trunc($4, date)::date)                           as particulars,
                               cast(round(cast(sum(inward) as numeric), 4) as float)  as inward,
                               cast(round(cast(sum(outward) as numeric), 4) as float) as outward
                        from inv_txn
                        where inv_txn.inventory_id = $3
                          and (date between $1 and $2)
                          and (case when array_length($5, 1) > 0 then branch_id = any ($5) else true end)
                        group by particulars
                        order by particulars)
            select jsonb_agg(jsonb_build_object('particulars', s1.particulars, 'inward', s1.inward, 'outward',
                                                s1.outward))
            from s1);
end;
$$ language plpgsql immutable
                    security definer;
--##
create function inventory_book_summary(from_date date, to_date date, inventory_id int, branches int[] default null)
    returns json as
$$
begin
    return (with s1 as (select sum(inward - outward) filter (where date <= $1)    as opening,
                               sum(inward) filter (where date between $1 and $2)  as inward,
                               sum(outward) filter (where date between $1 and $2) as outward
                        from inv_txn
                        where inv_txn.inventory_id = $3
                          and (date <= $2)
                          and (case when array_length($4, 1) > 0 then branch_id = any ($4) else true end))
            select jsonb_build_object('opening', s1.opening, 'inward', s1.inward, 'outward', s1.outward,
                                      'closing', coalesce(s1.opening, 0) + (s1.inward - s1.outward))
            from s1);
end;
$$ language plpgsql immutable
                    security definer; 