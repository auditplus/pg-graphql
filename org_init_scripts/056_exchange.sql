create table if not exists exchange
(
    voucher_id        int               not null primary key,
    voucher_no        text              not null,
    date              date              not null,
    base_voucher_type text              not null,
    account_id        int               not null,
    account_name      text              not null,
    branch_id         int               not null,
    branch_name       text              not null,
    opening           float             not null,
    adjusted          float             not null default 0.0,
    balance           float             not null generated always as (opening - adjusted) stored,
    contact_name      text,
    contact_mobile    text,
    ref_no            text,
    constraint invalid_adjustment check (balance >= 0.0),
    constraint base_voucher_type_invalid check (check_base_voucher_type(base_voucher_type))
);
--##
create function set_exchange(exchange_account int, exchange_amount float, v_branch int, v_branch_name text,
                             v_voucher_id int, v_voucher_no text, v_base_voucher_type text,
                             v_date date, v_ref_no text default null, v_exchange_detail json default null)
    returns boolean as
$$
declare
    ac_name text := (select name
                     from account
                     where id = exchange_account);
begin
    insert into exchange (voucher_id, voucher_no, date, base_voucher_type, account_id, account_name, branch_id,
                          branch_name, opening, contact_name, contact_mobile, ref_no)
    values (v_voucher_id, v_voucher_no, v_date, v_base_voucher_type, exchange_account, ac_name, v_branch, v_branch_name,
            exchange_amount, (v_exchange_detail ->> 'name')::text, (v_exchange_detail ->> 'mobile')::text, v_ref_no);
    return true;
end;
$$ language plpgsql security definer;