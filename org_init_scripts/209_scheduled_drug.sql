create function scheduled_drug(branch int, dt date, durgs text[] default null)
    returns table
            (
                id            int,
                date          date,
                voucher_no    text,
                branch_name   text,
                customer_name text,
                doctor_name   text,
                delivery_info json,
                items         jsonb
            )
as
$$
begin
    return query
        select sale_bill.id,
               sale_bill.date,
               sale_bill.voucher_no,
               sale_bill.branch_name,
               sale_bill.customer_name,
               min(doc.name),
               sale_bill.delivery_info,
               jsonb_agg(json_build_object('inventory_name', bat.inventory_name, 'batch_no', bat.batch_no, 'expiry',
                                           bat.expiry, 'qty', sbii.qty, 'drugs', sbii.drugs)) as items
        from sale_bill
                 left join sale_bill_inv_item sbii on sale_bill.id = sbii.sale_bill_id
                 left join batch bat on sbii.batch_id = bat.id
                 left join doctor doc on doc.id = sale_bill.doctor_id
        where sale_bill.branch_id = $1
          and sale_bill.date = $2
          and case
                  when (array_length($3, 1) > 0) then sbii.drugs @> $3::typ_drug_category[]
                  else sbii.drugs is not null end
        group by sale_bill.id
        order by sale_bill.id;
end;
$$ language plpgsql;