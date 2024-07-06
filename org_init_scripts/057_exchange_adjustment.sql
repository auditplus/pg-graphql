create table if not exists exchange_adjustment
(
    id                int               not null generated always as identity primary key,
    voucher_id        int               not null,
    exchange_id       int               not null,
    voucher_no        text              not null,
    base_voucher_type text              not null,
    amount            float             not null,
    date              date              not null,
    constraint base_voucher_type_invalid check (check_base_voucher_type(base_voucher_type))
);
--##
create function claim_exchange(exchange_adjs jsonb, advance_adjs jsonb, v_branch int, v_voucher_id int,
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
            where voucher_id = (j ->> 'id')::int
              and branch_id = v_branch;
            if not FOUND then
                raise exception 'Invalid exchange';
            end if;
            insert into exchange_adjustment(voucher_id, exchange_id, voucher_no, base_voucher_type, amount, date)
            values (v_voucher_id, (j ->> 'id')::int, v_voucher_no, v_base_voucher_type, (j ->> 'amount')::float,
                    v_date);
        end loop;
    for j in select jsonb_array_elements(advance_adjs)
        loop
            update exchange
            set adjusted = round((exchange.adjusted + (j ->> 'amount')::float)::numeric, 2)::float
            where voucher_id = (j ->> 'id')::int
              and branch_id = v_branch;
            if not FOUND then
                raise exception 'Invalid advance';
            end if;
            insert into exchange_adjustment (voucher_id, exchange_id, voucher_no, base_voucher_type, amount, date)
            values (v_voucher_id, (j ->> 'id')::int, v_voucher_no, v_base_voucher_type, (j ->> 'amount')::float,
                    v_date);
        end loop;
    return true;
end;
$$ language plpgsql security definer;