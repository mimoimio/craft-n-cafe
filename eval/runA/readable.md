# Run A — Capacity-First, No Passes

Source: `eval/runA/runA.csv`  
Cleaned CSV: `eval/runA/runA.clean.csv`  
Duration: **23:31**  
Account: `5470482596`  
Variant: **no-pass**  
Cash pack purchased: **Pocket Change — 2,000 cash** at 07:00

> The original CSV did not have cash-purchase columns yet. The 07:00 cash jump was Pocket Change (`+2,000`) followed by Register #2 (`-1,000`). The logger now records this explicitly.

---

## At a glance

| Metric | Start | End | Peak |
|---|---:|---:|---:|
| Level | 1 | **6** | 6 |
| EXP | 0 | 281 | 281 |
| Cash | 300 | **263** | **2,004** at 21:00 |
| Lifetime earned | 0 | **1,083** | — |
| Cash purchased | 0 | **2,000** | — |
| Customers served | 0 | **112** | — |
| Cashiers placed | 1 | **2** | 2 |
| Stations placed | 5 | **7** | 7 |
| Ingredient progress | 3 / 12 | **5 / 12** | 5 |
| Plot size | 32 | **32** | 32 |
| Workers | 0 | **1** | 1 |
| Upgrades | none | **none** | — |

### Rates

| Metric | Value |
|---|---:|
| Earned cash | **46.1 / min** |
| Customers served | **4.76 / min** |
| EXP | **11.95 / min** |
| Cash per customer | **9.67** |
| EXP per customer | **2.51** |
| Total spent | **3,120** |

Total spent = starting cash `300` + earned `1,083` + purchased `2,000` - ending cash `263`.

---

## Timeline

| Time | Level | Cash | Lifetime | Customers | Cashiers | Stations | Ingredient index | Workers | Key event |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|
| 00:00 | 1 | 300 | 0 | 0 | 1 | 5 | 3 | 0 | Start |
| 01:00 | 2 | 328 | 28 | 5 | 1 | 5 | 3 | 0 | First customer loop |
| 02:15 | 3 | 260 | 60 | 14 | 1 | 5 | 4 | 0 | Ice station bought |
| 05:30 | 4 | 400 | 200 | 32 | 1 | 6 | 4 | 0 | Ice station placed |
| 07:00 | 4 | 1,411 | 211 | 34 | 1 | 6 | 4 | 0 | Pocket Change +2,000; Register #2 -1,000 |
| 07:30 | 4 | 1,431 | 231 | 36 | 2 | 6 | 4 | 0 | Register #2 placed |
| 08:00 | 4 | 1,325 | 245 | 37 | 2 | 7 | 5 | 0 | Foam station bought/placed |
| 12:30 | 5 | 1,572 | 492 | 59 | 2 | 7 | 5 | 0 | — |
| 21:00 | 5 | 2,004 | 924 | 94 | 2 | 7 | 5 | 0 | Peak cash |
| 21:30 | 6 | 129 | 949 | 96 | 2 | 7 | 5 | 1 | Worker hired + walk/craft upgrades |
| 23:30 | 6 | 263 | 1,083 | 112 | 2 | 7 | 5 | 1 | End |

---

## Level milestones

| Level | Reached at |
|---:|---:|
| 2 | 00:45 |
| 3 | 02:15 |
| 4 | 05:30 |
| 5 | 12:30 |
| 6 | 21:30 |

Current EXP is **281**. Level 7 needs **360 EXP**, so the player is **79 EXP away**.

Capacity-first made leveling much faster:

| Metric | Session 1 | Run A |
|---|---:|---:|
| Level 6 reached | 37:00 | **21:30** |
| Customers/min | 3.0 | **4.76** |
| EXP/min | 6.55 | **11.95** |

---

## Ingredient / station milestones

IngredientsConfig order:

`espresso → water → milk → ice → foam → chocolate → teabag → icecream → matcha → lemon → boba → carbonator`

| Ingredient index | Reached at | Notes |
|---:|---:|---|
| 4 (ice) | 02:15 | Ice bought; placed at 05:30 |
| 5 (foam) | 08:00 | Foam bought/placed together |
| 6 (chocolate) | never | Costs 100; never purchased |

The player finished with **5/12 ingredient stations**. Chocolate was cheap and available at level 5, but the run never prompted it strongly enough.

---

## Major purchases

