# Play Session 1 — Readable Summary

Source: `eval/playsession1.csv`  
Cleaned CSV: `eval/playsession1.clean.csv`  
Duration: **45:31**  
Account: `5470482596`  
Active gamepasses: **2x Cash**, **Premium Paint**  
Purchased products: none

---

## At a glance

| Metric | Start | End | Peak |
|---|---:|---:|---:|
| Level | 1 | **6** | 6 |
| EXP | 0 | 298 | 298 |
| Cash | 300 | **1,672** | **2,337** at 31:00 |
| Lifetime earned | 0 | **9,843** | — |
| Customers served | 0 | **137** | — |
| Cashiers placed | 1 | **1** | 1 |
| Stations placed | 5 | **8** | 8 |
| Ingredient progress | 3 / 12 | **6 / 12** | 6 |
| Plot size | 32 | **32** | 32 |
| Workers | 0 | **1** | 1 |
| Upgrades | none | Brand Prestige 2 + ingredient upgrades | — |

### Rates

| Metric | Value |
|---|---:|
| Average cash earned | **216 / min** |
| Average customers served | **3.0 / min** |
| Average EXP | **6.6 / min** |
| Cash per customer | **71.9** |
| EXP per customer | **2.18** |
| Total spent | **8,471** |

Total spent = starting cash `300` + earned `9,843` - ending cash `1,672`.

---

## Timeline

| Time | Level | Cash | Lifetime | Customers | Cashiers | Stations | Ingredient index | Workers | Key event |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|
| 00:00 | 1 | 300 | 0 | 0 | 1 | 5 | 3 | 0 | Start |
| 01:00 | 2 | 350 | 50 | 5 | 1 | 5 | 3 | 0 | First customer loop |
| 03:00 | 3 | 356 | 156 | 15 | 1 | 5 | 4 | 0 | Ice station bought |
| 05:00 | 3 | 431 | 231 | 21 | 1 | 6 | 4 | 0 | Ice station placed |
| 10:00 | 4 | 649 | 449 | 33 | 1 | 6 | 4 | 0 | — |
| 15:00 | 4 | 811 | 731 | 47 | 1 | 7 | 5 | 0 | Foam station placed |
| 20:00 | 5 | 220 | 1,912 | 60 | 1 | 7 | 5 | 0 | Many ingredient upgrades |
| 25:00 | 5 | 121 | 2,941 | 69 | 1 | 8 | 6 | 0 | Chocolate station placed |
| 30:00 | 5 | 1,715 | 5,336 | 85 | 1 | 8 | 6 | 0 | Cash recovering |
| 35:00 | 5 | 187 | 5,958 | 89 | 1 | 8 | 6 | 0 | Brand Prestige 2 |
| 38:00 | 6 | 332 | 7,603 | 101 | 1 | 8 | 6 | 1 | First worker hired |
| 45:00 | 6 | 1,502 | 9,673 | 135 | 1 | 8 | 6 | 1 | — |
| 45:31 | 6 | 1,672 | 9,843 | 137 | 1 | 8 | 6 | 1 | End |

---

## Level milestones

| Level | Reached at |
|---:|---:|
| 2 | 00:45 |
| 3 | 02:45 |
| 4 | 09:00 |
| 5 | 20:00 |
| 6 | 37:00 |

Current EXP is **298**. Level 7 needs **360 EXP**, so the player is **62 EXP away**.

At this session's average rate, **level 12 would take roughly 2+ more hours**. This session was not too fast — it was on the slow side.

---

## Ingredient / station milestones

IngredientsConfig order:

`espresso → water → milk → ice → foam → chocolate → teabag → icecream → matcha → lemon → boba → carbonator`

| Ingredient index | Reached at | Notes |
|---:|---:|---|
| 4 (ice) | 03:00 | Ice station bought; placed 03:30 |
| 5 (foam) | 11:30 | Foam bought; placed 12:00 |
| 6 (chocolate) | 20:30 | Chocolate bought; placed 21:00 |
| 7 (teabag) | never | Costs 5,000; peak cash was only 2,337 |

The player finished the 45-minute session with **6/12 ingredient stations**.

---

## Major purchases

