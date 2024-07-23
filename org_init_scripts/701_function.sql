create function get_inventory(int)
    returns setof vw_inventory as
$$
begin
    return query select * from vw_inventory a where a.id = $1;
end
$$ language plpgsql security definer;
--##
create function get_account_opening(account_id int, branch_id int)
    returns setof vw_account_opening
as
$$
begin
    return query select a.* from vw_account_opening a where (a.account_id, a.branch_id) = ($1, $2);
end
$$ language plpgsql security definer;
--##
create function get_inventory_opening(inventory_id int, branch_id int, warehouse_id int)
    returns setof vw_inventory_opening
as
$$
begin
    return query
        select a.* from vw_inventory_opening a where (a.inventory_id, a.branch_id, a.warehouse_id) = ($1, $2, $3);
end
$$ language plpgsql security definer;
--##
create function get_voucher(int)
    returns setof vw_voucher as
$$
begin
    return query select * from vw_voucher where id = $1;
end
$$ language plpgsql security definer;
--##
create function get_sale_bill(rid int default null, v_id int default null, v_no text default null)
    returns setof vw_sale_bill
as
$$
begin
    return query select *
                 from vw_sale_bill a
                 where case
                           when $1 is not null then a.id = $1
                           when $2 is not null then a.voucher_id = $2
                           when $3 is not null then a.voucher_no = $3
                           else false end;
end
$$ language plpgsql security definer;
--##
create function get_recent_sale_bill(rid int default null, v_id int default null)
    returns setof vw_sale_bill
as
$$
begin
    return query select *
                 from vw_sale_bill a
                 where a.date between current_date - 2 and current_date
                   and case
                           when $1 is not null then a.id = $1
                           when $2 is not null then a.voucher_id = $2
                           else false end;
end
$$ language plpgsql security definer;
--##
create function get_credit_note(rid int default null, v_id int default null)
    returns setof vw_credit_note
as
$$
begin
    return query select *
                 from vw_credit_note a
                 where case
                           when $1 is not null then a.id = $1
                           when $2 is not null then a.voucher_id = $2
                           else false end;
end
$$ language plpgsql security definer;
--##
create function get_debit_note(rid int default null, v_id int default null)
    returns setof vw_debit_note
as
$$
begin
    return query select *
                 from vw_debit_note a
                 where case
                           when $1 is not null then a.id = $1
                           when $2 is not null then a.voucher_id = $2
                           else false end;
end
$$ language plpgsql security definer;
--##
create function get_purchase_bill(rid int default null, v_id int default null)
    returns setof vw_purchase_bill
as
$$
begin
    return query select *
                 from vw_purchase_bill a
                 where case
                           when $1 is not null then a.id = $1
                           when $2 is not null then a.voucher_id = $2
                           else false end;
end
$$ language plpgsql security definer;
--##
create function get_stock_adjustment(rid int default null, v_id int default null)
    returns setof vw_stock_adjustment
as
$$
begin
    return query select *
                 from vw_stock_adjustment a
                 where case
                           when $1 is not null then a.id = $1
                           when $2 is not null then a.voucher_id = $2
                           else false end;
end
$$ language plpgsql security definer;
--##
create function get_stock_deduction(rid int default null, v_id int default null)
    returns setof vw_stock_deduction
as
$$
begin
    return query select *
                 from vw_stock_deduction a
                 where case
                           when $1 is not null then a.id = $1
                           when $2 is not null then a.voucher_id = $2
                           else false end;
end
$$ language plpgsql security definer;
--##
create function get_stock_addition(rid int default null, v_id int default null)
    returns setof vw_stock_addition
as
$$
begin
    return query select *
                 from vw_stock_addition a
                 where case
                           when $1 is not null then a.id = $1
                           when $2 is not null then a.voucher_id = $2
                           else false end;
end
$$ language plpgsql security definer;
--##
create function get_material_conversion(rid int default null, v_id int default null)
    returns setof vw_material_conversion
as
$$
begin
    return query select *
                 from vw_material_conversion a
                 where case
                           when $1 is not null then a.id = $1
                           when $2 is not null then a.voucher_id = $2
                           else false end;
end
$$ language plpgsql security definer;
--##
create function get_personal_use_purchase(rid int default null, v_id int default null)
    returns setof vw_personal_use_purchase
as
$$
begin
    return query select *
                 from vw_personal_use_purchase a
                 where case
                           when $1 is not null then a.id = $1
                           when $2 is not null then a.voucher_id = $2
                           else false end;
end
$$ language plpgsql security definer;
--##
create function get_customer_advance(rid int default null, v_id int default null)
    returns setof vw_customer_advance
as
$$
begin
    return query select *
                 from vw_customer_advance a
                 where case
                           when $1 is not null then a.id = $1
                           when $2 is not null then a.voucher_id = $2
                           else false end;
end
$$ language plpgsql security definer;
--##
create function get_goods_inward_note(rid int default null, v_id int default null)
    returns setof vw_goods_inward_note
as
$$
begin
    return query select *
                 from vw_goods_inward_note a
                 where case
                           when $1 is not null then a.id = $1
                           when $2 is not null then a.voucher_id = $2
                           else false end;
end
$$ language plpgsql security definer;
--##
create function get_gift_voucher(rid int default null, v_id int default null)
    returns setof vw_gift_voucher
as
$$
begin
    return query select *
                 from vw_gift_voucher a
                 where case
                           when $1 is not null then a.id = $1
                           when $2 is not null then a.voucher_id = $2
                           else false end;
end
$$ language plpgsql security definer;