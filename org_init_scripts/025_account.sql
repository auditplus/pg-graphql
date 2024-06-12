create type typ_due_based_on as enum ('DATE', 'EFF_DATE');
--##
create table if not exists account
(
    id                       int       not null GENERATED BY default as identity (start with 101 increment by 1) primary key,
    name                     text      not null,
    account_type_id          int       not null,
    hide                     boolean   not null default false,
    is_default               boolean   not null default false,
    alias_name               text,
    gst_type                 text,
    cheque_in_favour_of      text,
    description              text,
    commission               float,
    base_account_types       text[]    not null,
    gst_reg_type             typ_gst_reg_type,
    gst_location_id          text,
    gst_no                   text,
    gst_is_exempted          boolean,
    gst_exempted_desc        text,
    sac_code                 text,
    bill_wise_detail         boolean,
    tracked                  boolean            default false,
    is_commission_discounted boolean            default false,
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
    state_id                 text,
    country_id               text,
    bank_beneficiary_id      int,
    agent_id                 int references account,
    commission_account_id    int references account,
    gst_tax_id               text,
    tds_nature_of_payment_id int,
    tds_deductee_type_id     text,
    created_at               timestamp not null default current_timestamp,
    updated_at               timestamp not null default current_timestamp,
    constraint name_min_length check (char_length(trim(name)) > 0)
);
--##
create function before_account()
    returns trigger as
$$
declare
    is_allow_account bool := true;
begin
    select allow_account, base_types
    into is_allow_account, new.base_account_types
    from account_type
    where id = new.account_type_id;
    if not is_allow_account then
        raise exception 'can not create/update account under account_type of %', new.account_type_id;
    end if;
    new.updated_at = current_timestamp;
    return new;
end;
$$ language plpgsql;
--##
create trigger sync_account
    before insert or update
    on account
    for each row
    when (not new.is_default)
execute procedure before_account();
--##
create function create_update_credit_account()
    returns trigger as
$$
declare
    deductee_type text := case when tg_table_name = 'customer' then null else new.tds_deductee_type_id end;
    acc_type      int;
begin
    if tg_op = 'INSERT' then
        if tg_table_name = 'customer' then
            select id
            into acc_type
            from account_type
            where id = new.tracking_account_type_id
              and 'SUNDRY_DEBTOR' = any (base_types);
        else
            select id
            into acc_type
            from account_type
            where id = new.tracking_account_type_id
              and 'SUNDRY_CREDITOR' = any (base_types);
        end if;
        if acc_type is null then
            raise exception 'Invalid tracking_account_type_id mapped';
        end if;
        insert into account(name, account_type_id, gst_reg_type, gst_location_id, gst_no, bill_wise_detail,
                            due_based_on, due_days, credit_limit, pan_no, aadhar_no, mobile, email, contact_person,
                            address, city, pincode, state_id, country_id, bank_beneficiary_id, agent_id, commission,
                            commission_account_id, is_commission_discounted, tds_deductee_type_id, tracked)
        values (new.name, acc_type, new.gst_reg_type, new.gst_location_id, new.gst_no, new.bill_wise_detail,
                new.due_based_on, new.due_days, new.credit_limit, new.pan_no, new.aadhar_no, new.mobile, new.email,
                new.contact_person, new.address, new.city, new.pincode, new.state_id, new.country_id,
                new.bank_beneficiary_id, new.agent_id, new.commission, new.commission_account_id,
                new.is_commission_discounted, deductee_type, true)
        returning id into new.credit_account_id;
    else
        update account
        set name                     = new.name,
            gst_reg_type             = new.gst_reg_type,
            gst_location_id          = new.gst_location_id,
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
            state_id                 = new.state_id,
            country_id               = new.country_id,
            bank_beneficiary_id      = new.bank_beneficiary_id,
            agent_id                 = new.agent_id,
            commission               = new.commission,
            tds_deductee_type_id     = deductee_type,
            is_commission_discounted = new.is_commission_discounted,
            commission_account_id    = new.commission_account_id
        where id = new.credit_account_id;
        if not FOUND then
            raise exception 'Invalid credit_account for %', new.name;
        end if;
    end if;
    return new;
end;
$$ language plpgsql security definer;