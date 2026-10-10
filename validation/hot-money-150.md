# Validation: graduation + hot money, min_early_sol=150 (2026-09-30)

Base setting: size_sol=1, max_fee_pct=1.22, min_early_sol=150, tp_pct=50, sl_pct=30, max_hold=1500

## 1. Every ~4-hour block on its own (fresh $2,000 account each)

| period | trades | win | profit SOL | profit $ | return | profit factor | max drawdown SOL |
|---|---|---|---|---|---|---|---|
| block 1 (tuning) | 23 | 70% | +0.520 | +62 | +3.1% | 11.63 | 0.019 |
| block 2 (tuning) | 17 | 76% | +0.685 | +82 | +4.1% | 22.64 | 0.010 |
| block 3 (tuning) | 17 | 94% | +0.731 | +88 | +4.4% | 81.93 | 0.009 |
| block 4 (mixed) | 23 | 65% | -0.157 | -19 | -0.9% | 0.81 | 0.602 |
| block 5 (unseen) | 31 | 61% | -0.210 | -25 | -1.3% | 0.79 | 0.882 |
| block 6 (unseen) | 24 | 71% | +1.670 | +200 | +10.0% | 29.36 | 0.022 |

Profitable blocks: **4 of 6**.

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
| min_early_sol=150 **(base)** | 131 | 71% | +3.207 | +385 | +19.2% | 2.64 | 0.882 |
| min_early_sol=200 | 46 | 91% | +1.970 | +236 | +11.8% | 63.77 | 0.016 |
| min_early_sol=300 | 44 | 93% | +1.953 | +234 | +11.7% | 131.81 | 0.011 |
| min_early_sol=500 | 39 | 92% | +1.704 | +204 | +10.2% | 115.12 | 0.011 |

### tp_pct

| setting | trades | win | profit SOL | profit $ | return | profit factor | max drawdown SOL |
|---|---|---|---|---|---|---|---|
| tp_pct=15 | 131 | 71% | +2.762 | +331 | +16.5% | 2.41 | 0.882 |
| tp_pct=25 | 131 | 71% | +2.949 | +354 | +17.7% | 2.51 | 0.882 |
| tp_pct=35 | 131 | 71% | +3.051 | +366 | +18.3% | 2.56 | 0.882 |
| tp_pct=50 **(base)** | 131 | 71% | +3.207 | +385 | +19.2% | 2.64 | 0.882 |
| tp_pct=75 | 131 | 71% | +3.445 | +413 | +20.6% | 2.76 | 0.882 |
| tp_pct=100 | 131 | 71% | +3.482 | +418 | +20.9% | 2.78 | 0.882 |
| tp_pct=200 | 131 | 71% | +3.482 | +418 | +20.9% | 2.78 | 0.882 |

### sl_pct

| setting | trades | win | profit SOL | profit $ | return | profit factor | max drawdown SOL |
|---|---|---|---|---|---|---|---|
| sl_pct=10 | 131 | 71% | +3.199 | +384 | +19.1% | 2.63 | 0.882 |
| sl_pct=15 | 131 | 71% | +3.199 | +384 | +19.1% | 2.63 | 0.882 |
| sl_pct=20 | 131 | 71% | +3.199 | +384 | +19.1% | 2.63 | 0.882 |
| sl_pct=30 **(base)** | 131 | 71% | +3.207 | +385 | +19.2% | 2.64 | 0.882 |
| sl_pct=40 | 131 | 71% | +3.207 | +385 | +19.2% | 2.64 | 0.882 |
| sl_pct=60 | 131 | 71% | +3.207 | +385 | +19.2% | 2.64 | 0.882 |

### max_hold

| setting | trades | win | profit SOL | profit $ | return | profit factor | max drawdown SOL |
|---|---|---|---|---|---|---|---|
| max_hold=300 | 131 | 50% | -0.181 | -22 | -1.1% | 0.88 | 0.916 |
| max_hold=750 | 131 | 68% | +1.090 | +131 | +6.5% | 1.55 | 0.953 |
| max_hold=1000 | 131 | 69% | +1.773 | +213 | +10.6% | 1.90 | 0.873 |
| max_hold=1500 **(base)** | 131 | 71% | +3.207 | +385 | +19.2% | 2.64 | 0.882 |
| max_hold=2250 | 131 | 72% | +3.312 | +397 | +19.8% | 2.70 | 0.871 |
| max_hold=3000 | 131 | 71% | +3.412 | +409 | +20.4% | 2.75 | 0.873 |
| max_hold=6000 | 133 | 69% | +2.491 | +299 | +14.9% | 1.77 | 1.227 |

### max_slot_sellers

| setting | trades | win | profit SOL | profit $ | return | profit factor | max drawdown SOL |
|---|---|---|---|---|---|---|---|
| max_slot_sellers=0 | 132 | 75% | -3.321 | -399 | -19.9% | 0.85 | 8.352 |
| max_slot_sellers=2 | 130 | 57% | +0.913 | +110 | +5.5% | 1.63 | 0.912 |
| max_slot_sellers=3 | 131 | 71% | +3.207 | +385 | +19.2% | 2.64 | 0.882 |
| max_slot_sellers=4 | 131 | 72% | +0.667 | +80 | +4.0% | 1.13 | 1.767 |
| max_slot_sellers=5 | 132 | 74% | -0.543 | -65 | -3.2% | 0.93 | 2.925 |
| max_slot_sellers=8 | 132 | 85% | +0.919 | +110 | +5.5% | 1.08 | 3.967 |

### max_fee_pct

