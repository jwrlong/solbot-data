-- A drain slot: at least five wallets each sell 0.9% to 1.1% of supply
-- in the same PumpSwap slot. One seller at a time looks like a dip.
-- Together they empty the pool, which is why a buy-the-dip strategy
-- cannot get out in time.
-- Supply is 1e15 raw units, so 1% is 1e13.

WITH one_percent_sells AS (
    SELECT
        mint,
        slot,
        wallet,
        quote_amount
    FROM trades
    WHERE venue = 'pump_swap'
      AND side = 'sell'
      AND quote_mint = ''
      AND base_amount BETWEEN 9000000000000 AND 11000000000000
),
drain_slots AS (
    SELECT
        mint,
        slot,
        count(DISTINCT wallet) AS wallets,
        sum(quote_amount) / 1e9 AS sol_out
    FROM one_percent_sells
    GROUP BY mint, slot
    HAVING count(DISTINCT wallet) >= 5
)
SELECT
    count(*) AS drain_slots,
    count(DISTINCT mint) AS tokens,
    round(sum(sol_out), 1) AS sol_sold_into_drains,
    max(wallets) AS most_wallets_in_one_slot
FROM drain_slots;
