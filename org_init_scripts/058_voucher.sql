create table if not exists voucher
(
    id                     int                   not null generated always as identity primary key,
    date                   date                  not null,
    session                uuid                  not null unique default gen_random_uuid(),
    eff_date               date,
    branch_id              int                   not null,
    branch_name            text                  not null,
    base_voucher_type      typ_base_voucher_type not null,
    voucher_type_id        int                   not null,
    voucher_no             text                  not null,
    voucher_prefix         text                  not null,
    voucher_fy             int                   not null,
    voucher_seq            int                   not null,
    branch_gst             json,
    party_gst              json,
    mode                   typ_voucher_mode,
    lut                    boolean,
    rcm                    boolean,
    ref_no                 text,
    party_id               int,
    party_name             text,
    description            text,
    amount                 float,
    memo                   int,
    pos_counter_id         int,
    approval_state         smallint              not null        default 0,
    require_no_of_approval smallint              not null        default 0,
    created_at             timestamp             not null        default current_timestamp,
    updated_at             timestamp             not null        default current_timestamp,
    check (approval_state between 0 and 5),
    check (require_no_of_approval >= approval_state)
);
--##
create function create_voucher(
    input_data json,
    unique_session uuid default null
)
    returns voucher as
$$
declare
    input          jsonb    := json_convert_case($1::jsonb, 'snake_case');
    v_voucher      voucher;
    v_req_approval smallint := (select case
                                           when (approval ->> 'approve5')::int is not null then 5
                                           when (approval ->> 'approve4')::int is not null then 4
                                           when (approval ->> 'approve3')::int is not null then 3
                                           when (approval ->> 'approve2')::int is not null then 2
                                           when (approval ->> 'approve1')::int is not null then 1
                                           else 0
                                           end
                                from voucher_type
                                where id = (input ->> 'voucher_type_id')::int);
    _res           bool;
begin
    insert into voucher (date, branch_id, voucher_type_id, branch_gst, party_gst, eff_date, mode, lut, rcm, memo,
                         ref_no, party_id, description, amount, require_no_of_approval, pos_counter_id, session)
    values ((input ->> 'date')::date, (input ->> 'branch_id')::int, (input ->> 'voucher_type_id')::int,
            (input ->> 'branch_gst')::json, (input ->> 'party_gst')::json, (input ->> 'eff_date')::date,
            coalesce((input ->> 'mode')::typ_voucher_mode, 'ACCOUNT'),
            (input ->> 'lut')::bool, (input ->> 'rcm')::bool, (input ->> 'memo')::int, input ->> 'ref_no',
            (input ->> 'party_id')::int, input ->> 'description', (input ->> 'amount')::float, v_req_approval,
            (input ->> 'pos_counter_id')::int, coalesce($2, gen_random_uuid()))
    returning * into v_voucher;
    if v_voucher.pos_counter_id is not null then
        select * into _res from apply_pos_counter_txn(v_voucher, (input ->> 'counter_trns')::jsonb);
    end if;
    if jsonb_array_length(coalesce((input ->> 'tds_details')::jsonb, '[]'::jsonb)) > 0 then
        select * into _res from apply_tds_on_voucher(v_voucher, (input ->> 'tds_details')::jsonb);
    end if;
    if jsonb_array_length(coalesce((input ->> 'ac_trns')::jsonb, '[]'::jsonb)) > 0 then
        select * into _res from insert_ac_txn(v_voucher, (input ->> 'ac_trns')::jsonb);
    end if;
    return v_voucher;
end;
$$ language plpgsql security definer;
--##
create function update_voucher(
    id int,
    date date,
    ref_no text default null,
    description text default null,
    branch_gst json default null,
    party_gst json default null,
    amount float default null,
    party int default null,
    ac_trns jsonb default null,
    rcm bool default false,
    lut bool default false,
    eff_date date default null,
    counter_trns jsonb default null,
    tds_details jsonb default null
)
    returns voucher as
$$
declare
    v_gst_location_type typ_gst_location_type;
    v_voucher           voucher;
    j                   json;
    acc                 account;
