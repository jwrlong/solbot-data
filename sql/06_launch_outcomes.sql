-- Sniping buys new launches. Almost all of them never graduate.
-- Mayhem mode is a third of launches but comes from a few hundred deployers.

SELECT
    CASE WHEN l.is_mayhem_mode THEN 'mayhem' ELSE 'normal' END AS launch_type,
    count(*) AS launches,
    count(DISTINCT l.deployer) AS deployers,
    count(g.mint) AS graduated,
    round(100.0 * count(g.mint) / count(*), 2) AS graduation_pct,
    count(*) FILTER (WHERE g.slot = l.slot) AS instant_graduations
FROM launches AS l
LEFT JOIN graduations AS g USING (mint)
GROUP BY 1
ORDER BY launches DESC;
