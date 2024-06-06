create function sync_updated_at()
    returns trigger as
$$
begin
    new.updated_at = current_timestamp;
    return new;
end;
$$ language plpgsql;
--##
create function sync_inv_item_delete()
    returns trigger as
$$
begin
    delete from inv_txn where id = old.id;
    return old;
end;
$$ language plpgsql;
--##
create type typ_voucher_mode as enum ('ACCOUNT', 'GST', 'INVENTORY');