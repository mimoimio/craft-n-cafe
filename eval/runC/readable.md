# Run C — Building-First with Opening Day Pack

Source: `eval/runC/runC.csv`  
Cleaned CSV: `eval/runC/runC.clean.csv`  
Duration: **44:01**  
Account: `5470482596`  
Variant: **no-pass**  
Cash purchase: **Opening Day Pack — 8,590 cash** at 15:30 (`cash_purchased_total = 8,590`)

> **Important:** this is not a clean free-player run. The Opening Day Pack paid out 8,000 cash plus 590 cash from duplicate starter items, and that purchase funded most of the mid-game. Run B remains the only clean free-player baseline.

---

## At a glance

| Metric | Start | End | Peak |
|---|---:|---:|---:|
| Level | 1 | **8** | 8 |
| EXP | 0 | 497 | 497 |
| Cash | 300 | **507** | **8,062** at 15:30 (post-pack); **2,691** otherwise |
| Lifetime earned | 0 | **12,505** | — |
| Cash purchased | 0 | **8,590** | — |
| Customers served | 0 | **254** | — |
| Cashiers placed | 1 | **2** | 2 |
| Stations placed | 5 | **10** | 10 |
| Ingredient progress | 3 / 12 | **8 / 12** | 8 |
| Plot size | 32 | **48** | 48 |
| Workers | 0 | **1** | 1 |
| Upgrades | none | Espresso 5, Water 5, Milk 5, Ice 5, Foam 4, Chocolate 2, Teabag 1 | — |

### Rates

| Metric | Value |
|---|---:|
| Earned cash | **284.1 / min** |
| Customers served | **5.77 / min** |
| EXP | **11.29 / min** |
| Cash per customer | **49.23** |
| EXP per customer | **1.96** |
| Total spent | **20,888** |

Total spent = starting cash `300` + earned `12,505` + purchased `8,590` - ending cash `507`.  
Of the 20,888 spent, **8,590 (41%) came from the Opening Day Pack.**

---

## Timeline

| Time | Level | Cash | Lifetime | Customers | Cashiers | Stations | Ingredient index | Workers | Plot | Key event |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|
| 00:00 | 1 | 300 | 0 | 0 | 1 | 5 | 3 | 0 | 32 | Start |
| 01:00 | 2 | 334 | 34 | 6 | 1 | 5 | 3 | 0 | 32 | First customer loop |
| 03:30 | 3 | 280 | 80 | 14 | 1 | 6 | 4 | 0 | 32 | Ice bought/placed |
| 08:30 | 4 | 147 | 247 | 37 | 1 | 6 | 4 | 0 | 32 | Level 4 |
| 09:00 | 4 | 147 | 247 | 39 | 2 | 6 | 4 | 0 | 32 | Register #2 bought (-300) |
| 10:30 | 4 | 60 | 280 | 44 | 2 | 7 | 5 | 0 | 32 | Foam bought/placed (-120) |
| 12:30 | 4 | 51 | 421 | 53 | 2 | 7 | 5 | 0 | 32 | Espresso/Water → 1 (-150) |
| 14:30 | 5 | 258 | 628 | 63 | 2 | 7 | 5 | 0 | 32 | Level 5 |
| 15:30 | 5 | 8,062 | 628 | 63 | 2 | 7 | 5 | 0 | 32 | **Opening Day Pack +8,590**; Chocolate bought + Espresso/Water → 3 (-786) |
| 16:00 | 5 | 8,062 | 628 | 63 | 2 | 8 | 6 | 0 | 32 | Chocolate placed |
| 17:30 | 5 | 62 | 653 | 65 | 2 | 8 | 6 | 0 | 32 | Upgrade dump: Espresso/Water/Milk/Ice → 5, Foam → 4, Chocolate → 1 (-8,025) |
| 24:30 | 6 | 469 | 3,560 | 102 | 2 | 8 | 6 | 1 | 32 | Level 6; Worker #1 + walk 2 + craft 3 (-2,500) |
| 29:30 | 6 | 113 | 6,204 | 142 | 2 | 8 | 6 | 1 | **48** | Plot expansion (-3,000) |
| 33:30 | 7 | 1,840 | 7,931 | 169 | 2 | 8 | 6 | 1 | 48 | Level 7 |
| 36:00 | 7 | 177 | 8,768 | 187 | 2 | 9 | 7 | 1 | 48 | Teabag bought/placed (-2,500) |
| 37:30 | 7 | 312 | 9,510 | 202 | 2 | 9 | 7 | 1 | 48 | Chocolate → 2 + more upgrades (-607) |
| 41:30 | 7 | 315 | 11,513 | 233 | 2 | 9 | 7 | 1 | 48 | Icecream bought (-2,000) |
| 42:00 | 7 | 428 | 11,626 | 237 | 2 | 10 | 8 | 1 | 48 | Icecream placed |
| 44:01 | 8 | 507 | 12,505 | 254 | 2 | 10 | 8 | 1 | 48 | Level 8; worker quality 2 (-800); end |

---

## Level milestones

| Level | Reached at |
|---:|---:|
| 2 | 01:00 |
| 3 | 03:30 |
| 4 | 08:30 |
| 5 | 14:30 |
| 6 | 24:30 |
| 7 | 33:30 |
| 8 | 44:01 |

Current EXP is **497**. Level 9 needs **640 EXP**, so the player is **143 EXP away**.

Level pacing is close to Run B: level 6 came 4 minutes later, but level 7/8 came 2–3 minutes earlier because of the post-pack upgrades.

---

## Ingredient / station milestones

