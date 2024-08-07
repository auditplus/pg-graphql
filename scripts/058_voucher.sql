create table if not exists voucher
(
    id                     int       not null generated always as identity primary key,
    date                   date      not null,
    session                uuid      not null unique default gen_random_uuid(),
    eff_date               date,
    branch_id              int       not null,
    branch_name            text      not null,
    base_voucher_type      text      not null,
    voucher_type_id        int       not null,
    voucher_no             text      not null,
    voucher_prefix         text      not null,
    voucher_fy             int       not null,
    voucher_seq            int       not null,
    branch_gst             json,
    party_gst              json,
    e_invoice_details      jsonb,
    mode                   text,
    lut                    boolean,
    rcm                    boolean,
    ref_no                 text,
    party_id               int,
    party_name             text,
    description            text,
    amount                 float,
    credit                 float,
    debit                  float,
    memo                   int,
    pos_counter_code       text,
    approval_state         smallint  not null        default 0,
    require_no_of_approval smallint  not null        default 0,
    created_at             timestamp not null        default current_timestamp,
    updated_at             timestamp not null        default current_timestamp,
    check (approval_state between 0 and 5),
    check (require_no_of_approval >= approval_state),
    constraint mode_invalid check (check_voucher_mode(mode)),
    constraint base_voucher_type_invalid check (check_base_voucher_type(base_voucher_type))
);
--##
create view vw_voucher
as
select a.*,
       (select json_agg(row_to_json(b.*))
        from vw_ac_txn b
        where b.voucher_id = a.id)                                                               as ac_trns,
       (select row_to_json(c.*) from vw_branch_condensed c where c.id = a.branch_id)             as branch,
       (select row_to_json(d.*) from vw_voucher_type_condensed d where d.id = a.voucher_type_id) as voucher_type,
       (select row_to_json(d.*) from vw_account_condensed d where d.id = a.party_id)             as party,
       (select json_agg(row_to_json(e.*)) from vw_tds_on_voucher e where e.voucher_id = a.id)    as tds_details
from voucher a;
--##
create function get_voucher(int)
    returns setof vw_voucher as
$$
begin
    return query select * from vw_voucher where id = $1;
end
$$ language plpgsql security definer;
--##
create view vw_voucher_approval_condensed as
select id, approval_state, require_no_of_approval
from voucher;
--##
create function create_voucher(input_data json, unique_session uuid default null)
    returns voucher as
$$
declare
    v_voucher      voucher;
    v_req_approval smallint;
    first_txn      json := (($1 ->> 'ac_trns')::jsonb)[0];
    _res           bool;
begin
    select case
               when approve5_id is not null then 5
               when approve4_id is not null then 4
               when approve3_id is not null then 3
               when approve2_id is not null then 2
               when approve1_id is not null then 1
               else 0
               end,
           auto_sequence
    into v_req_approval,_res
    from voucher_type
    where id = ($1 ->> 'voucher_type_id')::int;
    if not _res and ($1 ->> 'voucher_seq')::int is null then
        raise exception 'voucher_seq required for this voucher type';
    end if;
    insert into voucher (date, branch_id, voucher_type_id, branch_gst, party_gst, eff_date, mode, lut, rcm, memo,
                         ref_no, party_id, credit, debit, description, amount, require_no_of_approval, pos_counter_code,
                         e_invoice_details, session, voucher_seq)
    values (($1 ->> 'date')::date, ($1 ->> 'branch_id')::int, ($1 ->> 'voucher_type_id')::int,
            ($1 ->> 'branch_gst')::json, ($1 ->> 'party_gst')::json, ($1 ->> 'eff_date')::date,
            coalesce(($1 ->> 'mode')::text, 'ACCOUNT'), ($1 ->> 'lut')::bool, ($1 ->> 'rcm')::bool,
            ($1 ->> 'memo')::int, ($1 ->> 'ref_no')::text,
            coalesce(($1 ->> 'party_id')::int, (first_txn ->> 'account_id')::int), (first_txn ->> 'credit')::float,
            (first_txn ->> 'debit')::float, ($1 ->> 'description')::text, ($1 ->> 'amount')::float, v_req_approval,
            ($1 ->> 'pos_counter_code')::text, ($1 ->> 'e_invoice_details')::jsonb, coalesce($2, gen_random_uuid()),
            coalesce(($1 ->> 'voucher_seq')::int, 123))
    returning * into v_voucher;
    if not FOUND then
        raise exception 'Internal error for voucher insert';
    end if;
    if v_voucher.base_voucher_type != 'PAYMENT' and v_voucher.memo is not null then
        raise exception 'Memo conversion only allowed payment voucher';
    end if;
    if v_voucher.base_voucher_type = 'PAYMENT' and v_voucher.memo is not null then
        delete from voucher where voucher.id = v_voucher.memo;
    end if;
    if v_voucher.pos_counter_code is not null then
        select * into _res from apply_pos_counter_txn(v_voucher, ($1 ->> 'counter_transactions')::json);
    end if;
    if jsonb_array_length(coalesce(($1 ->> 'tds_details')::jsonb, '[]'::jsonb)) > 0 then
        select * into _res from apply_tds_on_voucher(v_voucher, ($1 ->> 'tds_details')::jsonb);
    end if;
    if jsonb_array_length(coalesce(($1 ->> 'ac_trns')::jsonb, '[]'::jsonb)) > 0 then
        select * into _res from insert_ac_txn(v_voucher, ($1 ->> 'ac_trns')::jsonb);
    end if;
    return v_voucher;
