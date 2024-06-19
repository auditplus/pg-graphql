CREATE TABLE TEMP_ACC (
  ID TEXT NOT NULL PRIMARY KEY,
  NAME TEXT,
  ACCOUNT_TYPE_ID INT,
  CONTACT_TYPE TEXT,
  GST_REG_TYPE TEXT,
  GST_LOCATION_ID TEXT,
  GST_NO TEXT,
  PAN_NO TEXT,
  BILL_WISE_DETAIL BOOL,
  DUE_BASED_ON TEXT,
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
begin
    begin
    cur_task = format('check_gst_no - %s: %s',new.gst_no, check_gst_no(new.gst_no));
    if check_gst_no(new.gst_no) then 
        cur_task = format('gstno true, insert account id: %s', new.id);
        INSERT INTO account(NAME, ACCOUNT_TYPE_ID, CONTACT_TYPE, GST_REG_TYPE, GST_LOCATION_ID, GST_NO, PAN_NO, BILL_WISE_DETAIL, 
        DUE_BASED_ON, MOBILE, TELEPHONE, EMAIL, CONTACT_PERSON, ADDRESS, CITY, PINCODE, STATE_ID, COUNTRY_ID) VALUES 
        (new.name, new.account_type_id, new.contact_type::typ_contact_type, new.gst_reg_type::typ_gst_reg_type, new.gst_location_id, new.gst_no, new.pan_no, new.bill_wise_detail,
        new.due_based_on::typ_due_based_on, new.mobile, new.telephone, new.email, new.contact_person, new.address, new.city, new.pincode, new.state_id, new.country_id);
        delete from temp_acc where id=new.id;
    else 
        cur_task = format('gstno false, insert account id: %s', new.id);
        INSERT INTO account(NAME, ACCOUNT_TYPE_ID, CONTACT_TYPE, GST_REG_TYPE, GST_LOCATION_ID, PAN_NO, BILL_WISE_DETAIL, 
        DUE_BASED_ON, MOBILE, TELEPHONE, EMAIL, CONTACT_PERSON, ADDRESS, CITY, PINCODE, STATE_ID, COUNTRY_ID) VALUES 
        (new.name, new.account_type_id, new.contact_type::typ_contact_type, new.gst_reg_type::typ_gst_reg_type, new.gst_location_id, new.pan_no, new.bill_wise_detail,
        new.due_based_on::typ_due_based_on, new.mobile, new.telephone, new.email, new.contact_person, new.address, new.city, new.pincode, new.state_id, new.country_id);
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