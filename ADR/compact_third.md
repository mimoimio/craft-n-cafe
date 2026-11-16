## Objective
- Finish Roblox game "Craft n' Cafe" for a **soft launch this week**, using a launch-readiness pass rather than new features.
- Analyze Run D playtest data and user's in-play notes (`eval/runC/adds.md`) to drive final tuning/fixes.

## Important Details
- User chose direction: **Launch readiness (Recommended)**; launch target: **Soft launch this week**.
- User explicitly requested: for Run D, **do not create `.clean.csv`**, only `readable.md`.
- Run C is **not a clean free-player run**: Opening Day Pack bought at 15:30 for **8,590 cash** (8,000 + 590 duplicate-item refund), funding 41% of spend.
- Run D is the **first long clean free-player run**: 107:03, no purchases, no passes.
- Prior assistant recommendations (not yet confirmed/applied): lower starter pack cash 8,000 → 3,000–5,000; lower first plot expansion 3,000 → 2,000; make NextGoal prioritize station/expansion before worker.
- Dead systems found: Daily (panels unmounted, `dailySlice` unregistered, no `ClaimDaily` server handler, config rewards unused ingredients); RecipePanel/Index (Sidebar `Sidebar.luau:126` toggles `"recipe"`, panel not mounted); leaderboard (`SyncLeaderboards` in `PlayerDataService.luau:27` never called, no UI); standalone StorePanel still mounted in `Main.luau` (user wants removed, shop-only).
- Seating is cosmetic: cash/EXP granted at serve (`CustomersService.luau:142`); counter frees immediately; seats only add 50s sit animation. Edge case: seat deleted mid-dine leaves customer at entrance for remaining timer (`CustomersService.luau:467`).
- Codebase checks: Rojo build succeeds; no Luau/Studio/selene/stylua binaries beyond `npx --yes @johnnymorganz/stylua-bin --check --syntax Luau`; session-2 changes never runtime-tested; whole tree uncommitted.
- `IS_PLAYTESTING = RunService:IsStudio()`; published uses real ProfileStore. `PlaytestConfig` no-pass override only active in Studio.

