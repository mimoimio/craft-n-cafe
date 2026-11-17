# Before Launch — Implementation Plan

## Status
Implemented in this session. See `plans/beforeLaunch/compact.md` for the current work state and verification checklist.
`rojo build` and Luau parse checks passed. Runtime/dashboard verification still needs a Studio/published playtest.

## Scope
Implement the pre-launch baseline only:
1. Measurements/funnels.
2. Daily leaderboards + all-time time played UI.
3. Personal daily HUD + perfect-cup feedback.
4. Join group cash reward.
5. Cheap starter pack.
6. Simple QPTR checklist + player promises docs.

Out of scope:
- Placeables pacing and floor/roof divergence.
- Recipe book, discovered drinks slice, recipe rewards.
- Base serve multipliers or broad price tuning.
- Leaderboard cash rewards.
- ARPPU/CVR product expansion beyond the cheap starter.

## Data model

### StatsEntity
Add:
- `PerfectCupsServed: number` — lifetime, player-only.
- `PlayerCustomersServed: number` — lifetime, player-only.
- `DailyPerfectCups: number`
- `DailyPlayerCustomers: number`
- `DailyKey: string` — UTC `YYYY-MM-DD`.
- `GroupRewardClaimed: boolean`
- `FeedbackPromptedAt: number` — `0` means never prompted.

### ServeCustomerPayload
Add:
- `perfectCup: boolean`
- `dayKey: string`

### statsSlice
- `startPlayerSession`: default all new fields.
- `serveCustomer`:
  - Reset daily counters when `payload.dayKey ~= playersStats.DailyKey`.
  - Increment lifetime and daily player-only counters only when `workerUid == "player"`.
  - Increment `PerfectCupsServed` / `DailyPerfectCups` only when `perfectCup == true` and player-served.
  - Keep `CustomersServed` as total (player + worker).
- Add `markGroupRewardClaimed`.
- Add `markFeedbackPrompted`.

### Profile template
Add defaults for all new stats fields.

## Leaderboards

### Config
New `src/shared/Configs/LeaderboardConfig.luau`:
- Perfect Cups board: daily, store base `DailyPerfectCups`.
- Customers board: daily, store base `DailyCustomers`.
- Time Played board: all-time, store `TopTimePlayed`, key prefix `TimePlayed`.
- Refresh interval 300s, page size 100, display top 10.

### Server `LeaderboardService.luau`
- On player removing: sync daily counters.
- Every 5 minutes: sync all active players' daily counters.
- Daily store name: `<StoreBase>_<YYYY-MM-DD>`.
- Time Played is written by the external `TimePlayedClass`; this service only reads it.
- `Remotes.FetchLeaderboard.OnServerInvoke` returns:
  - board id, display name, daily/reset label.
  - top 10 entries: rank, user id, name, value.
  - local player's value and rank if found in top 100.
- Cache board results for ~60 seconds.
- Wrap all DataStore calls in `pcall`; return empty data on failure.

### Client `RanksPanel.luau`
- Panel controlled by `UIState` panel `"ranks"`.
- Tabs: Perfect Cups, Customers, Time Played.
- Show top 10, local player highlight, local score/rank.
- Show daily reset text for daily boards.
- Loading and empty states.
- Sidebar button "Ranks".
- Mount in `Main.PlayPhase`.

### Personal HUD `DailyStatsHud.luau`
- Show `Today: X perfect · Y served`.
- Toast + sound when `DailyPerfectCups` increases.
- Reset toast baseline when `DailyKey` changes or the count decreases.
- Mount near `NextGoal`.

## Join group reward
- New `GroupRewardConfig.luau`: `GroupId = 1104050205`, `Cash = 500`.
- New `GroupRewardService.luau`:
  - `Remotes.ClaimGroupReward` handler.
  - Verify `Player:IsInGroupAsync(GroupId)` with `pcall`.
  - Reject if already claimed.
  - Grant cash + `markGroupRewardClaimed`; save profile where practical.
  - Log `GroupRewardClaimed` custom event.
- `SettingsPanel`:
  - Button “Join Group (+500 Cash)” / “Group Reward Claimed”.
  - `GroupService:PromptJoinAsync(GroupId)` on client.
  - On `Joined` or `AlreadyMember`, fire claim remote.
  - Toast results.

