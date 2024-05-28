create table if not exists inv_txn
(
    id                   uuid not null primary key,
    date                 date not null,
    branch               int  not null,
    division             int  not null,
    division_name        text not null,
    branch_name          text not null,
    warehouse            int  not null,
    warehouse_name       text not null,
    customer             int,
    customer_name        text,
    vendor               int,
    vendor_name          text,
    batch                int  not null,
    inventory            int  not null,
    reorder_inventory    int  not null,
    inventory_name       text not null,
    inventory_hsn        text,
    manufacturer         int,
    manufacturer_name    text,
    inward               float   default 0,
    outward              float   default 0,
    nlc                  float,
    cost                 float,
    sale_taxable_amount  float,
    sale_tax_amount      float,
    taxable_amount       float,
    asset_amount         float,
    cgst_amount          float,
    sgst_amount          float,
    igst_amount          float,
    cess_amount          float,
    ref_no               text,
    schedule_h           boolean,
    schedule_h1          boolean,
    narcotics            boolean,
    is_opening           boolean default false,
    inventory_voucher_id int,
    voucher              int,
    voucher_no           text,
    voucher_type         int,
    base_voucher_type    typ_base_voucher_type,
    category1            int,
    category1_name       text,
    category2            int,
    category2_name       text,
    category3            int,
    category3_name       text,
    category4            int,
    category4_name       text,
    category5            int,
    category5_name       text,
    category6            int,
    category6_name       text,
    category7            int,
    category7_name       text,
    category8            int,
    category8_name       text,
    category9            int,
    category9_name       text,
    category10           int,
    category10_name      text
);
--##
create function insert_inv_txn()
    returns trigger as
$$
begin
    update batch set inward = batch.inward + new.inward, outward = batch.outward + new.outward where id = new.batch;
    return new;
end;
$$ language plpgsql;
--##
create trigger insert_on_inv_txn
    after insert
    on inv_txn
    for each row
execute procedure insert_inv_txn();
--##
create function update_inv_txn()
    returns trigger as
$$
begin
    update batch
    set inward  = batch.inward + new.inward - old.inward,
        outward = batch.outward + new.outward - old.outward
    where id = new.batch;
    return new;
end;
$$ language plpgsql;
--##
create trigger update_on_inv_txn
    after update
    on inv_txn
    for each row
execute procedure update_inv_txn();
--##
create function delete_inv_txn()
    returns trigger as
$$
begin
    delete from batch where txn_id = old.id;
    update batch set inward = batch.inward - old.inward, outward = batch.outward - old.outward where id = old.batch;
    return new;
end;
$$ language plpgsql;
--##
create trigger delete_on_inv_txn
    after delete
    on inv_txn
    for each row
execute procedure delete_inv_txn();