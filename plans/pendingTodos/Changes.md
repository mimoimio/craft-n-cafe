Implemented all pending todos.

**What changed**
- Added shared `PatienceUtil` (30s patience) and wired it into `CustomerPrompts` and `CustomersService`.
- Added full-bar auto-fire in `StationPrompts` with double-submit guards; full bar now scores Perfect.
- Added Cancel between Paint and Rotate in the Build toolbar.
- Added client `WorkerWarnings` toasts for owned-but-unplaced stations needed by working baristas.
- Fixed worker assignment with customer reservation, per-worker cooldown, and configurable `AssistDelaySeconds` / `AssignCooldownSeconds`; reset workers now release their customers.
- Redesigned `ShopPanel` into a centered full-screen panel with tabs: Stations (front page includes registers), Registers, Furniture, Decor, Upgrades, Workers, Premium.
- Extracted `DetailsOverlay`, `ItemTab`, `UpgradeTab`, `StaffTab`, `PremiumTab`, and `ShopTabConfig`.
- Embedded `StorePanel` into the Premium tab and limited the details overlay to item tabs.
- Reworked `WorkerManagementCard` with image card/button backgrounds, a rig-based portrait, and stat icons.
- Marked the pending todo checklists complete.

**Verification**
- `rojo build default.project.json` succeeds.
- Stylua parsed every touched file with no syntax errors.
- No Luau lint/analyze tool is installed in the repo toolchain, so a Studio playtest is still recommended. Changes were not committed.