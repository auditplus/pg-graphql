create function convert_to_b2cs_supply_type(gst_location_type text) returns text as
$$
begin
    return CASE
               when (gst_location_type = 'LOCAL') then 'INTRA'
               when (gst_location_type = 'INTER_STATE') then 'INTER'
        end;
end
$$ language plpgsql;
--##
create function convert_to_b2b_invoice_type(reg_type text, lut bool) returns text as
$$
begin
    return
        CASE
            when (reg_type = 'REGULAR') then 'Regular B2B'
            when (reg_type = 'SPECIAL_ECONOMIC_ZONE' and lut = true) then 'SEZ supplies without payment'
            when (reg_type = 'SPECIAL_ECONOMIC_ZONE' and lut = false) then 'SEZ supplies with payment' end;
end
$$ language plpgsql;
--##
create function convert_to_nil_supply_type(reg_type text, location_type text) returns text as
$$
begin
    return
        CASE
            when (reg_type = 'UNREGISTERED' and location_type = 'LOCAL')
                then 'Intra-State supplies to unregistered persons'
            when (reg_type = 'UNREGISTERED' and location_type <> 'LOCAL')
                then 'Inter-State supplies to unregistered persons'
            when (reg_type <> 'UNREGISTERED' and location_type = 'LOCAL')
                then 'Intra-State supplies to registered persons'
            when (reg_type <> 'UNREGISTERED' and location_type <> 'LOCAL')
                then 'Inter-State supplies to registered persons'
            end;
end
$$ language plpgsql;
--##
create function convert_to_cdnur_invoice_type(reg_type text, location_type text,
                                              lut bool) returns text as
$$
begin
    return
        CASE
            when (reg_type = 'UNREGISTERED' and location_type <> 'LOCAL')
                then 'Inter-State supplies to unregistered persons'
            when (reg_type = 'SPECIAL_ECONOMIC_ZONE' and lut = true)
                then 'SEZ supplies without payment'
            when (reg_type = 'SPECIAL_ECONOMIC_ZONE' and lut = false)
                then 'SEZ supplies with payment'
            end;
end
$$ language plpgsql;
--##
--select * from cdnr_summary('{"from_date": "2024-07-01","to_date":"2024-08-01","gst_no":"33AAACT5558K1Z4"}'::json);
create function cdnr_summary(input json)
    returns table
            (
                gst_no      text,
                party_name  text,
                note_no     text,
                note_date   date,
                note_type   text,
                note_amt    float,
                pos         text,
                rev_charge  text,
                taxable     float,
                tax_ratio   float,
                cgst        float,
                sgst        float,
                igst        float,
                cess        float,
                total       float,
                supply_type text
            )
AS
$$
declare
    from_date date := (input ->> 'from_date')::date;
    to_date   date := (input ->> 'to_date')::date;
    gst_no    text := (input ->> 'gst_no')::text;
begin
    -- cdnr_summary
    return query
        select gst_txn.party_gst_no,
               gst_txn.party_name,
               gst_txn.voucher_no,
               gst_txn.date,
               left(gst_txn.base_voucher_type::text, 1),
               gst_txn.amount,
               gst_txn.party_location_id,
               'N',
               gst_txn.taxable_amount,
               gst_txn.tax_ratio,
               gst_txn.cgst_amount,
               gst_txn.sgst_amount,
               gst_txn.igst_amount,
               gst_txn.cess_amount,
               gst_txn.total,
               convert_to_b2b_invoice_type(gst_txn.party_reg_type, gst_txn.lut)
        from gst_txn
        where base_voucher_type in ('CREDIT_NOTE', 'DEBIT_NOTE')
          and (date between from_date and to_date)
          and branch_gst_no = gst_no
          and party_gst_no is not null;

end
$$ immutable language plpgsql
   security definer;
--##
--select * from cdnur_summary('{"from_date": "2024-07-01","to_date":"2024-08-01","gst_no":"33AAACT5558K1Z4"}'::json);
create function cdnur_summary(input json)
    returns table
            (
                note_no     text,
                note_date   date,
                note_type   text,
                note_amt    float,
                supply_type text,
                pos         text,
                taxable     float,
                tax_ratio   float,
                cgst        float,
                sgst        float,
                igst        float,
                cess        float,
                total       float
            )
AS
$$
declare
    from_date date := (input ->> 'from_date')::date;
    to_date   date := (input ->> 'to_date')::date;
    gst_no    text := (input ->> 'gst_no')::text;
