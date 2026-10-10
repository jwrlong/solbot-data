-- What does a round trip cost before a strategy can make anything?
-- SOL amounts in the trades table are lamports. quote_mint '' means the pool is priced in SOL.
-- Curve fee schedule: 0.95% protocol + 0.30% creator per trade.
-- PumpSwap fee is tiered: 1.25% on the smallest pools, down to 0.30% on the largest.

SELECT
    venue,
    count(*) AS trades,
    round(sum(quote_amount) / 1e9, 1) AS volume_sol,
    round(sum(fees) / 1e9, 1) AS fees_sol,
    round(100.0 * sum(fees) / sum(quote_amount), 3) AS fee_pct_of_volume,
    round(200.0 * sum(fees) / sum(quote_amount), 3) AS approx_round_trip_pct,
    round(sum(jito_tip) / 1e9, 2) AS jito_tips_sol
FROM trades
WHERE quote_mint = ''
GROUP BY venue
ORDER BY volume_sol DESC;
