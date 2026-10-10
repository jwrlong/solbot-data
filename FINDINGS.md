# solbot findings report: first clean 24-hour run

*Data: 2026-09-29 23:57 → 2026-09-30 ~23:10 CDT · Report written 2026-09-30 · Code: `main` + uncommitted fixes listed in §9 · §11–13 added after the strategy-improvement and wallet passes*

This report covers everything we learned from one full day of recorded Pump.fun and PumpSwap
activity:
- what the market looked like
- how we checked that our data and simulator match the chain
- the false results we caught along the way
- what each strategy did
- the patterns we found (including a repeated coordinated "drain" scheme)
- the bugs we fixed
- which strategy settings survive every robustness test we could think of

Supporting material is in [`docs/validation/`](validation/): full validation tables, the drain
study, the chain audit and the independent re-simulations.

---

## 0. Executive summary

- **Most strategies lose.** Fees (0.6–2.5% per round trip) wipe out momentum, flow, fade,
  sniping and random entries. On the corrected code, all of them lose on the day.
- **One setup is consistently profitable: "graduation + hot money".**
  - It buys tokens that graduate to PumpSwap in the same slot they launch, where **≥300 SOL was
    bought in the first ~2 slots** after graduation, and holds for 10 minutes.
  - On a $2,000 (16.7 SOL) account with 1 SOL per trade it made **+1.95 SOL (+$234, +11.7%)
    over the day in 44 trades, with a 93% win rate and a worst drawdown of 0.011 SOL.**
  - It was **profitable in all six 4-hour blocks** and in 18 of 19 hours with trades.
  - It barely changes when its exit settings, entry delay or fee filter change, or with latency
    from 0 to 12 s.
  - Resampling its trades 20,000 times never produced a losing day.
- **A looser version (≥150 SOL) made more (+3.21 SOL), but it is fragile.** Its profit depends on
  one exit parameter catching 5 bad trades, and 2 of the six 4-hour blocks lost money.
- **Our numbers match the chain.**
  - Every block of the day is stored.
  - Decoded trades match wallet and pool balances on-chain.
  - A separate Python re-simulation built only from on-chain data reproduces the strategy's
    profit. It comes out slightly *higher* than our simulator, so the simulator is conservative.
- **We found an organized "launder-and-drain" pattern.**
  1. A wallet buys a large share of a fresh token for up to ~7,000 SOL.
  2. Minutes to hours later, up to 100 sybil wallets, each holding exactly 1% of the supply,
     sell in the same slot and take the SOL back out.
  3. On-chain links show the "buyer" and the drain wallets are run by the same operators, in
     about three clusters that repeat the scheme across tokens.
  4. Buy-the-dip strategies walk straight into these drains.
- **Confidence:**
  - High that the numbers are computed correctly.
  - Moderate that the edge is real, because it's one day of data.
  - The ≥300 threshold was chosen after looking at the full day, so it has not had a truly
    unseen test yet.
  - The next step is to confirm it on a fresh day, then with live paper trading, before any
    real money.

---

## 1. The data

### 1.1 What was recorded

| Item | Value |
|---|---|
| Period | 23.2 hours, slots 451,863,358 → 452,071,879 |
| Blocks | 208,261 produced blocks, **all stored**, 0 open gaps |
| Trades | 15.5 M (12.8 M PumpSwap, 2.7 M bonding curve) |
| Launches | 30,901 (21,027 normal, 9,874 "mayhem mode") |
| Graduations to PumpSwap | 777 |
| PumpSwap pools created / liquidity events | 2,636 / 2,209 |
| Distinct wallets | 696,217 |
| Wallet funding traces | 35,822 wallets with first funder |
| Source | Helius RPC block follower (`getBlocks` + `getBlock`), ~6 s behind the chain |
| Storage | ClickHouse (every trade, launch, graduation, pool, liquidity event, SOL transfer, funding trace) |

### 1.2 What the market looked like

**Volume** (SOL-quoted trades as recorded; includes bot and wash volume):

| Venue | SOL volume | Trades | Wallets | Tokens traded |
|---|---|---|---|---|
| PumpSwap | 11.43 M SOL | 12.5 M | 600,785 | 16,581 |
| Bonding curve | 0.86 M SOL | 2.6 M | 160,101 | 37,944 |

**Launches and graduations:**

| Launch type | Launches | Graduated | Rate | Distinct deployers |
|---|---|---|---|---|
| Normal | 21,027 | 582 | 2.77% | 9,610 |
| Mayhem mode | 9,874 | 139 | 1.41% | 738 (≈13 launches per deployer) |

- **Almost half of all graduations are instant.** 336 of the 721 graduations whose launch we saw
  (47%) graduated **in the same slot they launched**: the creator bought out the whole curve at
  launch.
- Time from launch to graduation: median **14 seconds**, 90th percentile 29.5 minutes, 99th
  percentile 3.6 hours.

**PumpSwap fee tiers** (the fee depends on the pool's market cap: 1.25% for the smallest, falling
to 0.3%). Trades above 0.1 SOL:

| Fee tier | Trades | SOL volume |
|---|---|---|
| 0.30% (large caps) | 2.80 M | 9.68 M SOL (≈85% of volume) |
| 1.20% | 358 k | 457 k SOL |
| 1.25% (smallest) | 222 k | 123 k SOL |
| 1.19%, 1.15%, 1.10%, 1.00%, 0.99%, … | smaller | smaller |

---

## 2. How we checked accuracy

