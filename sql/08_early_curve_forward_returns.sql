-- An early bonding-curve buy, and the price a short time later.
-- 60 slots is about 24 seconds. 150 slots is about a minute.
-- The curve charges about 1.25% each side, so 2.5% is the round trip
-- a bot has to clear before it has made money.
-- The scalper signature is the public part of what fast curve bots do:
-- 18-50 slots after launch, the deployer has already sold, 3-6 SOL sold
-- in the previous 10 trades, and the price is already down at least 5%.

WITH labeled AS (
    SELECT
        CASE
            WHEN age BETWEEN 18 AND 50
             AND dev_sold = 1
             AND sell_last10 BETWEEN 3 AND 6
             AND p_10ago > 0
             AND (p / p_10ago - 1) <= -0.05
            THEN 'scalper_signature'
            ELSE 'everyone_else'
        END AS setup,
        p,
        p20,
        p60,
        p150
    FROM early_curve_buys
    WHERE p > 0
)
SELECT
    coalesce(setup, 'all_early_buys') AS setup,
    count(*) AS buys,
    round(median((p60 / p - 1) * 100), 2) AS median_return_24s_pct,
    round(avg((p60 / p - 1) * 100), 2) AS average_return_24s_pct,
    round(median((p150 / p - 1) * 100), 2) AS median_return_60s_pct,
    round(100.0 * count(*) FILTER (WHERE p60 / p - 1 > 0.025) / count(*), 1) AS pct_up_enough_to_clear_2_5pct_fee
FROM labeled
GROUP BY GROUPING SETS ((setup), ())
ORDER BY buys DESC;
