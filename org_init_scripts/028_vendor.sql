create table if not exists vendor
(
    id                       int              not null generated always as identity primary key,
    name                     text             not null,
    short_name               text,
    pan_no                   text,
    aadhar_no                text,
    gst_reg_type             typ_gst_reg_type not null,
    gst_location_id          text,
    gst_no                   text,
        
    mobile                   text,
    alternate_mobile         text,
    email                    text,
    telephone                text,
    contact_person           text,
    address                  text,
    city                     text,
    pincode                  text,
    state_id                 text,
    country_id               text,
    bank_beneficiary_id      int,
    tracking_account         boolean          not null default false,
    tracking_account_type_id int,
    credit_account_id        int,
    agent_id                 int,
    commission_account_id    int,
    commission               float,
    is_commission_discounted boolean                   default false,
    bill_wise_detail         boolean,
    due_based_on             typ_due_based_on,
    due_days                 int,
    credit_limit             float,
    tds_deductee_type_id     text,
    created_at               timestamp        not null default current_timestamp,
    updated_at               timestamp        not null default current_timestamp,
    constraint name_min_length check (char_length(trim(name)) > 0),
    constraint pan_no_invalid check (pan_no ~ '^[a-zA-Z]{5}[0-9]{4}[a-zA-Z]$'),
    constraint aadhar_no_invalid check (aadhar_no ~ '^[2-9][0-9]{3}[0-9]{4}[0-9]{4}$'),
    constraint gst_no_invalid check (check_gst_no(gst_no))
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