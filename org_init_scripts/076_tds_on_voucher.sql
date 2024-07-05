create table if not exists tds_on_voucher
(
    id                       uuid              not null primary key,
    date                     date              not null,
    eff_date                 date              not null,
    party_account_id         bigint            not null,
    party_name               text              not null,
    tds_account_id           bigint            not null,
    tds_nature_of_payment_id bigint            not null,
    tds_deductee_type_id     text              not null,
    branch_id                bigint            not null,
    branch_name              text              not null,
    amount                   float             not null,
    tds_amount               float             not null,
    tds_ratio                float             not null,
    base_voucher_type        base_voucher_type not null,
    voucher_no               text              not null,
    tds_section              text              not null,
    voucher_id               bigint            not null,
    pan_no                   text,
    ref_no                   text,
    constraint pan_no_invalid check (pan_no ~ '^[a-zA-Z]{5}[0-9]{4}[a-zA-Z]$')
);
--##
create function apply_tds_on_voucher(voucher, jsonb)
    returns boolean as
$$
declare
    item  tds_on_voucher;
    items tds_on_voucher[] := (select array_agg(x)
                               from jsonb_populate_recordset(
                                            null::tds_on_voucher,
                                            $2) as x);
begin
    delete from tds_on_voucher where voucher_id = $1.id;
    foreach item in array coalesce(items, array []::tds_on_voucher[])
        loop
            insert into tds_on_voucher (id, date, eff_date, party_account_id, party_name, tds_account_id, tds_ratio,
                                        tds_nature_of_payment_id, tds_deductee_type_id, branch_id, branch_name, amount,
                                        tds_amount, base_voucher_type, voucher_no, voucher_id, tds_section, ref_no)
            values (gen_random_uuid(), $1.date, coalesce($1.eff_date, $1.date), item.party_account_id, item.party_name,
                    item.tds_account_id, item.tds_ratio, item.tds_nature_of_payment_id, item.tds_deductee_type_id,
                    $1.branch_id, $1.branch_name, item.amount, item.tds_amount, $1.base_voucher_type, $1.voucher_no,
                    $1.id, item.tds_section, $1.ref_no);
        end loop;
    return true;
end;
$$ language plpgsql security definer;
