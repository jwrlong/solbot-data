# Trading strategies (branch `strategy/arb-graduated`)

Goal: many small, consistent wins on **graduated tokens** (PumpSwap, SOL-quoted), chosen by data. Every strategy
plugs into one engine, gets backtested on the same stored market data with realistic fees and latency, is ranked
on a leaderboard, and the winner runs through the same code live (`paper`, later `live`).

## What the data showed before any code

- **Most graduated Pump tokens trade in one pool, but the successful ones don't.** A first survey (65 tokens) looked
  single-pool everywhere, but it used DexScreener's multi-token endpoint, which returns only each token's *top* pool.
  Queried per token, graduates that grow (ANSEM, CATE, e/acc, ...) also have Meteora DLMM pools with $20k+ liquidity,
  so strategy B does apply to graduated tokens once they're established.
- **Fees set the bar.** Bonding curve: 1.25% per side. PumpSwap: tiered 1.25% down to 0.3% by market cap.
  A round trip at the 0.3% tier costs ~0.6% plus tx costs; at the 1.25% tier ~2.5%. Most "small win" ideas die here.
- **Tx costs at volume.** 10,000 round trips/day = 20,000 txs. At 0.001 SOL tips that's ~24 SOL/day, so the
  bot must *not* race with tips; it wins on selection, not speed (default model: 0.0001 SOL per tx).

## Strategies

Status after the first clean day (2026-09-30; details in [FINDINGS.md](FINDINGS.md) and
[validation/improvements.md](validation/improvements.md)): only `graduation` is profitable on
unseen data.

| Name | Idea | Status |
|---|---|---|
| `graduation` (C2) | **Primary.** Instant graduations with heavy early buying: enter `delay_slots` after graduation if ≥ `min_early_sol` (default 300) SOL was bought since and the pool is below `max_fee_pct` (default 1.22%); hold `max_hold` (default 1500 slots = 10 min), TP 50%, SL 30%, and exit on a coordinated dump (`max_slot_sellers`, default 3). | Validated on one day: +1.95 SOL/day on $2k, 93% win, 6/6 blocks profitable |
| `whale` | Enter after a single buy ≥ `min_buy_sol` that is ≥ `min_pool_pct` of the pool; fixed hold; dump exit. | Experimental: profitable, but a noisier copy of `graduation` (its trades are almost all instant graduations) |
| `snipe` | New launches with organic-looking early flow; exits on dev sell (`exit_dev_sell`), big dumps (`dump_pct`), outflow. | Loses; strict filters reach ~breakeven. Higher priority fees only add cost. Needs deployer intelligence |
| `dip` | Bonding-curve dip scalp: 15–120 slots after launch, dev has sold, 3–6 SOL sold in the last 10 trades, price down ≥5% → buy, sell after `max_hold` (default 60 slots). | Tested: profitable scalpers do this, but at their speed (same-slot backruns); our version loses on unseen data, even at 0 latency (FINDINGS §13) |
| `momentum` (C1) | Price up ≥ `min_rise_pct` over `window` slots on net buying → buy; TP/SL/trailing/time exits; dump exit. | Benchmark: loses on unseen data even after tuning |
| `flow` | Volume surge + net buying + many buyers; trailing stop, outflow and dump exits. | Benchmark: loses on unseen data even after tuning |
| `fade` (A) | Buy after a large sell; exit when `revert` of the drop recovers. Guards: `max_impact_pct`, `max_slot_sellers`, `confirm_slots`. | **Retired**: buys the first leg of coordinated drains |
| `random` | Control: random entries, fixed hold. Anything that doesn't clearly beat it has no edge. | Benchmark |
| `copy` (C3) | Copy wallets from a list (`wallets=<file>`, picked by `scripts/smart_wallets.py` on earlier data): buy when they buy, sell when they sell. | Tested: loses in every variant, even in-sample (FINDINGS §13) |
| `arb` (B) | Atomic cross-venue arbitrage. | Scanner built; found ~no edge; paused |

Common parameters: `size_sol`, `min_liq_sol` (also re-checked when an order fills), `tp_pct`, `sl_pct`, `trail_pct`,
`max_hold` (slots, ~0.4 s each), `cooldown`, `max_slot_sellers` (coordinated-dump exit; 0 = off).

## Engine model (and its limits)

- Pool state per token from every stored trade: post-trade reserves plus the fee rate that pool actually charged.
  Fills use constant-product math with that fee.
- **Our own fills move the pool** (an overlay on the recorded reserves), so a round trip costs exactly two fees and
  slippage recovers, as on-chain.
- **Latency:** orders fill `--latency` slots after the signal (default 1), against the state at that point.
- **Costs:** venue fees from the pool's tier + `--tx-cost` lamports per transaction.
- Not modelled yet: failed/dropped txs, intra-block landing position, other bots reacting to us.

## Usage

```sh
# 1. contiguous market data (public RPC ~3 s/block; paid RPC much faster)
solbot collect blocks --last-slots 9000            # ~1 hour of market

# 2. compare everything with built-in grids, or one strategy with your own grid
solbot backtest
solbot backtest --strategy fade -p min_impact_pct=3,5,8 -p revert=0.3,0.5 -p size_sol=0.1,0.5
solbot backtest --latency 2 --tx-cost 200000       # stress the assumptions

# B: measure cross-venue gaps (Jupiter quotes, one venue per leg), then summarize
solbot arb scan --top 40 --sizes-usd 25,250        # runs until Ctrl-C; rounds ≈ minutes at 1 req/s
solbot arb report --since-hours 24                  # hit rate, bps, best token/venue pairs, persistence

# 3. run the winner live with simulated fills
solbot paper --strategy fade -p min_impact_pct=5 -p revert=0.5 --source geyser
```

Reading results: compare every row with `random(...)`. Minutes of data prove nothing; trust a winner only after
hours to days of data, across different days, and after it survives `--latency 2` and higher tx costs.

## Roadmap on this branch

1. More contiguous data (paid RPC or gRPC makes this minutes instead of hours).
2. `arb` (B): scanner running (first result: majors are efficient, best round trip −9 bps). Next, depending on
   what hours of scanning show: our own decoders for the venues with real gaps (live pool state, sub-second
   detection, intra-venue pools Jupiter merges), then backtest, then the atomic executor.
3. Follow strategy (C3) once wallet scoring lands on `main`.
4. Live execution: tx builder, sender, position manager, kill switch; paper and live share the engine.
