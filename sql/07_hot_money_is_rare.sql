-- The bot's profitable rule does not buy every graduation.
-- It buys an instant graduation only when at least 300 SOL is bought
-- in the pool within about two slots. That set is small.
-- 150 SOL is the fragile cutoff: the median early buy sits just under it.

WITH instant AS (
    SELECT
        l.mint,
        l.slot
    FROM launches AS l
    JOIN graduations AS g
      ON g.mint = l.mint
     AND g.slot = l.slot
),
early_buys AS (
    SELECT
        i.mint,
        sum(t.quote_amount) / 1e9 AS sol_bought
    FROM instant AS i
    JOIN trades AS t
      ON t.mint = i.mint
     AND t.venue = 'pump_swap'
     AND t.side = 'buy'
     AND t.quote_mint = ''
     AND t.slot BETWEEN i.slot AND i.slot + 1
    GROUP BY i.mint
)
SELECT
    count(*) AS instant_graduations,
    count(*) FILTER (WHERE coalesce(e.sol_bought, 0) >= 150) AS early_buy_at_least_150_sol,
    count(*) FILTER (WHERE coalesce(e.sol_bought, 0) >= 300) AS early_buy_at_least_300_sol,
    round(median(e.sol_bought), 1) AS median_early_buy_sol
FROM instant AS i
LEFT JOIN early_buys AS e USING (mint);
