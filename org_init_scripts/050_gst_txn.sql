create type typ_gst_location_type as enum ('LOCAL', 'INTER_STATE');
--##
create table if not exists gst_txn
(
    ac_txn_id          uuid                  not null primary key,
    date               date                  not null,
    eff_date           date,
    hsn_code           text,
    branch_id          int                   not null,
    branch_name        text                  not null,
    item               int,
    item_name          text,
    uqc_id             text                  not null default 'OTH',
    qty                float                 not null,
    party_id           int,
    party_name         text,
    branch_reg_type    typ_gst_reg_type      not null default 'REGULAR',
    branch_gst_no      text                  not null,
    branch_location_id text                  not null,
    party_reg_type     typ_gst_reg_type,
    party_gst_no       text,
    party_location_id  text                  not null,
    gst_location_type  typ_gst_location_type not null generated always as ( case
                                                              when (branch_location_id = party_location_id)
                                                                  then 'LOCAL'::typ_gst_location_type
                                                              else 'INTER_STATE'::typ_gst_location_type end) stored,
    lut                boolean                        default false,
    gst_tax_id         text                  not null,
    tax_name           text                  not null,
    tax_ratio          float                 not null,
    taxable_amount     float                 not null default 0,
    cgst_amount        float                 not null default 0,
    sgst_amount        float                 not null default 0,
    igst_amount        float                 not null default 0,
    cess_amount        float                 not null default 0,
    total              float                 not null default 0,
    amount             float                 not null default 0,
    voucher_id         int                   not null,
    voucher_no         text                  not null,
    ref_no             text,
    voucher_type_id    int                   not null,
    base_voucher_type  typ_base_voucher_type not null,
    voucher_mode       typ_voucher_mode
);