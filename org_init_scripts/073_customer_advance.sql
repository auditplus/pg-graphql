--##
create table if not exists customer_advance
(
    id                 int                   not null generated always as identity primary key,
    date               date                  not null,
    eff_date           date,
    branch_id          int                   not null,
    branch_name        text                  not null,
    base_voucher_type  typ_base_voucher_type not null,
    voucher_type_id    int                   not null,
    voucher_id         int                   not null,
    voucher_no         text                  not null,
    voucher_prefix     text                  not null,
    voucher_fy         int                   not null,
    voucher_seq        int                   not null,
    advance_account_id int                   not null,
    amount             float                 not null,
    advance_detail     json,
    ref_no             text,
    description        text,
    ac_trns            jsonb,
    created_at         timestamp             not null default current_timestamp,
    updated_at         timestamp             not null default current_timestamp
);
--##
create function create_customer_advance(
    date Date,
    branch int,
    voucher_type int,
    ac_trns jsonb,
    advance_account int,
    amount float,
    advance_detail json,
    eff_date Date default null,
    ref_no text default null,
    description text default null,
    unique_session uuid default gen_random_uuid()
)
    returns customer_advance as
$$
declare
    v_voucher          voucher;
    v_customer_advance customer_advance;
    _fn_res            boolean;
begin
    select *
    into v_voucher
    from
        create_voucher(date := create_customer_advance.date, branch := create_customer_advance.branch,
                       voucher_type := create_customer_advance.voucher_type,
                       ref_no := create_customer_advance.ref_no,
                       description := create_customer_advance.description, mode := 'INVENTORY',
                       amount := create_customer_advance.amount, ac_trns := create_customer_advance.ac_trns,
                       eff_date := create_customer_advance.eff_date,
                       unique_session := create_customer_advance.unique_session
        );
    if v_voucher.base_voucher_type != 'CUSTOMER_ADVANCE' THEN
        raise exception 'Allowed only CUSTOMER_ADVANCE voucher type';
    end if;
    select *
    into _fn_res
    from set_exchange(exchange_account := create_customer_advance.advance_account,
                      exchange_amount := create_customer_advance.amount,
                      v_exchange_detail := create_customer_advance.advance_detail,
                      v_branch := create_customer_advance.branch, v_branch_name := v_voucher.branch_name,
                      v_voucher_id := v_voucher.id, v_voucher_no := v_voucher.voucher_no,
                      v_base_voucher_type := v_voucher.base_voucher_type, v_date := v_voucher.date,
                      v_ref_no := v_voucher.ref_no
         );
    if not FOUND then
        raise exception 'Internal error for set_exchange';
    end if;
    insert into customer_advance (date, eff_date, branch_id, branch_name, base_voucher_type, voucher_type_id,
                                  voucher_id, voucher_no, voucher_prefix, voucher_fy, voucher_seq, advance_account_id,
                                  amount, advance_detail, ref_no, description, ac_trns)
    values (create_customer_advance.date, create_customer_advance.eff_date, create_customer_advance.branch,
            v_voucher.branch_name, v_voucher.base_voucher_type, create_customer_advance.voucher_type,
            v_voucher.id, v_voucher.voucher_no, v_voucher.voucher_prefix, v_voucher.voucher_fy, v_voucher.voucher_seq,
            create_customer_advance.advance_account, create_customer_advance.amount,
            create_customer_advance.advance_detail, create_customer_advance.ref_no, create_customer_advance.description,
            create_customer_advance.ac_trns)
    returning * into v_customer_advance;
    return v_customer_advance;
END;
$$ language plpgsql security definer;
--##
create function update_customer_advance(
    v_id int,
    date Date,
    ac_trns jsonb,
    amount float,
    eff_date Date default null,
    ref_no text default null,
    description text default null
)
    returns customer_advance as
$$
declare
    v_voucher          voucher;
    v_customer_advance customer_advance;
begin
    update customer_advance
    set date        = update_customer_advance.date,
        eff_date    = update_customer_advance.eff_date,
        ref_no      = update_customer_advance.ref_no,
        description = update_customer_advance.description,
        amount      = update_customer_advance.amount,
        ac_trns     = update_customer_advance.ac_trns,
        updated_at  = current_timestamp
    where id = $1
    returning * into v_customer_advance;
    select *
    into v_voucher
    from
        update_voucher(id := v_customer_advance.voucher_id, date := v_customer_advance.date,
                       ref_no := v_customer_advance.ref_no, description := v_customer_advance.description,
                       amount := v_customer_advance.amount, ac_trns := v_customer_advance.ac_trns,
                       eff_date := v_customer_advance.eff_date
        );
    return v_customer_advance;
END;
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