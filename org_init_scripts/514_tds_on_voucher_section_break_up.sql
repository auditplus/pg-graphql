create function tds_on_voucher_section_break_up(from_date date, to_date date, branches bigint[])
    RETURNS table
            (
                section                      text,
                total                        float,
                total_tax_deducted_at_source float,
                total_after_tds_deduction    float
            )
AS
$$
begin
    return QUERY
        SELECT tds_section,
               sum(amount),
               sum(tds_amount),
               sum(amount - tds_amount)
        FROM tds_on_voucher
        WHERE (date BETWEEN $1 AND $2)
          AND (CASE
                   WHEN array_length($3, 1) > 0 THEN tds_on_voucher.branch_id = ANY ($3)
                   ELSE true END)
        group by tds_section
        order by tds_section;
end;
$$ language plpgsql;