Every number in this report was produced by the Rust backtester. We verified the backtester in
four independent ways:

### 2.1 Chain audit (`scripts/audit.py`)
This is Python, written separately from the Rust code. It reads the chain over RPC and our
database directly.

| # | Check | Method | Result |
|---|---|---|---|
| 1 | Completeness | `getBlocks` over the whole range vs stored slots | **PASS**: 208,261/208,261 blocks |
| 1 | Swaps per block | Count swap instructions in the chain's logs for random blocks vs stored trades | **PASS**: 40/40 blocks |
| 2 | Token amounts | Re-decode random trades with the current decoder; compare with the wallet's on-chain token balance change | **PASS**: 77/77 in the final run (plus 58/58 and 39/39 in earlier samples) |
| 2 | Pool reserves | Decoded post-trade reserves vs the pool's vault balances on-chain | **PASS**: 62/62 in the final run (plus 46/46 and 33/33) |
| 3 | Pricing | Pool math on the previous trade's reserves must reproduce each next trade | **PASS**: median error 0.0004% over 12.5 M PumpSwap trades; 0.0000003% over 2.5 M curve trades |
| 4 | Simulated trades: arithmetic | profit = proceeds − cost for every trade | **PASS**: all trades |
| 4 | Simulated trades: rugs | No liquidity withdrawal ≥20% while we held a pool | **PASS**: 131/131 and 44/44 |
| 4 | Simulated trades: prices | Our recorded buy/sell price and pool SOL vs the on-chain pool, including our own position | **PASS**: 80/80 legs for each candidate |

The final run passed **17/17 checks**; full output in [`validation/audit-full.txt`](validation/audit-full.txt).

Two notes on the audit:
- **Old rows.** About 17–27% of sampled stored rows were written by the decoder *before* today's
  fix (§9). Each is off by that one trade's fee in the pool's SOL. The audit re-decodes them, and
  the fills strategies see still match the chain within 0.1% (check 4).
- **Routed trades.** Two sampled trades looked wrong at first but are correct:
  - An aggregator forwarded the tokens from a buy to another wallet.
  - **12 wallets pooled their tokens into one account that sold them all at once** (another
    drain technique).

  In both cases the pool's side matches our decoded amount exactly. The audit now falls back to
  the pool's vault for such trades.

### 2.2 Independent re-simulation from on-chain data only (`scripts/resim.py`)
For every trade of a strategy, the script:
1. Fetches the last real pool transaction before our buy and before our sell.
2. Reads the vault balances, PumpSwap's virtual reserves and the fee rates from the chain's own
   event data.
3. Recomputes tokens received, sale proceeds and profit with the constant-product formula.

It uses nothing from our simulator's pool state.

| Candidate | Trades | Our simulator | Chain re-simulation | Tokens received (sim vs chain) | Trades off by >0.01 SOL + 2% |
|---|---|---|---|---|---|
| ≥150 SOL | 131 | +3.207 SOL | **+3.383 SOL** | median −0.10%, worst −0.92% | 0 |
| ≥300 SOL | 44 | +1.953 SOL | **+2.077 SOL** | median −0.37%, worst −0.77% | 0 |

**Our simulator is slightly pessimistic:** it gives us fewer tokens than the chain would. That's
the right direction for a backtest to err in.

### 2.3 Train / test split
Settings were tuned on the first 60% of the day (slots up to 451,988,000, ≈13.8 h) and then run
on the last 40% (≈9.3 h), which the tuning never saw. See §6.3 for the caveat on the ≥300 variant.

### 2.4 Robustness battery (`scripts/validate.py`)
For each candidate:
- every ~4-hour block on its own
- nearby values of every setting
- latency, failed transactions and priority/Jito costs
- trade size
- control groups
- results without the top trades
- 20,000 bootstrap resamples

Full tables: [`validation/hot-money-150.md`](validation/hot-money-150.md) and
[`validation/hot-money-300.md`](validation/hot-money-300.md).

---

## 3. False results we caught (the "hallucination log")

We found each of these ourselves before trusting a number:

| When | What looked good | What was really going on | Fix |
|---|---|---|---|
| 09-29, earlier runs | Huge profits on some tokens (VRAX etc.) | Hand-made PumpSwap pools whose creator pulled the liquidity (rug) | Trade only Pump.fun's official graduation pools (LP locked); detect liquidity withdrawals |
| 09-29, first hour of this run | Momentum "+$373 → +$544" | PumpSwap prices pools with ~17.6 SOL of **virtual** reserves on top of the real SOL; we counted them as liquidity and inflated prices by up to 28% | Track real vs price-setting reserves; data re-collected |
| 09-29 | Graduation "100% wins" | Entries in 0.08–1.7 SOL pools | Liquidity floor |
| 09-30 11 AM | Graduation +$267 | Real on-chain, but it came from 5 lucky trades and lost −2.35 SOL by the end of the day | Winners-vs-losers analysis → hot-money filter |
| 09-30 (our analysis) | "Skip the smallest tier" worth +9 SOL | Our analysis measured the fee tier *including during the hold*: look-ahead | Measure it before entry only (real value +2.7 SOL) |
| 09-30 | "END SOL −13.7" on the dashboard | The backtest reset capital at the midpoint and added two accounts together | One continuous account |
| 09-30 | Fade −96% | **Real**: fade bought the first leg of coordinated drains (§4.3) | Guards added; fade retired |
| 09-30 | Audit "failures" | The audit compared the wrong reserves and ignored our own position and routed trades | Audit fixed (§9) |

