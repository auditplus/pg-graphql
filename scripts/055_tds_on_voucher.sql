create table if not exists tds_on_voucher
(
    id                       uuid  not null primary key,
    date                     date  not null,
    eff_date                 date  not null,
    party_account_id         int   not null,
    party_name               text  not null,
    tds_account_id           int   not null,
    tds_nature_of_payment_id int   not null,
    tds_deductee_type_id     text  not null,
    branch_id                int   not null,
    branch_name              text  not null,
    amount                   float not null,
    tds_amount               float not null,
    tds_ratio                float not null,
    base_voucher_type        text  not null,
    voucher_no               text  not null,
    tds_section              text  not null,
    voucher_id               int   not null,
    pan_no                   text,
    ref_no                   text,
    constraint pan_no_invalid check (pan_no ~ '^[a-zA-Z]{5}[0-9]{4}[a-zA-Z]$'),
    constraint base_voucher_type_invalid check (check_base_voucher_type(base_voucher_type))
);
--##
create view vw_tds_on_voucher as
select a.voucher_id,
       a.tds_deductee_type_id,
       a.party_name,
       a.tds_ratio,
       a.tds_amount,
       a.amount,
       a.pan_no,
       a.tds_section,
       (select row_to_json(b.*) from vw_account_condensed b where b.id = a.party_account_id) as party_account,
       (select row_to_json(c.*) from vw_account_condensed c where c.id = a.tds_account_id)   as tds_account,
       (select row_to_json(d.*) from vw_tds_nature_of_payment_condensed d where d.id = a.tds_nature_of_payment_id)
                                                                                             as tds_nature_of_payment
from tds_on_voucher a;
