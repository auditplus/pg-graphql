create view sale_register_detail
as
select id,
       date,
       branch_id,
       branch_name,
       voucher_type_id,
       base_voucher_type,
       voucher_id,
       voucher_no,
       customer_id,
       customer_name,
       ref_no,
       amount,
       cash_amount,
       credit_amount,
       bank_amount,
       eft_amount,
       gift_voucher_amount
from sale_bill
union all
select id,
       date,
       branch_id,
       branch_name,
       voucher_type_id,
       base_voucher_type,
       voucher_id,
       voucher_no,
       customer_id,
       customer_name,
       ref_no,
       (amount * -1),
       (cash_amount * -1),
       (credit_amount * -1),
       (bank_amount * -1),
       0::float,
       0::float
from credit_note;
--##
create function sale_register_summary(input_data json)
    returns table
            (
                amount              float,
                cash_amount         float,
                bank_amount         float,
                credit_amount       float,
                eft_amount          float,
                gift_voucher_amount float
            )
as
$$
declare
    branches      int[] := (select array_agg(j::int)
                               from json_array_elements_text(($1 ->> 'branches')::json) as j);
    customers     int[] := (select array_agg(j::int)
                               from json_array_elements_text(($1 ->> 'customers')::json) as j);
    payment_modes text[]   := (select array_agg(j::text)
                               from json_array_elements_text(($1 ->> 'payment_modes')::json) as j);
begin
    if ($1 ->> 'view')::text not in ('SALE', 'CREDIT_NOTE', 'BOTH') then
        raise exception 'invalid view';
    end if;
    return query
        select sum(a.amount),
               sum(a.cash_amount),
               sum(a.bank_amount),
               sum(a.credit_amount),
               sum(a.eft_amount),
               sum(a.gift_voucher_amount)
        from sale_register_detail a
        where date between ($1 ->> 'from_date')::date and ($1 ->> 'to_date')::date
          and case
                  when ($1 ->> 'view')::text = 'BOTH' then true
                  else a.base_voucher_type = ($1 ->> 'view')::text end
          and case when array_length(branches, 1) > 0 then a.branch_id = any (branches) else true end
          and case when array_length(customers, 1) > 0 then a.customer_id = any (customers) else true end
          and case
                  when array_length(payment_modes, 1) > 0 then (
                      (case when 'CASH' = any (payment_modes) then (a.cash_amount <> 0) else false end)
                          or (case when 'CREDIT' = any (payment_modes) then (a.credit_amount <> 0) else false end)
                          or (case when 'EFT' = any (payment_modes) then (a.eft_amount <> 0) else false end)
                          or (case when 'BANK' = any (payment_modes) then (a.bank_amount <> 0) else false end)
                          or (case when 'GIFT' = any (payment_modes) then (a.gift_voucher_amount <> 0) else false end)
                      )
                  else true end;
end ;
$$ language plpgsql security definer;
--##
create function sale_register_group(input_data json)
    returns table
            (
                particular          date,
                branch_id           int,
                branch_name         text,
                amount              float,
                cash_amount         float,
                bank_amount         float,
                credit_amount       float,
                eft_amount          float,
                gift_voucher_amount float
            )
as
$$
declare
    branches      int[] := (select array_agg(j::int)
                               from json_array_elements_text(($1 ->> 'branches')::json) as j);
    customers     int[] := (select array_agg(j::int)
                               from json_array_elements_text(($1 ->> 'customers')::json) as j);
    payment_modes text[]   := (select array_agg(j::text)
                               from json_array_elements_text(($1 ->> 'payment_modes')::json) as j);
begin
    if upper($1 ->> 'group_by') not in ('MONTH', 'DAY') then
        raise exception 'invalid group_by value';
    end if;
    if ($1 ->> 'view')::text not in ('SALE', 'CREDIT_NOTE', 'BOTH') then
        raise exception 'invalid view';
    end if;
    if ($1 ->> 'group_by_branch')::bool then
        return query
            select date_trunc(($1 ->> 'group_by')::text, a.date)::date as particulars,
                   a.branch_id,
                   min(a.branch_name),
                   sum(a.amount),
                   sum(a.cash_amount),
                   sum(a.bank_amount),
                   sum(a.credit_amount),
                   sum(a.eft_amount),
                   sum(a.gift_voucher_amount)
            from sale_register_detail a
            where date between ($1 ->> 'from_date')::date and ($1 ->> 'to_date')::date
              and case
                      when ($1 ->> 'view')::text = 'BOTH' then true
                      else a.base_voucher_type = ($1 ->> 'view')::text end
              and case when array_length(branches, 1) > 0 then a.branch_id = any (branches) else true end
              and case when array_length(customers, 1) > 0 then a.customer_id = any (customers) else true end
              and case
                      when array_length(payment_modes, 1) > 0 then (
                          (case when 'CASH' = any (payment_modes) then (a.cash_amount <> 0) else false end)
                              or (case when 'CREDIT' = any (payment_modes) then (a.credit_amount <> 0) else false end)
                              or (case when 'EFT' = any (payment_modes) then (a.eft_amount <> 0) else false end)
                              or (case when 'BANK' = any (payment_modes) then (a.bank_amount <> 0) else false end)
                              or
                          (case when 'GIFT' = any (payment_modes) then (a.gift_voucher_amount <> 0) else false end)
                          )
                      else true end
            group by particulars, a.branch_id
            order by particulars;
    else
        return query
            select date_trunc(($1 ->> 'group_by')::text, a.date)::date as particulars,
                   null::int,
                   null::text,
                   sum(a.amount),
                   sum(a.cash_amount),
                   sum(a.bank_amount),
                   sum(a.credit_amount),
                   sum(a.eft_amount),
                   sum(a.gift_voucher_amount)
            from sale_register_detail a
            where date between ($1 ->> 'from_date')::date and ($1 ->> 'to_date')::date
              and case
                      when ($1 ->> 'view')::text = 'BOTH' then true
                      else a.base_voucher_type = ($1 ->> 'view')::text end
              and case when array_length(branches, 1) > 0 then a.branch_id = any (branches) else true end
              and case when array_length(customers, 1) > 0 then a.customer_id = any (customers) else true end
              and case
                      when array_length(payment_modes, 1) > 0 then (
                          (case when 'CASH' = any (payment_modes) then (a.cash_amount <> 0) else false end)
                              or (case when 'CREDIT' = any (payment_modes) then (a.credit_amount <> 0) else false end)
                              or (case when 'EFT' = any (payment_modes) then (a.eft_amount <> 0) else false end)
                              or (case when 'BANK' = any (payment_modes) then (a.bank_amount <> 0) else false end)
                              or
                          (case when 'GIFT' = any (payment_modes) then (a.gift_voucher_amount <> 0) else false end)
                          )
                      else true end
            group by particulars
            order by particulars;
    end if;
end;
$$ language plpgsql security definer;