---

## 4. Market discoveries

### 4.1 Fees are the wall
- A random control (random entries on liquid official pools, fixed hold) loses **almost exactly
  the fees**: about −0.65% per round trip on the 0.3% tier, with 99% losing trades.
- Any strategy needs more than ~0.6% (0.3% tier) to ~2.5% (1.25% tier) of edge per round trip,
  plus transaction costs, just to break even.
- Snipes also pay a priority fee on the way in and out.

### 4.2 Instant graduations are their own world
- 47% of graduations happen in the launch slot: the creator buys the entire bonding curve at once.
  For example, G7MZ's creator bought **79.3% of the supply for 85 SOL** in one transaction, and
  the token graduated in that same transaction.
- In **138** of the 336 instant graduations, ≥150 SOL of buying followed within ~2 slots. In
  **46**, it was ≥300 SOL.
- That early buying came from only **49 distinct wallets**. Four of them accounted for 67 tokens,
  each buying about 150–160 SOL every time (`4G9J…` 24 tokens, `9qZv…` 18, `HHKu…` 15, `4p7S…` 10).
  These are automated operators with a fixed buy size. The `min_early_sol=150` threshold happens
  to sit right at that size (§6.3).
- **Every trade of the profitable strategy is an instant graduation.** So the strategy trades one
  specific, organized niche.

### 4.3 The launder-and-drain scheme
**What it looks like** (G7MZ, verified transaction by transaction on-chain):

1. **Slot 451,919,566, tx #719.** The deployer creates the token and buys 79.3% of the supply
   for 85 SOL. The token graduates in the same transaction.
2. **Same slot, tx #721.** Wallet `3oB4…` buys **20.4% of the supply for 6,996 SOL (≈$840k)**
   with `buy_exact_quote_in`.
3. **16 minutes later, slots 451,922,009–010.** **96 different wallets each sell almost exactly
   1% of the supply** in two slots. The pool goes from **7,053 SOL to 87 SOL**.
4. `3oB4…` never sells.

**Who is behind it.** We checked the oldest transactions of the drain wallets over RPC:
- **The drain wallets' token accounts were set up by transactions signed by `3oB4…` itself**,
  about 30 hours earlier.
- So the "buyer" and the ~96 sellers are one operator. The 6,996 SOL wasn't lost: it moved
  through the pool into ~96 fresh wallets, paying ~2.5% in fees along the way. That is
  consistent with laundering or hiding where the money went.

**How common it is.** Pools where 5+ different wallets each sold about 1% of the supply in one
slot:

| | |
|---|---|
| Pools drained | **45** |
| Drains with 90+ wallets each | 14 |
| Largest drains (SOL out) | 7,015 · 2,656 · 2,013 · 1,895 · 1,223 · 1,034 · 912 · 848 · 846 · 803 |
| Time from graduation to drain (large ones) | 16 min · 31 min · 33 min · 61 min · 73 min · 163 min · 462 min · 894 min |
| Drain wallets that bought on the bonding curve | none in the large drains: their tokens were distributed to them |

**Operator links.** For each of the 12 largest drains we checked the oldest transactions of 3
drain wallets:

| Link | Evidence |
|---|---|
| `3oB4…` | The big early buyer in **G7MZ (6,997 SOL)** and **J6v6 (6,992 SOL)**. It also signed the setup of drain wallets in G7MZ, J6v6 and **3aDD** |
| `5JnK…` | The big early buyer in **3Fo7 (990 SOL)**. It signed drain-wallet setup in 3Fo7 and **9Cas** |
| `6dir…` | The deployer of **F6Ya**. It signed drain-wallet setup in F6Ya and **6nDP** |
| Shared setup signers | `36rJ…`, `Br1K…`, `FA8T…` (9Cas + 3Fo7); `DR2B…`, `Ddr3…` (3aDD + J6v6); `8ZqJ…`, `ACHY…` (6nDP + F6Ya) |

That points to roughly **three operator clusters running the same scheme repeatedly**. The full
table is in [`validation/drains.md`](validation/drains.md).

**Why it matters for trading:**
- A buy-the-dip strategy (fade) sees the first drain seller as a "dip", buys, and loses 94–99.99%
  of the position in the next slot. No exit can escape a one-slot collapse.
- A per-seller size limit misses it, because each seller holds only 1%.
- The detector that works counts **distinct sellers per slot** (`DumpWatch`, §9).
- The profitable strategy rides the same pumps. It survives because the large drains came
  **≥16 minutes after graduation**, while it exits within **10 minutes**. If the operators drain
  sooner, that protection weakens. The dump exit is the backstop, and for the ≥300 variant only
  8 of 44 trades were in pools that were later drained (+0.17 SOL).

### 4.4 Sniping new launches
On the corrected code, the sniper (0.1 SOL per launch with early-flow filters) made **1,153
trades: 18% winners, −10.46 SOL**. The median hold was **3.6 seconds**.

| Exit reason | Trades | Win % | Total |
|---|---|---|---|
| Dev sold | 556 | 16% | −5.46 SOL |
| Big holder dumped | 511 | 19% | −5.19 SOL |
| Stop-loss | 22 | 0% | −0.89 SOL |
| Time | 23 | 17% | −0.17 SOL |
| Net outflow | 21 | 43% | −0.13 SOL |
| Take-profit | 13 | 100% | **+1.47 SOL** |