| Time | Purchase | Cost |
|---:|---|---:|
| 02:15 | Ice station | 100 |
| 07:00 | Pocket Change cash pack | **+2,000 cash** |
| 07:00 | Register #2 | 1,000 |
| 08:00 | Foam station | 120 |
| 21:30 | Worker #1 | 1,000 |
| 21:30 | Worker walk upgrade → 2 | 500 |
| 21:30 | Worker craft upgrade → 2 | 400 |
| — | Chocolate station | **not bought** |
| — | Ingredient/global upgrades | **none** |
| — | Plot expansion | **none** |

### Spending split

| Category | Spend | Share |
|---|---:|---:|
| Register #2 | 1,000 | **32%** |
| Worker hire + upgrades | 1,900 | **61%** |
| Stations | 220 | **7%** |
| Upgrades | 0 | **0%** |
| Plot expansion | 0 | **0%** |

---

## My thoughts

### 1. Capacity-first works for level speed

This is the clearest result of the run. Level 6 arrived at **21:30** instead of **37:00**, customers/min rose from **3.0 to 4.76**, and EXP/min rose from **6.55 to 11.95**.

Register #2 + tutorial + reduced level gate did what they were supposed to do: the player bought capacity almost immediately after level 4.

### 2. But capacity alone starves cash

Cash per customer dropped from **71.9** in Session 1 to **9.67** here. That is expected because this run had:

- no 2x Cash
- no ingredient upgrades
- no Brand Prestige
- no Chocolate station
- only 5/12 ingredient stations

The player reached level 6 quickly but ended with only **263 cash**, nowhere near Teabag or plot expansion. The next test should be a **hybrid**: capacity first, then a little value.

### 3. The Register tutorial created a real cash-pack purchase moment

At level 4 the player had **400 cash**. Register #2 cost **1,000**. Within 90 seconds they bought Pocket Change for 2,000 cash, bought Register #2, and placed it at 07:30.

That is strong evidence that the tutorial and the Register cost wall work as a monetization funnel. But it is also a warning: a core capacity upgrade is currently soft-gated behind a Robux purchase for a free player.

If you want player-first progression, lower Register #2 to **300–400**. Free players can then buy it at level 4, and cash packs become optional acceleration instead of the expected path. If you intentionally want the $49 conversion moment, keep 1,000 and accept that the tutorial is nudging players toward the Store.

### 4. The player skipped Chocolate despite it costing only 100

They stopped at ingredient index 5 and never bought Chocolate. That kept cash per customer very low.

The current NextGoal HUD does not prompt the next station. After Register #2, it moved toward level 6 / worker / expansion. Add a station step after Register:

```text
Next: Buy Chocolate Station ($100)
```

or a generic “Next unowned station” goal. This should improve cash/customer without adding another tutorial.

### 5. Worker was hired at the end and upgraded immediately

Worker #1 arrived at **21:30** and immediately went to `2/2/1` for another 900 cash. That consumed most of the remaining money while leaving only ~2 minutes to benefit.

This is not necessarily bad, but Worker #1 at 1,000 plus 900 of upgrades is a large late-session sink. Consider:

- Worker #1 at 750–1,000
- Maybe make worker stat upgrades a little less tempting immediately after hire
- Or show worker value/expected benefit

### 6. Teabag and plot expansion are still unreached

This is expected in a no-upgrade run. Do not judge those walls from Run A alone. Run the hybrid first; if Teabag and plot expansion are still unreachable with Register #2 + Chocolate + one or two cheap upgrades, then lower them further.

### 7. No passes confirmed

`has_double_cash=false` and `has_premium_paint=false` for the whole run. The Studio override worked correctly.

### 8. Logger improvement is working

The new logger columns exposed the cash-pack event through `spend_delta`, `cash_purchased_total`, and `cash_purchases`. Future runs will show Pocket Change directly instead of a confusing `-1,000` spend delta.

---

## Recommended next play

**Run B — hybrid, no passes, no cash pack if possible**

1. Buy Register #2 at level 4.
2. Buy Chocolate station at level 5.
3. Buy one or two cheap value upgrades.
4. Hire Worker #1 at level 6.
5. Avoid worker stat upgrades until the worker actually has time to pay back.
6. Try plot expansion only after the above.

The goal is to see whether capacity + a little value can reach Teabag/plot affordability without needing a cash pack.

If Run B still requires a cash pack to afford Register #2 or Worker #1, lower those two costs. If Run B reaches Teabag/plot comfortably without a pack, the current costs are closer to right.
