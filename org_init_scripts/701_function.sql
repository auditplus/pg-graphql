create function get_voucher(int)
    returns setof vw_voucher as
$$
begin
    return query select * from vw_voucher where id = $1;
end
$$ language plpgsql security definer;
--##
create function get_sale_bill(rid int default null, v_id int default null)
    returns setof vw_sale_bill
as
$$
begin
    return query select *
                 from vw_sale_bill a
                 where case
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