### Run D key stats (from `eval/runD/runD.csv`, 222 lines)
- Duration **107:03**; level **13**; **671** customers; lifetime **32,052**; end cash **3,922**; peak cash **4,984** at 95.54 min.
- Rates: **299.4 cash/min**, **6.27 customers/min**, **14.21 EXP/min**, **47.77 cash/customer**, **2.27 EXP/customer**.
- Total spent **28,430** (no purchased cash).
- Level milestones: L2 0:45, L3 2:30, L4 6:31, L5 11:01, L6 17:31, L7 32:31, L8 48:01, L9 58:31, L10 72:31, L11 84:31, L12 94:02, L13 104:02.
- Level 14 needs 1,690 EXP (`level^2*10`); ended 246 away.
- Only **8/12 stations** (index 6, stopped after chocolate); never bought teabag/icecream.
- Bought Register #2 at 6:30 (300); station purchases only ice 100 + foam 120 + chocolate 100 = **320** total.
- First worker 28.5 min (1,000); second worker 96 min (5,000); plot 48 at 59.5 min (3,000).
- Spending split: **workers 16,000 (56%)**, **ingredient upgrades 8,810 (31%)**, **plot 3,000 (11%)**, stations 320 (1.1%), register 300 (1.1%).
- Bought **teabag and icecream upgrades without owning the stations** (confirms adds.md #12).
- Second worker raised throughput: 568 customers at 96 min → 671 at 107 min (~9.36/min vs 6.27 avg).
- Extra stations add almost nothing: Run C 49.23 cash/customer with 10 stations vs Run D 47.77 with 8.

### User's `eval/runC/adds.md` note list
1. Registers do almost nothing (player serves one at a time; first worker at level 6/1,000); suggests longer wait between customers; "not really a bad thing."
2. Non-station placeables nearly all unlocked by level 5; pace each category (at level 7 only half unlocked) and raise later prices.
3. Add red dots to ShopTabs + ItemTab; abstract category querying; clear dots on gamepad `GuiService.SelectedObject` change; add Previous/Next buttons in `DetailsOverlay.luau`; stop fetching product info every StorePanel mount (client config cache).
4. Teabag is a big jump (2,500) with no merit; upgraded espresso is better; more stations add cognitive challenge only; teabag same price as chocolate in `IngredientsConfig.luau`.
5. Add expansion tutorial when money > 3,000; remove if cash drops below.
6. Worker tab station-speed button shows $400 with 407 cash but stays black; buying deducts 438; later back to 400; $400 blackened button unresolved.
7. Insufficient-cash purchase buttons should open Shop Premium tab instead of StorePanel; unmount StorePanel and traces, make store only accessible in shop.
8. Upgrades feel okay (incremental grind).
9. Add placeholder images beside upgrade names.
10. Index was in sidebar but removed; maybe add RecipePanel + discovered-drinks slice.
11. Workers become faster/more efficient than player (full delegation); do not nerf yet.
12. Can upgrade teabag even without buying it.

## Work State
### Completed
- Created `eval/runC/runC.clean.csv` (copy of `runC.csv`) and `eval/runC/readable.md` (full Run C analysis: 44:01, level 8, 8,590 starter pack, 41% of spend, upgrade dump power spike, comparisons).
- Read full `eval/runD/runD.csv` (222 lines) and computed all Run D stats, level milestones, spend events, station/plot/worker changes.
- Read `eval/runC/adds.md`.
- Investigated worker stat button bug: `WorkerManagementCard.luau` uses `props.playerCash >= nextEntry.Cost`; `StaffTab.luau` passes `playerStats`; `ShopPanel/init.luau:189-191` subscribes `GlobalState` stats to `setPlayerStats`; server `WorkersService.UpgradeWorker` at line 45 validates cost from same config. Root cause not found; suspected stale prop or double-click race.
- Prior codebase audit completed (dead systems, seating, monetization, config values, progression).

### Active
- Writing `eval/runD/readable.md` (NOT yet created). Planned structure: title "Run D — Clean Free Player, Worker/Upgrade Build"; source/duration/account/variant/no purchases; at-a-glance table; rates; timeline; level milestones; ingredient/station milestones; major purchases + spending split; A/B/C/D comparison; "My thoughts" integrating adds.md.
- Formulating consolidated findings from adds.md mapped to pre-launch vs post-launch.

### Blocked
- Worker stat button bug (#6) needs Studio repro; no definitive cause.
- No confirmation on starter-pack cash reduction, plot expansion cost, or which adds.md fixes to implement.
- No commits made; current agent + visual work uncommitted.

## Next Move
1. Create `eval/runD/readable.md` only (no clean CSV) using the computed Run D stats and incorporating adds.md findings.
2. Summarize adds.md action items and recommend pre-launch fixes: gate ingredient upgrades on owned stations + server validation (#12, highest value), investigate/fix worker stat button (#6), route insufficient-funds CTAs to Shop Premium and unmount standalone StorePanel (#7), optional expansion prompt (#5); ask which to implement.

## Relevant Files
- `eval/runD/runD.csv`: Run D source data (222 lines, 107:03 clean free-player run).
- `eval/runD/readable.md`: **to create**.
- `eval/runC/adds.md`: user's 12 in-play notes.
- `eval/runC/readable.md`: completed Run C analysis (format template).
- `eval/runC/runC.clean.csv`: completed copy.
- `eval/runA/`, `eval/runB/`: prior readability format/comparison baselines.
- `ADR/compact_first.md`, `ADR/compact_sec.md`: session compacts (monetization/progression; worker/UI TODO implementation).
- `plans/pendingTodos/`: 7 completed plan docs (all checkboxes `[x]`).
- `src/shared/ReactComponents/ShopPanel/WorkerManagementCard.luau`: worker stat buttons; bug #6.
- `src/shared/ReactComponents/ShopPanel/StaffTab.luau`: passes `playerStats`/`playerCash`.
- `src/shared/ReactComponents/ShopPanel/init.luau:189-191`: stats subscription.
- `src/server/Services/WorkersService.luau:45`: `UpgradeWorker` server validation.
- `src/shared/Configs/WorkersConfig.luau`: worker/stat costs.
- `src/server/Services/CustomersService.luau`: spawn/serve/seating; `:142` reward on serve, `:467` dining tick.
- `src/shared/Configs/PlaceablesConfig.luau`: unlock levels (most non-stations level 4); needs pacing per adds #2.
- `src/shared/Configs/PlotExpansionsConfig.luau`: first expansion 3,000/level 6.
- `src/shared/Configs/MonetizationConfig.luau`: Opening Day Pack config.
- `src/shared/ReactComponents/Sidebar.luau:126`: dead Index button.
- `src/shared/producers/GlobalState/init.luau`: daily slice not registered.
- `src/server/Services/PlayerDataService.luau:27`: dead `SyncLeaderboards`.
- `src/shared/ReactComponents/Main.luau`: standalone StorePanel mount to remove per adds #7.
- `src/shared/ReactComponents/StorePanel.luau`, `PremiumTab.luau`, `ShopPanel/DetailsOverlay.luau`: store/tab routing and prev/next changes.
- `src/shared/Configs/PlaytestConfig.luau`: no-pass Studio override (current `Variant = "no-pass"`).
- `src/shared/ReactComponents/NextGoal.luau`: expansion/station goal ordering.