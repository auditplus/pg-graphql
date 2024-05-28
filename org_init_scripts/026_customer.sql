create table if not exists customer
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
    delivery_address         jsonb,
    tracking_account         boolean          not null default false,
    enable_loyalty_point     boolean          not null default false,
    loyalty_point            float,
    credit_account           int,
    agent                    int,
    commission_account       int,
    commission               float,
    is_commission_discounted boolean                   default false,
    bill_wise_detail         boolean,
    tags                     int[],
    due_based_on             typ_due_based_on,
    due_days                 int,
    credit_limit             float,
    created_at               timestamp        not null default current_timestamp,
    updated_at               timestamp        not null default current_timestamp
);
--##
create trigger sync_customer_updated_at
    before update
    on customer
    for each row
execute procedure sync_updated_at();
--##
create trigger create_update_customer_account
    before insert or update
    on customer
    for each row
    when (new.tracking_account)
execute procedure create_update_credit_account();