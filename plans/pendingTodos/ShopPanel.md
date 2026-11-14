# ShopPanel TODO Plan

Source: `src/shared/ReactComponents/ShopPanel/init.luau`

## Existing TODOs

> think and redesign in ShopPanel to only show important stuff like
> registers and stations at the front page and the others at other tabs.
> Instead of the frame on the right side, make it center and full screen.
>
> now there are tabs for:
> 1. Stations
> 2. Registers
> 3. Furnitures
> 4. Decorations
> 5. Upgrades ?
> 6. Workers ?
> 7. Premium shop. Has smaller tabs for the new redesigned StorePanel
>
> Split down the stuffs currently in this component into multiple components and files.
> Like the upgrade, the staffs

Additional TODOs:

> make overlay hidden when is in other tabs than item (lines 407-409)
>
> i think detailsOverlay can be another separate component (lines 410-412)

## Phase A - Extract components

- [x] Create `src/shared/ReactComponents/ShopPanel/DetailsOverlay.luau`.
  - Move the selected-item details overlay and buy/close controls into it.
- [x] Create `src/shared/ReactComponents/ShopPanel/UpgradeTab.luau`.
  - Move plot expansion and the `UpgradesConfig` loop into it.
- [x] Create `src/shared/ReactComponents/ShopPanel/StaffTab.luau`.
  - Move the hire button, max staff state, and `WorkerManagementCard` loop into it.
- [x] Create `src/shared/ReactComponents/ShopPanel/ItemTab.luau`.
  - Move the category row and placeable item grid into it.
- [x] Optionally create `src/shared/ReactComponents/ShopPanel/PremiumTab.luau`.
  - Wrap the redesigned `StorePanel` with its own sub-tabs.
- [x] Keep `ShopPanel/init.luau` as the layout and state orchestrator.

## Phase B - Redesign layout and tabs

- [x] Change the right-side slide-in frame to a centered, full-screen layout.
- [x] Define canonical tabs: Stations, Registers, Furniture, Decorations, Upgrades, Workers, Premium.
- [x] Show Registers and Stations on the default/front page.
- [x] Move other placeables into their respective tabs.
- [x] Extend `ShopTabs.luau` with the new tabs and level locks.
- [x] Map each `PlaceablesModule` category to the correct tab.
- [x] Keep mobile breakpoints usable in the new full-screen layout.

## Phase C - Details overlay behavior

- [x] Render `DetailsOverlay` only when the current tab is the item tab and an item is selected.
- [x] Clear `selectedItem` when switching away from the item tab.
- [x] Ensure the overlay no longer covers upgrade, staff, or premium tabs.

## Phase D - Premium shop

- [x] Embed the redesigned `StorePanel` inside the Premium tab.
- [x] Add smaller sub-tabs for the premium sections.
- [x] Verify purchase flows still work from the embedded store.

## Phase E - Cleanup and verification

- [x] Remove unused imports from `ShopPanel/init.luau` (for example `Mionum`, unused `Toasts`).
- [x] Verify mobile, desktop, and gamepad navigation.
- [x] Verify buy, upgrade, hire, and premium purchase flows.
- [x] Verify unlock notifications and `unackedUnlocks` behavior still work.

## Files likely touched

- `src/shared/ReactComponents/ShopPanel/init.luau`
- `src/shared/ReactComponents/ShopPanel/ShopTabs.luau`
- `src/shared/ReactComponents/ShopPanel/WorkerManagementCard.luau`
- `src/shared/ReactComponents/ShopPanel/DetailsOverlay.luau` (new)
- `src/shared/ReactComponents/ShopPanel/UpgradeTab.luau` (new)
- `src/shared/ReactComponents/ShopPanel/StaffTab.luau` (new)
- `src/shared/ReactComponents/ShopPanel/ItemTab.luau` (new)
- `src/shared/ReactComponents/ShopPanel/PremiumTab.luau` (new, optional)
- `src/shared/ReactComponents/StorePanel.luau`

## Acceptance criteria

- The shop opens centered and full-screen.
- Registers and Stations are immediately visible on the front page.
- All other content is organized under the correct tab.
- The details overlay only appears on the item tab.
- Upgrade and staff logic live in separate files.
- The premium shop is reachable through its own tab/sub-tabs.
- Existing purchase and upgrade flows still work.