end;
$$ language plpgsql security definer;
--##
create function update_voucher(id int, input_data json)
    returns voucher as
$$
declare
    v_voucher voucher;
    first_txn json := (($2 ->> 'ac_trns')::jsonb)[0];
    _res      bool;
begin
    update voucher
    set date        = ($2 ->> 'date')::date,
        ref_no      = ($2 ->> 'ref_no')::text,
        eff_date    = ($2 ->> 'eff_date')::date,
        description = ($2 ->> 'description')::text,
        party_gst   = ($2 ->> 'party_gst')::json,
        party_id    = coalesce(($2 ->> 'party_id')::int, (first_txn ->> 'account_id')::int),
        amount      = ($2 ->> 'amount')::float,
        rcm         = ($2 ->> 'rcm')::bool,
        lut         = ($2 ->> 'lut')::bool,
        memo        = ($2 ->> 'memo')::int,
        debit       = coalesce((first_txn ->> 'debit')::float, 0),
        credit      = coalesce((first_txn ->> 'credit')::float, 0),
        updated_at  = current_timestamp
    where voucher.id = $1
    returning * into v_voucher;
    if not FOUND then
        raise exception 'Voucher not found';
    end if;
    if v_voucher.base_voucher_type != 'PAYMENT' and v_voucher.memo is not null then
        raise exception 'Memo conversion only allowed payment voucher';
    end if;
    if v_voucher.base_voucher_type = 'PAYMENT' and v_voucher.memo is not null then
        delete from voucher where voucher.id = v_voucher.memo;
    end if;
    if v_voucher.pos_counter_code is not null then
        select * into _res from update_pos_counter_txn(v_voucher, ($2 ->> 'counter_transactions')::json);
    end if;
    select * into _res from apply_tds_on_voucher(v_voucher, ($2 ->> 'tds_details')::jsonb);
    select * into _res from update_ac_txn(v_voucher, ($2 ->> 'ac_trns')::jsonb);
    return v_voucher;
end;
$$ language plpgsql security definer;
--##
create function tgf_validate_voucher_update()
    returns trigger as
$$
begin
    if (old.e_invoice_details ->> 'irn_no')::text is not null then
        raise exception 'IRN number filled, Cannot update einvoice details';
    end if;
    return new;
end;
$$ language plpgsql security definer;
--##
create trigger tg_validate_voucher_update
    before update
    on voucher
    for each row
execute procedure tgf_validate_voucher_update();
--##
create function tgf_generate_voucher_no()
    returns trigger as
$$
begin
    declare
        fy     financial_year := (select a
                                  from financial_year a
                                  where a.fy_start <= new.date
                                    and a.fy_end >= new.date);
        br     branch         := (select a
                                  from branch a
                                  where a.id = new.branch_id);
        v_type voucher_type   := (select a
                                  from voucher_type a
                                  where a.id = new.voucher_type_id);
    begin
        if v_type.id is null then
            raise exception 'Voucher type not found';
        end if;
        if br.id is null then
            raise exception 'Branch not found';
        end if;
        if fy.id is null then
            raise exception 'Financial year not found';
        end if;
        if v_type.auto_sequence then
            insert into voucher_numbering(branch_id, f_year_id, voucher_type_id, seq)
            values (new.branch_id, fy.id, coalesce(v_type.sequence_id, v_type.id), 1)
            on conflict (branch_id, f_year_id, voucher_type_id) do update
                set seq = voucher_numbering.seq + 1
            returning seq into new.voucher_seq;
        end if;

        if new.party_id is not null then
            select name into new.party_name from account where id = new.party_id;
        end if;

        new.branch_name = br.name;
        new.base_voucher_type = v_type.base_type;
        new.voucher_prefix = concat(br.voucher_no_prefix, v_type.prefix);
        new.voucher_fy = concat(to_char(fy.fy_start, 'yy'), to_char(fy.fy_end, 'yy'))::int;
        new.voucher_no = concat(new.voucher_prefix, new.voucher_fy, new.voucher_seq);
    end;
    return new;
end;
$$ language plpgsql security definer;
--##
create function approve_voucher(id int, approve_state int, description text)
    returns void as
$$
declare
    v_voucher   voucher;
    apv_tag     int;
    member_json json := (select x::json
                         from current_setting('my.claims') x);
