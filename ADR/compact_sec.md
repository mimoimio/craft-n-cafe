## Objective
- Implement all TODOs from the six requested worker/prompt/UI files, with one plan document per source under `plans/` (later moved to `plans/pendingTodos/`).
- Continue through implementation and verification after the user approved the plan.

## Important Details
- User chose **"One file per source"** for plan docs; six docs now live in `plans/pendingTodos/`.
- Preserved the pre-existing uncommitted typo change in `CustomerPrompts.luau` (`-- warn(/"someoneElseServing?"...`).
- Tooling available: `rojo`, `wally`; no Luau/Studio/selene/stylua binaries. Syntax was checked via `npx --yes @johnnymorganz/stylua-bin --check --syntax Luau`.
- Auto-fire decision: full timing bar calls `Remotes.UseStation:InvokeServer(itemId, 1)`; `DrinksService.calculateScore` was changed to return `3` for `ratio >= 0.999`, making full bar “Perfect!”.
- Shop redesign decisions: centered/full-screen `Panel`; tabs `station`, `register`, `furniture`, `decoration`, `upgrade`, `staff`, `premium`; default `station` tab includes Station + Cashier; `register` is Cashier-only; furniture includes Furniture/Seat/Wall/Architecture; premium embeds `StorePanel`.
- BuildPanel Cancel clears selection and keeps the panel open.
- Two-worker fix: `lastAssignedAt` per worker, reserved customers during assignment, `WorkersConfig.AssistDelaySeconds = 3`, `AssignCooldownSeconds = 1`; `customersSlice.resetWorker` clears `servedBy`.
- Runtime smoke testing in Roblox Studio has not been performed.

## Work State
### Completed
- Added `src/shared/Utils/PatienceUtil.luau` with `MAX_WAITING_TIME = 30`, `getRatio`, `getColor`; updated `CustomerPrompts.luau` and `CustomersService.luau` to use it.
- `StationPrompts.luau`: extracted `handleScore`, added `submitScore`, auto-fire token/guard, perfect submission at full bar.
- `DrinksService.luau`: `calculateScore` returns `3` for `ratio >= 0.999`.
- `BuildPanel/init.luau`: added Cancel button between Paint and Rotate; LayoutOrder now Cancel 3, Rotate 4, Place 5.
- `WorkerManagementCard.luau`: rewritten with image card/button backgrounds, BuilderIcons stat icons, and `WorkerPortrait` ViewportFrame cloning `workspace.Rig` with fallback image.
- Added `WorkerWarnings.luau`; mounted in `Main.luau`; warns when an active worker needs an unplaced station that is owned in inventory.
- Worker AI/config: `WorkersConfig` named keys, `WorkerEntity.lastAssignedAt`, `workersSlice` assignment timestamp, `WorkersService.Tick` reserved-customer/multi-assignment rewrite, `customersSlice.resetWorker`.
- Removed stale TODO/critical-bug comments and unused `Debris` from `CafeRenderingService/Workers.luau`.
- ShopPanel refactor completed:
  - New: `ShopTabConfig.luau`, `DetailsOverlay.luau`, `ItemTab.luau`, `UpgradeTab.luau`, `StaffTab.luau`, `PremiumTab.luau`.
  - Rewrote `ShopTabs.luau` for 7 wrapped tabs with level locking.
  - Rewrote `ShopPanel/init.luau` for centered/full-screen layout, extracted tabs, details overlay, category filtering, flex content.
  - `StorePanel.luau` now accepts `{ Embedded: boolean? }?` and returns content without its own `Panel` when embedded.
- Verification: `stylua --check --syntax Luau` produced no parse errors; `rojo build default.project.json` succeeded.

### Active
- `git diff --check` reports trailing-whitespace warnings on newly added lines, e.g.:
  - `src/server/Services/CustomersService.luau:12,17`
  - `src/server/Services/DrinksService.luau:92-95`
  - `src/server/Services/WorkersService.luau:132-133`
  - Likely CRLF line-ending related; output was truncated.
- `plans/pendingTodos/*.md` still have unchecked `- [ ]` boxes.
- Runtime verification pending for: premium embedded `StorePanel`, `Enum.UIFlexMode.Fill` usage, worker portrait `workspace.Rig`, two-worker flow, station auto-fire.

### Blocked
- No Luau runtime / Roblox Studio available for behavioral tests.
- `git diff --check` whitespace warnings remain unresolved.
- Potential API risk: `Enum.UIFlexMode.Fill` used in `ShopPanel/init.luau`; verify in Studio.
- `WorkerPortrait` assumes `workspace.Rig` is replicated to clients; fallback image exists if absent.

## Next Move
1. Resolve `git diff --check` trailing-whitespace warnings in modified Luau files, likely by normalizing new lines to the repo’s expected line endings / stripping trailing spaces.
2. Mark `plans/pendingTodos/*.md` tasks `[x]`, then perform a Studio smoke test of ShopPanel tabs/premium, worker warnings, two-worker assignment, and station auto-fire.

## Relevant Files
- `plans/pendingTodos/Workers.md`
- `plans/pendingTodos/CustomerPrompts.md`
- `plans/pendingTodos/StationPrompts.md`
- `plans/pendingTodos/BuildPanel.md`
- `plans/pendingTodos/ShopPanel.md`
- `plans/pendingTodos/WorkerManagementCard.md`
- `src/shared/Utils/PatienceUtil.luau`: shared patience source of truth.
- `src/shared/ReactComponents/CustomerPrompts.luau`: uses `PatienceUtil`.
- `src/server/Services/CustomersService.luau`: uses `PatienceUtil.MAX_WAITING_TIME`.
- `src/shared/ReactComponents/StationPrompts.luau`: auto-fire logic.
- `src/server/Services/DrinksService.luau`: score 3 at full bar.
- `src/shared/ReactComponents/BuildPanel/init.luau`: Cancel toolbar button.
- `src/shared/ReactComponents/ShopPanel/WorkerManagementCard.luau`: image cards/icons/portrait.
- `src/shared/ReactComponents/WorkerWarnings.luau`: client missing-station toasts.
- `src/shared/ReactComponents/Main.luau`: mounts `WorkerWarnings`.
- `src/shared/Configs/WorkersConfig.luau`: assist/cooldown config.
- `src/shared/Types.luau`: `WorkerEntity.lastAssignedAt`.
- `src/shared/producers/GlobalState/workersSlice.luau`: assignment timestamps.
- `src/shared/producers/GlobalState/customersSlice.luau`: `resetWorker` clears `servedBy`.
- `src/server/Services/WorkersService.luau`: two-worker Tick rewrite.
- `src/server/Services/CafeRenderingService/Workers.luau`: stale comments removed.
- `src/shared/ReactComponents/ShopPanel/init.luau`: shop orchestrator/centered layout.
- `src/shared/ReactComponents/ShopPanel/ShopTabs.luau`: 7-tab UI.
- `src/shared/ReactComponents/ShopPanel/ShopTabConfig.luau`: tab/category mapping.
- `src/shared/ReactComponents/ShopPanel/DetailsOverlay.luau`: item detail modal.
- `src/shared/ReactComponents/ShopPanel/ItemTab.luau`: item grid.
- `src/shared/ReactComponents/ShopPanel/UpgradeTab.luau`: upgrades.
- `src/shared/ReactComponents/ShopPanel/StaffTab.luau`: hiring/worker cards.
- `src/shared/ReactComponents/ShopPanel/PremiumTab.luau`: embedded store.
- `src/shared/ReactComponents/StorePanel.luau`: added `Embedded` mode.