CREATE TABLE TEMP_ACC (
  ID TEXT NOT NULL PRIMARY KEY,
  NAME TEXT,
  CONTACT_TYPE TEXT,  
  -- ACCOUNT_TYPE_ID INT,
  ACCOUNT_TYPE_NAME TEXT,
  GST_REG_TYPE TEXT,
  GST_LOCATION_ID TEXT,
  GST_NO TEXT,
  PAN_NO TEXT,
  -- BILL_WISE_DETAIL BOOL,
  -- DUE_BASED_ON TEXT,
  MOBILE TEXT,
  TELEPHONE TEXT,
  EMAIL TEXT,
  CONTACT_PERSON TEXT,
  ADDRESS TEXT,
  CITY TEXT,
  PINCODE TEXT,
  STATE_ID TEXT,
  COUNTRY_ID TEXT
);
--##
create or replace function fn_account_from_temp_acc()
returns trigger
language plpgsql
as
$$
declare
    cur_task text := '';
    ac_type_id int;
    billwisedetail bool;
    duebasedon typ_due_based_on;
begin
    begin
    cur_task = format('getting account_type_id for account_type_name: %s',new.account_type_name);
    select id into ac_type_id from account_type where name=new.account_type_name or default_name::text=new.account_type_name;
    if new.contact_type in ('VENDOR','CUSTOMER','AGENT') then
      billwisedetail=true;
      duebasedon='EFF_DATE'::typ_due_based_on;
    end if;
    cur_task = format('account type name: %s id: %s',new.account_type_name, ac_type_id);
    if ac_type_id is not null then
    cur_task = format('ac_type_id: %s, check_gst_no - %s: %s',ac_type_id, new.gst_no, check_gst_no(new.gst_no));
      if new.gst_no is not null AND check_gst_no(new.gst_no) then
          cur_task = format('gstno true, insert account id: %s', new.id);
          INSERT INTO account(NAME, ACCOUNT_TYPE_ID, CONTACT_TYPE, GST_REG_TYPE, GST_LOCATION_ID, GST_NO, PAN_NO, 
          BILL_WISE_DETAIL, DUE_BASED_ON, MOBILE, TELEPHONE, EMAIL, CONTACT_PERSON, ADDRESS, CITY, PINCODE, STATE_ID, COUNTRY_ID) VALUES 
          (new.name, ac_type_id, new.contact_type::typ_contact_type, new.gst_reg_type::typ_gst_reg_type, new.gst_location_id, new.gst_no, new.pan_no,
          billwisedetail, duebasedon, new.mobile, new.telephone, new.email, new.contact_person, new.address, new.city, new.pincode, new.state_id, new.country_id);
          delete from temp_acc where id=new.id;
      else 
          cur_task = format('gstno false, insert account id: %s', new.id);
          INSERT INTO account(NAME, ACCOUNT_TYPE_ID, CONTACT_TYPE, GST_REG_TYPE, GST_LOCATION_ID, PAN_NO, 
          BILL_WISE_DETAIL, DUE_BASED_ON, MOBILE, TELEPHONE, EMAIL, CONTACT_PERSON, ADDRESS, CITY, PINCODE, STATE_ID, COUNTRY_ID) VALUES 
          (new.name, ac_type_id, new.contact_type::typ_contact_type, new.gst_reg_type::typ_gst_reg_type, new.gst_location_id, new.pan_no, 
          billwisedetail, duebasedon, new.mobile, new.telephone, new.email, new.contact_person, new.address, new.city, new.pincode, new.state_id, new.country_id);
      end if;
    else
        raise exception '%',cur_task;
    end if;
    exception when others then
      raise exception '%',cur_task;
    end;
    return new;
end;
$$;
--##
create trigger trig_account_from_temp_acc
after insert on temp_acc
for each row
execute procedure fn_account_from_temp_acc();