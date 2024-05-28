create type typ_due_based_on as enum ('DATE', 'EFF_DATE');
--##
create table if not exists account
(
    id                       int       not null GENERATED BY default as identity (start with 101 increment by 1) primary key,
    name                     text      not null,
    account_type             text      not null,
    hide                     boolean   not null default false,
    is_default               boolean   not null default false,
    alias_name               text,
    gst_type                 text,
    cheque_in_favour_of      text,
    description              text,
    commission               float,
    parents                  int[],
    gst_reg_type             typ_gst_reg_type,
    gst_location             text,
    gst_no                   text,
    gst_is_exempted          boolean,
    gst_exempted_desc        text,
    sac_code                 text,
    bill_wise_detail         boolean,
    tracked                  boolean default false,
    is_commission_discounted boolean default false,
    due_based_on             typ_due_based_on,
    due_days                 int,
    credit_limit             float,
    pan_no                   text,
    aadhar_no                text,
    mobile                   text,
    email                    text,
    contact_person           text,
    address                  text,
    city                     text,
    pincode                  text,
    category1                int[],
    category2                int[],
    category3                int[],
    category4                int[],
    category5                int[],
    state                    text,
    country                  text,
    bank_beneficiary         int,
    agent                    int references account,
    commission_account       int references account,
    parent                   int references account,
    gst_tax                  text,
    tds_nature_of_payment    int,
    tds_deductee_type        text,
    created_at               timestamp not null default current_timestamp,
    updated_at               timestamp not null default current_timestamp
);
--##
create trigger sync_account_updated_at
    before update
    on account
    for each row
execute procedure sync_updated_at();
--##
create function create_update_credit_account()
    returns trigger as
$$
declare
    acc_type text := 'SUNDRY_CREDITOR';
    deductee_type text;
begin
    if tg_op = 'INSERT' then
        if tg_table_name = 'customer' then
            acc_type := 'SUNDRY_DEBTOR';
        else deductee_type = new.tds_deductee_type;
        end if;
        insert into account(name, account_type, gst_reg_type, gst_location, gst_no, bill_wise_detail, due_based_on,
                            due_days, credit_limit, pan_no, aadhar_no, mobile, email, contact_person, address, city,
                            pincode, state, country, bank_beneficiary, agent, commission, commission_account,
                            is_commission_discounted, tds_deductee_type, tracked)
        values (new.name, acc_type, new.gst_reg_type, new.gst_location, new.gst_no, new.bill_wise_detail,
                new.due_based_on, new.due_days, new.credit_limit, new.pan_no, new.aadhar_no, new.mobile, new.email,
                new.contact_person, new.address, new.city, new.pincode, new.state, new.country, new.bank_beneficiary,
                new.agent, new.commission, new.commission_account, new.is_commission_discounted, deductee_type,true)
        returning id into new.credit_account;
    else
        update account
        set name                     = new.name,
            gst_reg_type             = new.gst_reg_type,
            gst_location             = new.gst_location,
            gst_no                   = new.gst_no,
            bill_wise_detail         = new.bill_wise_detail,
            due_based_on             = new.due_based_on,
            due_days                 = new.due_days,
            credit_limit             = new.credit_limit,
            pan_no                   = new.pan_no,
            aadhar_no                = new.aadhar_no,
            mobile                   = new.mobile,
            email                    = new.email,
            contact_person           = new.contact_person,
            address                  = new.address,
            city                     = new.city,
            pincode                  = new.pincode,
            state                    = new.state,
            country                  = new.country,
            bank_beneficiary         = new.bank_beneficiary,
            agent                    = new.agent,
            commission               = new.commission,
            is_commission_discounted = new.is_commission_discounted,
            commission_account       = new.commission_account
        where id = new.credit_account;
        if not FOUND then
            raise exception 'Invalid credit_account for %', new.name;
        end if;
    end if;
    return new;
end;
$$ language plpgsql;