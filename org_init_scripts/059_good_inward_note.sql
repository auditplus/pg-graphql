create table if not exists goods_inward_note
(
    id                int                   not null generated always as identity primary key,
    date              date                  not null,
    eff_date          date,
    vendor_id         int                   not null,
    branch_id         int                   not null,
    branch_name       text                  not null,
    division_id       int,
    warehouse_id      int,
    amount            float,
    voucher_id        int                   not null,
    voucher_type_id   int                   not null,
    base_voucher_type typ_base_voucher_type not null,
    voucher_no        text                  not null,
    voucher_prefix    text                  not null,
    voucher_fy        int                   not null,
    voucher_seq       int                   not null,
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
    created_at        timestamp             not null default current_timestamp,
    updated_at        timestamp             not null default current_timestamp
);
--##
create function create_goods_inward_note(
    input_data json,
    unique_session uuid default gen_random_uuid()
)
    returns goods_inward_note as
$$
declare
    v_voucher           voucher;
    v_goods_inward_note goods_inward_note;
    input               json := json_convert_case($1, 'snake_case');
begin
    select * into v_voucher from create_voucher(input, $2);
    if v_voucher.base_voucher_type != 'GOODS_INWARD_NOTE' then
        raise exception 'Allowed only GOODS_INWARD_NOTE voucher type';
    end if;
    insert into goods_inward_note(date, eff_date, vendor_id, branch_id, branch_name, division_id, warehouse_id, amount,
                                  voucher_id, voucher_type_id, base_voucher_type, voucher_no, voucher_prefix,
                                  voucher_fy, voucher_seq, ref_no, transport_id, transport_no, transport_person,
                                  transport_date, transport_amount, no_of_bundle, city, address, pincode, state_id,
                                  description)
    values (v_voucher.date, v_voucher.eff_date, (input ->> 'vendor_id')::int, v_voucher.branch_id,
            v_voucher.branch_name, (input ->> 'division_id')::int, (input ->> 'warehouse_id')::int,
            (input ->> 'amount')::int, v_voucher.id, v_voucher.voucher_type_id, v_voucher.base_voucher_type,
            v_voucher.voucher_no, v_voucher.voucher_prefix, v_voucher.voucher_fy, v_voucher.voucher_seq,
            v_voucher.ref_no, (input ->> 'transport_id')::int, (input ->> 'transport_no')::text,
            (input ->> 'transport_person')::text, (input ->> 'transport_date')::date,
            (input ->> 'transport_amount')::float, (input ->> 'no_of_bundle')::int, (input ->> 'city')::text,
            (input ->> 'address')::text, (input ->> 'pincode')::text, (input ->> 'state_id')::text,
            (input ->> 'description')::text)
    returning * into v_goods_inward_note;
    if not FOUND then
        raise exception 'Internal error for insert goods_inward_note';
    end if;
    return v_goods_inward_note;
end ;
$$ language plpgsql security definer;
--##
create function update_goods_inward_note(
    id int,
    date date,
    vendor int,
    bill_amount float,
    eff_date date default null,
    ref_no text default null,
    transport int default null,
    transport_no text default null,
    transport_person text default null,
    transport_date date default null,
    transport_amount float default null,
    no_of_bundle int default null,
    address text default null,
    city text default null,
    pincode text default null,
    state text default null,
    description text default null
)
    returns goods_inward_note as
$$
declare
    v_voucher           voucher;
    v_goods_inward_note goods_inward_note;
begin
    update goods_inward_note
    set date             = update_goods_inward_note.date,
        vendor_id        = update_goods_inward_note.vendor,
        bill_amount      = update_goods_inward_note.bill_amount,
        eff_date         = update_goods_inward_note.eff_date,
        ref_no           = update_goods_inward_note.ref_no,
        transport_id     = update_goods_inward_note.transport,
        transport_no     = update_goods_inward_note.transport_no,
        transport_person = update_goods_inward_note.transport_person,
        transport_date   = update_goods_inward_note.transport_date,
        transport_amount = update_goods_inward_note.transport_amount,
        no_of_bundle     = update_goods_inward_note.no_of_bundle,
        address          = update_goods_inward_note.address,
        city             = update_goods_inward_note.city,
        pincode          = update_goods_inward_note.pincode,
        state_id         = update_goods_inward_note.state,
        description      = update_goods_inward_note.description,
        updated_at       = current_timestamp
    where id = $1
    returning * into v_goods_inward_note;
    select *
    into v_voucher
    from
        update_voucher(id := v_goods_inward_note.voucher_id, date := update_goods_inward_note.date,
                       ref_no := update_goods_inward_note.ref_no, description := update_goods_inward_note.description,
                       amount := update_goods_inward_note.bill_amount, eff_date := update_goods_inward_note.eff_date);
    return v_goods_inward_note;
end;
$$ language plpgsql;
--##
create function delete_goods_inward_note(id int)
    returns void as
$$
declare
    voucher_id int;
begin
    delete from goods_inward_note where goods_inward_note.id = $1 returning voucher_id into voucher_id;
    if not FOUND then
        raise exception 'goods_inward_note not found';
    end if;
    delete from voucher where voucher.id = voucher_id;
    if not FOUND then
        raise exception 'Invalid goods_inward_note';
    end if;
end;
$$ language plpgsql;