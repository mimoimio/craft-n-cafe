## Short answer

**Yes, one more play is worth it — but not a blind replay.** The current run is a useful baseline. The next run should be a targeted **capacity-first** experiment after a small instrumentation pass. Otherwise you will likely repeat the same behavior.

If you want to play today, do a **15–20 minute no-upgrade, capacity-first run** after adding the gamepass override. Buy Register #2 as soon as possible, then a worker, and deliberately ignore ingredient upgrades.

---

## What to fix before the next full play

### 1. Studio gamepass override

Right now `MonetizationService.syncGamePasses` checks real ownership, so your owner account always has 2x Cash and Premium Paint even in Studio.

Add a Studio-only override in `MonetizationConfig`:

```lua
MonetizationConfig.PlaytestOwnedPasses = {
    DoubleCash = false,
    PremiumPaint = false,
}
```

When `RunService:IsStudio()` is true, `syncGamePasses` should use this table instead of `UserOwnsGamePassAsync`. Then you can test as a free player without touching your live passes.

For real-player satisfaction:
- Do **not** add a player billboard by default; it will clutter the cafe.
- Add a small persistent `2x` badge in the cash HUD or Store.
- Show a one-time “2x Cash active” toast/banner after purchase.
- Keep Store “Active/Owned” states visible.

### 2. Shared cup value calculation

`PlayersCup.luau` currently shows `cup.score`, not the actual cash value. The calculation lives in `CustomersService.luau`, so the two will drift.

Create `src/shared/Utils/DrinkValue.luau`:

```text
Calculate(cup, upgrades, ownedPasses)
  -> { Cash, EXP, BaseCash, Complexity, CashMultiplier, Quality }
```

Use it in:
- `CustomersService.ServeCustomer`
- `PlayersCup.luau`

Then the HUD can show something like:

```text
Drink in hand: Latte
$26 · Nice
```

instead of raw score. Subscribe `PlayersCup` to both `Cups` and `Stats` so upgrades and gamepasses are reflected.

### 3. Logger improvements

Add these columns:
- `income_delta` — change in lifetime cash
- `spend_delta` — `income_delta - cash_delta`
- `cash_per_min` — cumulative `lifetime_cash / elapsed_min`
- `exp_to_next_level` — next threshold minus current EXP
- `variant` — short label like `no-pass-capacity-first`

`cash_per_s` is noisy because a 15s/30s window mixes purchases and completions. `income_delta` and `spend_delta` will make runs much easier to compare.

### 4. Register visibility + targeted cost pass

Do **not** blanket-halve every cost. The data shows the player spent **68% on upgrades**, **0% on registers or plot expansion**. Halving upgrades makes that trap worse.

Recommended targeted changes:

| Thing | Current | Suggested |
|---|---:|---:|
| Register #2 | 2,000 / level 5 | **1,000 / level 4** |
| Register #3–5 | 6k / 15k / 30k | **half** |
| Worker #1 | 1,500 / level 6 | **1,000** |
| Plot expansion 2 | 6,000 / level 6 | **3,000** |
| Teabag station | 5,000 | **2,500** |
| Ice cream station | 4,000 | **2,000** |
| Matcha station | 6,000 | **3,000** |
| Lemon station | 8,000 | **4,000** |
| Boba station | 12,000 | **6,000** |
| Carbonator station | 20,000 | **10,000** |
| Ingredient upgrades | current | **keep or slightly raise** |

The goal is to remove walls around **capacity and building**, not make the upgrade trap cheaper.

### 5. Worker order-stealing

`WorkersService.Tick` assigns a worker to any queuing customer immediately. Add a short player-priority window:

```text
WORKER_ASSIST_DELAY = 6 seconds
```

Only auto-assign a worker if:
- customer is `queuing`
- `servedBy == nil`
- `now - customer.actionStartTime >= WORKER_ASSIST_DELAY`

This gives the player first chance to take the order. If the player takes it, `servedBy` becomes `"player"` and the worker skips it.

If that still feels wrong after testing, add a per-worker `autoServe` toggle later.

### 6. Next-goal HUD

Minute-to-minute progression felt stale. Add one small “Next goal” line to the HUD:

```text
Next: Register #2 at Level 4
Next: 62 EXP to Level 7
Next: Teabag station ($2,500)
```

Derive it from `LevelConfig`, `PlaceablesConfig`, `WorkersConfig`, and `PlotExpansionsConfig`. This is cheaper and more effective than changing the level curve, which already looks okay.

---

## Suggested tutorial order

Because unlocks currently are Upgrades 4 → Register 5 → Worker 6 → Expansion 6, I would adjust Register to level 4 and teach this order:

1. **Tutorial** — serve first customers (existing)
2. **ShopTutorial** — buy/place first station (existing)
3. **Paint** — optional “try painting your cafe”
4. **Register / Capacity** — buy and place Register #2
5. **Upgrades** — increase drink value after capacity
6. **Worker** — hire first barista
7. **Worker stats** — upgrade walk/craft/quality
8. **Expansion** — grow the plot
9. **Cafe Fame / daily goals** — later long-term goals

