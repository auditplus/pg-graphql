create table if not exists vendor
(
    id                       int              not null generated always as identity primary key,
    name                     text             not null,
    short_name               text,
    pan_no                   text,
    aadhar_no                text,
    gst_reg_type             typ_gst_reg_type not null,
    gst_location             text,
    gst_no                   text,
    mobile                   text,
    alternate_mobile         text,
    email                    text,
    telephone                text,
    contact_person           text,
    address                  text,
    city                     text,
    pincode                  text,
    state                    text,
    country                  text,
    bank_beneficiary         int,
    tracking_account         boolean          not null default false,
    credit_account           int,
    agent                    int,
    commission_account       int,
    commission               float,
    is_commission_discounted boolean                   default false,
    bill_wise_detail         boolean,
    due_based_on             typ_due_based_on,
    due_days                 int,
    credit_limit             float,
    tds_deductee_type        text,
    created_at               timestamp        not null default current_timestamp,
    updated_at               timestamp        not null default current_timestamp
);
--##
create trigger sync_vendor_updated_at
    before
        update
    on vendor
    for each row
execute procedure sync_updated_at();
--##
create trigger create_update_vendor_account
    before insert or update
    on vendor
    for each row
    when (new.tracking_account)
execute procedure create_update_credit_account();