create table if not exists gst_txn
(
    ac_txn_id          uuid              not null primary key,
    date               date              not null,
    eff_date           date,
    hsn_code           text,
    branch_id          int               not null,
    branch_name        text              not null,
    item               int,
    item_name          text,
    uqc_id             text              not null default 'OTH',
    qty                float             not null,
    party_id           int,
    party_name         text,
    branch_reg_type    text              not null default 'REGULAR',
    branch_gst_no      text              not null,
    branch_location_id text              not null,
    party_reg_type     text,
    party_gst_no       text,
    party_location_id  text              not null,
    gst_location_type  text              not null generated always as ( case
                                                                            when (branch_location_id = party_location_id)
                                                                                then 'LOCAL'
                                                                            else 'INTER_STATE' end) stored,
    lut                boolean                    default false,
    gst_tax_id         text              not null,
    tax_name           text              not null,
    tax_ratio          float             not null,
    taxable_amount     float             not null default 0,
    cgst_amount        float             not null default 0,
    sgst_amount        float             not null default 0,
    igst_amount        float             not null default 0,
    cess_amount        float             not null default 0,
    total              float             not null default 0,
    amount             float             not null default 0,
    voucher_id         int               not null,
    voucher_no         text              not null,
    ref_no             text,
    voucher_type_id    int               not null,
    base_voucher_type  text              not null,
    voucher_mode       text,
    constraint gst_location_type_invalid check (check_gst_location_type(gst_location_type)),
    constraint base_voucher_type_invalid check (check_base_voucher_type(base_voucher_type)),
    constraint voucher_mode_invalid check (check_voucher_mode(voucher_mode)),
    constraint branch_reg_type_invalid check (check_gst_reg_type(branch_reg_type)),
    constraint party_reg_type_invalid check (check_gst_reg_type(party_reg_type))
);
--##
create view vw_gst_txn_condensed
as
select ac_txn_id,
       amount,
       taxable_amount,
       hsn_code,
       gst_tax_id,
       qty,
       uqc_id
from gst_txn;