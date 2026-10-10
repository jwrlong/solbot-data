-- Where does the loss sit: the bonding curve, or PumpSwap after graduation?
-- venue0 is the first venue of the position. The bot's momentum, flow, fade,
-- and graduation strategies all trade PumpSwap.

WITH closed AS (
    SELECT
        wallet,
        mint,
        venue0,
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
)
SELECT
    c.venue0 AS venue,
    count(*) AS positions,
    count(DISTINCT c.wallet) AS wallets,
    round(sum(c.gross_pnl), 1) AS gross_pnl_sol,
    round(sum(coalesce(k.fee_sol, 0)), 1) AS fees_sol,
    round(sum(coalesce(k.tip_sol, 0)), 1) AS jito_tips_sol,
    round(sum(c.gross_pnl - coalesce(k.fee_sol, 0) - coalesce(k.tip_sol, 0)), 1) AS net_pnl_sol,
    round(100.0 * count(*) FILTER (WHERE c.gross_pnl > 0) / count(*), 1) AS gross_win_pct
FROM closed AS c
LEFT JOIN costs AS k USING (wallet, mint)
GROUP BY c.venue0
ORDER BY c.venue0;
