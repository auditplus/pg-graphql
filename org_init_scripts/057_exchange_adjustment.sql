create table if not exists exchange_adjustment
(
    id                bigserial         not null primary key,
    voucher_id        bigint            not null,
    exchange_id       bigint            not null,
    voucher_no        text              not null,
    base_voucher_type base_voucher_type not null,
    amount            float             not null,
    date              date              not null
);
--##
create function claim_exchange(exchange_adjs jsonb, advance_adjs jsonb, v_branch bigint, v_voucher_id bigint,
                               v_voucher_no text, v_base_voucher_type base_voucher_type, v_date date)
    returns boolean as
$$
declare
    j json;
begin
    for j in select jsonb_array_elements(exchange_adjs)
        loop
            update exchange
            set adjusted = round((exchange.adjusted + (j ->> 'amount')::float)::numeric, 2)::float
            where voucher_id = (j ->> 'id')::bigint
              and branch_id = v_branch;
            if not FOUND then
                raise exception 'Invalid exchange';
            end if;
            insert into exchange_adjustment(voucher_id, exchange_id, voucher_no, base_voucher_type, amount, date)
            values (v_voucher_id, (j ->> 'id')::bigint, v_voucher_no, v_base_voucher_type, (j ->> 'amount')::float,
                    v_date);
        end loop;
    for j in select jsonb_array_elements(advance_adjs)
        loop
            update exchange
            set adjusted = round((exchange.adjusted + (j ->> 'amount')::float)::numeric, 2)::float
            where voucher_id = (j ->> 'id')::bigint
              and branch_id = v_branch;
            if not FOUND then
                raise exception 'Invalid advance';
            end if;
            insert into exchange_adjustment (voucher_id, exchange_id, voucher_no, base_voucher_type, amount, date)
            values (v_voucher_id, (j ->> 'id')::bigint, v_voucher_no, v_base_voucher_type, (j ->> 'amount')::float,
                    v_date);
        end loop;
    return true;
end;
$$ language plpgsql security definer;