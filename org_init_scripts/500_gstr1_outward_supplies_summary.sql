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
create function outward_supplies_summary(from_date date, to_date date, gst_no text) returns json
as
$$
declare
    hsn_summary   json;
    b2cs_summary  json;
    b2b_details   json;
    b2cl_details  json;
    nil_summary   json;
    docs_summary  json;
    cdnr_summary  json;
    cdnur_summary json;
begin
    -- cdnr_summary
    with res as (select json_build_object(
                                'gstNo', party_gst_no,
                                'partyName', party_name,
                                'noteNo', voucher_no,
                                'noteDate', date,
                                'noteType', left(base_voucher_type::text, 1),
                                'noteAmt', amount,
                                'pos', party_location_id,
                                'revCharge', 'N',
                                'taxable', taxable_amount,
                                'taxRatio', tax_ratio,
                                'cgst', cgst_amount,
                                'sgst', sgst_amount,
                                'igst', igst_amount,
                                'cess', cess_amount,
                                'total', total,
                                'supplyType', convert_to_b2b_invoice_type(party_reg_type, lut)) as data
                 from gst_txn
                 where base_voucher_type in ('CREDIT_NOTE', 'DEBIT_NOTE')
                   and (date between from_date and to_date)
                   and branch_gst_no = gst_no
                   and party_gst_no is not null)
    select json_agg(data)
    from res
    into cdnr_summary;

    -- cdnur_summary
    --export return vouchers, b2cl return vouchers
    with res as (select json_build_object('noteNo', voucher_no,
                                          'noteDate', date,
                                          'noteType', left(base_voucher_type::text, 1),
                                          'noteAmt', amount,
                                          'supplyType',
                                          convert_to_cdnur_invoice_type(party_reg_type, gst_location_type, lut),
                                          'pos', party_location_id,
                                          'taxRatio', tax_ratio,
                                          'taxable', taxable_amount,
                                          'cgst', cgst_amount,
                                          'sgst', sgst_amount,
                                          'igst', igst_amount,
                                          'cess', cess_amount,
                                          'total', total) as data
                 from gst_txn
                 where base_voucher_type in ('CREDIT_NOTE', 'DEBIT_NOTE')
                   and (date between from_date and to_date)
                   and branch_gst_no = gst_no
                   and party_gst_no IS NULL
                   and party_reg_type in ('UNREGISTERED', 'IMPORT_EXPORT')
                   and gst_location_type = 'INTER_STATE'
                   and amount > 250000)
    select json_agg(data)
    from res
    into cdnur_summary;

    -- hsn_summary
    with res as (select json_build_object(
                                'description', min(item_name),
                                'uqc', uqc_id,
                                'hsnSacCode', hsn_code,
                                'qty', sum(qty),
                                'taxRatio', min(tax_ratio),
                                'taxable', sum(taxable_amount),
                                'cgst', sum(cgst_amount),
                                'sgst', sum(sgst_amount),
                                'igst', sum(igst_amount),
                                'cess', sum(cess_amount),
                                'total', sum(total)
                        ) as data
                 from gst_txn
                 where base_voucher_type = 'SALE'
                   and (date between from_date and to_date)
                   and branch_gst_no = gst_no
                   and hsn_code is not null
                 group by tax_ratio, hsn_code, uqc_id)
    select json_agg(data)
    from res
    into hsn_summary;

    --b2cs summary
    with res as (select json_build_object(
                                'pos', party_location_id,
                                'typ', 'OE',
                                'supplyType', convert_to_b2cs_supply_type(gst_location_type),
                                'taxRatio', tax_ratio,
                                'taxable', sum(taxable_amount),
                                'cgst', sum(cgst_amount),
                                'sgst', sum(sgst_amount),
                                'igst', sum(igst_amount),
                                'cess', sum(cess_amount),
                                'total', sum(total)) as data
                 from gst_txn
                 where base_voucher_type = 'SALE'
                   and (date between from_date and to_date)
                   and branch_gst_no = gst_no
                   and party_gst_no IS NULL
                   and party_reg_type = 'UNREGISTERED'
                   and (gst_location_type = 'LOCAL'
                     or (gst_location_type = 'INTER_STATE' and amount <= 250000)
                     )
                   and gst_tax_id not in ('gstna', 'gstngs', 'gstexempt')
                 group by party_location_id,
                          gst_location_type,
                          tax_ratio)
    select json_agg(data)
    from res
    into b2cs_summary;


    -- b2cl details
    with res as (select json_build_object('id', voucher_id,
                                          'pos', party_location_id,
                                          'mode', voucher_mode,
                                          'invNo', voucher_no,
                                          'voucherType', base_voucher_type,
                                          'invDate', date,
                                          'invAmt', amount,
                                          'taxRatio', tax_ratio,
                                          'taxable', taxable_amount,
                                          'cgst', cgst_amount,
                                          'sgst', sgst_amount,
                                          'igst', igst_amount,
                                          'cess', cess_amount,
                                          'total', total) as data
                 from gst_txn
                 where base_voucher_type = 'SALE'
                   and (date between from_date and to_date)
                   and branch_gst_no = gst_no
                   and party_gst_no IS NULL
                   and party_reg_type = 'UNREGISTERED'
                   and gst_location_type = 'INTER_STATE'
                   and gst_tax_id not in ('gstna', 'gstngs', 'gstexempt')
                   and amount > 250000)
    select json_agg(data)
    from res
    into b2cl_details;

    -- b2b details
    -- filter sale voucher & 0 taxes
    with res as (select json_build_object(
                                'id', voucher_id,
                                'gstNo', party_gst_no,
                                'pos', party_location_id,
                                'revCharge', 'N',
                                'voucherMode', voucher_mode,
                                'voucherType', base_voucher_type,
                                'invNo', voucher_no,
                                'invType', convert_to_b2b_invoice_type(party_reg_type, lut),
                                'invDate', date,
                                'invAmt', amount,
                                'taxRatio', tax_ratio,
                                'taxable', taxable_amount,
                                'cgst', cgst_amount,
                                'sgst', sgst_amount,
                                'igst', igst_amount,
                                'cess', cess_amount,
                                'total', total) as data
                 from gst_txn
                 where base_voucher_type = 'SALE'
                   and (date between from_date and to_date)
                   and branch_gst_no = gst_no
                   and party_gst_no is not null
                   and party_reg_type in ('REGULAR', 'SPECIAL_ECONOMIC_ZONE')
                   and gst_tax_id not in ('gstna', 'gstngs', 'gstexempt'))
    select json_agg(data)
    from res
    into b2b_details;

    -- nil summary
    with s1 as (select gst_tax_id                                                    as tax,
                       sum(taxable_amount)                                           as total,
                       convert_to_nil_supply_type(party_reg_type, gst_location_type) as supply_type
                from gst_txn
                where "base_voucher_type" = 'SALE'
                  and (date between from_date and to_date)
                  and branch_gst_no = gst_no
                  and gst_tax_id in ('gst0', 'gstngs', 'gstexempt')
                group by party_reg_type, gst_location_type, gst_tax_id),
         res as (select json_build_object('supplyType', s1.supply_type,
                                          'exptAmt',
                                          (sum(case when (s1.tax = 'gstexempt') then s1.total else 0 end)::numeric(10, 2))::float,
                                          'ngsupAmt',
                                          (sum(case when (s1.tax = 'gstngs') then s1.total else 0 end)::numeric(10, 2))::float,
                                          'nilAmt',
                                          (sum(case when (s1.tax = 'gst0') then s1.total else 0 end)::numeric(10, 2))::float) as data
                 from s1
                 group by s1.supply_type)
    select json_agg(data)
    from res
    into nil_summary;

    -- docs summary
    with s1 as (select voucher_id, min(voucher_no) as voucher_no
                from gst_txn
                where "base_voucher_type" = 'SALE'
                  and (date between from_date and to_date)
                  and branch_gst_no = gst_no
                group by voucher_id
                order by voucher_id),
         res as (select (case
                             when count(s1.voucher_id) > 0 then json_build_object(
                                     'totnum', count(s1.voucher_id),
                                     'netIssue', count(s1.voucher_id),
                                     'cancel', 0,
                                     'docTyp', 'Invoices for outward supply',
                                     'from', (array_agg(s1.voucher_no))[1],
                                     'to', (array_agg(s1.voucher_no))[count(s1.voucher_id)])
                             else null end
                            ) as data
                 from s1)
    select json_agg(data)
    into docs_summary
    from res
    where data is not null;


    return json_build_object(
            'cdnr', coalesce(cdnr_summary, '[]'::json),
            'cdnur', coalesce(cdnur_summary, '[]'::json),
            'hsn', coalesce(hsn_summary, '[]'::json),
            'b2b', coalesce(b2b_details, '[]'::json),
            'b2cs', coalesce(b2cs_summary, '[]'::json),
            'b2cl', coalesce(b2cl_details, '[]'::json),
            'exp', '[]'::json,
            'nil', coalesce(nil_summary, '[]'::json),
            'docs', coalesce(docs_summary, '[]'::json)
           );
end
$$ language plpgsql;
