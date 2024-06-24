do
$$
    declare
        _unit_id                int;
        _division_id            int;
        _inventory_id           int;
        _gst_tax_id             text  = 'gst12';
        _branch_account_type_id int   = (select id
                                         from account_type
                                         where default_name = 'BRANCH_OR_DIVISION'
                                         limit 1);
        _warehouse_id           int   = (select id
                                         from warehouse
                                         where name = 'Default'
                                         limit 1);
        _voucher_type_id        int   = (select id
                                         from voucher_type
                                         where is_default
                                           and base_type = 'SALE'
                                         limit 1);
        _branch_account_id      int;
        _gst_registration_id    int;
        _branch_id              int;
        _counter_id             int;
        _output                 sale_bill;
        input                   jsonb := '{
          "date": "2024-06-24",
          "branchGst": {
            "regType": "REGULAR",
            "locationId": "33",
            "gstNo": "33AAACS4668K1Z4"
          },
          "amount": 150,
          "invItems": [],
          "acTrns": []
        }'::jsonb;
    begin
        begin
            insert into unit (name, symbol, uqc_id, precision)
            values ('Pcs', 'Pcs', 'PCS', 0)
            returning id into _unit_id;

            insert into division (name) values ('Supermarket') returning id into _division_id;

            insert into inventory (name, unit_id, division_id, gst_tax_id)
            values ('Vicks candy', _unit_id, _division_id, _gst_tax_id)
            returning id into _inventory_id;

            insert into account (name, account_type_id, contact_type)
            values ('Main branch account', _branch_account_type_id, 'ACCOUNT')
            returning id into _branch_account_id;

            insert into gst_registration (gst_no, reg_type, state_id)
            values ('33AAACS4668K1Z4', 'REGULAR', 33)
            returning id into _gst_registration_id;

            insert into branch (name, voucher_no_prefix, account_id)
            values ('Main branch', 'MB', _branch_account_id)
            returning id into _branch_id;

            insert into pos_counter (name, branch_id) values ('Counter1', _branch_id) returning id into _counter_id;

            input = jsonb_insert(input, '{warehouseId}', _warehouse_id::text::jsonb);
            input = jsonb_insert(input, '{voucherTypeId}', _voucher_type_id::text::jsonb);
            input = jsonb_insert(input, '{branchId}', _branch_id::text::jsonb);

            select * into _output from create_sale_bill(input::json);
            raise info '%', _output;
            if _branch_id = 23 then
                raise exception 'Test failure';
            end if;
            rollback;

        end;
    end
$$ language plpgsql;