Devs and bundlers sell into the first buyers within seconds. Snipes that do run pay well (+1.47
SOL from 13 take-profits), but can't cover the rest. Without knowing *which deployers* dump
(deployer history), sniping is a losing game.

---

## 5. Strategy results on the corrected code

These are full-day results on a $2,000 (16.7 SOL) account with 1 SOL per trade and max 5 open
(snipe: 0.1 SOL per trade). For the swap strategies, each row is the better of two fee
settings: the 0.3% tier only, or every tier.

| Strategy | Idea | Trades | Win % | Profit | Verdict |
|---|---|---|---|---|---|
| **Graduation + hot money (≥300 SOL)** | Instant graduations with heavy early buying, hold 10 min | 44 | 93% | **+1.95 SOL** | **Primary candidate** |
| Graduation + hot money (≥150 SOL) | Same, looser | 131 | 71% | +3.21 SOL | Secondary: fragile (§6.4) |
| Graduation, old default | Enter every graduation, TP 25% | 552 | 59% | −2.35 SOL | Replace |
| Momentum | Buy rising prices | 10 | 20% | −0.07 SOL (0.3% tier) | No edge |
| Flow ("follow the money") | Volume surge + net buying | 36 | 25% | −1.05 SOL (0.3% tier) | No edge |
| Fade | Buy sharp drops | 50 | 24% | −5.41 SOL | **Retire** (drains) |
| Snipe | New launches with early flow | 1,153 | 18% | −10.46 SOL | Needs deployer intel |
| Random (control) | Random entries | 2,425 | 0.7% | −15.70 SOL | Fees |

With every fee tier allowed, momentum, flow and fade all lose 15–16 SOL: most of the account.

---

## 6. Graduation deep dive

### 6.1 Winners vs losers (what was true at entry)
`scripts/winners.py` joins each simulated trade to what the market looked like at entry.
Across the original graduation trades:
- **Pools still on the 1.25% fee tier (smallest market cap) lose.** They won only 33–36% of the
  time. On trades after the analysis point they lost −5.27 SOL while the rest made +0.87 SOL.
- **Heavy early buying marks the winners.** Trades with ≥149 SOL bought before entry won 77% of
  the time, and the gains were spread out rather than coming from a few trades.
- Entering in the first slots *without* that buying lost money (38% wins).

### 6.2 Tuning and first out-of-sample test (≥150 SOL)
We tuned on the first 60% of the day (198 combinations of fee cap, early SOL, TP, SL, hold and
trail), then ran the finalists on the last 40%:

| Setting (unseen last ~9.3 h) | Trades | Win % | Profit | Return |
|---|---|---|---|---|
| Old default (enter everything, TP 25%) | 280 | 43% | −4.34 SOL | −26% |
| Skip the smallest tier only | 136 | 52% | −0.09 SOL | −0.6% |
| ≥50 SOL early, TP 100%, 20 min | 115 | 57% | +1.66 SOL | +9.9% |
| ≥150 SOL early, TP 100%, 20 min | 64 | 69% | +1.72 SOL | +10.3% |
| **≥150 SOL early, TP 50%, 10 min** | 62 | 68% | **+2.40 SOL** | +14.4% |

### 6.3 How the ≥300 variant was found (caveat)
The robustness battery on ≥150 (§6.4) showed its profit hinged on the dump-exit threshold. While
investigating, a full-day grid showed that at `min_early_sol` ≥200–300 the result no longer
depends on that threshold. **That choice used the whole day**, so ≥300 has not had a truly
unseen test yet. Its 6-of-6 profitable blocks and flat neighbouring settings are good signs, but
the next fresh day is the real test.

### 6.4 Robustness battery: ≥150 vs ≥300 side by side

**Each ~4-hour block on its own** (fresh $2,000 account each):

| Block | ≥150 SOL | ≥300 SOL |
|---|---|---|
| 1 (tuning) | +0.520 (23 trades) | +0.137 (6) |
| 2 (tuning) | +0.685 (17) | +0.159 (7) |
| 3 (tuning) | +0.731 (17) | +0.197 (7) |
| 4 (mixed) | **−0.157** (23) | +0.189 (7) |
| 5 (unseen) | **−0.210** (31) | +0.328 (8) |
| 6 (unseen) | +1.670 (24) | +0.924 (8) |
| **Profitable blocks** | **4 / 6** | **6 / 6** |

**Dump-exit threshold** (distinct sellers in one slot that trigger an exit; full day):

| Threshold | ≥150 SOL | ≥300 SOL |
|---|---|---|
| off | **−3.32** | +2.05 |
| 2 | +0.91 | +0.56 |
| 3 (base) | +3.21 | +1.95 |
| 4 | +0.67 | +1.97 |
| 5 | **−0.54** | +1.97 |
| 8 | +0.92 | +2.01 |

- **Why ≥150 is fragile:** the whole difference between thresholds 3 and 4 (+2.54 SOL) comes
  from **5 trades**. At 3 sellers the exit got out just before each of them slid into the
  −30% stop-loss (−0.5 to −0.9 SOL each); at 4 it didn't. Across the other 126 trades, threshold
  3 is actually slightly worse (−0.28 SOL).
- **Why ≥300 is not:** its trades are in deep pools (median 1,057 SOL at entry) that rarely see
  coordinated selling within 10 minutes, so exits come from the time limit, not the dump
  detector.

**Other settings (full day, ≥300 SOL):**

