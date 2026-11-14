a# StationPrompts.luau TODO Plan

Source: `src/shared/ReactComponents/StationPrompts.luau`

## Existing TODO

> add auto fire server if reached the full value (1)

The timing bar is in `TimingBar`; the current server call is `Remotes.UseStation:InvokeServer(itemId, value)` inside `prompt.TriggerEnded` (around line 147).

## Tasks

- [x] Extract the large `validatedScore` if/else chain into a local `handleScore(validatedScore)` function.
- [x] Reuse `handleScore` from both the normal release path and the new auto-fire path.
- [x] On `prompt.Triggered`, start the progress tween and schedule an auto-fire at `TIMING_BAR_DURATION`.
- [x] When the auto-fire runs, call `Remotes.UseStation:InvokeServer(itemId, 1)`.
- [x] Treat the auto-fired value as a failed timing hit (server `calculateScore(1)` returns `0`, so the UI shows "Release On Green Area!").
- [x] Add a `hasAutoFired` ref/guard so releasing after auto-fire does not submit twice.
- [x] Cancel the scheduled auto-fire when `prompt.TriggerEnded` fires first.
- [x] Ensure the progress bar is locked at `1` when auto-fire happens.
- [x] Reset the guard on the next `prompt.Triggered`.
- [x] Verify the server's `calculateScore(1)` returns `0` (fail), not a perfect score.

## Known issue to keep documented

Lines 398-415 describe an existing ProximityPrompt custom-style edge case where the prompt may already be shown before React mounts its custom UI. This is not part of the auto-fire TODO, but should remain documented or be handled separately.

## Files likely touched

- `src/shared/ReactComponents/StationPrompts.luau`
- `src/server/Services/DrinksService.luau` (only if validation needs adjustment)

## Acceptance criteria

- Holding the station input until the timing bar reaches full value automatically submits a failed hit (no ingredient added).
- Releasing early still submits the normal value.
- Releasing after auto-fire does not add a duplicate ingredient.
- The score text and feedback appear correctly for both paths.
