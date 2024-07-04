create table if not exists pos_counter_session
(
    id                      bigserial not null primary key,
    pos_counter_id          bigint    not null,
    denomination            json      not null,
    closed_by_id            bigint    not null,
    settlement_id           bigint,
    petty_cash_denomination json,
    closed_at               timestamp not null default current_timestamp
);
--##
create function after_pos_counter_session()
    returns trigger as
$$
begin
    update pos_counter_transaction_breakup
    set session_id = new.id
    where session_id is null
      and pos_counter_id = new.pos_counter_id;
    update pos_counter_transaction
    set session_id = new.id
    where session_id is null
      and pos_counter_id = new.pos_counter_id;
    return new;
end;
$$ language plpgsql security definer;
--##
create trigger after_session_insert
    after insert
    on pos_counter_session
    for each row
execute procedure after_pos_counter_session();
--##
create function close_pos_session(counter_id bigint, denomination jsonb,
                                  petty_cash_denomination jsonb default null)
    returns bool as
$$
declare
    mid   bigint := (select (x::json ->> 'id')::bigint
                     from current_setting('my.claims') x);
    input json;
begin
    if ($3 ->> 'amount')::float > 0 then
        select *
        into input
        from build_session_close_voucher_data(counter_id := $1, credit := ($3 ->> 'amount')::float);
        perform create_voucher(input::json);
    end if;
    insert into pos_counter_session (pos_counter_id, denomination, closed_by_id, petty_cash_denomination)
    values ($1, $2, mid, $3);
    if ($3 ->> 'amount')::float > 0 then
        select *
        into input
        from build_session_close_voucher_data(counter_id := $1, debit := ($3 ->> 'amount')::float);
        perform create_voucher(input::json);
    end if;
    return true;
end ;
$$ language plpgsql security definer;
--##
create function build_session_close_voucher_data(counter_id bigint, credit float default 0, debit float default 0)
    returns json as
$$
declare
    v_type_id bigint;
    cash_id   bigint;
    br_id     bigint;
    ac_trns   jsonb := '[]';
    ac_trn    jsonb;
begin
    select id into v_type_id from voucher_type where is_default and base_type = 'CONTRA';
    select id into cash_id from account where is_default and base_account_types && array ['CASH'];
    select branch_id into br_id from pos_counter where id = $1;
    ac_trn = json_build_object('account_id', cash_id, 'credit', $2, 'debit', $3);
    ac_trns = jsonb_insert(ac_trns, '{0}', ac_trn, true);
    ac_trn = json_build_object('account_id', cash_id, 'debit', $2, 'credit', $3);
    ac_trns = jsonb_insert(ac_trns, '{1}', ac_trn, true);
    return json_build_object('branch_id', br_id, 'amount', ($2 + $3), 'voucher_type_id', v_type_id,
                             'date', current_date, 'ac_trns', ac_trns, 'pos_counter_id', $1,
                             'counter_transactions', json_build_object('amount', ($3 - $2), 'particulars', 'Cash',
                                                                       'breakup', jsonb_build_array(ac_trns[0])));
end;
$$ language plpgsql security definer;