begin
    if update_voucher.branch_gst ->> 'location' is not null and update_voucher.party_gst ->> 'location' is not null then
        if update_voucher.branch_gst ->> 'location' = update_voucher.party_gst ->> 'location' then
            v_gst_location_type = 'LOCAL';
        else
            v_gst_location_type = 'INTER_STATE';
        end if;
    elseif update_voucher.branch_gst ->> 'location' is not null and update_voucher.party_gst ->> 'location' is null then
        v_gst_location_type = 'LOCAL';
    end if;
    update voucher
    set date        = update_voucher.date,
        ref_no      = update_voucher.ref_no,
        eff_date    = update_voucher.eff_date,
        description = update_voucher.description,
        party_gst   = update_voucher.party_gst,
        party_id    = update_voucher.party,
        amount      = update_voucher.amount,
        ac_trns     = update_voucher.ac_trns,
        rcm         = update_voucher.rcm,
        lut         = update_voucher.lut,
        tds_details = update_voucher.tds_details,
        updated_at  = current_timestamp
    where id = $1
    returning * into v_voucher;
    delete from pos_counter_transaction where voucher_id = v_voucher.id and settlement_id is null;
    if FOUND and v_voucher.pos_counter_id is not null then
        insert into pos_counter_transaction (voucher_id, pos_counter_id, date, branch_id, branch_name, bill_amount,
                                             voucher_no, voucher_type_id, base_voucher_type, particular)
        values (v_voucher.id, v_voucher.pos_counter_id, v_voucher.date, v_voucher.branch_id, v_voucher.branch_name,
                v_voucher.amount, v_voucher.voucher_no, v_voucher.voucher_type_id, v_voucher.base_voucher_type,
                v_voucher.ref_no);
        for j in select jsonb_array_elements(addon.json_to_snake_case(update_voucher.counter_trns))
            loop
                select * into acc from account where account.id = (j ->> 'account_id')::int;
                insert into pos_counter_transaction_breakup (voucher_id, account_id, account_name, credit, debit)
                values (v_voucher.id, acc.id, acc.name, (j ->> 'credit')::float,
                        (j ->> 'debit')::float);
            end loop;
    end if;
    return v_voucher;
end;
$$ language plpgsql security definer;
--##
create function generate_voucher_no()
    returns trigger as