IngredientsConfig order:

`espresso → water → milk → ice → foam → chocolate → teabag → icecream → matcha → lemon → boba → carbonator`

| Ingredient index | Reached at | Notes |
|---:|---:|---|
| 4 (ice) | 03:30 | Bought/placed |
| 5 (foam) | 10:30 | Bought/placed |
| 6 (chocolate) | 16:00 | Bought with the pack; placed 16:00 |
| 7 (teabag) | 36:00 | Bought/placed |
| 8 (icecream) | 42:00 | Bought 41:30; placed 42:00 |
| 9 (matcha) | never | Costs 3,000; run ended at level 8 |

The player finished with **8/12** stations, the deepest run so far.

---

## Major purchases

| Time | Purchase | Cost |
|---:|---|---:|
| 03:30 | Ice station | 100 |
| 09:00 | Register #2 | 300 |
| 10:30 | Foam station | 120 |
| 12:30 | Espresso + Water → 1 | 150 |
| 15:30 | Opening Day Pack | **+8,590 cash** |
| 15:30 | Chocolate station + Espresso/Water → 3 | 786 |
| 17:30 | Espresso/Water/Milk/Ice → 5, Foam → 4, Chocolate → 1 | 8,025 |
| 24:30 | Worker #1 + walk 2 + craft 3 | 2,500 |
| 29:30 | Plot expansion → 48 | 3,000 |
| 36:00 | Teabag station | 2,500 |
| 37:30 | Chocolate → 2 + more ingredient upgrades | 607 |
| 41:30 | Icecream station | 2,000 |
| 44:01 | Worker quality → 2 | 800 |

### Spending split

| Category | Spend | Share |
|---|---:|---:|
| Ingredient upgrades | ~9,468 | **45%** |
| Stations | 4,820 | **23%** |
| Worker hire + upgrades | 3,300 | **16%** |
| Plot expansion | 3,000 | **14%** |
| Register #2 | 300 | **1%** |

---

## Run A vs Run B vs Run C

| Metric | Run A | Run B | Run C |
|---|---:|---:|---:|
| Duration | 23:31 | 50:01 | **44:01** |
| Variant | no-pass | no-pass | no-pass |
| Cash purchased | 2,000 (Pocket Change) | **0** | **8,590 (Opening Day Pack)** |
| Level | 6 | 8 | **8** |
| Level 6 time | 21:30 | 20:30 | **24:30** |
| Customers | 112 | 260 | **254** |
| Customers/min | 4.76 | 5.20 | **5.77** |
| Lifetime earned | 1,083 | 4,375 | **12,505** |
| Cash/min | 46.1 | 87.5 | **284.1** |
| Cash/customer | 9.67 | 16.83 | **49.23** |
| Ingredient index | 5 | 6 | **8** |
| Plot size | 32 | 32 | **48** |
| Registers | 2 | 2 | 2 |
| Worker | 1 | 1 | 1 |

---

## My thoughts

### 1. This run validates the pack and the receipt flow, not free-player pacing

The Opening Day Pack granted exactly once, was recorded in `purchased_products`, and contributed to `cash_purchased_total`. The 8,590 grant is correct: 8,000 base cash plus 590 refunded for starter items already owned. That is good launch QA.

But it means this run cannot answer whether a free player reaches Teabag or the first plot expansion. Run B is still the only clean free-player baseline, and it ended at 6/12 stations with no expansion.

### 2. The starter pack is very strong

8,590 cash is roughly:

- 30 minutes of post-upgrade income at 284/min,
- ~175 customers at Run C's 49.23 cash/customer,
- 41% of the entire run's spending.

It immediately funded the 8,025 upgrade dump, then the worker, plot expansion, Teabag, and Icecream. If you want a player-first soft launch, consider lowering the pack's cash to **3,000–5,000**, or making it grant a station/decor plus a smaller cash amount. If you keep 8,000, expect it to skip roughly the 15–30 minute mid-game.

### 3. The upgrade dump is the dominant power spike

At 17:30 the player spent 8,025 on ingredient upgrades. Earned cash rose from ~37/min before the dump to ~250+/min by 30:00. This confirms that value upgrades are strong once affordable, and that purchased cash converts directly into a large income jump. The upgrade trap is still real, but this player bought Register #2 first, so capacity-before-upgrades held.

### 4. Building-first works when the cash exists

Plot expansion happened at **29:30**, before Teabag and Icecream, and the player finished at 48 plot size. So the first expansion is reachable and does not feel punishing when funded. The open question is whether a free player can afford the 3,000 before other sinks.

### 5. Level pacing is acceptable

Level 6 at 24:30, level 8 at 44:01, level 9 only 143 EXP away. This is slightly slower than Run B early, then faster late. No curve change is needed for soft launch.

### 6. No new worker problem observed

The worker moved through `idle`, `walkingToStation`, and `serving` states, and two cashiers stayed busy. The player again spent 2,500 on worker hire + walk/craft immediately, then quality at the end. That is a player-priority pattern, not a bug.

### 7. Recommended next test

One clean free-player run with a deliberate plan:

1. Register #2 at level 4.
2. Foam and Chocolate.
3. Save 3,000 for plot expansion **before** worker upgrades.
4. Then worker, then Teabag.

If that run cannot reach the first expansion comfortably, lower it to **2,000**. If it can, keep 3,000 but make NextGoal show a persistent "Save for expansion" goal.

### 8. Small data note

The inventory blip at 15:30 is the Chocolate station bought with the pack cash, not a station granted by the pack. The pack's starter items were all already owned and refunded as cash.