begin
    select * into v_voucher from voucher where voucher.id = $1;
    if not FOUND then
        raise exception 'Voucher not FOUND/Invalid ';
    end if;
    if v_voucher.approval_state = v_voucher.require_no_of_approval then
        raise exception 'Already approved';
    end if;
    if v_voucher.approval_state <> ($2 - 1) then
        raise exception 'invalid approve state';
    end if;
    select case
               when $2 = 5 then approve5_id
               when $2 = 4 then approve4_id
               when $2 = 3 then approve3_id
               when $2 = 2 then approve2_id
               when $2 = 1 then approve1_id
               end
    into apv_tag
    from voucher_type
    where voucher_type.id = v_voucher.voucher_type_id;
    if not exists(select *
                  from approval_tag a
                  where a.id = apv_tag
                    and (member_json ->> 'id')::int = any (a.members)) then
        raise exception 'Unable to get approval tag member/ Someone needs to approve';
    end if;
    update voucher set approval_state = $2 where voucher.id = $1 returning * into v_voucher;
    insert into approval_log(member_id, member_name, description, voucher_id, base_voucher_type, voucher_type_id,
                             voucher_no, approval_state)
    values ((member_json ->> 'id')::int, (member_json ->> 'name')::text, $3, $1, v_voucher.base_voucher_type,
            v_voucher.voucher_type_id, v_voucher.voucher_no, $2);
    if v_voucher.require_no_of_approval = v_voucher.approval_state then
        update bill_allocation set is_approved = true where voucher_id = v_voucher.id and ref_type = 'NEW';
    end if;
end;
$$ language plpgsql security definer;
--##
create function delete_voucher(id int)
    returns void as
$$
begin
    delete from voucher where voucher.id = $1;
end;
$$ language plpgsql;
--##
create trigger tg_gen_voucher_no_for_voucher
    before insert
    on voucher
    for each row
execute procedure tgf_generate_voucher_no();
--##
create function insert_ac_txn(voucher, jsonb)
    returns bool as
$$
declare
    j          json;
    acc        account;
    dr_max_acc account;
    cr_max_acc account;
    v_ac_txn   ac_txn;
    _res       bool;
    _sno       smallint := 1;
begin
    select *
    into dr_max_acc
    from account
    where id = (select (x ->> 'account_id')::int
                from jsonb_array_elements($2) x
                where (x ->> 'debit')::float > 0
                order by (x ->> 'debit')::float desc
                limit 1);
    select *
    into cr_max_acc
    from account
    where id = (select (x ->> 'account_id')::int
                from jsonb_array_elements($2) x
                where (x ->> 'credit')::float > 0
                order by (x ->> 'credit')::float desc
                limit 1);
    for j in select jsonb_array_elements($2)
        loop
            select * into acc from account where id = (j ->> 'account_id')::int;
            if not acc.transaction_enabled then
                raise exception '% this account does not allowed transaction', acc.name;
            end if;
            if array ['SUNDRY_CREDITOR', 'SUNDRY_DEBTOR'] && acc.base_account_types and
               jsonb_array_length((j ->> 'bill_allocations')::jsonb) = 0 then
                raise exception 'bill_allocations required for Sundry type';
            end if;
            if array ['BANK_ACCOUNT', 'BANK_OD_ACCOUNT'] && acc.base_account_types and
               jsonb_array_length((j ->> 'bank_allocations')::jsonb) = 0 then
                raise exception 'bank_allocations required for Bank type';
            end if;
            insert into ac_txn(id, sno, date, eff_date, account_id, credit, debit, account_name, base_account_types,
                               branch_id, branch_name, alt_account_id, alt_account_name, ref_no, voucher_id, voucher_no,
                               voucher_prefix, voucher_fy, voucher_seq, voucher_type_id, base_voucher_type,
                               voucher_mode, is_memo, is_default)
            values (coalesce((j ->> 'id')::uuid, gen_random_uuid()), _sno, $1.date, $1.eff_date,
                    (j ->> 'account_id')::int, (j ->> 'credit')::float, (j ->> 'debit')::float, acc.name,
                    acc.base_account_types, $1.branch_id, $1.branch_name,
                    case when (j ->> 'credit')::float = 0 then cr_max_acc.id else dr_max_acc.id end,
                    case when (j ->> 'credit')::float = 0 then cr_max_acc.name else dr_max_acc.name end, $1.ref_no,
                    $1.id, $1.voucher_no, $1.voucher_prefix, $1.voucher_fy, $1.voucher_seq, $1.voucher_type_id,
                    $1.base_voucher_type, $1.mode, $1.base_voucher_type = 'MEMO', (j ->> 'is_default')::bool)
            returning * into v_ac_txn;
            if (j ->> 'gst_info')::json ->> 'gst_tax_id' is not null then
                select * into _res from insert_tax_allocation($1, (j ->> 'gst_info')::json, v_ac_txn);
            end if;
            if array ['SUNDRY_CREDITOR', 'SUNDRY_DEBTOR'] && acc.base_account_types then
                select * into _res from insert_bill_allocation($1, (j ->> 'bill_allocations')::jsonb, v_ac_txn);
            end if;
            if array ['BANK_ACCOUNT', 'BANK_OD_ACCOUNT'] && acc.base_account_types then
                select * into _res from insert_bank_allocation($1, (j ->> 'bank_allocations')::jsonb, v_ac_txn);
            end if;
            if jsonb_array_length((j ->> 'category_allocations')::jsonb) > 0 then
                select * into _res from insert_cat_allocation($1, (j ->> 'category_allocations')::jsonb, v_ac_txn);
            end if;
            _sno = _sno + 1;
        end loop;
    return true;
