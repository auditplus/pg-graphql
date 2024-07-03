use crate::common::{execute_stmt, perform_queries, sql_prepared};
use sea_orm::{ConnectionTrait, DbErr, FromQueryResult, JsonValue, TransactionTrait};
use serde_json::json;

mod common;

#[tokio::test]
async fn test_account_default() -> Result<(), DbErr> {
    let db = common::setup().await;
    let txn = db.begin().await?;
    common::login(&txn, "admin".to_string(), "1".to_string()).await;
    let sql = "select count(*) as count from account";
    let out = execute_stmt(&txn, sql).await?;
    let exp = vec![json!({
        "count": 17
    })];
    assert_eq!(exp, out);
    Ok(())
}

#[tokio::test]
async fn test_insert_division() -> Result<(), DbErr> {
    let txn = common::setup().await.begin().await?;
    common::login(&txn, "admin".to_string(), "1".to_string()).await;
    let sql = "insert into division (name) values ('supermarket') returning name";
    let out = execute_stmt(&txn, sql).await?;
    let exp = vec![json!({
        "name":  "supermarket"
    })];
    assert_eq!(exp, out);
    Ok(())
}

#[tokio::test]
async fn test_insert_sale() -> Result<(), DbErr> {
    let txn = common::setup().await.begin().await?;
    common::login(&txn, "admin".to_string(), "1".to_string()).await;
    let sql = r"
    do $$
    declare
        _unit_id int;
        _division_id int;
        _inventory_id int;
        _gst_tax_id text = 'gst12';
        _branch_account_type_id int = (select id from account_type where default_name = 'BRANCH_OR_DIVISION' limit 1);
        _branch_account_id int;
        _gst_registration_id int;
        _branch_id int;
    begin
        insert into unit (name, symbol, uqc_id, precision) values ('Pcs', 'Pcs', 'PCS', 0) returning id into _unit_id;
        insert into division (name) values ('Supermarket') returning id into _division_id;
        insert into inventory (name, unit_id, division_id, gst_tax_id) values ('Vicks candy', _unit_id, _division_id, _gst_tax_id) returning id into _inventory_id;
        insert into account (name, account_type_id, contact_type) values ('Main branch account', _branch_account_type_id, 'ACCOUNT') returning id into _branch_account_id;
        insert into gst_registration (gst_no, reg_type, state_id) values ('33AAACH7409R1Z8', 'REGULAR', 33) returning id into _gst_registration_id;
        insert into branch (name, voucher_no_prefix, account_id) values ('Main branch', 'MB', _branch_account_id) returning id into _branch_id;
        if _branch_id = 23 then
            raise exception 'Test failure';
        end if;
    end
    $$;
    ";
    let res = txn.execute_unprepared(sql).await;
    assert_eq!(true, res.is_ok());
    // assert!(true, "{}", res.is_ok());
    Ok(())
}

#[tokio::test]
async fn test_e_invoice_proxy() -> Result<(), DbErr> {
    let txn = common::setup().await.begin().await?;
    common::login(&txn, "admin".to_string(), "1".to_string()).await;
    let sql = "select * from e_invoice_proxy('/einvoice/authenticate', 'GET', '29AABCT1332L000');";

    let res = txn.execute_unprepared(sql).await;
    assert_eq!(true, res.is_ok());
    Ok(())
}