| Setting | Values tested | Result |
|---|---|---|
| Take-profit | 15–200% | +1.95 SOL for all (price rarely rises 15% within 10 min) |
| Stop-loss | 10–60% | +1.95 SOL for all (never hit) |
| Hold | 300 / 750 / 1000 / **1500** / 2250 / 3000 / 6000 slots | −0.08 / +0.48 / +0.75 / **+1.95** / +2.12 / +2.21 / +1.26 |
| Entry delay | 1–10 slots | +1.91 to +2.02 |
| Fee cap | 1.10–1.30% | +1.91 to +1.95 |
| Early SOL | 200 / **300** / 500 | +1.97 / **+1.95** / +1.70 |

Holding 10–20 minutes is the plateau. Shorter holds don't give the drift time to work, and 40
minutes starts running into drains.

**Execution stress** (unseen window only, ≥300 SOL):

| Condition | Trades | Profit |
|---|---|---|
| Baseline (1 slot, 5% failed txs, 0.0001 SOL/tx) | 20 | +1.36 SOL |
| Latency 0 / 2 / 5 / 15 (6 s) / 30 (12 s) slots | 20 | +1.35 / +1.37 / +1.38 / +1.40 / +1.40 |
| 20% failed txs | 14 | +1.24 |
| 0.001 SOL per tx (priority fees) | 20 | +1.32 |
| 0.005 SOL per tx (Jito tips) | 20 | +1.16 |
| 2 slots + 20% fails + 0.001 SOL/tx | 14 | +1.21 |

**Latency doesn't matter for this strategy.** It profits from a drift over minutes, not from
being first. The 6-second Helius block feed is enough.

**Controls** (same exits, different entry rules; full day):

| Entry rule | Trades | Win % | Profit |
|---|---|---|---|
| ≥300 SOL early buying | 44 | 93% | +1.95 |
| ≥150 SOL early buying | 131 | 71% | +3.21 |
| No early-buying filter (skip smallest tier only) | 312 | 52% | +0.66 |
| No filters at all | 544 | 46% | **−4.62** |
| Old default (TP 25%, 5 min, no filters, no dump exit) | 552 | 59% | −2.35 |

**Trade-level statistics:**

| | ≥150 SOL | ≥300 SOL |
|---|---|---|
| Trades / winners | 131 / 93 (71%) | 44 / 41 (93%) |
| Total / mean / median per trade | +3.207 / +0.0245 / +0.0178 SOL | +1.953 / +0.0444 / +0.0269 SOL |
| Without the best 1 / 3 / 5 / 10 trades | +2.33 / +1.59 / +1.29 / +0.66 | +1.07 / +0.95 / +0.83 / +0.60 |
| Without the worst 3 trades | +4.86 | +1.97 |
| Worst single trade | −0.86 SOL | −0.011 SOL |
| Market price change, entry → exit | mixed | **up in all 44** (min +0.5%, median +4.3%, max +90%) |
| Median hold | 141 s | 600 s (time exit) |
| Bootstrap 5th–95th percentile (20,000 resamples) | +0.61 to +5.72 SOL | +0.96 to +3.65 SOL |
| Chance the day's total ≤ 0 (bootstrap) | 2.2% | **0.0%** |
| Profitable hours | 20 of 23 | 18 of 19 |
| Distinct early big buyers behind the trades | 46 | 35 |
| Trades in pools later drained | – | 8 (+0.17 SOL) |

**Account sizes** (≥300 SOL, full day):

| Account | Per trade | Profit | Return |
|---|---|---|---|
| 1 SOL | 0.2 SOL | +0.38 SOL | +38% |
| 5 SOL | 0.5 SOL | +0.97 SOL | +19% |
| 16.7 SOL ($2,000) | 1 SOL | +1.95 SOL | +11.7% |

Sizes above ~1 SOL per trade aren't trustworthy in this backtest (see §8).

### 6.5 Why might it work?
A plausible mechanism, not proven:
1. In these instant-graduation tokens, the operators who bought hundreds of SOL of the token
   keep buying (volume bots, promotion) for a while to attract buyers.
2. The price drifts up a few percent over the next 10–20 minutes.
3. We enter after their first big buy, ride the drift, and leave well before the typical drain
   time (the large drains came ≥16 min after graduation).

The edge is therefore **tied to how these operators behave**, and that can change without
warning.

---

## 7. The recommended setting (for validation, not yet for money)

```
solbot backtest --strategy graduation -p size_sol=1 -p max_fee_pct=1.22 \
  -p min_early_sol=300 -p tp_pct=50 -p sl_pct=30 -p max_hold=1500
```

**Enter** when all of these hold:
- A token graduates to its official Pump.fun pool.
- ≥300 SOL is bought in the pool in the first 2 slots.
- The pool is already below the 1.25% fee tier.

Buy on the next trade.

**Exit** on whichever comes first:
- 10 minutes (1,500 slots)
- 3+ different wallets selling in one slot
- +50% (take-profit)
- −30% (stop-loss)

Both candidates are in `scripts/overnight.sh`, together with a 6-second-latency variant and the
old default for comparison.

---

## 8. Known limitations of the backtest

1. **One day of data.** Every result comes from one Tuesday–Wednesday. Market regimes and
   operator behavior change.
2. **Other traders don't react to us.** The replay keeps every recorded trade as it happened and
   layers our position on top. At 1 SOL in pools holding 200–1,000+ SOL this is minor. At
   5–10 SOL per trade the results (which show the same % return) are **not realistic**.
3. **Latency is a fixed number of slots.** Real fills vary, and we can be front-run or
   sandwiched. The strategy is insensitive to latency up to 12 s, which limits the damage.
