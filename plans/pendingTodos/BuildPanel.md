# BuildPanel TODO Plan

Source: `src/shared/ReactComponents/BuildPanel/init.luau`

## Existing TODO

> add cancel button somewhere between delete, paint and rotate

The toolbar is defined in the `Toolbar` HStack around lines 439-595. Current button order: Delete, Paint, Rotate, Place.

## Tasks

- [x] Add a `Cancel` `SmallButton` to the `Toolbar` HStack.
- [x] Place it between `PaintTool` and `Rotate`.
- [x] Adjust `LayoutOrder` values so the visual order is Delete, Paint, Cancel, Rotate, Place.
- [x] On activated, call `UIState.selectBuildItem(nil)` to deselect the current item.
- [x] Ensure delete mode and paint mode are cleared when cancel is pressed.
- [x] Ensure `PlacementController:selectItem(nil)` runs through the existing effect so the ghost item disappears.
- [x] Keep the build panel open after cancelling; only the selected item should be cleared.
- [x] Add an icon asset consistent with the existing toolbar style.
- [x] Add a controller label/binding if the other toolbar buttons show one.
- [x] Verify mobile sizing and gamepad selection behavior.
- [x] Remove or avoid introducing unused imports while editing.

## Files likely touched

- `src/shared/ReactComponents/BuildPanel/init.luau`
- Possibly `src/shared/Controllers/PlacementController.luau` if a dedicated cancel helper is added

## Acceptance criteria

- A cancel button appears between Paint and Rotate.
- Pressing it clears the selected item and removes the placement ghost.
- The Build panel remains open.
- Delete and Paint modes are not left active after cancelling.
