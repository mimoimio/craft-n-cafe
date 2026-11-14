## Objective
- Tune and ship monetisation + progression for Roblox game “Craft n’ Cafe” during crunch time.
- Use CSV playtest logs to evaluate pacing, capacity/value investment, and monetisation moments, then iterate.

## Important Details
- User wants **player-first, non-gacha monetisation**: 2x Cash gamepass, cash packs, Premium Paint, starter pack; no second currency.
- Confirmed decisions: targeted cost pass; Register #2 at **300 / level 4**; Register-only tutorial; workers wait **6s** before auto-taking orders; NextGoal HUD included.
- Current repo has user refactors: edit `src/shared/ReactComponents/BuildPanel/init.luau` and `src/shared/ReactComponents/ShopPanel/init.luau`; old `BuildPanel.luau`/`ShopPanel.luau` files no longer exist.
- `IS_PLAYTESTING = RunService:IsStudio()`; Studio uses mock ProfileStore. `PlaytestConfig` defaults to **no-pass** with `OwnedPasses = { DoubleCash = false, PremiumPaint = false }`.
- `MonetizationConfig` gamepass/cash-pack IDs are filled; `StarterProduct.ProductId` remains `0`.
- Current cost tuning: Register #2 **300/level4**; Registers #3–5 **3000/7500/15000**; Worker #1 **1000**; plot expansions **3000/9000/20000**; teabag **2500**, icecream **2000**, matcha **3000**, lemon **4000**, boba **6000**, carbonator **10000**; upgrade costs unchanged.
- Logger cadence: baseline `t=0`, every **15s** for first **180s**, then every **30s**. Prints on unmount; admin-only via `Main.PlayPhase`.
- Cash-pack tracking added: `Stats.CashPurchased`, `Stats.CashPurchases`; logger columns `cash_purchased_total`, `cash_purchased_delta`, `cash_purchases`; `spend_delta` now excludes purchased cash.
- Run A conclusion: capacity-first sped leveling (level 6 at 21:30 vs 37:00) but starved cash/customer (9.67) due no upgrades/station variety. At 07:00 user bought **PocketChange +2000** and **Register #2 -1000**.
- Run B CSV is present but not yet analyzed. Raw final facts: **50:01**, level **8**, EXP **516**, cash **1267**, lifetime **4375**, customers **260**, cashiers **2**, stations **8**, ingredient index **6**, workers **1**, plot **32**, no cash purchases, no passes.
- No commit has been made.

## Work State
### Completed
- Monetisation backend: `MonetizationService`, receipt safety, gamepass syncing, cash packs, starter pack, Studio pass override.
- Store UI, Get Cash CTAs, Premium Paint gating/server validation, 2x Cash application.
- Shared `DrinkValue` util; `CustomersService` and `PlayersCup` now use it. HUD shows cash value + quality.
- Logger improvements: variant, income/spend, cash/min, EXP-to-next, cash-purchase tracking.
- `RegisterTutorial` cash-aware; `NextGoal` cash-aware and station-aware.
- Worker player-priority delay.
- Session 1 analysis: `eval/playsession1/readable.md`; Run A analysis: `eval/runA/readable.md`, `eval/runA/runA.clean.csv`.
- Verified via `luau-compile` and `rojo build`; no runtime playtest after latest build.

### Active
- Analyze `eval/runB/runB.csv` and compare against Session 1 / Run A.
- Determine whether current costs still leave walls (teabag/plot/worker) after Register #2 = 300.

### Blocked
- None.

## Next Move
1. Create `eval/runB/runB.clean.csv` and `eval/runB/readable.md` in the same format as `eval/runA/readable.md`.
2. Compare Run B vs Run A: level timing, cash/customer, station index, cashier count, worker timing, plot/teabag reachability; then propose the next tuning pass.

## Relevant Files
- `eval/runB/runB.csv`: latest playtest log to analyze.
- `eval/runA/readable.md`: format/reference for Run B summary.
- `eval/playsession1/readable.md`: baseline analysis.
- `src/shared/ReactComponents/PlaytestLogger.luau`: admin CSV logger.
- `src/shared/Utils/PlaytestSnapshot.luau`: CSV columns/row construction.
- `src/shared/Configs/PlaytestConfig.luau`: variant + Studio pass override.
- `src/shared/Configs/MonetizationConfig.luau`: product/pass IDs and cash pack amounts.
- `src/server/Services/MonetizationService.luau`: receipt grants + cash purchase recording.
- `src/shared/producers/GlobalState/statsSlice.luau`: `CashPurchased` / `CashPurchases` actions.
- `src/shared/Configs/PlaceablesConfig.luau`: Register/late-station costs.
- `src/shared/Configs/WorkersConfig.luau`: worker costs.
- `src/shared/Configs/PlotExpansionsConfig.luau`: plot costs.
- `src/shared/ReactComponents/RegisterTutorial.luau`: cash-aware register tutorial.
- `src/shared/ReactComponents/NextGoal.luau`: cash/station-aware next goal HUD.
- `src/shared/ReactComponents/PlayersCup.luau`: cup HUD value.
- `src/shared/Utils/DrinkValue.luau`: shared cash/EXP calculation.
- `src/server/Services/WorkersService.luau`: 6s worker assist delay.