| setting | trades | win | profit SOL | profit $ | return | profit factor | max drawdown SOL |
|---|---|---|---|---|---|---|---|
| max_fee_pct=1.1 | 45 | 91% | +1.923 | +231 | +11.5% | 75.38 | 0.011 |
| max_fee_pct=1.16 | 102 | 76% | +2.866 | +344 | +17.2% | 3.20 | 0.871 |
| max_fee_pct=1.22 **(base)** | 131 | 71% | +3.207 | +385 | +19.2% | 2.64 | 0.882 |
| max_fee_pct=1.3 | 131 | 71% | +3.207 | +385 | +19.2% | 2.64 | 0.882 |

### delay_slots

| setting | trades | win | profit SOL | profit $ | return | profit factor | max drawdown SOL |
|---|---|---|---|---|---|---|---|
| delay_slots=1 | 131 | 70% | +3.171 | +380 | +19.0% | 2.62 | 0.881 |
| delay_slots=2 | 131 | 71% | +3.207 | +385 | +19.2% | 2.64 | 0.882 |
| delay_slots=3 | 131 | 72% | +3.139 | +377 | +18.8% | 2.59 | 0.882 |
| delay_slots=5 | 136 | 69% | +2.987 | +358 | +17.9% | 2.43 | 0.885 |
| delay_slots=10 | 153 | 67% | +2.015 | +242 | +12.1% | 1.90 | 0.886 |

## 3. Execution stress (unseen window only)

| condition | trades | win | profit SOL | profit $ | return | profit factor | max drawdown SOL |
|---|---|---|---|---|---|---|---|
| baseline: 1 slot latency, 5% failed txs, 0.0001 SOL/tx | 62 | 68% | +2.405 | +289 | +14.4% | 13.41 | 0.066 |
| 0 slot latency (optimistic) | 62 | 68% | +2.386 | +286 | +14.3% | 13.00 | 0.066 |
| 2 slots latency | 62 | 69% | +2.380 | +286 | +14.2% | 13.73 | 0.067 |
| 5 slots (2 s) | 62 | 68% | +2.318 | +278 | +13.9% | 12.12 | 0.067 |
| 15 slots (6 s, Helius block feed) | 62 | 66% | +2.309 | +277 | +13.8% | 11.71 | 0.067 |
| 30 slots (12 s) | 62 | 66% | +2.392 | +287 | +14.3% | 12.59 | 0.069 |
| 20% failed txs | 52 | 69% | +1.480 | +178 | +8.9% | 11.01 | 0.050 |
| 0.001 SOL per tx (priority fees) | 62 | 68% | +2.289 | +275 | +13.7% | 10.81 | 0.074 |
| 0.005 SOL per tx (Jito tips) | 62 | 58% | +1.777 | +213 | +10.6% | 5.06 | 0.115 |
| 2 slots + 20% fails + 0.001 SOL/tx | 52 | 71% | +1.332 | +160 | +8.0% | 8.34 | 0.058 |

## 4. Trade size (full day; account scaled so size isn't capped by cash)

| size | trades | win | profit SOL | profit $ | return | profit factor | max drawdown SOL |
|---|---|---|---|---|---|---|---|
| 0.05 SOL/trade (start 1 SOL) | 131 | 65% | +0.135 | +16 | +13.5% | 2.27 | 0.045 |
| 0.2 SOL/trade (start 1 SOL) | 131 | 70% | +0.621 | +75 | +62.1% | 2.56 | 0.177 |
| 0.5 SOL/trade (start 5 SOL) | 131 | 71% | +1.592 | +191 | +31.8% | 2.62 | 0.441 |
| 1 SOL/trade (start 16.7 SOL) | 131 | 71% | +3.207 | +385 | +19.2% | 2.64 | 0.882 |
| 2 SOL/trade (start 33 SOL) | 131 | 71% | +6.423 | +771 | +19.5% | 2.65 | 1.761 |
| 5 SOL/trade (start 84 SOL) | 131 | 71% | +15.973 | +1917 | +19.0% | 2.64 | 4.388 |
| 10 SOL/trade (start 167 SOL) | 131 | 71% | +31.562 | +3787 | +18.9% | 2.63 | 8.732 |

## 5. Controls (same exits, different entries; full day)

| entry rule | trades | win | profit SOL | profit $ | return | profit factor | max drawdown SOL |
|---|---|---|---|---|---|---|---|
| base: >=150 SOL early buying, not smallest tier | 131 | 71% | +3.207 | +385 | +19.2% | 2.64 | 0.882 |
| no early-buying filter, not smallest tier | 312 | 52% | +0.657 | +79 | +3.9% | 1.08 | 3.281 |
| no filters at all | 544 | 46% | -4.615 | -554 | -27.6% | 0.81 | 6.091 |
| >=150 SOL early buying, no dump exit | 132 | 75% | -3.321 | -399 | -19.9% | 0.85 | 8.352 |
| old default (TP 25%, 5 min, no filters, no dump exit) | 552 | 59% | -2.348 | -282 | -14.1% | 0.93 | 6.447 |

## 6. Trade-level statistics (full day)

- Trades: 131; winners 93 (71%)
- Total +3.207 SOL; mean +0.0245; median +0.0178
- Without the best 1 / 3 / 5 / 10 trades: +2.326 / +1.587 / +1.285 / +0.662 SOL
- Without the worst 3 trades: +4.861 SOL
- Hold time: median 141 s, 90th percentile 600 s
- Exit reasons: dump 88 trades +2.176 SOL; time 36 trades +1.011 SOL; end 3 trades +0.043 SOL; tp 2 trades +1.392 SOL; sl 2 trades -1.414 SOL
- Bootstrap (20,000 resamples of the 131 trades): 5th-95th percentile total +0.608 to +5.716 SOL; chance the total is <= 0: 2.2%
- Hours with trades: 23; profitable hours: 20

_Validation took 540 s._
