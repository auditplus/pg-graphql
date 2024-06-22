create function party_info(batch_id int)
    returns jsonb as
$$
declare
    bat batch := (select batch
                  from batch
                  where id = $1);
begin
    return
        (with a as (select party_id,
                           min(party_name)       as party_name,
                           sum(inward - outward) as closing
                    from inv_txn
                    where inv_txn.batch_id = $1
                    group by party_id
                    order by closing desc, party_name)
         select jsonb_agg(jsonb_build_object('party_id', a.party_id, 'party_name', a.party_name, 'closing', a.closing,
                                             'landing_value', a.closing * coalesce(bat.landing_cost, 0), 'cost_value',
                                             a.closing * coalesce(bat.p_rate, 0), 'nlc_value', a.closing * bat.nlc))
         from a);
end;
$$ language plpgsql;