# Before Launch — Session Compact

## Objective
Make Craft n' Cafe ready for the weekly live-game loop, not just a bare-minimum launch. The pre-launch baseline is:
measurement + leaderboards + personal feedback + join group reward + cheap starter + QPTR/promises docs.
Economy tuning is intentionally deferred to the user's Run E data and the 10k-visit threshold.

## User decisions
- Pre-launch blockers: measurements/funnels tested, QPTR checklist, join group + reward, leaderboards, cheap starter.
- Leaderboards are simple, not a weekly Cafe Score:
  - Daily Perfect Cups Served: player-only, `cups[player].status == 3`, never worker-served.
  - Daily Customers Served: player-only, only when `workerUid == "player"`.
  - Existing all-time Time Played board stays.
- Leaderboard display: UI Ranks panel + personal HUD + keep the existing physical Time Played board.
- Leaderboards are social flex, not cash faucets.
- Join group reward: cash only. Group ID `1104050205`.
- Cheap starter: around R$20, small cash, no 8,000 cash and no duplicate starter-item refunds.
- Recipe book stays a week 1–2 feature.
- No base serve multipliers. The user is raising prices instead.
- Recipe milestone rewards: all claims one-time (not daily-capped). Pacing will come from prices.
- Future after pre-launch: placeables pacing + diverge floor/roof; recipe book + discovered drinks slice + recipe rewards.
- QPTR and promises docs should be kept simple.

## Important context
- The user already changed `WorkersConfig.luau`: walk/craft/quality upgrade costs raised.
- The user already changed `UpgradesConfig.luau`: ingredient upgrade curve changed from `1.7^x` to `2^x`.
- The user disabled the mock ProfileStore in `PlayerDataService.luau` for multi-session Run E.
  The current file still has a dangling `if IS_PLAYTESTING then`; it evaluates nil/false, so the real store is used.
- The user may need to force no-pass in published playtests on their own account.
- Run D reached level 13 and meaningful progression in ~107 minutes, roughly the 7-day × 15-minute target.
  The concern is bingeability, not total time. The user is handling pacing through prices.
- Do not add serve multipliers or broad price tuning in this work.
- `TimePlayedClass.server.luau` is in the Studio workspace, not in the Rojo tree. It writes to the
  `TopTimePlayed` OrderedDataStore with keys `TimePlayed<userId>` and values in minutes.
- Perfect cup caveat: `cupsSlice` stores the minimum ingredient score, and `calculateScore` currently returns 3
  for a timing range, not only a full bar. Confirm whether `status == 3` is the intended definition.
- `GlobalState` is session-only. Daily leaderboards need persisted profile counters and OrderedDataStore sync.

## Pre-launch feature list
1. Measurements/funnels:
   - Onboarding funnel and level progression funnel.
   - Shop funnel for CVR.
   - Native feedback prompt, automatic trigger disabled, manual Settings button.
   - Fix economy event logging.
2. Daily leaderboards + all-time time played in a Ranks UI.
3. Personal daily HUD + perfect-cup toast/sound.
4. Join group cash reward.
5. Cheap starter pack.
6. Simple QPTR checklist and player promises docs.

## Worries / intentions
- Do not tune the economy from one run. Treat Run E as directional, not statistical.
- Keep new systems config-driven and feature-flagged where reasonable.
- One metric-changing variable per week; do not mix CVR and retention changes.
- Verify funnel events in the Creator Dashboard `View Events` before trusting weekly results.
- The physical Time Played board may not be included in a Rojo build; the UI reads the datastore, not the model.
- If Studio DataStore access is off, leaderboard calls must fail gracefully and not block gameplay.
- No leaderboard cash rewards initially; that would add another faucet and complicate pacing.
- The cheap starter must avoid the old duplicate-item refund faucet.

## Work state
- Compact and implementation plan created.
- Pre-launch features implemented:
  - `TelemetryService`: onboarding/level/shop funnels, content custom events.
  - Native feedback prompt controller/component; automatic prompt disabled; Settings manual button.
  - Daily leaderboard service + Ranks panel + daily HUD + perfect-cup toast.
  - Join group cash reward service + Settings button (group `1104050205`, 500 cash).
  - Cheap starter config (500 cash, R$19 hint, no items).
  - Economy event logging fix.
  - Playtest CSV columns for new stats.
  - `PlaytestConfig` mock flag cleanup + no-pass override for admin user ID.
  - QPTR and player promises docs.
- Verification: `stylua --syntax Luau` parse check and `rojo build` succeeded.
- Runtime verification pending: Studio/published smoke test, Creator Dashboard funnels, View Events, Feedback dashboard, Run E.
- Dashboard price for the starter product still needs to be set to ~R$19–25 manually.
- Worker/upgrade cost changes are the user's; do not revert.
- No base serve multipliers were added.

## Remaining / next
- Run E multi-session playtest and inspect new CSV columns.
- Verify player-only leaderboard counters ignore worker-served customers.
- Verify perfect-cup definition and board behavior.
- Verify group reward in published game with a non-owner account.
- Verify `View Events` for Onboarding, Level Progression, and Shop.
- Decide whether `status == 3` should mean full-bar perfect; if so, fix `DrinksService.calculateScore`.
- Future after launch: placeables pacing + floor/roof divergence; recipe book/discovered drinks/rewards; no serve multipliers.

## Relevant files
- `src/server/Services/TelemetryService.luau`
- `src/server/Services/LeaderboardService.luau`
- `src/server/Services/GroupRewardService.luau`
- `src/server/Services/PlayerDataService.luau`
- `src/server/Services/CustomersService.luau`
- `src/server/Services/MonetizationService.luau`
- `src/shared/Configs/LeaderboardConfig.luau`
- `src/shared/Configs/GroupRewardConfig.luau`
- `src/shared/Configs/FeedbackPromptConfig.luau`
- `src/shared/Configs/MonetizationConfig.luau`
- `src/shared/Configs/PlaytestConfig.luau`
- `src/shared/Configs/WorkersConfig.luau`
- `src/shared/Configs/UpgradesConfig.luau`
- `src/shared/Controllers/FeedbackPromptController.luau`
- `src/shared/ReactComponents/RanksPanel.luau`
- `src/shared/ReactComponents/DailyStatsHud.luau`
- `src/shared/ReactComponents/FeedbackPrompt.luau`
- `src/shared/ReactComponents/SettingsPanel.luau`
- `src/shared/producers/GlobalState/cupsSlice.luau`
- `src/shared/producers/GlobalState/statsSlice.luau`
- `src/shared/Types.luau`
- `src/shared/Remotes.luau`
- `src/shared/Utils/PlaytestSnapshot.luau`
- `live_game_checklist/qptr_checklist.md`
- `live_game_checklist/promises.md`
- `appendices/quantifyleaderboardmodule.luau`
- `appendices/inworkspacealready/TimePlayedLeaderboard/TimePlayedClass.server.luau`