4. **Failed transactions** are modeled as a flat 5% (tested up to 20%).
5. **Old stored rows** carry a small decoding error (fees in the pool's SOL after exact-quote-in
   buys). It is bounded: simulated fills match the chain within 0.1%, and the independent
   re-simulation agrees.
6. **The ≥300 threshold was picked after seeing the full day** (§6.3).
7. **The niche is small:** about 44 trades a day at 1 SOL is about +2 SOL/day (≈$234) before any
   scaling, and scaling is limited by (2).

---

## 9. Bugs found and fixed (all uncommitted as of this report)

| Area | Bug | Effect | Fix |
|---|---|---|---|
| Decoder | PumpSwap `buy_exact_quote_in` fills its amount fields the opposite way round from `buy` | Pool SOL after such buys overstated by the trade's fees (82 SOL on the 6,996 SOL buy); inverted-pool sells recorded ~0.3% low | net = min, total = max, vault = `quote_amount_in_with_lp_fee`. Verified: real buys match the pool formula to 0.01% for both instructions. 2 new golden fixtures; the vault test covers multi-swap txs |
| Engine | Buys didn't re-check pool liquidity when the order landed | Fade bought 1 SOL into a pool already drained to 0.2 SOL | Every buy carries its liquidity floor; re-checked at fill |
| Strategies | Coordinated multi-wallet dumps not modeled | Fade −96%; graduation held into drains | `DumpWatch`: counts distinct sellers per slot; entries skipped and positions exited at 3+ |
| Fade | Bought drops of any size | Bought drains | `max_impact_pct` (default 30%) |
| Graduation | No early-flow filter | Entered every graduation | `min_early_sol`, `max_slot_sellers` |
| Backtest | Capital reset to the start amount at the midpoint | "END SOL" could go negative | One continuous account; halves measured against the balance at each half's start |
| Backtest | Setting names cut off | Couldn't tell settings apart | Full names listed under the table |
| Backtest / loop | Top-ranked setting could have 0 trades | Dashboard rows blank; trade files empty | Dump the best setting that traded; dashboard hides 0-trade settings |
| Audit | Compared price-setting reserves (incl. virtual) to vaults | False failures | Compare real reserves |
| Audit | Ignored our own position on exit legs | False failures | Adds our position back before comparing |
| Audit | Pricing check misread stored buy amounts | "0.3% error" | Handles old and new rows; now 0.0004% |
| Audit | Didn't know Pump's `BoostBuyAndBurn` buyback instruction | Swap-count mismatch | Added |
| Audit | Routed trades (aggregators, pooled sybil sells) | False failures | Falls back to the pool vault |
| Audit | Tested the stored rows, not the current decoder | Couldn't tell an old row from a live bug | Re-decodes each sample with the current decoder |
| CLI | `solbot --help` printed the Helius API key | Key in terminal output and logs | `hide_env_values` on `--rpc` |

---

## 10. Recommendations (inputs to the plan)

**Strategy**
1. **Promote graduation + hot money (≥300)** as the primary candidate, with ≥150 as a comparison
   arm. Size 0.1–0.2 SOL for the first real tests.
2. **Retire fade.** It is structurally exposed to one-slot drains.
3. **Keep momentum, flow and random as benchmarks only.**
4. **Snipe only with deployer intelligence.** Score deployers by what happened to their past
   launches (dev sells within seconds, drains) and skip the bad ones. The funding traces
   (35,822 wallets) are the starting point.
5. **Build drain intelligence into the graduation entry:**
   - Flag tokens whose supply sits in many ~1% wallets, or whose big early buyer or deployer is
     linked to past drains (the clusters in §4.3).
   - Skip them, or tighten the exit on them.
6. **Record decision logs:** why each strategy entered or skipped. Future winners-vs-losers
   analysis can then use signals that aren't in the trade dump.

**Validation and process**
7. **Collect a fresh day** with the updated loop and judge both candidates on it untouched. This
   is the real out-of-sample test for ≥300.
8. **Live paper trading** of the winner on a real-time feed, recording fills against the actual
   next-slot pool state.
9. **Then a tiny live test** with a hard daily loss limit, after the executor is built.
10. **Commit** today's fixes, and add a CI job for the golden decoder tests.

---

## 11. Strategy improvements (tuned on the first 60%, tested on the last 40%)

Each strategy was grid-searched on the tuning window, and its 3 best settings were run once on
the unseen window. Full tables: [`validation/improvements.md`](validation/improvements.md).
Profits are on the unseen window.

