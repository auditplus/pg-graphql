create table if not exists inv_txn
(
    id                   uuid   not null primary key,
    date                 date   not null,
    branch_id            bigint not null,
    division_id          bigint not null,
    division_name        text   not null,
    branch_name          text   not null,
    warehouse_id         bigint not null,
    warehouse_name       text   not null,
    party_id             bigint,
    party_name           text,
    batch_id             bigint not null,
    inventory_id         bigint not null,
    reorder_inventory_id bigint not null,
    inventory_name       text   not null,
    inventory_hsn        text,
    manufacturer_id      bigint,
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
    inventory_voucher_id bigint,
    voucher_id           bigint,
    voucher_no           text,
    voucher_type_id      bigint,
    base_voucher_type    base_voucher_type,
    category1_id         bigint,
    category1_name       text,
    category2_id         bigint,
    category2_name       text,
    category3_id         bigint,
    category3_name       text,
    category4_id         bigint,
    category4_name       text,
    category5_id         bigint,
    category5_name       text,
    category6_id         bigint,
    category6_name       text,
    category7_id         bigint,
    category7_name       text,
    category8_id         bigint,
    category8_name       text,
    category9_id         bigint,
    category9_name       text,
    category10_id        bigint,
    category10_name      text
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