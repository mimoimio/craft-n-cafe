## Recommendation

Launch with a **small, direct-purchase store**, not Quantify’s gacha/meta layer. The code has **no live monetization** — only an unused `OwnedGamePasses` field (`src/shared/Types.luau:136`). Also, `IS_PLAYTESTING = true` mocks ProfileStore (`src/server/Services/PlayerDataService.luau:19`), so **all progress and any purchases would be lost on rejoin**. Fix that before selling anything.

**Launch package I recommend**

| Product | Type | Suggested price | Grants | Role |
|---|---|---:|---|---|
| **2x Cash** | Gamepass | R$299 | Permanent 2x cash from customers | Main seller, simple and transparent |
| **Pocket Change** | Dev product | R$49 | $2,000 cash | Cheap entry purchase |
| **Cafe Fund** | Dev product | R$199 | $10,000 cash | Mid-tier |
| **Investor** | Dev product | R$699 | $50,000 cash | Whale tier |
| **Premium Paint** | Gamepass | R$99 | 8–10 exclusive paint swatches | Cosmetic, supports building |
| **Opening Day Pack** | Dev product / one-time guarded | R$199 | $3,000 + starter stations + Cashier | Optional first-purchase offer |

**Defer:** extra barista gamepass, donations, daily quests, achievements, titles, leaderboards. They are good, but not launch-critical.

**Do not copy from Quantify:** second currency, gacha/random boxes, revives, rarity pricing, or daily rewards that dwarf the core loop. Quantify’s own doc flags those as problems.

---

## What the code actually supports

| Area | Reality |
|---|---|
| Currencies | Cash only. No Qubits/Crowns. Keep it that way. |
| Content | ~98 drinks, 58 placeables, 12 ingredients/stations, 5 cashiers, 4 workers. |
| Last content unlock | Carbonator station at level 12 (`PlaceablesConfig`). |
| Level pace | Level 12 needs 1,440 EXP = ~480 perfect serves (`LevelConfig.luau:22`). |
| Average perfect payout | ~32.5 cash; range ~3–114 (`CustomersService.luau:141`). |
| Total one-time cash sink | ~134k cash: items ~13.8k, plot ~21k, upgrades ~79k, workers ~20k. |
| Real bottleneck | Cash and throughput, not level. After level 12, cash has too little to buy. |
| Monetization code | None. No `MarketplaceService`, `ProcessReceipt`, product config, or store UI. |
| Dead systems | Daily panel/slice, Recipe panel, Spawner, UpgradePanel are not wired into `GlobalState`/`Main`. Don’t build the store on top of them. |

This matters because ChatGPT assumed “30 unlockables” and a finished Daily/Index system. You actually have much more drink content, but a **short cash sink** and several dead UI paths.

---

## Implementation plan

### Phase 0 — Persistence and schema (must-do first)

Files: `PlayerDataService.luau`, `Types.luau`, `statsSlice.luau`

1. Replace `IS_PLAYTESTING = true` with a real flag:
   - Use `RunService:IsStudio()` for Studio-only mocking, or a `USE_MOCK_DATASTORE` constant that is **false** for live.
   - Test on a published test place; Studio DataStore behavior differs.
2. Add to `PROFILE_TEMPLATE` and `Types`:
   - `Stats.OwnedGamePasses = {}`
   - `Stats.PurchasedProducts = {}`
   - `Stats.LifetimeCash = 0`
   - `PurchaseHistory = {}` (receipt id → timestamp)
3. In `statsSlice.startPlayerSession`, default-clone those fields.
4. Update `serveCustomer` to increment `LifetimeCash` (earned cash only, not purchased cash).
5. Fix `SyncLeaderboards`: `profile.Data.CupsServed` does not exist; use `profile.Data.Stats.CustomersServed`.
6. Prune `PurchaseHistory` to the last 100 receipts.

### Phase 1 — Server monetization service

New files:
- `src/shared/Configs/MonetizationConfig.luau`
- `src/server/Services/MonetizationService.luau`

Config should contain:
- Gamepass IDs and keys: `DoubleCash`, `PremiumPaint`.
- Cash products: `ProductId`, cash amount, display name, icon, enabled.
- Optional starter product: cash, item list, one-time.
- `Enabled = false` by default until dashboard IDs are filled.