end;
$$ language plpgsql;
--##
create function update_ac_txn(voucher, jsonb)
    returns bool as
$$
declare
    acc            account;
    missed_ac_txns uuid[];
    j              json;
    dr_max_acc     account;
    cr_max_acc     account;
    v_ac_txn       ac_txn;
    _res           bool;
    _sno           smallint := 1;
begin
    select array_agg(a.id)
    into missed_ac_txns
    from ((select id, account_id
           from ac_txn
           where voucher_id = $1.id)
          except
          select id, account_id
          from jsonb_to_recordset($2) as src(id uuid, account_id int)) as a;
    delete from ac_txn where id = any (missed_ac_txns);
    select *
    into dr_max_acc
    from account
    where id = (select (x ->> 'account_id')::int
                from jsonb_array_elements($2) x
                where (x ->> 'debit')::float > 0
                order by (x ->> 'debit')::float desc
                limit 1);
    select *
    into cr_max_acc
    from account
    where id = (select (x ->> 'account_id')::int
                from jsonb_array_elements($2) x
                where (x ->> 'credit')::float > 0
                order by (x ->> 'credit')::float desc
                limit 1);
    for j in select jsonb_array_elements($2)
        loop
            select * into acc from account where id = (j ->> 'account_id')::int;
            if not acc.transaction_enabled then
                raise exception '% this account does not allowed transaction', acc.name;
            end if;
            if array ['SUNDRY_CREDITOR', 'SUNDRY_DEBTOR'] && acc.base_account_types and
               jsonb_array_length((j ->> 'bill_allocations')::jsonb) = 0 then
                raise exception 'bill_allocations required for Sundry type';
            end if;
            if array ['BANK_ACCOUNT', 'BANK_OD_ACCOUNT'] && acc.base_account_types and
               jsonb_array_length((j ->> 'bank_allocations')::jsonb) = 0 then
                raise exception 'bank_allocations required for Bank type';
            end if;
            insert into ac_txn(id, sno, date, eff_date, account_id, credit, debit, account_name, base_account_types,
                               branch_id, branch_name, alt_account_id, alt_account_name, ref_no, voucher_id, voucher_no,
                               voucher_prefix, voucher_fy, voucher_seq, voucher_type_id, base_voucher_type,
                               voucher_mode, is_memo, is_default)
            values (coalesce((j ->> 'id')::uuid, gen_random_uuid()), _sno, $1.date, $1.eff_date, acc.id,
                    (j ->> 'credit')::float, (j ->> 'debit')::float, acc.name, acc.base_account_types, $1.branch_id,
                    $1.branch_name, case when (j ->> 'credit')::float = 0 then cr_max_acc.id else dr_max_acc.id end,
                    case when (j ->> 'credit')::float = 0 then cr_max_acc.name else dr_max_acc.name end, $1.ref_no,
                    $1.id, $1.voucher_no, $1.voucher_prefix, $1.voucher_fy, $1.voucher_seq, $1.voucher_type_id,
                    $1.base_voucher_type, $1.mode, $1.base_voucher_type = 'MEMO', (j ->> 'is_default')::bool)
            on conflict (id) do update
                set date             = excluded.date,
                    eff_date         = excluded.eff_date,
                    sno              = excluded.sno,
                    credit           = excluded.credit,
                    debit            = excluded.debit,
                    account_name     = excluded.account_name,
                    branch_name      = excluded.branch_name,
                    alt_account_id   = excluded.alt_account_id,
                    alt_account_name = excluded.alt_account_name,
                    is_default       = excluded.is_default,
                    ref_no           = excluded.ref_no
            returning * into v_ac_txn;
            if (j ->> 'gst_info')::json ->> 'gst_tax_id' is not null then
                select * into _res from update_tax_allocation($1, (j ->> 'gst_info')::json, v_ac_txn);
            end if;
            if array ['BANK_ACCOUNT', 'BANK_OD_ACCOUNT'] && acc.base_account_types then
                select * into _res from update_bank_allocation($1, (j ->> 'bank_allocations')::jsonb, v_ac_txn);
            end if;
            if array ['SUNDRY_CREDITOR', 'SUNDRY_DEBTOR'] && acc.base_account_types then
                select * into _res from update_bill_allocation($1, (j ->> 'bill_allocations')::jsonb, v_ac_txn);
            end if;
            if jsonb_array_length((j ->> 'category_allocations')::jsonb) > 0 then
                select * into _res from update_cat_allocation($1, (j ->> 'category_allocations')::jsonb, v_ac_txn);
            end if;
            _sno = _sno + 1;
        end loop;
    return true;
