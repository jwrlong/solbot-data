-- Most new tokens never leave the bonding curve.
-- Of the ones that do, many graduate in the same slot they launched:
-- the creator bought out the curve immediately. That is a different market
-- from an ordinary new token.

SELECT
    CASE WHEN l.is_mayhem_mode THEN 'mayhem' ELSE 'normal' END AS launch_type,
    count(*) AS launches,
    count(g.mint) AS graduated,
    round(100.0 * count(g.mint) / count(*), 2) AS graduation_pct,
    count(*) FILTER (WHERE g.slot = l.slot) AS graduated_same_slot,
    round(
        100.0 * count(*) FILTER (WHERE g.slot = l.slot) / nullif(count(g.mint), 0),
        1
    ) AS same_slot_pct_of_graduations
FROM launches AS l
LEFT JOIN graduations AS g USING (mint)
GROUP BY 1
ORDER BY 1;
