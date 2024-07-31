create index ac_txn_account_id_date on ac_txn (account_id, date);
--##
create index ac_txn_account_id on ac_txn (account_id);
--##
create index ac_txn_account_id_branch_id on ac_txn (account_id, branch_id);
--##
create index ac_txn_voucher_id on ac_txn (voucher_id);
--##
create index bill_allocation_ac_txn_id on bill_allocation (ac_txn_id);
--##
create index bank_txn_ac_txn_id on bank_txn (ac_txn_id);
--##
create index acc_cat_txn_ac_txn_id on acc_cat_txn (ac_txn_id);
--##
create index batch_barcode on batch (barcode);