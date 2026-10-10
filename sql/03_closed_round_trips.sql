-- Did the traders who fully exited make money?
-- A position is closed when the wallet sold within 2% of the tokens it bought.
-- sol_out - sol_in is profit before fees. Fees and Jito tips are added from the trades.
-- Ordinary priority fees are not in the data, so the net is still a little high.

WITH closed AS (
    SELECT
        wallet,
        mint,
        sol_out - sol_in AS gross_pnl
    FROM wallet_positions
    WHERE sells > 0
      AND bought_tok > 0
      AND sold_tok BETWEEN bought_tok * 0.98 AND bought_tok * 1.02
),
costs AS (
    SELECT
        wallet,
        mint,
        sum(fees) / 1e9 AS fee_sol,
        sum(jito_tip) / 1e9 AS tip_sol
    FROM trades
    WHERE quote_mint = ''
    GROUP BY wallet, mint
),
by_wallet AS (
    SELECT
        c.wallet,
        sum(c.gross_pnl) AS gross_pnl,
        sum(coalesce(k.fee_sol, 0) + coalesce(k.tip_sol, 0)) AS cost_sol
    FROM closed AS c
    LEFT JOIN costs AS k USING (wallet, mint)
    GROUP BY c.wallet
)
SELECT
    (SELECT count(*) FROM closed) AS positions,
    count(*) AS wallets,
    round(sum(gross_pnl), 1) AS gross_pnl_sol,
    round(sum(cost_sol), 1) AS fees_and_tips_sol,
    round(sum(gross_pnl - cost_sol), 1) AS net_pnl_sol,
    round(100.0 * (SELECT count(*) FROM closed WHERE gross_pnl > 0) / (SELECT count(*) FROM closed), 1) AS position_win_pct,
    round(100.0 * count(*) FILTER (WHERE gross_pnl > 0) / count(*), 1) AS wallets_in_profit_before_fees_pct,
    round(100.0 * count(*) FILTER (WHERE gross_pnl - cost_sol > 0) / count(*), 1) AS wallets_in_profit_pct,
    round(median(gross_pnl - cost_sol), 4) AS median_wallet_net_sol
FROM by_wallet;