| Strategy | Before | Best tuned | What changed | Verdict |
|---|---|---|---|---|
| **graduation** | −4.73 SOL | **+1.71 to +2.44 SOL** | Early-buying filter, 10–15 min hold, dump exit. **These are now the defaults** (`min_early_sol=300`, `max_fee_pct=1.22`, TP 50, SL 30, 1,500 slots) | ✅ Validated |
| **whale** (new) | – | +1.23 to +1.29 SOL | Follow any single buy ≥100 SOL that is ≥10% of the pool | ⚠️ Experimental: 247 of 248 trades are instant graduations within a minute, and 82% of its profit comes from tokens `graduation` also trades |
| snipe | −5.03 SOL | −0.13 / +0.10 / −0.04 SOL | Low priority fee, ≥25 buyers, ≤5% bundled, dump at 10%, optional dev-sell exit | ❌ About breakeven on only 22–37 trades |
| momentum | −15.73 SOL | −0.16 SOL | 0.3% tier only, dump exit | ❌ Benchmark |
| flow | −15.04 SOL | −2.49 SOL | ≥25 buyers, 5× volume, dump exit | ❌ Benchmark |
| fade | −15.72 SOL | −0.09 to −0.14 SOL | 0.3% tier only, drop cap, dump exit (a confirmation delay didn't help) | ❌ Retired |

The dump exit, fill-time liquidity check and big-cap-only filters cut the losses of momentum,
flow and fade by 85–99%. None of them makes money, even on the data they were tuned on. The
winners-vs-losers analysis found no entry filter that makes them profitable in either half. That
held in every group we checked: instant graduations, pool age, big caps.

`scripts/overnight.sh` now runs:
- graduation ≥300 (primary), ≥150 (comparison), the 6 s-latency variant and the old default
- whale (experimental)
- strict snipe and original snipe
- momentum, flow and random as benchmarks

Fade is out of the loop.

## 12. Do snipes need higher priority fees?

**No. Higher fees make sniping worse, and even the best possible placement doesn't make it
profitable.**

**Snipe result by priority fee** (tuning window, 0.1 SOL per snipe, 529–578 trades):

| Priority fee per tx | Result |
|---|---|
| 0 | −4.10 to −4.29 SOL |
| 0.0002 SOL | −4.33 to −4.51 SOL |
| 0.001 SOL (old default) | −5.26 to −5.46 SOL |
| 0.005 SOL | −9.88 to −10.26 SOL |

- **At 0.1 SOL per snipe, fees are a big share of the position.** Each 0.001 SOL fee is 1% of
  the position per transaction, 2% per round trip.
- **Best-case placement still loses.** The simulator doesn't give a higher fee a better
  position, so we also simulated the best a big fee could buy: landing immediately (0 latency,
  entry right after the signal). It still loses −3.30 SOL (vs −5.40 at 1 slot).
- **Getting in earlier helps, but not enough:**

| Entry timing (slots after launch) | Result |
|---|---|
| 0 | −4.20 SOL |
| 1 | −4.28 SOL |
| 2 | −4.10 SOL |
| 4 | −4.29 SOL |
| 8 | −3.51 SOL |

  (All at a 0 fee. Waiting a little longer is *slightly* less bad.)

**What real buyers pay** (Jito tips recorded on-chain, curve buys by slots after launch):

| Slots after launch | Buys | With a Jito tip | Median tip | 90th percentile |
|---|---|---|---|---|
| 0 (launch slot) | 33,904 | 11.9% | 0.00024 SOL | 0.0102 SOL |
| 1 | 11,202 | 9.9% | 0.00003 SOL | 0.003 SOL |
| 2 | 6,197 | 6.1% | 0.00001 SOL | 0.003 SOL |
| 3–5 | 18,672 | 4.6% | 0.00005 SOL | 0.003 SOL |
| 6–25 | 102,748 | 6.1% | 0.0001 SOL | 0.0011 SOL |

- Launch-slot buys average 4 SOL: mostly the creator's own bundle, not snipers we could outbid.
- Ordinary priority fees (compute-unit price) aren't recorded yet. Worth adding if sniping is
  revisited.

**Why sniping loses:** over 90% of snipes end because the dev sells or a big holder dumps within
seconds (median hold 3.6 s). The fix is choosing *which* launches to snipe, using deployer history
over more than one day, not paying to land sooner.

**If snipes run live anyway:** use a low fee (≤0.0002 SOL) plus a Jito tip only when a bundle
is needed. The graduation strategy doesn't need speed at all: it makes the same money at 12 s of
latency.

## 13. Wallet study: who makes money, and can we copy them?

**Realized profit per wallet.** We counted only positions a wallet fully opened and closed
within the day: 1.06 M positions across 262 k wallets.
- Only **27.8% of wallets were profitable**.
- All wallets together lost **26,500 SOL** on closed positions: fees, and money moved to insiders.

**Full list:** every profitable wallet (4,012, with address, profit after fees, style and behaviour metrics) is in
[`wallets/PROFITABLE_WALLETS.md`](wallets/PROFITABLE_WALLETS.md) and
[`wallets/profitable-wallets.csv`](wallets/profitable-wallets.csv) (`scripts/wallet_report.py`).

**Who wins:**

| Type | Examples | Behaviour | Result |
|---|---|---|---|
| Graduation leaders | `4G9J…` +2,375 SOL (25 positions), `2w3n…` +1,956, `9qZv…` +1,900, `4p7S…` +1,896, `HHKu…` +1,569 | Buy ~150 SOL in the same slot as an instant graduation, hold 15–30 min | 100% wins, about +60% per position |
| Curve scalpers | `bwamJzzt`, `2CQgjcdN`, `E4FPggw9`, `FFdBLYqL` | 3–8 SOL on the bonding curve, sold after 7–10 s | 70–100% wins; too fast to copy |
| Slower curve bots | `sssssDdM` | 761 positions, median hold 8 min | +208 SOL at a 52% win rate |

**How the leaders make money.** One traced example (token BHMu):
1. In one slot, the creator buys **79% of the supply** for 85 SOL and leader `4G9J…` buys 13%
   for 165 SOL.
2. Outside buyers bring the pool up to ~408 SOL.
3. 40 minutes later, the leader sells for 324 SOL (**+97%**).
4. Most such tokens then collapse, because the creator still holds 79% of the supply.

The leaders are part of the setup: they buy *before* anyone can react, and they know when to leave.

**Ideas tested and rejected** (tuned on the first 60%, judged on the last 40%):

| Idea | Result |
|---|---|
| **Exit when the leader exits** (graduation, `exit_on_leader_sell=1`) | Slightly *worse* than the fixed 10-min exit (≥300: +1.27 vs +1.36 SOL unseen). The creator's supply often crashes the price before the leader sells |
| **Copy wallets that were profitable in the tuning window** (new `copy` strategy; 5 wallet lists from 11 to 286 wallets, chosen by `scripts/smart_wallets.py`) | Lost the whole account in **every** variant, **even on the window the wallets were chosen from**. Copying adds a second round of fees and price impact, and the wallets' edge is being first, which a copy can't be |
| Copying one leader (`4G9J…`) | +0.06 SOL with the dump exit (26 trades); **−4.29 SOL** without it (18 of 26 hit the stop-loss, median −82%). The copyable part is exactly what `graduation` already does |
| **Last-mile curve buys** (buy when a normal launch's curve crosses 50/65/75 SOL of its 85 SOL) | Only 34–45% go on to graduate; median price 10 min later **−29% to −34%**. The average is slightly positive (+2.4% to +4%) only because of a few huge winners |

**Curve scalpers: can we do what they do?** (`dip` strategy, tested 2026-09-30)

After fees, several bonding-curve scalpers really do make money: `CWiNFAEk` +24 SOL,
`AXkori31` +22, `EaaCfVxV` +22, `3TZkRoVa` +22, several more +5 to +15. Others lose after fees
(`AMDEmVoc` −85). They pay the same fees as everyone (0.95% + 0.3% creator per side, no
cashback).

Their entries share a signature, compared with 668 k other early curve buys:

| | Profitable scalpers | Everyone else |
|---|---|---|
| Time after launch | 18–50 slots (7–20 s) | 111 slots |
| SOL already in the curve | 9–16 SOL | 6.4 SOL |
| SOL sold in the previous 10 trades | 3–6 SOL | 0.4 SOL |
| Dev had already sold | 68–100% | 52% |
| Price over the previous 10 trades | flat or down | +2.6% |
| Average price move 24 s later | **+2% to +12%** | **−6.8%** |

In other words, they buy the dip right after the dev and early bundlers dump.

**Across all traders**, buys matching "dev sold + 3–6 SOL sold recently + price down ≥5%" averaged
**+3.4% (tuning) and +1.7% (unseen)** 24 s later. That's before fees (~2.5% round trip) and our
own price impact.

**The `dip` strategy** (that rule, one entry per launch, fixed hold) in the full engine:
- **Tuning window:** best +0.87 SOL (160–280 trades).
- **Unseen window:** **every variant lost** (−2.2 to −11.7 SOL). That includes take-profit /
  stop-loss exits, and **0-latency fills** (−2.5 to −16.6 SOL).

**Why they win and we can't copy it:**
- 78–99% of their buys land in the **same slot** as the trade they react to.
- `AXkori31` buys right behind the **dev's sell, in the same slot, 79% of the time**: it backruns
  dumps within ~0.4 s.
- Even simulated at their speed, the public-signal version loses. Their edge probably also relies
  on information we don't capture: which devs dump everything, exact position within a slot,
  possibly links to the sellers.

**Verdict:** not replicable from our data and latency. `dip` is kept as an experiment (not in the
loop). Revisit only with a same-slot execution path (Triton gRPC + Jito backrun bundles) and
several days of deployer history.

**Ideas we won't pursue:**
- **Sandwiching / front-running other traders.** Some top wallets probably do this. It profits by
  making ordinary users' trades worse.
- **Launching or co-running pump schemes.** Harmful and legally risky.

**Not yet explored:**
- **Mayhem-mode launches** (32% of launches, 738 deployers averaging 13 launches each).
- **Deployer and operator reputation over several days.** Recognizing the launch groups behind
  instant graduations (and their drain timing) could sharpen the graduation strategy's entries and
  exits.
- **Ecosystem coins** (SOL and majors via Jupiter), on years of free candle data.

## 14. Reproduce

```bash
# Chain audit (completeness, decoding, pricing, simulated trades)
python3 scripts/audit.py --samples 40 --trades-csv <dump.csv>
# Independent re-simulation of a strategy's trades from on-chain data
python3 scripts/resim.py <dump.csv>
# Robustness battery for a graduation setting (overrides are key=value)
python3 scripts/validate.py min_early_sol=300
# Winners vs losers
python3 scripts/winners.py <dump.csv>
# Coordinated-drain study
python3 scripts/drains.py
# Train / test backtests
solbot backtest --from-slot 451863358 --to-slot 451988000 ...   # tuning window
solbot backtest --from-slot 451988001 --to-slot 452071879 ...   # unseen window
```

**Glossary**

| Term | Meaning |
|---|---|
| Slot | ~0.4 s |
| Graduation | A token leaves its bonding curve for a PumpSwap pool |
| Instant graduation | A token graduates in its launch slot |
| Official pool | Pump.fun's own graduation pool; LP locked, can't be rugged |
| Fee tier | PumpSwap's fee: 1.25% (smallest caps) down to 0.3% |
| Virtual reserves | Extra SOL PumpSwap uses in pricing that isn't actually in the pool |
| Drain | Many wallets dumping ~1% each in the same slot |
| Profit factor | Gross wins ÷ gross losses |
| Drawdown | Largest peak-to-trough fall of the account |
