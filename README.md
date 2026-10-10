# solbot dataset: Pump.fun + PumpSwap, 23.2 hours (2026-09-29 → 2026-09-30)

Every trade, token launch, graduation, pool and liquidity event on Pump.fun (the bonding curve)
and PumpSwap (its AMM) over **23.2 hours**: Solana slots **451,863,358 → 452,071,879**,
2026-09-30 04:57 UTC to 2026-10-01 ~04:10 UTC. The data was decoded directly from the chain
(every block, none missing) by the `solbot` project.

The findings report is in [`FINDINGS.md`](FINDINGS.md). Its supporting tables are in
`validation/`, and the profitable-wallet study is in `wallets/`.

## Files (`data/`, Parquet with zstd compression)

| File | Rows | What one row is |
|---|---|---|
| `trades.parquet` | 15,508,459 | One swap (buy or sell) on the bonding curve or PumpSwap |
| `launches.parquet` | 30,901 | A new token created on Pump.fun |
| `graduations.parquet` | 777 | A token finishing its bonding curve (moves to a PumpSwap pool) |
| `pools.parquet` | 2,636 | A PumpSwap pool created |
| `liquidity.parquet` | 2,209 | A deposit/withdrawal of pool liquidity |
| `sol_transfers.parquet` | 37,043 | A plain SOL transfer seen while tracing wallet funding |
| `wallets.parquet` | 35,822 | First-funding trace of a wallet (who sent it its first SOL) |
| `slots.parquet` | 208,261 | One Solana block (slot, time, parent) |
| `wallet_positions.parquet` | 3,083,140 | *Derived:* one wallet × token, totals of what it bought and sold in the window |
| `early_curve_buys.parquet` | 668,412 | *Derived:* bonding-curve buys 10–400 slots after launch, with the market state before and the price 20/60/150 slots after |

## Units and conventions (read first)

- **SOL amounts are in lamports** (1 SOL = 1,000,000,000). Divide `quote_amount`, `fees`,
  `*_reserves` (quote side), `lamports` and `jito_tip` by `1e9` for SOL.
  - Exception: the derived files `wallet_positions` (`sol_in`, `sol_out`) and
    `early_curve_buys` (`q`, `rq_before`, `net_before`, `buy_last10`, `sell_last10`) are
    already in SOL.
- **Token amounts are raw units.** Pump.fun tokens have 6 decimals and 1,000,000,000 total
  supply, so 1e15 raw = 100% of the supply.
- **Time:** a *slot* is one Solana block, about 0.4 s. `block_time` is UTC. Ordering within a
  slot: `tx_index` (position in the block), then `event_index`.
- **Venues** (`venue`):
  - `pump_curve`: the bonding curve (before graduation)
  - `pump_swap`: the AMM pool (after graduation)
- **`side`** is from the trader's point of view: `buy` = SOL in, tokens out.
- **Price:** `quote_reserves / base_reserves` = lamports per raw token after the trade. Multiply
  by `1e-3` for SOL per whole token.
- **Two kinds of reserves:**
  - `quote_reserves` / `base_reserves` include PumpSwap's *virtual* reserves (which set the
    price).
  - `real_quote_reserves` / `real_base_reserves` are what is actually in the pool. Liquidity =
    `real_quote_reserves / 1e9` SOL.
- **`quote_mint`:** empty = SOL. A few PumpSwap pools are priced in USDC or other tokens; filter
  `quote_mint = ''` for SOL markets.
- **`fees`:** total venue fees on the trade, in lamports:
  - curve: 0.95% protocol + 0.3% creator
  - PumpSwap: tiered from 1.25% (smallest caps) down to 0.3%
- **`jito_tip`:** the tip paid to Jito validators for priority (0 if none). Ordinary priority
  fees are *not* recorded.
- **`fee_payer` vs `wallet`:** `wallet` is the trader in the event; `fee_payer` signed and paid
  for the transaction (they differ for bots and routers).
