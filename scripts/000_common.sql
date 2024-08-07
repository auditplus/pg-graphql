create schema addon;
--##
create extension pgcrypto with schema addon;
--##
create extension pgjwt with schema addon;
--##
create extension http with schema addon;
--##
create function tgf_sync_updated_at()
    returns trigger as
$$
begin
    new.updated_at = current_timestamp;
    return new;
end;
$$ language plpgsql;
--##
create function tgf_sync_inv_item_delete()
    returns trigger as
$$
begin
    delete from inv_txn where id = old.id;
    return old;
end;
$$ language plpgsql;
--##
create function check_voucher_mode(text) returns bool as
$$
begin
    return $1 in ('ACCOUNT', 'GST', 'INVENTORY');
end
$$ language plpgsql;
--##
create function check_base_account_type(text) returns bool as
$$
begin
    return $1 in ('DIRECT_INCOME', 'INDIRECT_INCOME', 'SALE', 'DIRECT_EXPENSE', 'INDIRECT_EXPENSE',
                  'PURCHASE', 'FIXED_ASSET', 'CURRENT_ASSET', 'LONGTERM_LIABILITY', 'CURRENT_LIABILITY', 'EQUITY',
                  'STOCK', 'CASH', 'BANK_ACCOUNT', 'EFT_ACCOUNT', 'SUNDRY_DEBTOR', 'TDS_RECEIVABLE', 'BANK_OD_ACCOUNT',
                  'BRANCH_OR_DIVISION', 'SUNDRY_CREDITOR', 'TDS_PAYABLE', 'DUTIES_AND_TAXES', 'GST');
end
$$ language plpgsql;
--##
create function check_base_account_types(text[]) returns bool as
$$
begin
    return array ['DIRECT_INCOME', 'INDIRECT_INCOME', 'SALE', 'DIRECT_EXPENSE', 'INDIRECT_EXPENSE',
               'PURCHASE', 'FIXED_ASSET', 'CURRENT_ASSET', 'LONGTERM_LIABILITY', 'CURRENT_LIABILITY', 'EQUITY',
               'STOCK', 'CASH', 'BANK_ACCOUNT', 'EFT_ACCOUNT', 'SUNDRY_DEBTOR','TDS_RECEIVABLE', 'BANK_OD_ACCOUNT',
               'BRANCH_OR_DIVISION', 'SUNDRY_CREDITOR', 'TDS_PAYABLE', 'DUTIES_AND_TAXES', 'GST'] @> $1;
end
$$ language plpgsql;
--##
create function check_category_type(text) returns bool as
$$
begin
    return $1 in ('ACCOUNT', 'INVENTORY');
end
$$ language plpgsql;
--##
create function check_org_status(text) returns bool as
$$
begin
    return $1 in ('ACTIVE', 'SUSPENDED', 'DEACTIVATED');
end
$$ language plpgsql;
--##
create function check_drug_category(text) returns bool as
$$
begin
    return $1 in ('SCHEDULE_H', 'SCHEDULE_H1', 'NARCOTICS');
end
$$ language plpgsql;
--##
create function check_price_apply_on(text) returns bool as
$$
begin
    return $1 in ('ALL_INVENTORY', 'INVENTORY', 'CATEGORY', 'TAG', 'BATCH');
end
$$ language plpgsql;
--##
create function check_price_computation(text) returns bool as
$$
begin
    return $1 in ('FIXED_PRICE', 'DISCOUNT', 'LANDING_COST', 'NLC');
end
$$ language plpgsql;
--##
create function check_print_layout(text) returns bool as
$$
begin
    return $1 in ('SALE', 'CREDIT_NOTE', 'SALE_QUOTATION', 'PURCHASE', 'DEBIT_NOTE',
                  'STOCK_TRANSFER', 'BATCH', 'RACK', 'CHEQUE_BOOK', 'SETTLEMENT', 'POS_SERVER_SETTLEMENT',
                  'GIFT_VOUCHER', 'CUSTOMER_ADVANCE', 'GOODS_INWARD_NOTE', 'GIFT_VOUCHER_COUPON');
end
$$ language plpgsql;
--##
create function check_gst_reg_type(text) returns bool as
$$
begin
    return $1 in ('REGULAR', 'COMPOSITE', 'UNREGISTERED', 'IMPORT_EXPORT', 'SPECIAL_ECONOMIC_ZONE');
end
$$ language plpgsql;
--##
create function check_contact_type(text) returns bool as
$$
begin
    return $1 in ('ACCOUNT', 'CUSTOMER', 'VENDOR', 'AGENT', 'EMPLOYEE', 'TRANSPORT');
end
$$ language plpgsql;
--##
create function check_due_based_on(text) returns bool as
$$
begin
    return $1 in ('DATE', 'EFF_DATE');
end
$$ language plpgsql;
--##
create function check_offer_reward_type(text) returns bool as
$$
begin
    return $1 in ('FREE', 'DISCOUNT');
end
$$ language plpgsql;
--##
create function check_pos_mode(text) returns bool as
$$
begin
    return $1 in ('CASHIER', 'BILLING', 'NORMAL');
end
$$ language plpgsql;
--##
create function check_base_voucher_type(text) returns bool as
$$
begin
    return $1 in ('CONTRA', 'PAYMENT', 'RECEIPT', 'JOURNAL', 'SALE', 'CREDIT_NOTE', 'PURCHASE', 'DEBIT_NOTE',
                  'SALE_QUOTATION', 'STOCK_JOURNAL', 'STOCK_ADJUSTMENT', 'STOCK_DEDUCTION', 'STOCK_ADDITION',
                  'MATERIAL_CONVERSION', 'MANUFACTURING_JOURNAL', 'MEMO', 'WASTAGE', 'GOODS_INWARD_NOTE',
                  'GIFT_VOUCHER', 'PERSONAL_USE_PURCHASE', 'CUSTOMER_ADVANCE');
end
$$ language plpgsql;
--##
create function check_inventory_type(text) returns bool as
$$
begin
    return $1 in ('STANDARD', 'MULTI_VARIANT');
end
$$ language plpgsql;
--##
create function check_reorder_mode(text) returns bool as
$$
begin
    return $1 in ('FIXED', 'DYNAMIC');
end
$$ language plpgsql;
--##
create function check_batch_entry_type(text) returns bool as
$$
begin
    return $1 in ('PURCHASE', 'STOCK_ADDITION', 'MATERIAL_CONVERSION', 'OPENING');
end
$$ language plpgsql;
--##
create function check_pending_ref_type(text) returns bool as
$$
begin
    return $1 in ('NEW', 'ADJ', 'ON_ACC');
end
$$ language plpgsql;
--##
create function check_bank_txn_type(text) returns bool as
$$
begin
    return $1 in ('RTGS', 'CHEQUE', 'NEFT', 'CASH', 'ATM', 'CARD', 'E_FUND_TRANSFER', 'OTHERS');
end
$$ language plpgsql;
--##
create function check_gst_location_type(text) returns bool as
$$
begin
    return $1 in ('LOCAL', 'INTER_STATE');
end
$$ language plpgsql;
--##
create function check_gift_voucher_expiry_type(text) returns bool as
$$
begin
    return $1 in ('DAY', 'MONTH', 'YEAR');
end
$$ language plpgsql;
--##
create function check_purchase_mode(text) returns bool as
$$
begin
    return $1 in ('CASH', 'CREDIT');
end
$$ language plpgsql;