begin
    --cdnur_summary
    --export return vouchers, b2cl return vouchers
    return query
        select gst_txn.voucher_no,
               gst_txn.date,
               left(gst_txn.base_voucher_type::text, 1),
               gst_txn.amount,
               convert_to_cdnur_invoice_type(gst_txn.party_reg_type, gst_txn.gst_location_type, gst_txn.lut),
               gst_txn.party_location_id,
               gst_txn.taxable_amount,
               gst_txn.tax_ratio,
               gst_txn.cgst_amount,
               gst_txn.sgst_amount,
               gst_txn.igst_amount,
               gst_txn.cess_amount,
               gst_txn.total
        from gst_txn
        where gst_txn.base_voucher_type in ('CREDIT_NOTE', 'DEBIT_NOTE')
          and (gst_txn.date between from_date and to_date)
          and gst_txn.branch_gst_no = gst_no
          and gst_txn.party_gst_no IS NULL
          and gst_txn.party_reg_type in ('UNREGISTERED', 'IMPORT_EXPORT')
          and gst_txn.gst_location_type = 'INTER_STATE'
          and gst_txn.amount > 250000;
end
$$ immutable language plpgsql
   security definer;
--##
create function hsn_summary(input json)
    returns table
            (
                description     text,
                uqc text,
                hsn_sac_code text,
                qty float,
                taxable     float,
                tax_ratio   float,
                cgst        float,
                sgst        float,
                igst        float,
                cess        float,
                total       float
            )
AS
$$
declare
    from_date date := (input ->> 'from_date')::date;
    to_date   date := (input ->> 'to_date')::date;
    gst_no    text := (input ->> 'gst_no')::text;
begin
    -- hsn_summary
    return query
    select min(gst_txn.item_name), gst_txn.uqc_id, gst_txn.hsn_code, sum(gst_txn.qty), sum(gst_txn.taxable_amount), min(gst_txn.tax_ratio),
    sum(gst_txn.cgst_amount), sum(gst_txn.sgst_amount), sum(gst_txn.igst_amount), sum(gst_txn.cess_amount), sum(gst_txn.total)
     from gst_txn
     where gst_txn.base_voucher_type = 'SALE'
       and (gst_txn.date between from_date and to_date)
       and gst_txn.branch_gst_no = gst_no
       and gst_txn.hsn_code is not null
     group by gst_txn.tax_ratio, gst_txn.hsn_code, gst_txn.uqc_id;

end
$$ immutable language plpgsql
   security definer;
--##
create function b2cs_summary(input json)
    returns table
            (
                pos         text,
                typ         text,
                supply_type text,
                taxable     float,
                tax_ratio   float,
                cgst        float,
                sgst        float,
                igst        float,
                cess        float,
                total       float
            )
AS
$$
declare
    from_date date := (input ->> 'from_date')::date;
    to_date   date := (input ->> 'to_date')::date;
    gst_no    text := (input ->> 'gst_no')::text;
begin
    --b2cs summary
    return query
        select a.party_location_id,
               'OE',
               convert_to_b2cs_supply_type(a.gst_location_type),
               sum(a.taxable_amount),
               a.tax_ratio,
               sum(a.cgst_amount),
               sum(a.sgst_amount),
               sum(a.igst_amount),
               sum(a.cess_amount),
               sum(a.total)
        from gst_txn as a
        where a.base_voucher_type = 'SALE'
          and (a.date between from_date and to_date)
          and a.branch_gst_no = gst_no
          and a.party_gst_no IS NULL
          and a.party_reg_type = 'UNREGISTERED'
          and (a.gst_location_type = 'LOCAL'
            or (a.gst_location_type = 'INTER_STATE' and a.amount <= 250000)
            )
          and a.gst_tax_id not in ('gstna', 'gstngs', 'gstexempt')
        group by a.party_location_id,
                 a.gst_location_type,
                 a.tax_ratio;

end
$$ immutable language plpgsql
   security definer;
--##
create function b2cl_summary(input json)
    returns table
            (
                id           int,
                pos          text,
                mode         text,
                inv_no       text,
                voucher_type text,
                inv_date     date,
                inv_amt      float,
                taxable      float,
                tax_ratio    float,
                cgst         float,
                sgst         float,
                igst         float,
                cess         float,
                total        float
            )
AS
$$
declare
    from_date date := (input ->> 'from_date')::date;
    to_date   date := (input ->> 'to_date')::date;
    gst_no    text := (input ->> 'gst_no')::text;
