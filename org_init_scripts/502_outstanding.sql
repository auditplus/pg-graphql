create view outstanding
as
with s1 as (select pending, sum(amount) as closing
            from bill_allocation
            group by pending)
select s1.closing                 as closing,
       ba.id                      as id,
       ba.ac_txn_id               as ac_txn,
       ba.date                    as date,
       ba.eff_date                as eff_date,
       ba.is_memo                 as is_memo,
       ba.account_id              as account,
       ba.account_name            as account_name,
       ba.base_account_types      as base_account_types,
       ba.agent_id                as agent,
       ba.agent_name              as agent_name,
       ba.branch_id               as branch,
       ba.branch_name             as branch_name,
       ba.amount                  as amount,
       ba.pending                 as pending,
       ba.ref_type::text          as ref_type,
       ba.base_voucher_type::text as base_voucher_type,
       ba.voucher_mode::text      as voucher_mode,
       ba.ref_no                  as ref_no,
       ba.voucher_no              as voucher_no,
       ba.voucher_id              as voucher,
       ba.updated_at              as updated_at
from bill_allocation as ba
         left join s1 on ba.pending = s1.pending
where ba.is_memo = false
  and s1.closing <> 0;