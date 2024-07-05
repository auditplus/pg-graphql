create table if not exists customer_advance
(
    id                 int       not null generated always as identity primary key,
    date               date              not null,
    eff_date           date,
    branch_id          int            not null,
    branch_name        text              not null,
    base_voucher_type  base_voucher_type not null,
    voucher_type_id    int            not null,
    voucher_id         int            not null,
    voucher_no         text              not null,
    voucher_prefix     text              not null,
    voucher_fy         int               not null,
    voucher_seq        int            not null,
    advance_account_id int            not null,
    amount             float             not null,
    advance_detail     json,
    ref_no             text,
    description        text,
    created_at         timestamp         not null default current_timestamp,
    updated_at         timestamp         not null default current_timestamp
);
--##
create function create_customer_advance(input_data json, unique_session uuid default null)
    returns customer_advance as
$$
declare
    v_voucher          voucher;
    v_customer_advance customer_advance;
    _fn_res            boolean;
begin
    $1 = jsonb_set($1::jsonb, '{mode}', '"INVENTORY"');
    select * into v_voucher from create_voucher($1, $2);
    if v_voucher.base_voucher_type != 'CUSTOMER_ADVANCE' then
        raise exception 'Allowed only CUSTOMER_ADVANCE voucher type';
    end if;
    select *
    into _fn_res
    from set_exchange(exchange_account := ($1 ->> 'advance_account_id')::int,
                      exchange_amount := v_voucher.amount,
                      v_branch := v_voucher.branch_id, v_branch_name := v_voucher.branch_name,
                      v_voucher_id := v_voucher.id, v_voucher_no := v_voucher.voucher_no,
                      v_base_voucher_type := v_voucher.base_voucher_type,
                      v_date := v_voucher.date, v_ref_no := v_voucher.ref_no,
                      v_exchange_detail := ($1 ->> 'advance_detail')::json);
    if not FOUND then
        raise exception 'Internal error for set_exchange';
    end if;
    insert into customer_advance (date, eff_date, branch_id, branch_name, base_voucher_type, voucher_type_id,
                                  voucher_id, voucher_no, voucher_prefix, voucher_fy, voucher_seq, advance_account_id,
                                  amount, advance_detail, ref_no, description)
    values (v_voucher.date, v_voucher.eff_date, v_voucher.branch_id, v_voucher.branch_name, v_voucher.base_voucher_type,
            v_voucher.voucher_type_id, v_voucher.id, v_voucher.voucher_no, v_voucher.voucher_prefix,
            v_voucher.voucher_fy, v_voucher.voucher_seq, ($1 ->> 'advance_account_id')::int, v_voucher.amount,
            ($1 ->> 'advance_detail')::json, v_voucher.ref_no, v_voucher.description)
    returning * into v_customer_advance;
    return v_customer_advance;
END;
$$ language plpgsql security definer;
--##
create function update_customer_advance(v_id int, input_data json)
    returns customer_advance as
$$
declare
    v_voucher          voucher;
    v_customer_advance customer_advance;
begin
    update customer_advance
    set date           = ($2 ->> 'date')::date,
        eff_date       = ($2 ->> 'eff_date')::date,
        ref_no         = ($2 ->> 'ref_no')::text,
        description    = ($2 ->> 'description')::text,
        amount         = ($2 ->> 'amount')::float,
        advance_detail = ($2 ->> 'advance_detail')::json,
        updated_at     = current_timestamp
    where id = $1
    returning * into v_customer_advance;
    if not FOUND then
        raise exception 'customer_advance not found';
    end if;
    select *
    into v_voucher
    from
        update_voucher(v_customer_advance.voucher_id, $2);
    return v_customer_advance;
END ;
$$ language plpgsql security definer;
--##
create function delete_customer_advance(id int)
    returns void as
$$
declare
    v_id int;
begin
    delete from customer_advance where customer_advance.id = $1 returning voucher_id into v_id;
    delete from exchange where voucher_id = v_id;
    delete from voucher where voucher.id = v_id;
    if not FOUND then
        raise exception 'Invalid customer_advance';
    end if;
end;
$$ language plpgsql security definer;