begin
    --b2cl summary
    return query
        select a.voucher_id,
               a.party_location_id,
               a.voucher_mode,
               a.voucher_no,
               a.base_voucher_type,
               a.date,
               a.amount,
               a.taxable_amount,
               a.tax_ratio,
               a.cgst_amount,
               a.sgst_amount,
               a.igst_amount,
               a.cess_amount,
               a.total
        from gst_txn as a
        where a.base_voucher_type = 'SALE'
          and (a.date between from_date and to_date)
          and a.branch_gst_no = gst_no
          and a.party_gst_no IS NULL
          and a.party_reg_type = 'UNREGISTERED'
          and a.gst_location_type = 'INTER_STATE'
          and a.gst_tax_id not in ('gstna', 'gstngs', 'gstexempt')
          and a.amount > 250000;

end
$$ immutable language plpgsql
   security definer;
--##   
create function b2b_summary(input json)
    returns table
            (
                id           int,
                gst_no       text,
                pos          text,
                rev_charge   text,
                voucher_mode text,
                voucher_type text,
                inv_no       text,
                inv_type     text,
                inv_date     date,
                inv_amt      float,
                taxable      float,
                tax_ratio    float,
                cgst         float,
                sgst         float,
                igst         float,
                cess         float,
                total        float
            )
AS
$$
declare
    from_date date := (input ->> 'from_date')::date;
    to_date   date := (input ->> 'to_date')::date;
    gst_no    text := (input ->> 'gst_no')::text;
begin
    -- b2b details
    -- filter sale voucher & 0 taxes
    return query
    select a.voucher_id,
           a.party_gst_no,
           a.party_location_id,
           'N',
           a.voucher_mode,
           a.base_voucher_type,
           a.voucher_no,
           convert_to_b2b_invoice_type(a.party_reg_type, a.lut),
           a.date,
           a.amount,
           a.taxable_amount,
           a.tax_ratio,
           a.cgst_amount,
           a.sgst_amount,
           a.igst_amount,
           a.cess_amount,
           a.total
    from gst_txn as a
    where a.base_voucher_type = 'SALE'
      and (a.date between from_date and to_date)
      and a.branch_gst_no = gst_no
      and a.party_gst_no is not null
      and a.party_reg_type in ('REGULAR', 'SPECIAL_ECONOMIC_ZONE')
      and a.gst_tax_id not in ('gstna', 'gstngs', 'gstexempt');

end
$$ immutable language plpgsql
   security definer;
--##   
create function nil_summary(input json)
    returns table
            (
                supply_type text,
                expt_amt   float,
                ngsup_amt  float,
                nil_amt    float
            )
AS
$$
declare
    from_date date := (input ->> 'from_date')::date;
    to_date   date := (input ->> 'to_date')::date;
    gst_no    text := (input ->> 'gst_no')::text;
begin
    -- nil summary
    return query
        with s1 as (select gst_tax_id                                                    as tax,
                           sum(taxable_amount)                                           as total,
                           convert_to_nil_supply_type(party_reg_type, gst_location_type) as supply_type
                    from gst_txn
                    where "base_voucher_type" = 'SALE'
                      and (date between from_date and to_date)
                      and branch_gst_no = gst_no
                      and gst_tax_id in ('gst0', 'gstngs', 'gstexempt')
                    group by party_reg_type, gst_location_type, gst_tax_id)
        select s1.supply_type,
               (sum(case when (s1.tax = 'gstexempt') then s1.total else 0 end)::numeric(10, 2))::float,
               (sum(case when (s1.tax = 'gstngs') then s1.total else 0 end)::numeric(10, 2))::float,
               (sum(case when (s1.tax = 'gst0') then s1.total else 0 end)::numeric(10, 2))::float
        from s1
        group by s1.supply_type;

end
$$ immutable language plpgsql
   security definer;
--##   
create function docs_summary(input json)
returns table
(
    totnum int,
    net_issue int,
    cancel int,
    doc_typ text,
    "from" text,
    "to" text
)
AS
$$
declare
    from_date date := (input ->> 'from_date')::date;
    to_date   date := (input ->> 'to_date')::date;
    gst_no    text := (input ->> 'gst_no')::text;
begin
    -- docs summary
    return query
    with s1 as (select voucher_id, min(voucher_no) as voucher_no
            from gst_txn
            where base_voucher_type = 'SALE'
              and (date between from_date and to_date)
              and branch_gst_no = gst_no
            group by voucher_id
            order by voucher_id)
     select
         count(s1.voucher_id)::int,
         count(s1.voucher_id)::int,
         0::int,
         'Invoices for outward supply',
         (array_agg(s1.voucher_no))[1],
         (array_agg(s1.voucher_no))[count(s1.voucher_id)]
    from s1;

end
$$ immutable language plpgsql
   security definer;
--##   