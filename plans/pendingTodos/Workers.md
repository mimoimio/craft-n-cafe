# Workers.luau TODO Plan

Source: `src/server/Services/CafeRenderingService/Workers.luau`

## Existing TODOs

> do client side, when worker found no station for it's next station in plot, then warn player.
> either warn when observing worker's ingredient mismatch with placed stations, or
> warn when there are unplaced stations in inventory. Maybe just unplaced stations.
>
> do something like observe the cashier in `src/server/Services/CafeRenderingService/Cafe.luau:64`

Additional note in the file (lines 41-44):

> CRITICAL BUG: after the 6 sec implementation, if player has two staffs, the second staff wont do anything.
> Maybe because the wait keeps resetting? Instead of wait 6 sec for player to take the customer,
> give workers a slower cooldown, maybe 3s, meaning at 3s they lock and take whatever order there is.

## Tasks

### 1. Client-side missing-station warning

- [x] Create a client-side observer/hook, for example `src/shared/Hooks/useWorkerStationWarnings.luau` or `src/shared/ReactComponents/WorkerWarnings.luau`.
- [x] Mount it in the client UI so warnings are shown only for the local player.
- [x] Observe `state.Workers[playerId]`, `state.Plot[playerId].placedItems`, `state.Plot[playerId].spatialItems`, and `state.Inventory[playerId]`.
- [x] Follow the observer pattern used in `Cafe.luau:63` (`GlobalState:observe` with a selector and per-key add/remove callbacks).
- [x] For each active worker, resolve the next required station from `targetUuid` / `recipeQueue`.
- [x] Detect when the required station is not placed on the plot.
- [x] Prefer the "unplaced station in inventory" warning: if the missing station is owned in inventory, show a toast such as `Place your <Station> station`.
- [x] Use `Toasts.useToast().open(message, duration, color)` for the warning.
- [x] Dedupe warnings per worker/station and throttle repeats so the toast does not spam.
- [x] Reset the dedupe state when the station is placed.

### 2. Optional ingredient mismatch warning

- [x] Compare the worker's recipe ingredients with the stations currently placed on the plot.
- [x] Warn when a required ingredient station is missing, but only if that station is owned in inventory.

### 3. Two-worker bug

- [x] Reproduce with two hired workers and multiple simultaneous customers.
- [x] Inspect `WorkersService.Tick` assignment logic for starvation, resetting waits, and `assignedThisTick` early breaks.
- [x] Add a per-worker assignment cooldown (`lastTend` or a new cooldown field).
- [x] Replace the 6-second player-first delay with a configurable worker cooldown (approximately 3 seconds).
- [x] Move the cooldown value into `WorkersConfig` so it can be tuned.
- [x] Verify that different workers can be assigned to different customers in the same tick/loop.
- [x] Verify that `servedBy`, `action`, and `recipeQueue` stay consistent after assignment.

## Files likely touched

- `src/server/Services/CafeRenderingService/Workers.luau`
- `src/server/Services/WorkersService.luau`
- `src/shared/Configs/WorkersConfig.luau`
- `src/shared/Hooks/useWorkerStationWarnings.luau` (new)
- Client UI mount point

## Acceptance criteria

- A toast appears when a worker needs a station that is not placed but is owned in inventory.
- Warnings do not spam and disappear after the station is placed.
- Two or more workers can work on separate customers without one starving the other.
- Worker assignment cooldown is configurable and behaves as intended.