## Cheap starter
- `MonetizationConfig.StarterProduct`:
  - Keep key and product ID.
  - `Cash = 500`.
  - `Items = {}`.
  - `PriceHint = 19`.
  - Update display name/description.
- Dashboard price must also be changed to ~R$19–25 by the user.
- This removes the old 8,000 cash + duplicate-item refund faucet.

## Measurements/funnels

### `TelemetryService.luau`
- Apply `GlobalState` middleware; log after successful dispatch.
- Onboarding funnel:
  1. Joined
  2. Play Pressed
  3. Customer Arrived
  4. Order Taken
  5. Cup Taken
  6. First Ingredient
  7. First Customer Served
  8. Second Customer Served
  9. Tutorial Complete
- Level progression funnel: levels 2–20 via `LogFunnelStepEvent`.
- Content custom events: `WorkerHired`, `PlotExpanded`, `StationPurchased`.
- Deduplicate per player.
- Studio prints; published calls are wrapped in `pcall`.
- Remove dead `LogTutorialStep` path from `StatsService.luau` and `Remotes.luau`.

### Shop funnel
- Add `Remotes.LogShopFunnel`.
- Client steps:
  1. Opened Premium.
  2. Selected Product.
- Server step 3 on successful cash product / gamepass purchase.
- Per-player shop session id stored in `TelemetryService`/`MonetizationService`.

### Feedback prompt
- Config: `AutoPromptEnabled = false`, required level 6, 30-day cooldown.
- `FeedbackPromptController`: wraps `SocialService:PromptFeedbackSubmissionAsync`, Studio guard, manual mode.
- `FeedbackPrompt` component mounted in `Main`; auto logic gated off.
- `SettingsPanel` manual “Send Feedback” button.
- `FeedbackPromptedAt` profile field + `MarkFeedbackPrompted` remote.
- Owner cannot submit; test with alt. Studio cannot show the native prompt.

### Economy logging
- Fix `MonetizationService.logPurchase`:
  - Use `Enum.AnalyticsEconomyTransactionType.RobuxPurchase.Name`.
  - Use the real ending cash balance.

## Playtest logging
- Add columns to `PlaytestSnapshot`:
  - `perfect_cups_served`
  - `player_customers_served`
  - `daily_perfect_cups`
  - `daily_player_customers`
  - `daily_key`
  - `group_reward_claimed`
  - `feedback_prompted_at`
- This supports Run E multi-session analysis.

## Playtest support
- Add `PlaytestConfig.UseMockProfileStore = false` and replace the dangling `IS_PLAYTESTING` check.
- Add `PlaytestConfig.AlwaysNoPassUserIds = { [5470482596] = true }` so published admin playtests can run without passes.
- Apply the override in `MonetizationService.syncGamePasses`.

## Configs
- `src/shared/Configs/LeaderboardConfig.luau`
- `src/shared/Configs/GroupRewardConfig.luau`
- `src/shared/Configs/FeedbackPromptConfig.luau`

## Verification
- `npx --yes @johnnymorganz/stylua-bin --check --syntax Luau` on changed files.
- `rojo build default.project.json`.
- Studio smoke test:
  - Leaderboard UI opens and fails gracefully if DataStore is unavailable.
  - Daily HUD updates after a player-served customer.
  - Perfect-cup toast only appears for player-served perfect cups.
  - Join group button handles joined/pending/not-joined.
  - Feedback Settings button prints the Studio guard.
  - Telemetry prints funnel/custom events.
- Published test with alt account:
  - Creator Hub → Analytics → Funnels → View Events.
  - Audience → Feedback after submitting the native prompt.
  - Ranks panel shows daily boards after scores sync.
- Run E:
  - Check new CSV columns.
  - Verify worker-served customers do not raise player-only counters.

## Risks
- Perfect cup definition may need a scoring fix before trusting the board.
- DataStore availability in Studio can make the ranks panel empty; it must not error.
- Time Played board depends on the external Studio script.
- Changing `StarterProduct.Cash` in code does not change the Roblox dashboard price.
- The group reward requires the group ID to be correct and join eligibility.
- Do not tune prices or add serve multipliers in this pass.
