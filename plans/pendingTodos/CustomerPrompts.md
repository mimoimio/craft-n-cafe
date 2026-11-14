# CustomerPrompts.luau TODO Plan

Source: `src/shared/ReactComponents/CustomerPrompts.luau`

## Existing TODO

> abstract this logic, the waiter's patience. I want to make it longer, but maybe easier if util.
> Because `Customers.luau` also uses it.

The inline patience color logic is in `CustomerPrompts.luau:108-110`.
The server timeout currently lives in `src/server/Services/CustomersService.luau:16` as `MAX_WAITING_TIME = 20`.

## Tasks

- [x] Create a shared patience utility, for example `src/shared/Utils/PatienceUtil.luau` or `src/shared/Configs/PatienceConfig.luau`.
- [x] Export a single `MAX_WAITING_TIME` value from the utility.
- [x] Export a function such as `getRatio(secondsWaited)` that returns the normalized patience value.
- [x] Export a function such as `getColor(secondsWaited)` that returns the green/yellow/red color.
- [x] Replace the inline color lerp in `CustomerPrompts.luau:108-110` with the utility.
- [x] Update `CustomersService.luau` to import `MAX_WAITING_TIME` from the utility instead of defining it locally.
- [x] Search for any other patience or timeout duplicates and replace them with the utility.
- [x] Increase the patience duration via the shared config, as requested.
- [x] Keep the meter thresholds in sync with the new duration.
- [x] Verify the TODO's reference to `Customers.luau`; the actual timeout logic appears to be in `CustomersService.luau`.

## Files likely touched

- `src/shared/Utils/PatienceUtil.luau` (new) or `src/shared/Configs/PatienceConfig.luau` (new)
- `src/shared/ReactComponents/CustomerPrompts.luau`
- `src/server/Services/CustomersService.luau`

## Acceptance criteria

- Patience duration is defined in one place.
- The customer prompt meter color and the server timeout use the same source of truth.
- Increasing patience requires changing only the shared config.
- Color transitions at 0s, halfway, and timeout still look correct.
