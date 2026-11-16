# PlacementController

Source: `src/shared/Controllers/PlacementController.luau:3`

- [ ] There's this thing with walls,
  where a wall is 2x0 grid, and when cursor moved,
  it snapped when cursor changed grid, my expected
  behavior is like this.
  cursor 0,0, the ghost is placed starting at -1,0,
  but right now it is placed at 0,0

  like, I want it ghost on the middle/exactly on the cursor, instead of starting at the cursor
