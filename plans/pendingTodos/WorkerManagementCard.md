# WorkerManagementCard.luau TODO Plan

Source: `src/shared/ReactComponents/ShopPanel/WorkerManagementCard.luau`

## Existing TODO

> use images for buttons and cards

## Tasks

- [x] Replace the plain `Frame` card background with an image-based card background.
- [x] Use `ImageLabel`/`ImageButton` or the `SmallButton` image support consistently with `ItemButton`.
- [x] Add a barista portrait or avatar image area in the card header.
- [x] Use icons for the three stat upgrade buttons:
  - walk speed
  - craft speed
  - quality
- [x] Keep the dynamic level, value, and price text overlaid on the images.
- [x] Add hover/press visuals such as `HoverScale` and stroke state changes.
- [x] Keep the existing `Visible`, `LayoutOrder`, mobile sizing, and maxed/unaffordable states unchanged.
- [x] Add a clear maxed-state visual when a stat cannot be upgraded further.
- [x] Add a clear unaffordable visual when the player cannot pay.
- [x] Store any new image asset IDs in a local constant or existing config for reuse.

## Files likely touched

- `src/shared/ReactComponents/ShopPanel/WorkerManagementCard.luau`
- Possibly a shared asset/config file for card and stat icons

## Acceptance criteria

- The worker card uses image assets instead of plain colored rectangles.
- Each stat button has a recognizable icon plus its level, value, and price text.
- Maxed and unaffordable states remain visually obvious.
- Multiple worker cards still lay out correctly in the staff tab.
- Mobile and gamepad behavior is unchanged.
