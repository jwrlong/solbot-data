# Validation: graduation + hot money, min_early_sol=300 (2026-09-30)

Base setting: size_sol=1, max_fee_pct=1.22, min_early_sol=300, tp_pct=50, sl_pct=30, max_hold=1500

## 1. Every ~4-hour block on its own (fresh $2,000 account each)

| period | trades | win | profit SOL | profit $ | return | profit factor | max drawdown SOL |
|---|---|---|---|---|---|---|---|
| block 1 (tuning) | 6 | 100% | +0.137 | +16 | +0.8% | inf | 0.000 |
| block 2 (tuning) | 7 | 100% | +0.159 | +19 | +0.9% | 1592.62 | 0.000 |
| block 3 (tuning) | 7 | 100% | +0.197 | +24 | +1.2% | 1970.22 | 0.000 |
| block 4 (mixed) | 7 | 86% | +0.189 | +23 | +1.1% | 22.79 | 0.009 |
| block 5 (unseen) | 8 | 100% | +0.328 | +39 | +2.0% | 3277.93 | 0.000 |
| block 6 (unseen) | 8 | 62% | +0.924 | +111 | +5.5% | 63.74 | 0.011 |

Profitable blocks: **6 of 6**.

## 2. Neighbouring settings (is the best one a lucky spike?)

### min_early_sol

| setting | trades | win | profit SOL | profit $ | return | profit factor | max drawdown SOL |
|---|---|---|---|---|---|---|---|
| min_early_sol=0 | 312 | 52% | +0.657 | +79 | +3.9% | 1.08 | 3.281 |
| min_early_sol=25 | 264 | 53% | +2.274 | +273 | +13.6% | 1.54 | 0.883 |
| min_early_sol=50 | 258 | 53% | +2.612 | +313 | +15.6% | 1.71 | 0.883 |
| min_early_sol=75 | 256 | 54% | +3.233 | +388 | +19.4% | 2.01 | 0.882 |
| min_early_sol=100 | 248 | 53% | +3.158 | +379 | +18.9% | 2.01 | 0.886 |
| min_early_sol=125 | 241 | 53% | +2.850 | +342 | +17.1% | 1.93 | 0.892 |
| min_early_sol=150 | 131 | 71% | +3.207 | +385 | +19.2% | 2.64 | 0.882 |
| min_early_sol=200 | 46 | 91% | +1.970 | +236 | +11.8% | 63.77 | 0.016 |
| min_early_sol=300 **(base)** | 44 | 93% | +1.953 | +234 | +11.7% | 131.81 | 0.011 |
| min_early_sol=500 | 39 | 92% | +1.704 | +204 | +10.2% | 115.12 | 0.011 |

### tp_pct

| setting | trades | win | profit SOL | profit $ | return | profit factor | max drawdown SOL |
|---|---|---|---|---|---|---|---|
| tp_pct=15 | 44 | 93% | +1.953 | +234 | +11.7% | 131.81 | 0.011 |
| tp_pct=25 | 44 | 93% | +1.953 | +234 | +11.7% | 131.81 | 0.011 |
| tp_pct=35 | 44 | 93% | +1.953 | +234 | +11.7% | 131.81 | 0.011 |
| tp_pct=50 **(base)** | 44 | 93% | +1.953 | +234 | +11.7% | 131.81 | 0.011 |
| tp_pct=75 | 44 | 93% | +1.953 | +234 | +11.7% | 131.81 | 0.011 |
| tp_pct=100 | 44 | 93% | +1.951 | +234 | +11.7% | 131.72 | 0.011 |
| tp_pct=200 | 44 | 93% | +1.951 | +234 | +11.7% | 131.72 | 0.011 |

### sl_pct

| setting | trades | win | profit SOL | profit $ | return | profit factor | max drawdown SOL |
|---|---|---|---|---|---|---|---|
| sl_pct=10 | 44 | 93% | +1.953 | +234 | +11.7% | 131.81 | 0.011 |
| sl_pct=15 | 44 | 93% | +1.953 | +234 | +11.7% | 131.81 | 0.011 |
| sl_pct=20 | 44 | 93% | +1.953 | +234 | +11.7% | 131.81 | 0.011 |
| sl_pct=30 **(base)** | 44 | 93% | +1.953 | +234 | +11.7% | 131.81 | 0.011 |
| sl_pct=40 | 44 | 93% | +1.953 | +234 | +11.7% | 131.81 | 0.011 |
| sl_pct=60 | 44 | 93% | +1.953 | +234 | +11.7% | 131.81 | 0.011 |

