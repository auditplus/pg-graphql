create table if not exists inv_txn
(
    id                   uuid   not null primary key,
    date                 date   not null,
    branch_id            int    not null,
    division_id          int    not null,
    division_name        text   not null,
    branch_name          text   not null,
    warehouse_id         int    not null,
    warehouse_name       text   not null,
    party_id             int,
    party_name           text,
    batch_id             int    not null,
    inventory_id         int    not null,
    reorder_inventory_id int    not null,
    inventory_name       text   not null,
    inventory_hsn        text,
    manufacturer_id      int,
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
    is_opening           boolean default false,
    inventory_voucher_id int,
    voucher_id           int,
    voucher_no           text,
    voucher_type_id      int,
    base_voucher_type    text,
    category1_id         int,
    category1_name       text,
    category2_id         int,
    category2_name       text,
    category3_id         int,
    category3_name       text,
    category4_id         int,
    category4_name       text,
    category5_id         int,
    category5_name       text,
    category6_id         int,
    category6_name       text,
    category7_id         int,
    category7_name       text,
    category8_id         int,
    category8_name       text,
    category9_id         int,
    category9_name       text,
    category10_id        int,
    category10_name      text,
    constraint base_voucher_type_invalid check (check_base_voucher_type(base_voucher_type))
);
--##
create function insert_inv_txn()
    returns trigger as
$$
begin
    update batch set inward = batch.inward + new.inward, outward = batch.outward + new.outward where id = new.batch_id;
    return new;
end;
$$ language plpgsql security definer;
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
    where id = new.batch_id;
    return new;
end;
$$ language plpgsql security definer;
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
    update batch set inward = batch.inward - old.inward, outward = batch.outward - old.outward where id = old.batch_id;
    return new;
end;
$$ language plpgsql security definer;
--##
create trigger delete_on_inv_txn
    after delete
    on inv_txn
    for each row
execute procedure delete_inv_txn();