| Time | Purchase | Approx. cost |
|---:|---|---:|
| 03:00 | Ice station | 100 |
| 11:30 | Foam station | 120 |
| 16:00 | Espresso upgrade → 4 | 786 |
| 17:30–20:00 | Water / milk / ice upgrades | ~1,200+ |
| 20:30 | Chocolate station | 100 |
| 25:00–27:30 | More ingredient upgrades | ~1,800 |
| 35:00 | Brand Prestige → 2 | 2,150 |
| 38:00 | First worker | 1,500 |
| 39:00–41:30 | Worker walk/craft upgrades | ~900 |

**No cashier upgrades and no plot expansion were purchased.**

### Spending split (approximate)

| Category | Spend | Share |
|---|---:|---:|
| Ingredient / global upgrades | ~5,750 | **68%** |
| Worker hire + upgrades | ~2,400 | **28%** |
| Stations | ~320 | **4%** |
| Cashiers | 0 | **0%** |
| Plot expansion | 0 | **0%** |

---

## My thoughts

### 1. Progression is not too fast — the risk is the opposite

Level 6 after 37 minutes and 6/12 ingredient stations after 45 minutes is a slow pace. The player never reached the 5,000-cost teabag station, never expanded the plot, and never bought a second cashier. If the goal is “not unlock everything too quickly,” this session says the pace is safe, possibly too slow for a first-session retention target.

### 2. Cashier count is the hidden bottleneck

`cashier_count` stayed at **1** for the entire 45 minutes. Customers averaged only **3.0/min**. Cashier #2 unlocks at level 5 and costs 2,000. The player reached level 5 at 20:00 and could afford Cashier #2 by 31:00, but never bought it.

That suggests cashiers are not discoverable or not perceived as the throughput lever. They sit in the **Item** catalog, while the player spent most of their time in the **Upgrade** tab. Consider:

- Adding a “Registers” or “Capacity” section to the Upgrade/Staff UI.
- Showing a warning when all cashiers are occupied and customers are waiting.
- Making the first extra cashier a more obvious milestone.

### 3. Ingredient upgrades are a cash trap

The player spent about **68% of all spending** on ingredient/global upgrades, while spending **0% on cashiers or plot expansion**. Ingredient upgrades are cheap, numerous, and give small flat bonuses. They feel productive but do not increase customer throughput.

This is not necessarily bad, but it means the upgrade tab may be steering players away from the more impactful capacity purchases. Consider:

- Showing the expected extra cash/min for each upgrade.
- Locking ingredient upgrades until the related station is placed.
- Reordering the Upgrade tab so capacity/throughput options are more prominent.

### 4. The 5,000 teabag station is a hard wall

The station curve goes from a 100-cost chocolate station to a 5,000-cost teabag station. The player's peak cash was 2,337. That is a large cliff, and it stopped ingredient progression at index 6.

If that wall is intentional, it is working. If not, consider smoothing it — for example, teabag around 2,000–2,500, or another small station step before it.

### 5. Plot expansion is effectively unreachable

The first expansion costs 6,000. Peak cash was 2,337, and ending cash was 1,672. The player never expanded. Since building is the game’s differentiator, a first expansion that never happens in a 45-minute session may be too expensive or not visible enough as a goal.

### 6. Worker hire is a good power spike, but late

The first worker was hired at **38:00** and immediately stayed busy (`walkingToStation`), with walk/craft upgrades following. The player spent 38 minutes serving manually. If automation is meant to be a fun mid-game reward, level 6 / 1.5k may be slightly late — or at least the player should see it as a goal earlier.

### 7. 2x Cash is not trivializing the game

2x Cash was active for the whole session. Even with it, the player ended at level 6 with 1,672 cash. Without 2x, cash income would be roughly half, making the teabag wall and plot expansion even further away. The monetization pass is safe on this front.

### 8. Cash rewards scale nicely with station/upgrade progress

Average cash per customer rose substantially as the player added stations and upgrades. That is a good progression feel: investment makes each customer more valuable. The limiting factor is still how few customers can be served.

### 9. Suggested next playtest

Run a **capacity-first** session:

- Buy Cashier #2 as soon as it is affordable.
- Delay ingredient upgrades.
- Compare customers/min, EXP/min, and level timing against this run.

That will show whether cashier count or upgrade spend is the real pacing lever.

### 10. Logger improvement idea

The CSV is usable, but two extra columns would make future sessions easier:

- `income_delta` — change in lifetime cash (pure earnings)
- `spend_delta` — `income_delta - cash_delta` (pure spending)

`cash_per_s` is noisy because a 15s/30s window contains purchases and customer completions. `lifetime_cash / elapsed` is the better trend line.