The data suggests **capacity before upgrades** is the most important teaching change. The player could afford Register #2 at 31:00 but never bought it.

Other mechanics you have not fully tutorialized:
- Paint
- Seats / dine-in
- Cafe open/closed setting
- Worker stat upgrades
- Expansion
- Cafe Fame
- Store / gamepasses
- Daily leaderboard / quests
- Recipe index/discovery, if still intended

---

## Should cashiers become automatic?

Not yet. The data says the player **could** afford Register #2 but didn’t understand its value. That is a teaching/visibility problem first.

Recommended sequence:
1. Lower Register #2 to level 4 / 1,000 and add a Register tutorial.
2. Run the next playtest.
3. If Register count still stays at 1, then consider auto-granting Register #2 to inventory at level 4 or auto-placing it.

Auto-unlocking all registers removes a meaningful cash sink and player choice, so use it only if the tutorial fails.

---

## Next playtest matrix

### Run A — capacity-first, no passes
- 15–20 minutes
- Buy Register #2 immediately at level 4
- Buy Worker #1 at level 6
- Ignore ingredient upgrades
- Goal: measure customers/min, EXP/min, and time to level 6/7

### Run B — upgrade-first, no passes
- 15–20 minutes
- Same as the current run: ingredient upgrades first
- Goal: compare against Run A

### Run C — after targeted cost changes
- 30–45 minutes
- Play naturally with the new costs and Register tutorial
- Goal: validate whether the teabag/plot walls feel reachable without unlocking everything too quickly

---

## My thoughts on your specific points

- **Gamepass confusion:** Test override first. For real players, use HUD badges and purchase feedback, not a player billboard.
- **Cup value mismatch:** Definitely fix with a shared util. This is a real consistency bug.
- **Halve all costs:** Do not halve upgrades. Halve capacity/building/station walls instead.
- **Level 6 at 45 minutes:** Fine. The problem is moment-to-moment direction, not the level curve itself.
- **Lack of motivation:** Next-goal HUD and tutorial chain first. Daily leaderboard/quests later.
- **Tutorial order:** Register → Upgrades → Worker → Expansion. Move Register to level 4.
- **Worker stealing orders:** Add a 6s player-priority delay.
- **Cashier auto-unlock:** Try cheaper + tutorial first; auto-grant only if data still shows the problem.
- **Walls:** Teabag 5k and plot 6k are the main walls. Reduce them without making upgrades cheaper.
- **Disable your passes:** Add the Studio override; no need to touch live ownership.
- **Logger:** Add income/spend/cash-per-min/EXP-to-next columns and a run variant label.

My recommendation: **do the instrumentation + Register tutorial + targeted cost pass first, then run A and B as short experiments.** One more blind baseline will not teach you much.
---
>>> just tell me if you have everything to build
---
Not fully — I need 4 decisions confirmed:

1. **Cost pass:** targeted reductions only (recommended), or blanket 50% across all configs?
2. **Register #2:** level 4 + 1,000 + tutorial (recommended), or auto-grant at level 4?
3. **Worker priority:** 6s “player first” grace delay (recommended), or per-worker auto-serve toggle?
4. **Tutorial scope:** implement only Register now, or also Upgrades/Worker/Expansion/Paint tutorials in the same pass?

Everything else is clear: gamepass test override, shared cup-value util, logger columns, next-goal HUD, and the playtest matrix are all defined.
---

>>> 1. recommended
>>> 2. recommended, and do look at example tutorials before like @src/shared/ReactComponents/ShopTutorial.luau and @src/shared/ReactComponents/Tutorial.luau 
>>> 3. recommended
>>> 4. only register.

---
1. recommended
2. recommended, and do look at example tutorials before like @src/shared/ReactComponents/ShopTutorial.luau and @src/shared/ReactComponents/Tutorial.luau 
3. recommended
4. only register.Implemented the confirmed pass.
---

- **Playtest config:** `PlaytestConfig.luau` now controls `Variant` and Studio pass overrides. Default is `no-pass`; change `OwnedPasses` if you want to test with passes.
- **Cup value:** new `DrinkValue.luau` is shared by `CustomersService` and `PlayersCup`. HUD now shows actual dollar value + quality, not raw score.
- **Logger:** now adds `variant`, `income_delta`, `spend_delta`, `cash_per_min`, and `exp_to_next_level`.
- **Costs:** Register #2 is now level 4 / 1,000; Registers #3–5 halved; Worker #1 is 1,000; plot expansions and late stations halved. Upgrade costs left unchanged.
- **Register tutorial:** added `RegisterTutorial.luau`, mounted in `Main`. It guides Shop → Buy Register #2 → Build → Place, after the ice-station tutorial.
- **Worker priority:** workers now wait 6 seconds before auto-claiming a queuing customer.
- **Next goal HUD:** added `NextGoal.luau`, showing the next level/register/worker/expansion goal.

Verified with `luau-compile` and `rojo build`. No runtime playtest was run. No commit made.