end;
$$ language plpgsql;
--##
create function insert_tax_allocation(voucher, json, ac_txn)
    returns bool as
$$
declare
    gst gst_tax;
begin
    select * into gst from gst_tax where id = ($2 ->> 'gst_tax_id')::text;
    insert into gst_txn(ac_txn_id, date, eff_date, hsn_code, branch_id, branch_name, item, item_name, uqc_id, qty,
                        party_id, party_name, branch_reg_type, branch_gst_no, branch_location_id, party_reg_type,
                        party_location_id, party_gst_no, lut, gst_tax_id, tax_name, tax_ratio, taxable_amount,
                        cgst_amount, sgst_amount, igst_amount, cess_amount, total, amount, voucher_id, voucher_no,
                        ref_no, voucher_type_id, base_voucher_type, voucher_mode)
    values ($3.id, $1.date, $1.eff_date, ($2 ->> 'hsn_code')::text, $1.branch_id, $1.branch_name, $3.account_id,
            $3.account_name, coalesce(($2 ->> 'uqc_id')::text, 'OTH'), coalesce(($2 ->> 'qty')::float, 1), $1.party_id,
            $1.party_name, ($1.branch_gst ->> 'reg_type')::text, ($1.branch_gst ->> 'gst_no')::text,
            ($1.branch_gst ->> 'location_id')::text, ($1.party_gst ->> 'reg_type')::text,
            coalesce(($1.party_gst ->> 'location_id')::text, ($1.branch_gst ->> 'location_id')::text),
            ($1.party_gst ->> 'gst_no')::text, $1.lut, ($2 ->> 'gst_tax_id')::text, gst.name, gst.igst,
            coalesce(($2 ->> 'taxable_amount')::float, 0), coalesce(($2 ->> 'cgst_amount')::float, 0),
            coalesce(($2 ->> 'sgst_amount')::float, 0), coalesce(($2 ->> 'igst_amount')::float, 0),
            coalesce(($2 ->> 'cess_amount')::float, 0),
            coalesce(($2 ->> 'taxable_amount')::float, 0) + coalesce(($2 ->> 'cgst_amount')::float, 0) +
            coalesce(($2 ->> 'sgst_amount')::float, 0) + coalesce(($2 ->> 'igst_amount')::float, 0) +
            coalesce(($2 ->> 'cess_amount')::float, 0), $1.amount, $1.id, $1.voucher_no, $1.ref_no, $1.voucher_type_id,
            $1.base_voucher_type, $1.mode);
    return true;
end;
$$ language plpgsql;
--##
create function insert_cat_allocation(voucher, jsonb, ac_txn)
    returns boolean as
$$
declare
    i    json;
    _sno smallint := 1;
begin
    for i in select jsonb_array_elements($2)
        loop
            insert into acc_cat_txn (id, sno, ac_txn_id, date, account_id, account_name, base_account_types, branch_id,
                                     branch_name, amount, voucher_id, voucher_no, base_voucher_type, voucher_type_id,
                                     voucher_mode, ref_no, is_memo, category1_id, category2_id, category3_id,
                                     category4_id, category5_id)
            values (coalesce((i ->> 'id')::uuid, gen_random_uuid()), _sno, $3.id, $1.date, $3.account_id,
                    $3.account_name, $3.base_account_types, $1.branch_id, $1.branch_name, (i ->> 'amount')::float,
                    $1.id, $1.voucher_no, $1.base_voucher_type, $1.voucher_type_id, $1.mode, $1.ref_no, $3.is_memo,
                    (i ->> 'category1_id')::int, (i ->> 'category2_id')::int, (i ->> 'category3_id')::int,
                    (i ->> 'category4_id')::int, (i ->> 'category5_id')::int);
            _sno = _sno + 1;
        end loop;
    return true;
end;
$$ language plpgsql;
--##
create function insert_bill_allocation(voucher, jsonb, ac_txn)
    returns bool as
$$
declare
    agent_acc account;
    i         json;
    p_id      uuid;
    _sno      smallint := 1;