### max_hold

| setting | trades | win | profit SOL | profit $ | return | profit factor | max drawdown SOL |
|---|---|---|---|---|---|---|---|
| max_hold=300 | 42 | 31% | -0.079 | -10 | -0.5% | 0.35 | 0.079 |
| max_hold=750 | 43 | 84% | +0.476 | +57 | +2.9% | 15.99 | 0.024 |
| max_hold=1000 | 44 | 86% | +0.752 | +90 | +4.5% | 34.54 | 0.019 |
| max_hold=1500 **(base)** | 44 | 93% | +1.953 | +234 | +11.7% | 131.81 | 0.011 |
| max_hold=2250 | 45 | 96% | +2.119 | +254 | +12.7% | 149.79 | 0.011 |
| max_hold=3000 | 44 | 93% | +2.208 | +265 | +13.2% | 154.04 | 0.011 |
| max_hold=6000 | 42 | 88% | +1.264 | +152 | +7.6% | 1.97 | 0.941 |

### max_slot_sellers

| setting | trades | win | profit SOL | profit $ | return | profit factor | max drawdown SOL |
|---|---|---|---|---|---|---|---|
| max_slot_sellers=0 | 44 | 98% | +2.053 | +246 | +12.3% | 2619.36 | 0.001 |
| max_slot_sellers=2 | 43 | 79% | +0.556 | +67 | +3.3% | 11.24 | 0.027 |
| max_slot_sellers=3 | 44 | 93% | +1.953 | +234 | +11.7% | 131.81 | 0.011 |
| max_slot_sellers=4 | 44 | 93% | +1.967 | +236 | +11.8% | 132.78 | 0.011 |
| max_slot_sellers=5 | 44 | 93% | +1.967 | +236 | +11.8% | 134.28 | 0.011 |
| max_slot_sellers=8 | 44 | 96% | +2.009 | +241 | +12.0% | 167.05 | 0.011 |

### max_fee_pct

| setting | trades | win | profit SOL | profit $ | return | profit factor | max drawdown SOL |
|---|---|---|---|---|---|---|---|
| max_fee_pct=1.1 | 43 | 93% | +1.906 | +229 | +11.4% | 128.67 | 0.011 |
| max_fee_pct=1.16 | 43 | 93% | +1.906 | +229 | +11.4% | 128.67 | 0.011 |
| max_fee_pct=1.22 **(base)** | 44 | 93% | +1.953 | +234 | +11.7% | 131.81 | 0.011 |
| max_fee_pct=1.3 | 44 | 93% | +1.953 | +234 | +11.7% | 131.81 | 0.011 |

### delay_slots

| setting | trades | win | profit SOL | profit $ | return | profit factor | max drawdown SOL |
|---|---|---|---|---|---|---|---|
| delay_slots=1 | 44 | 91% | +1.908 | +229 | +11.4% | 104.43 | 0.012 |
| delay_slots=2 | 44 | 93% | +1.953 | +234 | +11.7% | 131.81 | 0.011 |
| delay_slots=3 | 44 | 96% | +1.984 | +238 | +11.9% | 155.94 | 0.010 |
| delay_slots=5 | 44 | 96% | +2.007 | +241 | +12.0% | 169.73 | 0.009 |
| delay_slots=10 | 44 | 96% | +2.023 | +243 | +12.1% | 177.30 | 0.009 |

## 3. Execution stress (unseen window only)