- **Official pools:** Pump.fun's own graduation pool for a token is the one created at
  graduation (`pools.creator` is Pump's program authority); its liquidity is locked. Other
  PumpSwap pools for the same token are hand-made and can be rug-pulled.

## Columns

**trades:** `signature`, `event_index`, `slot`, `tx_index`, `block_time`, `venue`, `mint` (token),
`pool` (PumpSwap pool; empty on the curve), `wallet`, `fee_payer`, `side`, `base_amount`
(tokens), `quote_amount` (lamports), `quote_mint`, `fees`, `base_reserves`, `quote_reserves`,
`real_base_reserves`, `real_quote_reserves`, `jito_tip`, `ix_name` (instruction, curve only),
`source`.

**launches:** `mint`, `signature`, `slot`, `tx_index`, `block_time`, `venue`, `bonding_curve`,
`deployer`, `creator`, `fee_payer`, `name`, `symbol`, `uri` (metadata link), `quote_mint`,
`token_total_supply`, `virtual_token_reserves`, `virtual_quote_reserves`, `is_mayhem_mode`,
`is_holder_reward`, `jito_tip`, `source`.

**graduations:** `mint`, `signature`, `slot`, `block_time`, `bonding_curve`, `source`.

**pools:** `pool`, `signature`, `slot`, `block_time`, `venue`, `base_mint`, `quote_mint`,
`creator`, `coin_creator`, `base_amount`, `quote_amount` (initial deposit), `source`.

**liquidity:** `signature`, `event_index`, `slot`, `tx_index`, `block_time`, `venue`, `pool`, `mint`,
`quote_mint`, `kind` (deposit/withdraw), `user`, `base_amount`, `quote_amount`, `base_reserves`,
`quote_reserves` (after), `share_pct` (% of the pool moved), `source`.

**sol_transfers:** `signature`, `ix_index`, `slot`, `block_time`, `from_wallet`, `to_wallet`,
`lamports`, `kind`, `source`.

**wallets:** `wallet`, `first_funder`, `first_funding_sig`, `first_funding_slot`,
`first_funding_lamports`, `first_activity_slot`, `history_sigs`, `history_complete`, `traced_at`.

**slots:** `slot`, `parent_slot`, `block_time`, `block_height`.

**wallet_positions** (derived from trades):
- `wallet`, `mint`
- `bought_tok`, `sold_tok`
- `sol_in`, `sol_out` (SOL, before fees)
- `buys`, `sells`
- `first_buy`, `last_sell`, `first_slot` (slots)
- `venue0` (first venue seen), `venues`

A position is *closed* when `sold_tok` is within ±2% of `bought_tok`; its realized profit before
fees is `sol_out - sol_in`.

**early_curve_buys** (derived from trades): one bonding-curve buy 10–400 slots after its
token's launch.

| Column | Meaning |
|---|---|
| `mint`, `slot`, `ti` (tx_index), `wallet` | The buy |
| `q` | SOL spent |
| `age` | Slots since launch |
| `p` | Price after the buy |
| `rq_before` | SOL in the curve before the buy |
| `net_before` | Net SOL bought since launch |
| `trades_before` | Trades since launch |
| `buy_last10`, `sell_last10` | SOL bought / sold in the previous 10 trades |
| `dev_sold` | 1 if the deployer had sold any tokens before this buy |
| `p_10ago` | Price 10 trades earlier |
| `p20`, `p60`, `p150` | Price 20/60/150 slots later (any venue) |

## Known caveats

- **Old PumpSwap rows.** PumpSwap `buy_exact_quote_in` trades decoded before a fix on
  2026-09-30 store `quote_amount` as the fee-inclusive total, and their post-trade quote reserves
  are slightly high (by that trade's fees). This affects roughly 20% of PumpSwap buys and is
  small: the next trade's reserves are correct again. For a buy, the net amount that reached the
  pool is `quote_amount - fees` if that reproduces the pool math better (see `FINDINGS.md` §2).
- **Duplicates removed.** Rows were exported de-duplicated (`FINAL`).
- **Open positions.** Tokens launched before the window, or positions still open at its end,
  have partial histories.
- **Bot and wash volume.** Volume includes a lot of it (see the coordinated-drain section of the
  findings).

## Getting started

**SQL with DuckDB** (`pip install duckdb`, or the DuckDB CLI). No database server needed:

```sql
-- Hourly volume by venue
SELECT date_trunc('hour', block_time) AS hour, venue,
       count(*) AS trades, sum(quote_amount) / 1e9 AS sol_volume
FROM 'data/trades.parquet' WHERE quote_mint = ''
GROUP BY ALL ORDER BY hour;

-- Launches that graduated, and how long it took
SELECT l.mint, l.symbol, (g.slot - l.slot) * 0.4 / 60 AS minutes_to_graduate
FROM 'data/launches.parquet' l JOIN 'data/graduations.parquet' g USING (mint)
ORDER BY minutes_to_graduate;

-- Realized profit per wallet on closed positions (before fees)
SELECT wallet, count(*) AS positions, sum(sol_out - sol_in) AS pnl_sol
FROM 'data/wallet_positions.parquet'
WHERE sells > 0 AND sold_tok BETWEEN bought_tok * 0.98 AND bought_tok * 1.02
GROUP BY wallet ORDER BY pnl_sol DESC LIMIT 50;
```

**Python:** `pandas.read_parquet('data/launches.parquet')`. For `trades.parquet` (15.5 M rows)
use DuckDB or Polars, or read only the columns you need:

```python
pd.read_parquet('data/trades.parquet', columns=['slot', 'mint', 'side', 'quote_amount'])
```

**R:** `arrow::read_parquet()`. **Power BI / Tableau** read Parquet directly.

Explorers for any address, token or transaction: `https://solscan.io/account/<address>`,
`https://solscan.io/token/<mint>`, `https://solscan.io/tx/<signature>`.
