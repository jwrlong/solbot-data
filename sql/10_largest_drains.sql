-- Same drain definition as 09, rolled up to the token.
-- Large drains often span two slots, so the token total is the right size.
-- minutes_after_graduation is how long a 10-minute hold has before this starts.
-- Tokens launched before this window have no graduation row, so that value is blank.

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
    SELECT mint, slot
    FROM one_percent_sells
    GROUP BY mint, slot
    HAVING count(DISTINCT wallet) >= 5
),
events AS (
    SELECT
        s.mint,
        s.slot,
        s.wallet,
        s.quote_amount
    FROM one_percent_sells AS s
    JOIN drain_slots AS d
      ON d.mint = s.mint
     AND d.slot = s.slot
)
SELECT
    coalesce(max(l.symbol), substr(e.mint, 1, 8)) AS symbol,
    e.mint,
    count(DISTINCT e.slot) AS drain_slots,
    count(DISTINCT e.wallet) AS wallets,
    round(sum(e.quote_amount) / 1e9, 1) AS sol_out,
    round((min(e.slot) - min(g.slot)) * 0.4 / 60.0, 1) AS minutes_after_graduation
FROM events AS e
LEFT JOIN launches AS l ON l.mint = e.mint
LEFT JOIN graduations AS g ON g.mint = e.mint
GROUP BY e.mint
ORDER BY sol_out DESC;