begin
    select * into agent_acc from account where id = (select agent_id account where id = $3.account_id);
    for i in select jsonb_array_elements($2)
        loop
            if (i ->> 'ref_type') = 'NEW' then
                p_id = coalesce((i ->> 'pending')::uuid, gen_random_uuid());
                if exists (select id from bill_allocation where pending = p_id and ref_type = 'NEW') then
                    raise exception 'This new ref already exist';
                end if;
            elseif (i ->> 'ref_type') = 'ADJ' then
                p_id = (i ->> 'pending')::uuid;
                if p_id is null then raise exception 'pending must be required on adjusted ref'; end if;
            else
                p_id = null;
            end if;
            insert into bill_allocation (id, sno, ac_txn_id, date, eff_date, is_memo, account_id, branch_id, amount,
                                         pending, ref_type, ref_no, voucher_id, account_name, base_account_types,
                                         branch_name, base_voucher_type, voucher_mode, voucher_no, agent_id, agent_name,
                                         is_approved)
            values (coalesce((i ->> 'id')::uuid, gen_random_uuid()), _sno, $3.id, $1.date,
                    coalesce($1.eff_date, $1.date), $3.is_memo, $3.account_id, $1.branch_id, (i ->> 'amount')::float,
                    p_id, (i ->> 'ref_type')::text, coalesce((i ->> 'ref_no')::text, $3.ref_no), $1.id, $3.account_name,
                    $3.base_account_types, $1.branch_name, $1.base_voucher_type, $1.mode, $1.voucher_no, agent_acc.id,
                    agent_acc.name, $1.require_no_of_approval = $1.approval_state);
            _sno = _sno + 1;
        end loop;
    return true;
end;
$$ language plpgsql;
--##
create function insert_bank_allocation(voucher, jsonb, ac_txn)
    returns bool as
$$
declare
    alt_acc account;
    i       json;
    _sno    smallint := 1;
begin
    for i in select jsonb_array_elements($2)
        loop
            select * into alt_acc from account where id = (i ->> 'account_id')::int;
            insert into bank_txn (id, sno, ac_txn_id, date, inst_date, inst_no, in_favour_of, is_memo, amount,
                                  account_id, account_name, base_account_types, alt_account_id, alt_account_name,
                                  particulars, branch_id, branch_name, voucher_id, voucher_no, base_voucher_type,
                                  bank_beneficiary_id, txn_type)
            values (coalesce((i ->> 'id')::uuid, gen_random_uuid()), _sno, $3.id, $1.date, (i ->> 'inst_date')::date,
                    (i ->> 'inst_no')::text, (i ->> 'in_favour_of')::text, $3.is_memo, (i ->> 'amount')::float,
                    $3.account_id, $3.account_name, $3.base_account_types, alt_acc.id, alt_acc.name,
                    (i ->> 'particulars')::text, $1.branch_id, $1.branch_name, $1.id, $1.voucher_no,
                    $1.base_voucher_type, (i ->> 'bank_beneficiary_id')::int, (i ->> 'txn_type')::text);
            _sno = _sno + 1;
        end loop;
    return true;
end;
$$ language plpgsql;
--##
create function update_tax_allocation(voucher, json, ac_txn)
    returns bool as
$$
declare
    gst gst_tax := (select gst_tax
                    from gst_tax
                    where id = ($2 ->> 'gst_tax_id')::text);
begin
    insert into gst_txn(ac_txn_id, date, eff_date, hsn_code, branch_id, branch_name, item, item_name, uqc_id, qty,
                        party_id, party_name, branch_reg_type, branch_gst_no, branch_location_id, party_reg_type,
                        party_location_id, party_gst_no, lut, gst_tax_id, tax_name, tax_ratio, taxable_amount,
                        cgst_amount, sgst_amount, igst_amount, cess_amount, total, amount, voucher_id, voucher_no,
                        ref_no, voucher_type_id, base_voucher_type, voucher_mode)
    values ($3.id, $1.date, $1.eff_date, ($2 ->> 'hsn_code')::text, $1.branch_id, $1.branch_name, $3.account_id,
            $3.account_name, coalesce(($2 ->> 'uqc_id')::text, 'OTH'), coalesce(($2 ->> 'qty')::float, 1), $1.party_id,
            $1.party_name, ($1.branch_gst ->> 'reg_type')::text, ($1.branch_gst ->> 'gst_no')::text,
            ($1.branch_gst ->> 'location_id')::text, ($1.party_gst ->> 'reg_type')::text,
            coalesce(($1.party_gst ->> 'location_id')::text, ($1.branch_gst ->> 'location_id')::text),
            ($1.party_gst ->> 'gst_no')::text, $1.lut, ($2 ->> 'gst_tax_id')::text, gst.name, gst.igst,
            coalesce(($2 ->> 'taxable_amount')::float, 0), coalesce(($2 ->> 'cgst_amount')::float, 0),
            coalesce(($2 ->> 'sgst_amount')::float, 0), coalesce(($2 ->> 'igst_amount')::float, 0),
            coalesce(($2 ->> 'cess_amount')::float, 0),
            coalesce(($2 ->> 'taxable_amount')::float, 0) + coalesce(($2 ->> 'cgst_amount')::float, 0) +
            coalesce(($2 ->> 'sgst_amount')::float, 0) + coalesce(($2 ->> 'igst_amount')::float, 0) +
            coalesce(($2 ->> 'cess_amount')::float, 0), $1.amount, $1.id, $1.voucher_no, $1.ref_no, $1.voucher_type_id,
            $1.base_voucher_type, $1.mode)
    on conflict (ac_txn_id) do update
        set date              = excluded.date,
            eff_date          = excluded.eff_date,
            item_name         = excluded.item_name,
            branch_name       = excluded.branch_name,
            hsn_code          = excluded.hsn_code,
            uqc_id            = excluded.uqc_id,
            qty               = excluded.qty,
            party_id          = excluded.party_id,
            party_name        = excluded.party_name,
            party_reg_type    = excluded.party_reg_type,
            party_gst_no      = excluded.party_gst_no,
            party_location_id = excluded.party_location_id,
            lut               = excluded.lut,
            gst_tax_id        = excluded.gst_tax_id,
            tax_name          = excluded.tax_name,
            tax_ratio         = excluded.tax_ratio,
            taxable_amount    = excluded.taxable_amount,
            cgst_amount       = excluded.cgst_amount,
            sgst_amount       = excluded.sgst_amount,
            igst_amount       = excluded.igst_amount,
            cess_amount       = excluded.cess_amount,
            total             = excluded.total,
            amount            = excluded.amount,
            ref_no            = excluded.ref_no;
    return true;
