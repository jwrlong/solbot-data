-- How big each market was, and how much of the volume was fees.
-- SOL amounts in the trades table are lamports. Divide by 1e9 to get SOL.
-- quote_mint = '' keeps SOL-priced markets and drops the few USDC pools.

SELECT
    venue,
    count(*) AS trades,
    count(DISTINCT wallet) AS wallets,
    count(DISTINCT mint) AS tokens,
    round(sum(quote_amount) / 1e9, 1) AS volume_sol,
    round(sum(fees) / 1e9, 1) AS fees_sol,
    round(100.0 * sum(fees) / nullif(sum(quote_amount), 0), 3) AS fee_pct_of_volume
FROM trades
WHERE quote_mint = ''
GROUP BY venue
ORDER BY volume_sol DESC;
