# Strategy improvement search (2026-09-30): tune on first 60%, test on last 40%

Produced by `scripts/improve.py`. Each table: the pre-change baseline, then the 3 best settings on the tuning window, run once on the unseen window. $2,000 account (16.7 SOL), 1 SOL per trade (snipe 0.1), max 5 open.

## whale (new)

120 settings tried on the tuning window.

| setting | tuning: trades | win | profit SOL | unseen: trades | win | profit SOL | max DD |
|---|---|---|---|---|---|---|---|
| defaults (min_buy_sol=100, min_pool_pct=10, max_hold=1500) | 143 | 46% | +0.966 | 108 | 53% | **+1.228** | 0.928 |
| max_age_min=30,max_hold=3000,min_buy_sol=100,min_pool_pct=5 | 142 | 46% | +1.147 | 107 | 53% | **+1.270** | 0.884 |
| max_age_min=30,max_hold=3000,min_buy_sol=100,min_pool_pct=20 | 142 | 46% | +1.147 | 106 | 54% | **+1.285** | 0.884 |


## graduation

24 settings tried on the tuning window.
| setting | tuning: trades | win | profit SOL | unseen: trades | win | profit SOL | max DD |
|---|---|---|---|---|---|---|---|
| baseline (max_fee_pct=1.3,max_hold=300,max_slot_sellers=0,min_early_sol=0,sl_pct=15,tp_pct=25) | 265 | 64% | +1.587 | 280 | 55% | -4.729 | 6.188 |
| max_hold=3000,max_slot_sellers=3,min_early_sol=150 | 68 | 74% | +1.759 | 64 | 69% | **+1.714** | 0.873 |
| max_hold=2250,max_slot_sellers=3,min_early_sol=150 | 68 | 75% | +1.684 | 62 | 69% | **+2.443** | 0.066 |
| max_hold=1500,max_slot_sellers=3,min_early_sol=150 | 68 | 75% | +1.610 | 62 | 68% | **+2.405** | 0.066 |

## snipe

48 settings tried on the tuning window.
| setting | tuning: trades | win | profit SOL | unseen: trades | win | profit SOL | max DD |
|---|---|---|---|---|---|---|---|
| baseline (size_sol=0.1) | 558 | 17% | -5.265 | 589 | 20% | -5.027 | 5.007 |
| dump_pct=10,exit_dev_sell=0,max_bundle_pct=5,min_buyers=15,min_net_sol=8,priority_sol=0.0002,size_sol=0.1 | 29 | 34% | +0.202 | 37 | 22% | **-0.130** | 0.287 |
| dump_pct=10,exit_dev_sell=0,max_bundle_pct=5,min_buyers=25,min_net_sol=3,priority_sol=0.0002,size_sol=0.1 | 15 | 40% | +0.099 | 22 | 32% | **+0.095** | 0.225 |
| dump_pct=10,exit_dev_sell=1,max_bundle_pct=5,min_buyers=25,min_net_sol=3,priority_sol=0.0002,size_sol=0.1 | 15 | 47% | -0.030 | 22 | 36% | **-0.039** | 0.144 |

## momentum

48 settings tried on the tuning window.
| setting | tuning: trades | win | profit SOL | unseen: trades | win | profit SOL | max DD |
|---|---|---|---|---|---|---|---|
| baseline (max_fee_pct=1.3,max_slot_sellers=0) | 651 | 32% | -15.762 | 648 | 34% | -15.727 | 15.826 |
| max_fee_pct=0.35,max_slot_sellers=3,min_rise_pct=5,sl_pct=6,tp_pct=30,window=150 | 27 | 18% | -1.084 | 36 | 11% | **-0.155** | 0.154 |
| max_fee_pct=0.35,max_slot_sellers=3,min_rise_pct=5,sl_pct=6,tp_pct=10,window=150 | 27 | 18% | -1.084 | 36 | 11% | **-0.155** | 0.154 |
| max_fee_pct=0.35,max_slot_sellers=3,min_rise_pct=5,sl_pct=15,tp_pct=30,window=150 | 27 | 18% | -1.084 | 36 | 11% | **-0.155** | 0.154 |

## flow

32 settings tried on the tuning window.
| setting | tuning: trades | win | profit SOL | unseen: trades | win | profit SOL | max DD |
|---|---|---|---|---|---|---|---|
| baseline (max_fee_pct=1.3,max_slot_sellers=0) | 345 | 22% | -9.825 | 434 | 24% | -15.043 | 15.467 |
| max_fee_pct=1.3,max_hold=4500,max_slot_sellers=3,min_buyers=25,trail_pct=10,vol_mult=5 | 162 | 25% | -4.799 | 196 | 31% | **-2.494** | 2.975 |
| max_fee_pct=1.3,max_hold=1500,max_slot_sellers=3,min_buyers=25,trail_pct=10,vol_mult=5 | 162 | 25% | -4.799 | 196 | 31% | **-2.494** | 2.975 |
| max_fee_pct=1.3,max_hold=4500,max_slot_sellers=3,min_buyers=25,trail_pct=20,vol_mult=5 | 162 | 24% | -4.808 | 196 | 30% | **-2.976** | 3.332 |

## fade

48 settings tried on the tuning window.
| setting | tuning: trades | win | profit SOL | unseen: trades | win | profit SOL | max DD |
|---|---|---|---|---|---|---|---|
| baseline (max_fee_pct=1.3,max_impact_pct=100,max_slot_sellers=0) | 632 | 27% | -15.777 | 614 | 30% | -15.720 | 15.738 |
| confirm_slots=0,max_fee_pct=0.35,min_impact_pct=5,revert=0.6,sl_pct=20 | 24 | 25% | -5.391 | 27 | 22% | **-0.141** | 0.213 |
| confirm_slots=0,max_fee_pct=0.35,min_impact_pct=5,revert=0.6,sl_pct=10 | 24 | 25% | -5.391 | 27 | 22% | **-0.141** | 0.213 |
| confirm_slots=0,max_fee_pct=0.35,min_impact_pct=5,revert=0.3,sl_pct=20 | 24 | 17% | -5.441 | 27 | 15% | **-0.094** | 0.159 |