end;
$$ language plpgsql;
--##
create function update_bank_allocation(voucher, jsonb, ac_txn)
    returns bool as
$$
declare
    alt_acc    account;
    i          json;
    missed_ids uuid[];
    _sno       smallint := 1;
begin
    select array_agg(x.id)
    into missed_ids
    from (select id
          from bank_txn
          where ac_txn_id = $3.id
            and account_id = $3.account_id
          except
          select id
          from jsonb_to_recordset($2) as src(id uuid)) as x;
    delete from bank_txn where id = any (missed_ids);
    for i in select jsonb_array_elements($2)
        loop
            select * into alt_acc from account where id = (i ->> 'account_id')::int;
            insert into bank_txn (id, sno, ac_txn_id, date, inst_date, inst_no, in_favour_of, is_memo, amount,
                                  account_id,
                                  account_name, base_account_types, alt_account_id, alt_account_name, particulars,
                                  branch_id, branch_name, voucher_id, voucher_no, base_voucher_type,
                                  bank_beneficiary_id, txn_type)
            values (coalesce((i ->> 'id')::uuid, gen_random_uuid()), _sno, $3.id, $1.date, (i ->> 'inst_date')::date,
                    (i ->> 'inst_no')::text, (i ->> 'in_favour_of')::text, $3.is_memo, (i ->> 'amount')::float,
                    $3.account_id, $3.account_name, $3.base_account_types, alt_acc.id, alt_acc.name,
                    (i ->> 'particulars')::text, $1.branch_id, $1.branch_name, $1.id, $1.voucher_no,
                    $1.base_voucher_type, (i ->> 'bank_beneficiary_id')::int, (i ->> 'txn_type')::text)
            on conflict (id)
                do update
                set date                = excluded.date,
                    inst_date           = excluded.inst_date,
                    inst_no             = excluded.inst_no,
                    sno                 = excluded.sno,
                    in_favour_of        = excluded.in_favour_of,
                    amount              = excluded.amount,
                    txn_type            = excluded.txn_type,
                    bank_beneficiary_id = excluded.bank_beneficiary_id,
                    alt_account_id      = excluded.alt_account_id,
                    alt_account_name    = excluded.alt_account_name,
                    particulars         = excluded.particulars,
                    bank_date           = (case
                                               when
                                                   (
                                                       bank_txn.date != excluded.date or
                                                       bank_txn.inst_date != excluded.inst_date or
                                                       bank_txn.in_favour_of != excluded.in_favour_of or
                                                       bank_txn.credit != excluded.credit or
                                                       bank_txn.debit != excluded.debit or
                                                       bank_txn.txn_type != excluded.txn_type or
                                                       bank_txn.bank_beneficiary_id !=
                                                       excluded.bank_beneficiary_id or
                                                       bank_txn.particulars != excluded.particulars or
                                                       bank_txn.inst_no != excluded.inst_no
                                                       )
                                                   then null
                                               else bank_txn.bank_date end);
            _sno = _sno + 1;
        end loop;
    return true;
end;
$$ language plpgsql;
--##
create function update_bill_allocation(voucher, jsonb, ac_txn)
    returns bool as
$$
declare
    agent_acc  account;
    i          json;
    p_id       uuid;
    missed_ids uuid[];
    _sno       smallint := 1;