| condition | trades | win | profit SOL | profit $ | return | profit factor | max drawdown SOL |
|---|---|---|---|---|---|---|---|
| baseline: 1 slot latency, 5% failed txs, 0.0001 SOL/tx | 20 | 85% | +1.362 | +163 | +8.2% | 92.87 | 0.011 |
| 0 slot latency (optimistic) | 20 | 85% | +1.346 | +161 | +8.1% | 81.08 | 0.011 |
| 2 slots latency | 20 | 90% | +1.373 | +165 | +8.2% | 105.60 | 0.010 |
| 5 slots (2 s) | 20 | 90% | +1.381 | +166 | +8.3% | 107.49 | 0.010 |
| 15 slots (6 s, Helius block feed) | 20 | 90% | +1.395 | +167 | +8.3% | 124.77 | 0.009 |
| 30 slots (12 s) | 20 | 90% | +1.396 | +167 | +8.4% | 184.23 | 0.006 |
| 20% failed txs | 14 | 93% | +1.244 | +149 | +7.5% | 105.47 | 0.011 |
| 0.001 SOL per tx (priority fees) | 20 | 85% | +1.324 | +159 | +7.9% | 63.69 | 0.013 |
| 0.005 SOL per tx (Jito tips) | 20 | 75% | +1.156 | +139 | +6.9% | 19.35 | 0.035 |
| 2 slots + 20% fails + 0.001 SOL/tx | 14 | 93% | +1.212 | +145 | +7.3% | 67.76 | 0.012 |

## 4. Trade size (full day; account scaled so size isn't capped by cash)

| size | trades | win | profit SOL | profit $ | return | profit factor | max drawdown SOL |
|---|---|---|---|---|---|---|---|
| 0.05 SOL/trade (start 1 SOL) | 44 | 82% | +0.089 | +11 | +8.9% | 46.63 | 0.001 |
| 0.2 SOL/trade (start 1 SOL) | 44 | 91% | +0.383 | +46 | +38.3% | 104.65 | 0.003 |
| 0.5 SOL/trade (start 5 SOL) | 44 | 93% | +0.972 | +117 | +19.4% | 124.64 | 0.006 |
| 1 SOL/trade (start 16.7 SOL) | 44 | 93% | +1.953 | +234 | +11.7% | 131.81 | 0.011 |
| 2 SOL/trade (start 33 SOL) | 44 | 93% | +3.912 | +469 | +11.9% | 135.58 | 0.022 |
| 5 SOL/trade (start 84 SOL) | 44 | 93% | +9.779 | +1173 | +11.6% | 137.58 | 0.056 |
| 10 SOL/trade (start 167 SOL) | 44 | 93% | +19.516 | +2342 | +11.7% | 137.66 | 0.112 |

## 5. Controls (same exits, different entries; full day)

| entry rule | trades | win | profit SOL | profit $ | return | profit factor | max drawdown SOL |
|---|---|---|---|---|---|---|---|
| base: >=300 SOL early buying, not smallest tier | 44 | 93% | +1.953 | +234 | +11.7% | 131.81 | 0.011 |
| no early-buying filter, not smallest tier | 312 | 52% | +0.657 | +79 | +3.9% | 1.08 | 3.281 |
| no filters at all | 544 | 46% | -4.615 | -554 | -27.6% | 0.81 | 6.091 |
| >=300 SOL early buying, no dump exit | 44 | 98% | +2.053 | +246 | +12.3% | 2619.36 | 0.001 |
| old default (TP 25%, 5 min, no filters, no dump exit) | 552 | 59% | -2.348 | -282 | -14.1% | 0.93 | 6.447 |

## 6. Trade-level statistics (full day)

- Trades: 44; winners 41 (93%)
- Total +1.953 SOL; mean +0.0444; median +0.0269
- Without the best 1 / 3 / 5 / 10 trades: +1.071 / +0.945 / +0.829 / +0.598 SOL
- Without the worst 3 trades: +1.968 SOL
- Hold time: median 600 s, 90th percentile 600 s
- Exit reasons: time 38 trades +1.079 SOL; dump 4 trades -0.008 SOL; end 1 trades +0.000 SOL; tp 1 trades +0.882 SOL
- Bootstrap (20,000 resamples of the 44 trades): 5th-95th percentile total +0.959 to +3.653 SOL; chance the total is <= 0: 0.0%
- Hours with trades: 19; profitable hours: 18

_Validation took 526 s._
