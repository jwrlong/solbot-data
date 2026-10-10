-- The curve's profit is not spread across traders. The top 1% of wallets
-- by net result take almost all of it. Copying a typical wallet copies the rest.
-- Rank is within the venue of the position's first trade.

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
        sum(fees) / 1e9 + sum(jito_tip) / 1e9 AS cost_sol
    FROM trades
    WHERE quote_mint = ''
    GROUP BY wallet, mint
),
by_wallet AS (
    SELECT
        c.venue0,
        c.wallet,
        sum(c.gross_pnl - coalesce(k.cost_sol, 0)) AS net_pnl
    FROM closed AS c
    LEFT JOIN costs AS k USING (wallet, mint)
    GROUP BY c.venue0, c.wallet
),
ranked AS (
    SELECT
        venue0,
        net_pnl,
        row_number() OVER (PARTITION BY venue0 ORDER BY net_pnl DESC) AS rank,
        count(*) OVER (PARTITION BY venue0) AS wallets
    FROM by_wallet
)
SELECT
    venue0 AS venue,
    count(*) AS wallets,
    round(sum(net_pnl), 1) AS net_pnl_sol,
    round(sum(net_pnl) FILTER (WHERE rank <= wallets * 0.01), 1) AS top_1pct_net_sol,
    round(sum(net_pnl) FILTER (WHERE rank > wallets * 0.01), 1) AS everyone_else_net_sol
FROM ranked
GROUP BY venue0
ORDER BY venue0;
