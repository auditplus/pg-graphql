create type typ_gst_location_type as enum ('LOCAL', 'INTER_STATE');
--##
create table if not exists gst_txn
(
    ac_txn            uuid                  not null primary key,
    date              date                  not null,
    eff_date          date,
    hsn_code          text,
    branch            int                   not null,
    branch_name       text                  not null,
    item              int,
    item_name         text,
    uqc               text                  not null default 'OTH',
    qty               float                 not null,
    party             int,
    party_name        text,
    branch_reg_type   typ_gst_reg_type      not null default 'REGULAR',
    branch_gst_no     text                  not null,
    branch_location   text                  not null,
    party_reg_type    typ_gst_reg_type,
    party_gst_no      text,
    party_location    text                  not null,
    gst_location_type typ_gst_location_type not null,
    lut               boolean                        default false,
    gst_tax           text                  not null,
    tax_name          text                  not null,
    tax_ratio         float                 not null,
    taxable_amount    float                 not null default 0,
    cgst_amount       float                 not null default 0,
    sgst_amount       float                 not null default 0,
    igst_amount       float                 not null default 0,
    cess_amount       float                 not null default 0,
    total             float                 not null default 0,
    amount            float                 not null default 0,
    voucher           int                   not null,
    voucher_no        text                  not null,
    ref_no            text,
    voucher_type      int                   not null,
    base_voucher_type typ_base_voucher_type not null,
    voucher_mode      typ_voucher_mode
);