create table if not exists goods_inward_note
(
    id                int       not null generated always as identity primary key,
    date              date      not null,
    eff_date          date,
    vendor_id         int       not null,
    vendor_name       text      not null,
    branch_id         int       not null,
    branch_name       text      not null,
    division_id       int,
    warehouse_id      int,
    warehouse_name    text,
    amount            float,
    voucher_id        int       not null,
    voucher_type_id   int       not null,
    base_voucher_type text      not null,
    voucher_no        text      not null,
    voucher_prefix    text      not null,
    voucher_fy        int       not null,
    voucher_seq       int       not null,
    ref_no            text,
    transport_id      int,
    transport_no      text,
    transport_person  text,
    transport_date    date,
    transport_amount  float,
    no_of_bundle      int,
    city              text,
    address           text,
    pincode           text,
    state_id          text,
    description       text,
    created_at        timestamp not null default current_timestamp,
    updated_at        timestamp not null default current_timestamp,
    constraint base_voucher_type_invalid check (check_base_voucher_type(base_voucher_type))
);
--##
create view vw_goods_inward_note
as
select a.*,
       (select json_agg(row_to_json(b.*)) from vw_ac_txn b where b.voucher_id = a.voucher_id)    as ac_trns,
       (select row_to_json(c.*) from vw_account_condensed c where c.id = a.vendor_id)            as vendor,
       (select row_to_json(d.*) from vw_branch_condensed d where d.id = a.branch_id)             as branch,
       (select row_to_json(e.*) from vw_voucher_type_condensed e where e.id = a.voucher_type_id) as voucher_type,
       (select row_to_json(i.*) from vw_voucher_approval_condensed i where i.id = a.voucher_id)  as voucher,
       case
           when a.transport_id is not null then (select row_to_json(f.*)
                                                 from vw_account_condensed f
                                                 where f.id = a.transport_id) end                as transport,
       case
           when a.division_id is not null then (select row_to_json(g.*)
                                                from division g
                                                where g.id = a.division_id) end                  as division
from goods_inward_note a;
--##
create function get_goods_inward_note(rid int default null, v_id int default null)
    returns setof vw_goods_inward_note
as
$$
begin
    return query select *
                 from vw_goods_inward_note a
                 where case
                           when $1 is not null then a.id = $1
                           when $2 is not null then a.voucher_id = $2
                           else false end;
end
$$ language plpgsql security definer;
--##
create function create_goods_inward_note(input_data json, unique_session uuid default null)
    returns goods_inward_note as
$$
declare
    v_voucher           voucher;
    v_goods_inward_note goods_inward_note;
    ven                 account   := (select account
                                      from account
                                      where id = ($1 ->> 'vendor_id')::int
                                        and contact_type = 'VENDOR');
    war                 warehouse := (select warehouse
                                      from warehouse
                                      where id = ($1 ->> 'warehouse_id')::int);
begin
    $1 = jsonb_set($1::jsonb, '{mode}', '"INVENTORY"');
    select * into v_voucher from create_voucher($1, $2);
    if v_voucher.base_voucher_type != 'GOODS_INWARD_NOTE' then
        raise exception 'Allowed only GOODS_INWARD_NOTE voucher type';
    end if;
    insert into goods_inward_note(date, eff_date, vendor_id, vendor_name, branch_id, branch_name, division_id,
                                  warehouse_id, warehouse_name, amount, voucher_id, voucher_type_id, base_voucher_type,
                                  voucher_no, voucher_prefix, voucher_fy, voucher_seq, ref_no, transport_id,
                                  transport_no, transport_person, transport_date, transport_amount, no_of_bundle, city,
                                  address, pincode, state_id, description)
    values (v_voucher.date, v_voucher.eff_date, ven.id, ven.name, v_voucher.branch_id, v_voucher.branch_name,
            ($1 ->> 'division_id')::int, war.id, war.name, ($1 ->> 'amount')::float, v_voucher.id,
            v_voucher.voucher_type_id, v_voucher.base_voucher_type, v_voucher.voucher_no, v_voucher.voucher_prefix,
            v_voucher.voucher_fy, v_voucher.voucher_seq, v_voucher.ref_no, ($1 ->> 'transport_id')::int,
            ($1 ->> 'transport_no')::text, ($1 ->> 'transport_person')::text, ($1 ->> 'transport_date')::date,
            ($1 ->> 'transport_amount')::float, ($1 ->> 'no_of_bundle')::int, ($1 ->> 'city')::text,
            ($1 ->> 'address')::text, ($1 ->> 'pincode')::text, ($1 ->> 'state_id')::text, ($1 ->> 'description')::text)
    returning * into v_goods_inward_note;
    if not FOUND then
        raise exception 'Internal error for insert goods_inward_note';
    end if;
    return v_goods_inward_note;
end ;
$$ language plpgsql security definer;
--##
create function update_goods_inward_note(v_id int, input_data json)
    returns goods_inward_note as
$$
declare
    v_voucher           voucher;
    v_goods_inward_note goods_inward_note;
    ven                 account := (select account
                                    from account
                                    where id = ($2 ->> 'vendor_id')::int
                                      and contact_type = 'VENDOR');
begin

    update goods_inward_note
    set date             = ($2 ->> 'date')::date,
        eff_date         = ($2 ->> 'eff_date')::date,
        vendor_id        = ven.id,
        vendor_name      = ven.name,
        amount           = ($2 ->> 'amount')::float,
        ref_no           = ($2 ->> 'ref_no')::text,
        transport_id     = ($2 ->> 'transport_id')::int,
        transport_no     = ($2 ->> 'transport_no')::text,
        transport_person = ($2 ->> 'transport_person')::text,
        transport_date   = ($2 ->> 'transport_date')::date,
        transport_amount = ($2 ->> 'transport_amount')::float,
        no_of_bundle     = ($2 ->> 'no_of_bundle')::int,
        address          = ($2 ->> 'address')::text,
        city             = ($2 ->> 'city')::text,
        pincode          = ($2 ->> 'pincode')::text,
        state_id         = ($2 ->> 'state_id')::text,
        description      = ($2 ->> 'description')::text,
        updated_at       = current_timestamp
    where id = $1
    returning * into v_goods_inward_note;
    if not FOUND then
        raise exception 'goods_inward_note not found';
    end if;
    select * into v_voucher from update_voucher(v_goods_inward_note.voucher_id, $2);
    return v_goods_inward_note;
end;
$$ language plpgsql security definer;
--##
create function delete_goods_inward_note(id int)
    returns void as
$$
declare
    v_id int;
begin
    delete from goods_inward_note where goods_inward_note.id = $1 returning voucher_id into v_id;
    if not FOUND then
        raise exception 'goods_inward_note not found';
    end if;
    delete from voucher where voucher.id = v_id;
    if not FOUND then
        raise exception 'Invalid goods_inward_note';
    end if;
end;
$$ language plpgsql security definer;