Server responsibilities:
- On profile creation, query `MarketplaceService:UserOwnsGamePassAsync` for each pass and write `Stats.OwnedGamePasses`.
- On `PromptGamePassPurchaseFinished` (server), re-check ownership, update state/profile, and save.
- Set `MarketplaceService.ProcessReceipt` once.
- Receipt flow:
  1. Find player and profile; if missing, return `NotProcessedYet`.
  2. If `PurchaseHistory[PurchaseId]` exists, return `PurchaseGranted` (idempotent).
  3. Validate product ID against config.
  4. Grant cash/items/pass entitlement server-side.
  5. Record receipt + `PurchasedProducts`.
  6. `profile:Save()`; return `PurchaseGranted` only on success, otherwise `NotProcessedYet`.
- Add `grantCash` and `setGamePassOwnership` actions to `statsSlice`; use `buyItem` with `totalCost = 0` for item grants.
- Never trust client-provided amounts or product IDs.
- Log enabled/disabled products on startup; skip IDs equal to `0`.

For **2x Cash**, apply in `CustomersService.ServeCustomer`:
```
cashReward *= MonetizationConfig.GetCashMultiplier(playersStats.OwnedGamePasses)
```
Apply after the existing score/ingredient calculation, before `serveCustomer` dispatch. Worker-served customers use the same path, so it applies there too. Do **not** apply to cash-pack grants.

### Phase 2 — Store UI and conversion points

New file: `src/shared/ReactComponents/StorePanel.luau`

- Modal/panel with tabs: **Cash**, **Perks**, **Style**.
- Reuse existing `SmallButton`, `SmallText`, `VStack`, `HStack`, `DefaultScrollFrame`, `Toasts`, breakpoints.
- Cards show name, cash amount, price, `Owned` / `Active` / `Buy`.
- Use `MarketplaceService:GetProductInfo` for price display (pcall; fallback to “Buy”).
- Clicking a cash pack calls `MarketplaceService:PromptProductPurchase`; gamepass calls `PromptGamePassPurchase`.
- Subscribe to `Stats.OwnedGamePasses` and `Stats.Cash`.

Wire-up:
- Add `UIState.toggle("store")` support; no schema change needed.
- Add a **Store** button in `Sidebar.luau` (cash icon; red dot until viewed).
- Render `StorePanel` in `Main.PlayPhase` (`Main.luau:184`).
- In `ShopPanel.luau:637`, when `not canAfford`, add a **Get Cash** button that opens the store. This is the highest-converting moment.
- Optional: add a small `+` button to `CashHud` that opens the store.
- Unlock the store after tutorial/first serve, not at join.

### Phase 3 — Progression tuning (config-first)

Do this in the same update as 2x Cash, otherwise the pass makes an already-short progression shorter.

Current meaningful one-time sink is ~134k. Suggested targets:

| Sink | Current | Proposed |
|---|---|---|
| Cashiers | 250/300/400/500/600 at levels 1/4/4/5/6 | 1k/5k/15k/40k/100k at levels 3/6/9/12/16 |
| Workers | 500/600/700/800 at levels 5/6/7/9 | 2.5k/10k/30k/80k at levels 6/9/12/16 |
| Worker stat upgrades | ~4.35k per worker | ~3x current |
| Plot expansions | 3k/6k/12k at levels 5/8/10 | 10k/40k/120k at levels 6/10/14 |
| Café Fame (new) | — | 10 levels, unlock 12, cost ~5k × 1.35^(n−1), +2% tips per level |
| Late station prices | 1k each | icecream 8k, matcha 12k, lemon 20k, boba 35k, carbonator 60k |

Add a small reward for combining ingredients:
- XP currently only uses `cup.status` (`CustomersService.luau:145`). Change to:
  `expGain = cup.status * (1 + 0.1 * (#ingredients - 1))`.
- Optional cash complexity bonus:
  `cashReward *= 1 + 0.1 * (#ingredients - 1)` capped at 1.5x.
- This makes multi-ingredient drinks feel worthwhile without overhauling recipes.

Fix the existing `generic_price` mismatch:
- Comment says +15%, description/code says +50% per level (`UpgradesConfig.luau:21–37`).
- Recommend **+15% per level** and adjust cost; otherwise level 10 gives 6x drink value.

