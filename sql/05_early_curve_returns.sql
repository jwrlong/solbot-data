-- Price change after a bonding-curve buy, before fees.
-- 20, 60, and 150 slots are about 8, 24, and 60 seconds.
-- The curve charges about 1.25% each way, so a round trip needs more than
-- +2.5% just to break even.

SELECT
    count(*) AS buys_with_later_prices,
    round(100 * median((p20 - p) / p), 2) AS median_return_8s_pct,
    round(100 * median((p60 - p) / p), 2) AS median_return_24s_pct,
    round(100 * median((p150 - p) / p), 2) AS median_return_60s_pct,
    round(100 * avg((p150 - p) / p), 2) AS average_return_60s_pct,
    round(100.0 * count(*) FILTER (WHERE (p150 - p) / p > 0.025) / count(*), 1)
        AS pct_beating_round_trip_fee
FROM early_curve_buys
WHERE p > 0
  AND p20 > 0
  AND p60 > 0
  AND p150 > 0;
