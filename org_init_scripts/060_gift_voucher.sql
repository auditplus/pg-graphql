create type typ_gift_voucher_expiry as enum ('DAY', 'MONTH', 'YEAR');
--##
create table if not exists gift_voucher
(
    id                      int                   not null generated always as identity primary key,
    name                    text                  not null,
    voucher_id              int                   not null,
    date                    date                  not null,
    eff_date                date,
    valid_from              date,
    valid_to                date,
    expiry                  int,
    expiry_type             typ_gift_voucher_expiry,
    branch_id               int                   not null,
    branch_name             text                  not null,
    issued                  int                   not null,
    claimed                 int                   not null default 0,
    deactivated             int                   not null default 0,
    amount                  float                 not null,
    gift_voucher_account_id int                   not null,
    party_account_id        int                   not null,
    voucher_type_id         int                   not null,
    base_voucher_type       typ_base_voucher_type not null,
    voucher_no              text                  not null,
    voucher_prefix          text                  not null,
    voucher_fy              int                   not null,
    voucher_seq             int                   not null,
    ref_no                  text,
    description             text,
    denominations           jsonb                 not null,
    created_at              timestamp             not null default current_timestamp,
    updated_at              timestamp             not null default current_timestamp,
    constraint name_min_length check (char_length(trim(name)) > 0)
);
--##
create function create_gift_voucher(
    input_data json,
    unique_session uuid default null
)
    returns gift_voucher as
$$
declare
    v_voucher      voucher;
    v_gift_voucher gift_voucher;
    input          jsonb := json_convert_case($1::jsonb, 'snake_case');
    j              json;
    val_to         date  := (input ->> 'valid_to')::date;
    iss_count      int   := (select sum((y ->> 'count')::int)
                             from jsonb_array_elements((input ->> 'denominations')::jsonb) y);
begin
    select * into v_voucher from create_voucher(input::json, $2);
    if v_voucher.base_voucher_type != 'GIFT_VOUCHER' then
        raise exception 'Allowed only GIFT_VOUCHER voucher type';
    end if;
    insert into gift_voucher(voucher_id, date, eff_date, branch_id, branch_name, issued, valid_from, valid_to, expiry,
                             expiry_type, amount, voucher_type_id, base_voucher_type, voucher_no, voucher_prefix,
                             voucher_fy, voucher_seq, ref_no, description, denominations, name, party_account_id,
                             gift_voucher_account_id)
    values (v_voucher.id, v_voucher.date, v_voucher.eff_date, v_voucher.branch_id, v_voucher.branch_name, iss_count,
            (input ->> 'valid_from')::date, (input ->> 'valid_to')::date, (input ->> 'expiry')::int,
            (input ->> 'expiry_type')::typ_gift_voucher_expiry, (input ->> 'amount')::float, v_voucher.voucher_type_id,
            v_voucher.base_voucher_type, v_voucher.voucher_no, v_voucher.voucher_prefix, v_voucher.voucher_fy,
            v_voucher.voucher_seq, v_voucher.ref_no, v_voucher.description, (input ->> 'denominations')::jsonb,
            (input ->> 'name')::text, (input ->> 'party_account_id')::int, (input ->> 'gift_voucher_account_id')::int)
    returning * into v_gift_voucher;
    if not FOUND then
        raise exception 'Internal error for insert gift_voucher';
    end if;
    if v_gift_voucher.expiry is not null and v_gift_voucher.expiry_type is not null then
        val_to := (v_gift_voucher.date + concat(v_gift_voucher.expiry, v_gift_voucher.expiry_type)::interval)::date;
    end if;
    for j in select jsonb_array_elements((input ->> 'denominations')::jsonb)
        loop
            insert into gift_coupon(name, amount, gift_voucher_id, branch_id, valid_from, valid_to,
                                    gift_voucher_account_id)
            select v_gift_voucher.name,
                   (j ->> 'amount')::float,
                   v_gift_voucher.id,
                   v_gift_voucher.branch_id,
                   v_gift_voucher.valid_from,
                   val_to,
                   v_gift_voucher.gift_voucher_account_id
            from generate_series(1, (j ->> 'count')::int);
        end loop;
    return v_gift_voucher;
end;
$$ language plpgsql;
--##
create function update_gift_voucher(
    id int,
    date date,
    ac_trns jsonb,
    eff_date date default null,
    ref_no text default null,
    description text default null,
    amount float default null
)
    returns gift_voucher as
$$
declare
    v_gift_voucher gift_voucher;
    v_voucher      voucher;
begin
    update gift_voucher
    set date        = update_gift_voucher.date,
        eff_date    = update_gift_voucher.eff_date,
        ref_no      = update_gift_voucher.ref_no,
        description = update_gift_voucher.description,
        amount      = update_gift_voucher.amount,
        ac_trns     = update_gift_voucher.ac_trns,
        updated_at  = current_timestamp
    where id = $1
    returning * into v_gift_voucher;
    select *
    into v_voucher
    from
        update_voucher(id := v_gift_voucher.voucher_id, date := v_gift_voucher.date, ref_no := v_gift_voucher.ref_no,
                       description := v_gift_voucher.description, amount := v_gift_voucher.amount,
                       ac_trns := v_gift_voucher.ac_trns, eff_date := v_gift_voucher.eff_date);
    return v_gift_voucher;
end;
$$ language plpgsql;
--##
create function delete_gift_voucher(id int)
    returns void as
$$
declare
    voucher_id int;
begin
    delete from gift_voucher where gift_voucher.id = $1 returning voucher_id into voucher_id;
    delete from voucher where voucher.id = voucher_id;
    if not FOUND then
        raise exception 'Invalid gift_voucher';
    end if;
end;
$$ language plpgsql;
--##
create function claim_gift_coupon(gift_coupons jsonb)
    returns boolean as
$$
declare
    j               json;
    gift_voucher_id int;
begin
    for j in select jsonb_array_elements(gift_coupons)
        loop
            delete
            from gift_coupon
            where id = (j ->> 'id')::int
              and gift_voucher_account_id = (j ->> 'account')::int
              and active = true
            returning gift_voucher_id into gift_voucher_id;
            if not FOUND then
                raise exception 'gift voucher coupon is invalid';
            end if;
            update gift_voucher set claimed = gift_voucher.claimed + 1 where id = gift_voucher_id;
        end loop;
    return true;
end;
$$ language plpgsql security definer;