Add **Café Fame** to `UpgradesConfig` so it automatically appears in the existing Shop upgrade tab. It is a repeatable cash sink that gives cash packs and 2x Cash something meaningful to buy after level 12.

Do **not** increase XP curve yet. The level gate is not the bottleneck; cash is. Revisit after playtests.

### Phase 4 — Optional high-value additions after launch

1. **Café Rating / decor bonus**
   - Distinct decoration/furniture/seat items give a small tip bonus, e.g. +0.5% per unique item, cap +20%.
   - Makes building matter, matches the game’s differentiator, and creates a soft decor cash sink.
   - Implement from `plotState` in `CustomersService`; no new assets.
2. **Daily login/quests**
   - Rewrite `DailyConfig` to grant cash/XP, not ingredients — ingredients are no longer consumed in the current station crafting.
   - Add the Daily slice back to `GlobalState`, add `DailyService`, render the existing DailyPanel, add a Sidebar button.
   - 3 rotating quests using existing counters (`CustomersServed`, `LifetimeCash`, workers). Keep rewards small (e.g. 500–2,000 cash), not 50x core income.
3. **Achievements/titles**
   - Use `CustomersServed`, `LifetimeCash`, level, workers, plot size.
   - Start with HUD badges; add chat tags later.
4. **Leaderboards**
   - Fix the existing OrderedDataStore sync and add Customers Served / Lifetime Cash boards.

---

## What to take from ChatGPT / Quantify

**Take:**
- Session loop: serve → earn → upgrade → build → serve again.
- Milestone/long-term goals built from existing systems.
- Daily quests later, but modest rewards.
- Keep building/creativity central; don’t make progression only about earning cash faster.

**Reject for now:**
- Second currency (Qubits/Crowns).
- Gacha, building boxes, rarity systems.
- Revives/pay-to-continue (no fail state).
- Paid permanent power that skips the core loop.
- Daily rewards that dwarf normal play.

**Correct ChatGPT’s incomplete view:** you have ~98 drinks, ~58 placeables, 12 stations, 5 cashiers, 4 workers, and a level-12 content cap — not “30 unlockables.” The real issues are the short cash sink, dead Daily/Index panels, and missing persistence/monetization.

---

## Pre-publish test checklist

- [ ] `IS_PLAYTESTING` is off in the published place; profile saves and loads across rejoin.
- [ ] Old profile loads; `Reconcile` adds new fields without wiping data.
- [ ] Buy each cash pack: correct amount, exactly once; rejoin persists.
- [ ] Duplicate/retried receipt does not double-grant.
- [ ] Unknown product ID cannot grant cash.
- [ ] Buy 2x Cash: ownership appears, multiplier applies to player-served and worker-served customers, persists on rejoin.
- [ ] Buy Premium Paint: swatches appear; server rejects non-owned premium swatches.
- [ ] Store panel works on mobile/gamepad; prices load or degrade gracefully.
- [ ] “Get Cash” appears when the player cannot afford shop/worker/plot upgrades.
- [ ] Cash packs do not count toward `LifetimeCash`.
- [ ] `ProcessReceipt` returns `NotProcessedYet` if profile/save is unavailable.
- [ ] No console errors from old CashHud/Shelves/DiscoveredDrinks selectors.
- [ ] Tutorial → first serve → first purchase path is smooth.

---

## Decisions needed

1. **Monetization posture:** Is 2x Cash + cash packs + cosmetic paint acceptable, or do you want cosmetics-only? My recommendation is the former, with no gacha and no recipe/station paywalls.
2. **Progression pace:** Do you want the moderate rebalance above (roughly 2–3x longer to max), or keep the current fast pace and only add monetization? I recommend rebalancing slightly, otherwise 2x Cash and a $50k pack will exhaust progression quickly.
3. **Launch scope:** Minimal launch (2x Cash + 3 cash packs + Store + persistence fix) or recommended launch (+ Premium Paint + starter pack + balance pass)? I recommend the recommended launch if you have 2–3 dev days.
4. **Product IDs:** Do you already have Roblox gamepass/developer-product IDs, or should the code ship with placeholders until you create them?