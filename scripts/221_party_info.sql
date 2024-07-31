create function party_info(batch_id int)
    returns table
            (
                party_id      int,
                party_name    text,
                closing       float,
                landing_value float,
                cost_value    float,
                nlc_value     float
            )
as
$$
declare
    bat batch := (select batch
                  from batch
                  where id = $1);
begin
    return query
        with a as (select b.party_id,
                          min(b.party_name)         as party_name,
                          sum(b.inward - b.outward) as closing
                   from inv_txn b
                   where b.batch_id = $1
                   group by b.party_id)
        select a.party_id,
               a.party_name,
               a.closing,
               a.closing * coalesce(bat.landing_cost, 0),
               a.closing * coalesce(bat.p_rate, 0),
               a.closing * bat.nlc
        from a
        order by a.closing desc, a.party_name;
end;
$$ language plpgsql security definer
                    immutable;