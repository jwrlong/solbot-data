-- Realized result for positions a wallet both opened and closed inside this day.
-- A position is closed when the tokens sold are within 2% of the tokens bought.
-- sol_in and sol_out are already in SOL, and they are before venue fees.

WITH closed AS (
    SELECT
        wallet,
        sol_out - sol_in AS pnl_sol
    FROM wallet_positions
    WHERE sells > 0
      AND bought_tok > 0
      AND sold_tok BETWEEN bought_tok * 0.98 AND bought_tok * 1.02
),
by_wallet AS (
    SELECT
        wallet,
        count(*) AS positions,
        sum(pnl_sol) AS pnl_sol
    FROM closed
    GROUP BY wallet
)
SELECT
    (SELECT count(*) FROM closed) AS positions,
    count(*) AS wallets,
    count(*) FILTER (WHERE pnl_sol > 0) AS profitable_wallets,
    round(100.0 * count(*) FILTER (WHERE pnl_sol > 0) / count(*), 1) AS pct_wallets_profitable,
    round(sum(pnl_sol), 1) AS total_pnl_sol,
    round(sum(pnl_sol) FILTER (WHERE pnl_sol > 0), 1) AS winning_wallets_pnl_sol,
    round(sum(pnl_sol) FILTER (WHERE pnl_sol <= 0), 1) AS losing_wallets_pnl_sol
FROM by_wallet;