begin
    select array_agg(x.id)
    into missed_ids
    from (select id
          from bill_allocation
          where ac_txn_id = $3.id
            and account_id = $3.account_id
          except
          select id
          from jsonb_to_recordset($2) as src(id uuid)) as x;
    delete from bill_allocation where id = any (missed_ids);
    select * into agent_acc from account where id = (select agent_id account where id = $3.account_id);
    for i in select * from jsonb_array_elements($2)
        loop
            if (i ->> 'ref_type') = 'NEW' then
                p_id = coalesce((i ->> 'pending')::uuid, gen_random_uuid());
                if exists (select id
                           from bill_allocation
                           where pending = p_id
                             and ref_type = 'NEW'
                             and not (id = coalesce((i ->> 'id')::uuid))) then
                    raise exception 'This new ref already exist';
                end if;
            elseif (i ->> 'ref_type') = 'ADJ' then
                p_id = (i ->> 'pending')::uuid;
                if p_id is null then raise exception 'pending must be required on adjusted ref'; end if;
            else
                p_id = null;
            end if;
            insert into bill_allocation (id, sno, ac_txn_id, date, eff_date, is_memo, account_id, branch_id, amount,
                                         pending,
                                         ref_type, ref_no, voucher_id, account_name, base_account_types, branch_name,
                                         base_voucher_type, voucher_mode, voucher_no, agent_id, agent_name, is_approved)
            values (coalesce((i ->> 'id')::uuid, gen_random_uuid()), _sno, $3.id, $1.date,
                    coalesce($1.eff_date, $1.date),
                    $3.is_memo, $3.account_id, $1.branch_id, (i ->> 'amount')::float, p_id, (i ->> 'ref_type')::text,
                    coalesce((i ->> 'ref_no')::text, $3.ref_no), $1.id, $3.account_name, $3.base_account_types,
                    $1.branch_name, $1.base_voucher_type, $1.mode, $1.voucher_no, agent_acc.id, agent_acc.name,
                    $1.require_no_of_approval = $1.approval_state)
            on conflict (id) do update
                SET date        = excluded.date,
                    eff_date    = excluded.eff_date,
                    sno         = excluded.sno,
                    amount      = excluded.amount,
                    agent_name  = excluded.agent_name,
                    branch_name = excluded.branch_name,
                    ref_type    = excluded.ref_type,
                    ref_no      = excluded.ref_no,
                    pending     = excluded.pending;
            _sno = _sno + 1;
        end loop;
    return true;
end;
$$ language plpgsql;
--##
create function update_cat_allocation(voucher, jsonb, ac_txn)
    returns bool as
$$
declare
    i          json;
    missed_ids uuid[];
    _sno       smallint := 1;
begin
    select array_agg(x.id)
    into missed_ids
    from (select id
          from acc_cat_txn
          where ac_txn_id = $3.id
            and account_id = $3.account_id
          except
          select id
          from jsonb_to_recordset($2) as src(id uuid)) as x;
    delete from acc_cat_txn where id = any (missed_ids);
    for i in select * from jsonb_array_elements($2)
        loop
            insert into acc_cat_txn (id, sno, ac_txn_id, date, account_id, account_name, base_account_types, branch_id,
                                     branch_name, amount, voucher_id, voucher_no, base_voucher_type, voucher_type_id,
                                     voucher_mode, ref_no, is_memo, category1_id, category2_id, category3_id,
                                     category4_id, category5_id)
            values (coalesce((i ->> 'id')::uuid, gen_random_uuid()), _sno, $3.id, $1.date, $3.account_id,
                    $3.account_name,
                    $3.base_account_types, $1.branch_id, $1.branch_name, (i ->> 'amount')::float, $1.id, $1.voucher_no,
                    $1.base_voucher_type, $1.voucher_type_id, $1.mode, $1.ref_no, $3.is_memo,
                    (i ->> 'category1_id')::int, (i ->> 'category2_id')::int, (i ->> 'category3_id')::int,
                    (i ->> 'category4_id')::int, (i ->> 'category5_id')::int)
            on conflict (id) do update
                SET date         = excluded.date,
                    account_name = excluded.account_name,
                    sno          = excluded.sno,
                    branch_name  = excluded.branch_name,
                    amount       = excluded.amount,
                    category1_id = excluded.category1_id,
                    category2_id = excluded.category2_id,
                    category3_id = excluded.category3_id,
                    category4_id = excluded.category4_id,
                    category5_id = excluded.category5_id;
            _sno = _sno + 1;
        end loop;
    return true;
end;
$$ language plpgsql;
--##
create function apply_tds_on_voucher(voucher, jsonb)
    returns boolean as
$$
declare
    item  tds_on_voucher;
    items tds_on_voucher[] := (select array_agg(x)
                               from jsonb_populate_recordset(
                                            null::tds_on_voucher,
                                            $2) as x);
begin
    delete from tds_on_voucher where voucher_id = $1.id;
    foreach item in array coalesce(items, array []::tds_on_voucher[])
        loop
            insert into tds_on_voucher (id, date, eff_date, party_account_id, party_name, tds_account_id, tds_ratio,
                                        tds_nature_of_payment_id, tds_deductee_type_id, branch_id, branch_name, amount,
                                        tds_amount, base_voucher_type, voucher_no, voucher_id, tds_section, ref_no)
            values (gen_random_uuid(), $1.date, coalesce($1.eff_date, $1.date), item.party_account_id, item.party_name,
                    item.tds_account_id, item.tds_ratio, item.tds_nature_of_payment_id, item.tds_deductee_type_id,
                    $1.branch_id, $1.branch_name, item.amount, item.tds_amount, $1.base_voucher_type, $1.voucher_no,
                    $1.id, item.tds_section, $1.ref_no);
        end loop;
    return true;
end;
$$ language plpgsql security definer;