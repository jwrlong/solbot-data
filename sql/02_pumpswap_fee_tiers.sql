-- PumpSwap does not charge one fee. Most volume is the 0.30% tier.
-- A strategy that also trades the 1.25% tier needs about four times the edge.
-- Restricted to SOL-quoted trades of at least 0.1 SOL, where the tier is meaningful.

WITH priced AS (
    SELECT
        round(100.0 * fees / quote_amount, 2) AS fee_pct,
        quote_amount
    FROM trades
    WHERE venue = 'pump_swap'
      AND quote_mint = ''
      AND quote_amount >= 100000000
)
SELECT
    fee_pct,
    count(*) AS trades,
    round(sum(quote_amount) / 1e9, 1) AS volume_sol,
    round(fee_pct * 2, 2) AS round_trip_pct
FROM priced
GROUP BY fee_pct
HAVING count(*) >= 1000
ORDER BY volume_sol DESC;
