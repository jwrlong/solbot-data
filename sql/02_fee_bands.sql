-- Fee rate on buys of at least 0.1 SOL.
-- A round trip pays this rate twice. On the bonding curve that is about 2.5%.
-- A strategy with a smaller edge than that loses even when it guesses the direction.

SELECT
    venue,
    CASE
        WHEN fees * 1.0 / quote_amount < 0.004 THEN 'under 0.40%'
        WHEN fees * 1.0 / quote_amount < 0.008 THEN '0.40-0.80%'
        WHEN fees * 1.0 / quote_amount < 0.011 THEN '0.80-1.10%'
        WHEN fees * 1.0 / quote_amount < 0.0123 THEN '1.10-1.23%'
        WHEN fees * 1.0 / quote_amount < 0.0135 THEN '1.23-1.35%'
        ELSE 'above 1.35%'
    END AS fee_band,
    count(*) AS trades,
    round(sum(quote_amount) / 1e9, 1) AS volume_sol
FROM trades
WHERE quote_mint = ''
  AND side = 'buy'
  AND quote_amount >= 100000000
GROUP BY 1, 2
ORDER BY 1, 2;