$$
begin
    declare
        fy     financial_year;
        br     branch;
        v_type voucher_type;
        seq_no int;
    begin
        select *
        into v_type
        from voucher_type
        where id = new.voucher_type_id;

        select *
        into br
        from branch
        where id = new.branch_id;

        select *
        into fy
        from financial_year
        where fy_start <= new.date
          and fy_end >= new.date;
        if not FOUND then
            raise exception 'Financial year not found';
        end if;
        insert into voucher_numbering(branch_id, f_year_id, voucher_type_id, seq)
        values (new.branch_id, fy.id, coalesce(v_type.sequence_id, v_type.id), 1)
        on conflict (branch_id, f_year_id, voucher_type_id) do update
            set seq = voucher_numbering.seq + 1
        returning seq into seq_no;

        if new.party_id is not null then
            select name into new.party_name from account where id = new.party_id;
        end if;

        new.branch_name = br.name;
        new.base_voucher_type = v_type.base_type;
        new.voucher_prefix = concat(br.voucher_no_prefix, v_type.prefix);
        new.voucher_fy = concat(to_char(fy.fy_start, 'yy'), to_char(fy.fy_end, 'yy'))::int;
        new.voucher_seq = seq_no;
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
    v_voucher voucher;
    apv_tag   int;
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
    select json_extract_path(approval, format('approve%s', v_voucher.approval_state + 1))::text
    into apv_tag
    from voucher_type
    where voucher_type.id = v_voucher.voucher_type_id;
    if not FOUND then
        raise exception 'Unable to get approval stage';
    end if;
    if not exists(select *
                  from approval_tag
                  where approval_tag.id = apv_tag
                    and current_setting('my.id')::int = any (members)) then
        raise exception 'Unable to get approval tag member/ Someone needs to approve';
    end if;
    update voucher set approval_state = $2 where id = $1 returning * into v_voucher;
    insert into approval_log(member_id, member_name, description, voucher_id, base_voucher_type, voucher_type_id,
                             voucher_no, approval_state)
    values (current_setting('my.id')::int, current_setting('my.name')::text, $3, $1, v_voucher.base_voucher_type,
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
create trigger gen_voucher_no_for_voucher
    before insert
    on voucher
    for each row
execute procedure generate_voucher_no();
--##
create function update_ac_txn()
    returns trigger as
$$
declare
    j              json;
    ex_ba          jsonb;
    ex_ta          jsonb;
    ex_bka         jsonb;
    i              json;
    acc            account;
    agent_acc      account;
    missed_ac_txns uuid[];
    missed_ba_ids  uuid[];
    missed_ta_ids  uuid[];
    missed_bka_ids uuid[];
    gst            gst_tax;
    cr_max_acc     account;
    dr_max_acc     account;
    is_mem         boolean := false;
    approved       boolean;
    p_id           uuid;
begin
    if new.base_voucher_type = 'MEMO' then
        is_mem = true;
    end if;
    if new.base_voucher_type != 'PAYMENT' and new.memo is not null then
        raise exception 'Memo conversion only allowed payment voucher';
    end if;
    if new.base_voucher_type = 'PAYMENT' and new.memo is not null then
        delete from voucher where id = new.memo;
    end if;

    select array(select distinct on (id,account) id
                 from (select id, account
                       from (select *
                             from jsonb_to_recordset(old.ac_trns) as dst(id uuid, account int)
                             except
                             select *
                             from jsonb_to_recordset(new.ac_trns) as src(id uuid, account int))))
    into missed_ac_txns;
    delete from ac_txn where id = any (missed_ac_txns);
    select *
    into dr_max_acc
    from account
    where id = (select (x ->> 'account')::int
                from jsonb_array_elements(new.ac_trns) x
                where (x ->> 'debit')::float > 0
                order by (x ->> 'debit')::float desc
                limit 1);
    select *
    into cr_max_acc
    from account
    where id = (select (x ->> 'account')::int
                from jsonb_array_elements(new.ac_trns) x
                where (x ->> 'credit')::float > 0
                order by (x ->> 'credit')::float desc
                limit 1);
    for j in select jsonb_array_elements(new.ac_trns)
        loop
            select * into acc from account where id = (j ->> 'account')::int;
            insert into ac_txn(id, date, eff_date, account_id, credit, debit, account_name, base_account_types,
                               branch_id,
                               branch_name, alt_account_id, alt_account_name, ref_no, voucher_id, voucher_no,
                               voucher_prefix, voucher_fy, voucher_seq, voucher_type_id, base_voucher_type,
                               voucher_mode, is_memo)
            values ((j ->> 'id')::uuid, new.date, new.eff_date, (j ->> 'account')::int, (j ->> 'credit')::float,
                    (j ->> 'debit')::float, acc.name, acc.base_account_types, new.branch_id, new.branch_name,
                    case when (j ->> 'credit')::float = 0 then cr_max_acc.id else dr_max_acc.id end,
                    case when (j ->> 'credit')::float = 0 then cr_max_acc.name else dr_max_acc.name end,
                    new.ref_no, new.id, new.voucher_no, new.voucher_prefix, new.voucher_fy, new.voucher_seq,
                    new.voucher_type_id, new.base_voucher_type, new.mode, is_mem)
            on conflict (id) do update
                SET date             = excluded.date,
                    eff_date         = excluded.eff_date,
                    credit           = excluded.credit,
                    debit            = excluded.debit,
                    account_name     = excluded.account_name,
                    branch_name      = excluded.branch_name,
                    alt_account_id   = excluded.alt_account_id,
                    alt_account_name = excluded.alt_account_name,
                    ref_no           = excluded.ref_no;
            if (j -> 'gst_tax') is not null then
                select * into gst from gst_tax where id = (j ->> 'gst_tax')::text;
                insert into gst_txn(ac_txn_id, date, eff_date, hsn_code, branch_id, branch_name, item, item_name,
                                    uqc_id, qty, party_id, party_name, branch_reg_type, branch_gst_no,
                                    branch_location_id, party_reg_type, gst_location_type, party_gst_no,
                                    party_location_id, lut, gst_tax_id, tax_name, tax_ratio, taxable_amount,
                                    cgst_amount, sgst_amount, igst_amount, cess_amount, total, amount,
                                    voucher_id, voucher_no, ref_no, voucher_type_id, base_voucher_type, voucher_mode)
                values ((j ->> 'id')::uuid, new.date, new.eff_date, (j ->> 'hsn_code')::text, new.branch_id,
                        new.branch_name, (j ->> 'account')::int, acc.name, coalesce((j ->> 'uqc')::text, 'OTH'),
                        coalesce((j ->> 'qty')::float, 1), new.party_id, new.party_name,
                        (new.branch_gst ->> 'reg_type')::typ_gst_reg_type, (new.branch_gst ->> 'gst_no')::text,
                        (new.branch_gst ->> 'location')::text, (new.party_gst ->> 'reg_type')::typ_gst_reg_type,
                        new.gst_location_type, (new.party_gst ->> 'gst_no')::text,
                        coalesce((new.party_gst ->> 'location')::text, (new.branch_gst ->> 'location')::text),
                        new.lut, (j ->> 'gst_tax')::text, gst.name, gst.igst,
                        coalesce((j ->> 'taxable_amount')::float, 0), coalesce((j ->> 'cgst_amount')::float, 0),
                        coalesce((j ->> 'sgst_amount')::float, 0), coalesce((j ->> 'igst_amount')::float, 0),
                        coalesce((j ->> 'cess_amount')::float, 0),
                        coalesce((j ->> 'taxable_amount')::float, 0) + coalesce((j ->> 'cgst_amount')::float, 0) +
                        coalesce((j ->> 'sgst_amount')::float, 0) + coalesce((j ->> 'igst_amount')::float, 0) +
                        coalesce((j ->> 'cess_amount')::float, 0), new.amount, new.id, new.voucher_no, new.ref_no,
                        new.voucher_type_id, new.base_voucher_type, new.mode)
                on conflict (ac_txn_id) do update
                    SET date              = excluded.date,
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
                        gst_location_type = excluded.gst_location_type,
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
            end if;

            select (x ->> 'bill_allocations')::jsonb
            into ex_ba
            from jsonb_array_elements(old.ac_trns) x
            where (x ->> 'id')::uuid = (j ->> 'id')::uuid;
            select array(select distinct on (id) id
                         from (select id
                               from (select *
                                     from jsonb_to_recordset(ex_ba) as dst(id uuid) --old
                                     except
                                     select *
                                     from jsonb_to_recordset((j ->> 'bill_allocations')::jsonb) as src(id uuid) -- new
                                    )))
            into missed_ba_ids;
            delete from bill_allocation where id = any (missed_ba_ids);

            if acc.account_type_id in ('SUNDRY_CREDITOR', 'SUNDRY_DEBTOR') then
                if jsonb_array_length((j ->> 'bill_allocations')::jsonb) > 0 then
                    select * into agent_acc from account where id = acc.agent_id;
                    for i in select * from jsonb_array_elements((j ->> 'bill_allocations')::jsonb)
                        loop
                            if (i ->> 'ref_type') = 'NEW' then
                                approved := case
                                                when (new.require_no_of_approval <> new.approval_state) then false
                                                else true end;
                                p_id = coalesce((i ->> 'pending')::uuid, gen_random_uuid());
                                if exists (select voucher_no
                                           from bill_allocation
                                           where pending = p_id
                                             and id <> (i ->> 'id')::uuid) then
                                    raise exception 'This new ref already exist';
                                end if;
                            elseif (i ->> 'ref_type') = 'ADJ' then
                                p_id = (i ->> 'pending')::uuid;
                                if p_id is null then raise exception 'pending must be required on adjusted ref'; end if;
                            else
                                p_id = null;
                            end if;
                            insert into bill_allocation (id, ac_txn_id, date, eff_date, is_memo, account_id, branch_id,
                                                         amount, pending, ref_type, ref_no, voucher_id, account_name,
                                                         base_account_types, branch_name, base_voucher_type,
                                                         voucher_mode,
                                                         voucher_no, agent_id, agent_name, is_approved)
                            values ((i ->> 'id')::uuid, (j ->> 'id')::uuid, new.date, coalesce(new.eff_date, new.date),
                                    is_mem, (j ->> 'account')::int, new.branch_id, (i ->> 'amount')::float, p_id,
                                    (i ->> 'ref_type')::typ_pending_ref_type,
                                    coalesce((i ->> 'ref_no')::text, new.ref_no), new.id, acc.name,
                                    acc.base_account_types,
                                    new.branch_name, new.base_voucher_type, new.mode, new.voucher_no, agent_acc.id,
                                    agent_acc.name, approved)
                            on conflict (id) do update
                                SET date        = excluded.date,
                                    eff_date    = excluded.eff_date,
                                    amount      = excluded.amount,
                                    agent_name  = excluded.agent_name,
                                    branch_name = excluded.branch_name,
                                    ref_type    = excluded.ref_type,
                                    ref_no      = excluded.ref_no,
                                    pending     = excluded.pending;
                        end loop;
                else
                    delete from bill_allocation where ac_txn_id = (j ->> 'id')::uuid;
                end if;
            end if;
            select (x ->> 'bank_allocations')::jsonb
            into ex_bka
            from jsonb_array_elements(old.ac_trns) x
            where (x ->> 'id')::uuid = (j ->> 'id')::uuid;

            select array(select distinct on (id, account) id
                         from (select id, account
                               from (select *
                                     from jsonb_to_recordset(ex_bka) as dst(id uuid, account int)
                                     except
                                     select *
                                     from jsonb_to_recordset((j ->> 'bank_allocations')::jsonb) as src(id uuid, account int))))
            into missed_bka_ids;
            delete from bank_txn where id = any (missed_bka_ids);
            if acc.account_type_id not in ('BANK_ACCOUNT', 'BANK_OD_ACCOUNT') and
               jsonb_array_length((j ->> 'bank_allocations')::jsonb) > 0 then
                raise exception 'bank_allocations allowed only bank transaction';
            end if;
            for i in select * from jsonb_array_elements((j ->> 'bank_allocations')::jsonb)
                loop
                    select * into cr_max_acc from account where id = (i ->> 'account')::int;
                    insert into bank_txn (id, ac_txn_id, date, inst_date, inst_no, in_favour_of, is_memo, debit, credit,
                                          account_id, account_name, base_account_types, alt_account_id,
                                          alt_account_name,
                                          particulars, branch_id, branch_name, voucher_id, voucher_no,
                                          base_voucher_type, bank_beneficiary_id, txn_type)
                    values ((i ->> 'id')::uuid, (j ->> 'id')::uuid, new.date, (i ->> 'inst_date')::date,
                            (i ->> 'inst_no')::text, (i ->> 'in_favour_of')::text, is_mem,
                            case when (i ->> 'amount')::float > 0 then (i ->> 'amount')::float else 0 end,
                            case when (i ->> 'amount')::float < 0 then abs((i ->> 'amount')::float) else 0 end,
                            (j ->> 'account')::int, acc.name, acc.base_account_types, cr_max_acc.id, cr_max_acc.name,
                            (i ->> 'particulars')::text, new.branch_id, new.branch_name, new.id, new.voucher_no,
                            new.base_voucher_type, (i ->> 'bank_beneficiary')::int,
                            (i ->> 'txn_type')::typ_bank_txn_type)
                    on conflict (id)
                        do update
                        set date                = excluded.date,
                            inst_date           = excluded.inst_date,
                            inst_no             = excluded.inst_no,
                            in_favour_of        = excluded.in_favour_of,
                            credit              = excluded.credit,
                            debit               = excluded.debit,
                            txn_type            = excluded.txn_type,
                            bank_beneficiary_id = excluded.bank_beneficiary_id,
                            alt_account_name    = excluded.alt_account_name,
                            particulars         = excluded.particulars,
                            alt_account_id      = excluded.alt_account_id,
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
                end loop;
            select (x ->> 'category_allocations')::jsonb
            into ex_ta
            from jsonb_array_elements(old.ac_trns) x
            where (x ->> 'id')::uuid = (j ->> 'id')::uuid;

            select array(select distinct on (id) id
                         from (select id
                               from (select *
                                     from jsonb_to_recordset(ex_ta) as dst(id uuid)
                                     except
                                     select *
                                     from jsonb_to_recordset((j ->> 'category_allocations')::jsonb) as src(id uuid))))
            into missed_ta_ids;
            delete from acc_cat_txn where id = any (missed_ta_ids);
            for i in select * from jsonb_array_elements((j ->> 'category_allocations')::jsonb)
                loop
                    insert into acc_cat_txn (id, ac_txn_id, date, account_id, account_name, base_account_types,
                                             branch_id,
                                             branch_name, amount, voucher_id, voucher_no, base_voucher_type,
                                             voucher_type_id, voucher_mode, ref_no, is_memo, category1_id, category2_id,
                                             category3_id, category4_id, category5_id)
                    values ((i ->> 'id')::uuid, (j ->> 'id')::uuid, new.date, (j ->> 'account')::int, acc.name,
                            acc.account_type_id, new.branch_id, new.branch_name, (i ->> 'amount')::float, new.id,
                            new.voucher_no, new.base_voucher_type, new.voucher_type_id, new.mode, new.ref_no, is_mem,
                            (i ->> 'category1')::int, (i ->> 'category2')::int, (i ->> 'category3')::int,
                            (i ->> 'category4')::int, (i ->> 'category5')::int)
                    on conflict (id) do update
                        SET date         = excluded.date,
                            account_name = excluded.account_name,
                            branch_name  = excluded.branch_name,
                            amount       = excluded.amount,
                            category1_id = excluded.category1_id,
                            category2_id = excluded.category2_id,
                            category3_id = excluded.category3_id,
                            category4_id = excluded.category4_id,
                            category5_id = excluded.category5_id;
                end loop;
        end loop;
    delete from tds_on_voucher where voucher_id = new.id;
    for j in select jsonb_array_elements(new.tds_details)
        loop
            insert into tds_on_voucher (id, date, eff_date, party_account_id, party_name, tds_account_id, tds_ratio,
                                        tds_nature_of_payment_id, tds_deductee_type_id, branch_id, branch_name, amount,
                                        tds_amount, base_voucher_type, voucher_no, voucher_id, tds_section, ref_no)
            values (gen_random_uuid(), new.date, coalesce(new.eff_date, new.date), (j ->> 'party_account')::int,
                    (j ->> 'party_name')::text, (j ->> 'tds_account')::int, (j ->> 'tds_ratio')::float,
                    (j ->> 'tds_nature_of_payment')::int, (j ->> 'tds_deductee_type')::text, new.branch_id,
                    new.branch_name, (j ->> 'amount')::float, (j ->> 'tds_amount')::float, new.base_voucher_type,
                    new.voucher_no, new.id, (j ->> 'tds_section')::text, new.ref_no);
        end loop;
    return new;
end;
$$ language plpgsql;
--##
create trigger update_voucher_ac_trns
    after update
    on voucher
    for each row
execute procedure update_ac_txn();
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
            if array ['SUNDRY_CREDITOR', 'SUNDRY_DEBTOR'] && acc.base_account_types and
               jsonb_array_length((j ->> 'bill_allocations')::jsonb) = 0 then
                raise exception 'bill_allocations required for Sundry type';
            end if;
            if array ['BANK_ACCOUNT', 'BANK_OD_ACCOUNT'] && acc.base_account_types and
               jsonb_array_length((j ->> 'bank_allocations')::jsonb) = 0 then
                raise exception 'bank_allocations required for Bank type';
            end if;
            insert into ac_txn(id, date, eff_date, account_id, credit, debit, account_name, base_account_types,
                               branch_id, branch_name, alt_account_id, alt_account_name, ref_no, voucher_id, voucher_no,
                               voucher_prefix, voucher_fy, voucher_seq, voucher_type_id, base_voucher_type,
                               voucher_mode, is_memo, is_default)
            values (coalesce((j ->> 'id')::uuid, gen_random_uuid()), $1.date, $1.eff_date, (j ->> 'account_id')::int,
                    (j ->> 'credit')::float, (j ->> 'debit')::float, acc.name, acc.base_account_types, $1.branch_id,
                    $1.branch_name, case when (j ->> 'credit')::float = 0 then cr_max_acc.id else dr_max_acc.id end,
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
            $1.party_name, ($1.branch_gst ->> 'reg_type')::typ_gst_reg_type, ($1.branch_gst ->> 'gst_no')::text,
            ($1.branch_gst ->> 'location_id')::text, ($1.party_gst ->> 'reg_type')::typ_gst_reg_type,
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
$$ language plpgsql security definer;
--##
create function insert_cat_allocation(voucher, jsonb, ac_txn)
    returns boolean as
$$
declare
    i json;
begin
    for i in select jsonb_array_elements($2)
        loop
            insert into acc_cat_txn (id, ac_txn_id, date, account_id, account_name, base_account_types, branch_id,
                                     branch_name, amount, voucher_id, voucher_no, base_voucher_type, voucher_type_id,
                                     voucher_mode, ref_no, is_memo, category1_id, category2_id, category3_id,
                                     category4_id, category5_id)
            values (coalesce((i ->> 'id')::uuid, gen_random_uuid()), $3.id, $1.date, $3.account_id, $3.account_name,
                    $3.base_account_types, $1.branch_id, $1.branch_name, (i ->> 'amount')::float, $1.id, $1.voucher_no,
                    $1.base_voucher_type, $1.voucher_type_id, $1.mode, $1.ref_no, $3.is_memo,
                    (i ->> 'category1_id')::int, (i ->> 'category2_id')::int, (i ->> 'category3_id')::int,
                    (i ->> 'category4_id')::int, (i ->> 'category5_id')::int);
        end loop;
    return true;
end;
$$ language plpgsql security definer;
--##
create function insert_bill_allocation(voucher, jsonb, ac_txn)
    returns bool as
$$
declare
    agent_acc account;
    i         json;
    p_id      uuid;
begin
    select * into agent_acc from account where id = (select agent_id account where id = $3.account_id);
    for i in select jsonb_array_elements($2)
        loop
            if (i ->> 'ref_type') = 'NEW' then
                p_id = coalesce((i ->> 'pending')::uuid, gen_random_uuid());
                if exists (select id from bill_allocation where pending = p_id) then
                    raise exception 'This new ref already exist';
                end if;
            elseif (i ->> 'ref_type') = 'ADJ' then
                p_id = (i ->> 'pending')::uuid;
                if p_id is null then raise exception 'pending must be required on adjusted ref'; end if;
            else
                p_id = null;
            end if;
            insert into bill_allocation (id, ac_txn_id, date, eff_date, is_memo, account_id, branch_id, amount, pending,
                                         ref_type, ref_no, voucher_id, account_name, base_account_types, branch_name,
                                         base_voucher_type, voucher_mode, voucher_no, agent_id, agent_name, is_approved)
            values (coalesce((i ->> 'id')::uuid, gen_random_uuid()), $3.id, $1.date, coalesce($1.eff_date, $1.date),
                    $3.is_memo, $3.account_id, $1.branch_id, (i ->> 'amount')::float, p_id,
                    (i ->> 'ref_type')::typ_pending_ref_type, coalesce((i ->> 'ref_no')::text, $3.ref_no), $1.id,
                    $3.account_name, $3.base_account_types, $1.branch_name, $1.base_voucher_type, $1.mode,
                    $1.voucher_no, agent_acc.id, agent_acc.name, $1.require_no_of_approval = $1.approval_state);
        end loop;
    return true;
end;
$$ language plpgsql security definer;
--##
create function insert_bank_allocation(voucher, jsonb, ac_txn)
    returns bool as
$$
declare
    alt_acc account;
    i       json;
begin
    for i in select jsonb_array_elements($2)
        loop
            select * into alt_acc from account where id = (i ->> 'account_id')::int;
            insert into bank_txn (id, ac_txn_id, date, inst_date, inst_no, in_favour_of, is_memo, amount,
                                  account_id, account_name, base_account_types, alt_account_id, alt_account_name,
                                  particulars, branch_id, branch_name, voucher_id, voucher_no, base_voucher_type,
                                  bank_beneficiary_id, txn_type)
            values (coalesce((i ->> 'id')::uuid, gen_random_uuid()), $3.id, $1.date, (i ->> 'inst_date')::date,
                    (i ->> 'inst_no')::text, (i ->> 'in_favour_of')::text, $3.is_memo, (i ->> 'amount')::float,
                    $3.account_id, $3.account_name, $3.base_account_types, alt_acc.id, alt_acc.name,
                    (i ->> 'particulars')::text, $1.branch_id, $1.branch_name, $1.id, $1.voucher_no,
                    $1.base_voucher_type, (i ->> 'bank_beneficiary_id')::int, (i ->> 'txn_type')::typ_bank_txn_type);
        end loop;
    return true;
end;
$$ language plpgsql security definer;