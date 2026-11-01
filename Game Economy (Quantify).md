# Quantify Lobby - Economy, Monetization & Progression Design Document

This document reconstructs the economy, monetization, and progression systems from the Rojo export of the
Quantify lobby place (`shape_factory`, place id `106281373202161`). It is written as a design reference for
building similar systems in another game.

## Scope and caveats

- Source of truth is the code in `src/` and `default.project.json`.
- This export contains the lobby code plus shared/in-match data modules. The in-match round loop
  (`Server_The_Game`) is **not present**, so a few call sites (Qubit payout, win/loss handling, card
  selection) are inferred from the shared modules and client UI.
- Robux prices below are the **displayed** prices in `RobuxShop.lua`. Real prices are configured on Roblox
  and can differ. Product IDs are listed in `RobuxData.lua`.
- The project is a script overlay on an existing `.rbxlx`; assets, remotes, GUI instances, and world
  geometry are not included. See the main ingestion notes.
- Some systems are partially implemented or contain legacy code. These are flagged explicitly.

Primary source files:

| System | File |
|---|---|
| Currencies / stats | `src/ServerScriptService/Server/Classes/Player.lua`, `src/ServerScriptService/Server/Modules/Data.lua`, `src/ServerScriptService/Server/Modules/ProfileTemplate.lua` |
| Match cash / quota | `src/ReplicatedStorage/Shared/Game.lua` |
| Buildings / items | `src/ReplicatedStorage/Shared/ItemData.lua`, `src/ReplicatedStorage/Shared/BuildingBoxData.lua` |
| Runes | `src/ReplicatedStorage/Shared/RuneData.lua`, `src/ServerScriptService/Server/Classes/Rune/` |
| Cards / upgrades | `src/ReplicatedStorage/Shared/UpgradeData.lua`, `src/ServerScriptService/Server/Modules/Upgrades.lua` |
| Maps / difficulty | `src/ReplicatedStorage/Shared/MapData.lua`, `src/ReplicatedStorage/Shared/DifficultyData.lua` |
| Modifiers / challenges | `src/ReplicatedStorage/Shared/ModifierData.lua`, `src/ReplicatedStorage/Shared/ChallengeRoundData.lua` |
| Daily quests | `src/ReplicatedStorage/Shared/DailyQuests.lua` |
| Codes / daily login | `src/ServerScriptService/Server/Classes/Receive/Code.lua` |
| Titles | `src/ReplicatedStorage/Schemas/TitleSchema.lua`, `src/ServerScriptService/Server/Classes/Titles.lua` |
| Robux catalog | `src/ReplicatedStorage/Shared/RobuxShop.lua`, `src/ReplicatedStorage/Shared/RobuxData.lua` |
| Receipts / gifts | `src/ServerScriptService/Server/Main.server.lua` |
| Leaderboards | `src/ServerScriptService/Server/Modules/Leaderboard.lua`, `src/ServerScriptService/Server/Modules/Data.lua` |

## TL;DR design pillars

1. **Four-tier currency separation**: per-run cash, persistent soft currency (Qubits), earned premium
   currency (Crowns), and Robux. Each has a different source and sink.
2. **Gacha-heavy meta loop**: rune rolls, building boxes, and building rarity pricing are the main ways to
   convert Qubits into power. The lobby shop is a deterministic alternative at a much higher price.
3. **Difficulty/modifier risk-reward**: harder difficulties and optional modifiers multiply Qubit payouts,
   giving players a voluntary difficulty slider with economic upside.
4. **Daily engagement economy**: 7-day login rewards, 3 seeded daily quests, daily leaderboards, and codes.
   Daily quests are by far the largest faucet.
5. **Status monetization**: donations leaderboard, titles, chat tags, pets, and gift broadcasts convert
   Robux into visible status, not just power.
6. **Convenience monetization**: animation skip, auto-reroll, and reroll quantity are sold as quality-of-life
   upgrades on top of the gacha.
7. **Continue monetization**: revives at the moment of failure, including a team-wide "revive all".
8. **No hard paywall to maps/difficulties**: progression gates are stat-based; the main paid shortcut is
   rune slot unlocks.

---

## 1. Currency map

| Currency | Persistence | Earned from | Spent on | Notes |
|---|---|---|---|---|
| **Cash** | Per match | Selling shapes, `Capital Surge` (start cash), `Loose Change` (round-start cash) | In-match shop (buildings) | Team quota is tracked separately; personal cash is spendable. |
| **Qubits** | Persistent | Match payouts (`Player:CalcQubits`), daily quests, daily login, codes, Robux packs | Rune rerolls, building boxes, lobby building shop | Main progression currency. Integer, floor on display. |
| **Crowns** | Persistent | Daily login (day 7), daily quests (quests 2 and 3), codes | Crown Shop (7 exclusive buildings) | Not directly purchasable with Robux in this build. |
| **Robux** | Platform | Purchases | Qubit packs, gamepasses, rune slot unlocks, revives, donations, gifts | Prices are configured on Roblox; display prices in `RobuxShop`. |
| **Donations** | Persistent stat | Robux donation products | None (status only) | Tracked in Robux value; leaderboard and title. |

Displayed symbols:

- `Q$` = Qubits (lobby shop)
- `$` = match cash (in-match shop)
- `R$` = Robux (shop, rune slot unlock pricing, donation leaderboard)

---

## 2. Core gameplay loop

```
Lobby
  -> queue at a teleporter (up to 12 players)
  -> owner selects map and optional modifiers / daily quest
  -> reserved server teleport
  -> in-match: vote difficulty, build factory, sell shapes vs quota
  -> win/lose
       win: Qubit payout + retry / endless vote
       lose: retry / lobby / Robux revive
  -> back to lobby
  -> spend Qubits on runes, building boxes, building shop
  -> unlock maps/difficulties/rune slots, climb leaderboards
```

The lobby itself is also a small shape-factory sandbox: `StupidLobbyMovement.lua` drives conveyors and
sellers around `workspace.Lobby.BuildingParts`, but lobby sellers only visually consume shapes and do not
award cash. The real cash economy runs in the match place.

---

## 3. In-match economy (Cash and quota)

### 3.1 Cash sources and sinks

- Cash is generated by selling shapes (`Part:sell` -> `Game.addQuotaCash`).
- `Game.addQuotaCash(amount)`:
  - Multiplies `amount` by `Stack Overflow` rune value for each player holding it once the quota is already met.
  - Adds to the team pool `Game.data.cash` and lifetime run total `Game.data.totalCash`.
  - Splits the amount equally among players as **personal cash** (`share = amount / playerCount`), used to
    buy buildings from the in-match shop.
  - Marks `quotaMet` when the team pool reaches the quota.
- Cash is reset at the start of each match.
- The in-match shop (`ingameShop.lua`, server `Receive/BoughtItem.lua`) sells `AlwaysAvailable` items using
  `ItemData.Items[item].Price`.
- The `Shopping Frenzy` rune reduces in-match shop prices by 15% per copy equipped.
- `Smart Shopper` is designed to give a 15% chance to keep money, but the visible `BoughtItem` handler does
  not implement that roll; assume it lives elsewhere or is unfinished.

### 3.2 Quota formula

From `Game.calcQuota` (`Shared/Game.lua`):

```
playerFactor = 1 + ln(playerCount) * 0.03
newQuota = round((quota * difficultyQuotaScaling) * (1.02 * playerFactor))
finalQuota = max(25, max(quota, newQuota))
```

- Adding players barely increases quota: 1 player = 1.00x, 4 players ~= 1.042x, 12 players ~= 1.075x.
- The 1.02 constant is a flat per-round inflation on top of difficulty scaling.
- Round 1 quota = the difficulty's `StartingQuota`; every subsequent round compounds.

Sample curves (solo player, ignoring cards/upgrades):

| Round | Easy (start 15, x1.20) | Hard (start 25, x1.50) | Insane (start 30, x2.00) |
|---:|---:|---:|---:|
| 1 | 15 | 25 | 30 |
| 2 | 25 (floor) | 38 | 61 |
| 3 | 31 | 58 | 124 |
| 4 | 38 | 89 | 253 |
| 5 | 47 | 136 | 516 |
| 10 | 130 | 1,140 | 18,236 |
| 20 | 984 | 80,111 | 22,762,887 |
| 30 | n/a (20-round mode) | 5,631,281 | 28,413,780,003 |
| 40 | n/a | n/a (30-round mode) | 35,467,509,017,027 |

Values include the x1.02 flat inflation and the 25-quota floor, and assume a solo player. Rows beyond a
mode's round count are marked n/a. The intended fantasy is exponential production growth within a run;
quota is the pacing gate. The exact numbers depend on missing multiplier/card code, but the shape is clear:
each difficulty is a different exponential.

### 3.3 Shape economy

Base shape values (`Part/init.lua`):

| Shape | Value |
|---|---:|
| Triangle | 5 |
| Square | 10 |
| Pentagon | 15 |
| Hexagon | 20 |
| Circle | 30 |

- Spawn shape chances come from card upgrades: `squareChance`, `pentagonChance`, `hexagonChance`,
  `circleChance`. Default produces triangles.
- `SpawnModule` caps live parts at 250 and enforces a minimum spawn cadence of 2 seconds divided by the
  `Spawn` attribute.
- Mutations multiply value and some change visuals/size:

| Mutation | Effect | Rarity of card |
|---|---|---:|
| Shiny | x1.1 value | Common |
| Golden | x1.5 value | Uncommon |
| Diamond | x2.5 value | Rare |
| Velocitated | value scales with velocity | Epic |
| Hyper | x3 value, unpredictable | Epic |
| Antimatter | x5 value, 2x size | Epic |
| Growing | value and size grow over time | Rare |
| Mitosis | 2% chance on sell to split into two | Legendary |
| Alchemist's Touch | 50% chance to turn non-golden shapes golden before sale | Mythic |

- Mutation application order is fixed in `Part.MUTATION_APPLICATION_ORDER`.
- Old/removed mutation scripts `Dicey` and `Catalyst` still exist in the folder but are not in current
  `UpgradeData`.
- `ToRemove` items are purged from player inventory on login and refunded in Qubits based on rarity. This is
  a useful live-ops migration pattern.

### 3.4 In-match upgrade cards (roguelite progression)

- Cards are end-of-round upgrades, offered as a shared draft and voted on by players
  (`Classes/Receive/Cards.lua`, `gui/cards.lua`).
- `Upgrades.GetCards` draws **4** cards without replacement, using rarity weights:

| Rarity | Weight |
|---|---:|
| Common | 55 |
| Uncommon | 25 |
| Rare | 10 |
| Epic | 6 |
| Legendary | 3 |
| Mythic | 1 |

- Card pool is 16 cards. Chances and effects:

| Card | Rarity | Effect |
|---|---|---|
| SQUARE | Common | +10% square chance |
| SHINY | Common | +15% shiny chance, x1.1 value |
| SPEEDY CONVEYORS | Common | +5% conveyor speed (multiplicative) |
| PENTAGON | Uncommon | +5% pentagon chance |
| RAPID | Uncommon | -10% dropper cooldown (multiplicative) |
| GOLDEN | Uncommon | +5% golden chance, x1.5 value |
| HEXAGON | Rare | +5% hexagon chance |
| OVERTIME | Rare | +5 seconds round time |
| DIAMOND | Rare | +2.5% diamond chance, x2.5 value |
| GROWTH | Rare | +5% growing chance |
| CIRCLE | Epic | +2.5% circle chance |
| VELOCITATION | Epic | +5% velocitated chance |
| HYPER | Epic | +5% hyper chance, x3 value |
| ANTIMATTER | Epic | +3% antimatter chance, x5 value, 2x size |
| MITOSIS | Legendary | +2% chance sold shape splits (cap 20) |
| ALCHEMIST'S TOUCH | Mythic | +50% chance non-golden shape turns golden before sale |

- `Cap` values exist in data but cap enforcement is **commented out** in `Upgrades.ApplyCard`. Chances can
  exceed 100%; each shape spawn rolls the checks sequentially.
- `Dealer` (rune) is designed to add an extra card choice; `Jackpot` (rune) is designed to improve card
  rarity. Neither is implemented in the visible card generation function (no player context), so treat
  those as design intent for the missing loop.
- Voting is cooperative: the majority/selected card becomes the run upgrade. This creates a social
  progression layer inside the run and is a strong idea to borrow.

### 3.5 Challenge rounds and modifiers

**Challenge rounds** (`ChallengeRoundData.lua`) are temporary, per-round twists:

| Challenge | Effect |
|---|---|
| Super Fast Conveyors | 2x conveyor speed |
| Slow Conveyors | 0.5x conveyor speed |
| Low Gravity | Half gravity |
| High Gravity | Double gravity (not in active list) |
| HYPER | All shapes HYPER |
| DIAMONDS ARE FOREVER | All shapes diamond |
| SPEED ROUND | 2x conveyor speed, half round time |

They apply `dataMultiply`, `ExtrasMultiply`, `UpgradesAdd` temporarily and restore original values when the
round ends.

**Player-selected modifiers** (`ModifierData.lua`) are chosen in the lobby queue and multiply Qubit payout:

| Modifier | Description | Payout multiplier |
|---|---|---:|
| Speed Mode | Half time, 2x shape drop rate | 1.0 |
| Speedy Conveyors | 2x conveyor speed, half round | 1.5 |
| No Cards | No cards at end of round | 2.0 |
| Surplus Only | Only keep money above quota | 1.75 |
| No Challenge | No challenge rounds | 0.5 |
| Super Challenge | Every round is a challenge round | 1.25 |
| No Runes | Runes have no effect | 3.0 |
| Expensive | Shop prices rise with rounds | 1.5 |
| Circular | All shapes are circles | 0.25 |
| No Shape Cards | No shape cards in your hand | 1.25 |
| Slower Droppers | Droppers 2x slower | 1.5 |
| Slower Conveyors | Conveyors 2x slower | 1.25 |
| Legendary+ | All cards are Legendary or higher | 0.1 |

- Payout multiplier is the product of all selected modifiers.
- `No Runes` at x3 is the highest single multiplier and intentionally disables the rune meta.
- The color coding helper maps multiplier to red/green (`ModifierData.GetColor`).
- This is a clean, low-cost way to add player-driven difficulty and economy depth.

---

## 4. Meta economy: Qubits

### 4.1 Qubit faucets

**Match payout** (`Player:CalcQubits`):

```
base = MapData.Maps[map].Qubits
difficultyMultiplier = DifficultyData.Modes[difficulty].Stat["Qubit Multiplier"]
modifierMultiplier = product(ModifierData.Modifiers[m].Multiplier for m in run.modifiers)
runFraction = (won) ? 1 : ((round - 1) / totalRounds)
total = floor(base * difficultyMultiplier * modifierMultiplier * runFraction)
total *= (1 + QubitScavengerCount * 0.10)
total *= (1 + HoarderCount * 0.50)
endless bonus: +15 Qubits per round beyond totalRounds
```

- The call site is in the missing `Server_The_Game` loop, but the function is complete.
- Important: partial runs pay proportional to completed rounds, not only on win.
- Map base payouts:

| Map | Base Qubits | Unlock |
|---|---:|---|
| Tutorial | 300 | Special |
| Plains | 100 | None |
| Graveyard | 125 | 1 win |
| Desert | 125 | 1 win |
| Mountains | 150 | 2 wins |
| Tundra | 175 | 4 wins |
| The Baseplate | 200 | 5 wins |
| Jungle | 225 | 6 wins |
| Crystal Caverns | 250 | 7 wins |
| Coralreach | 275 | 8 wins |
| Lunar Outpost | 300 | 10 wins |
| Factory | 325 | 15 wins |
| Underworld | 350 | 20 wins |

- Difficulty multipliers: Easy 1.0x, Normal 1.5x, Hard 2.0x, Insane 3.0x (Tutorial 1.0x).
- Example wins: Plains Easy = 100; Underworld Insane = 1,050; Underworld Insane with No Runes = 3,150;
  stack more modifiers for higher.
- Partial example: 19 of 30 rounds on Hard, Mountains = (19/30) * 150 * 2 = 190 Qubits.
- Endless mode adds 15 per excess round, which is small compared to map/difficulty scaling but rewards
  pushing past the win condition.

**Other Qubit faucets**:

| Source | Amount | Frequency |
|---|---:|---|
| Daily quest 1 | 5,000 | 1/day |
| Daily quest 2 | 1 Crown | 1/day |
| Daily quest 3 | 2 Crowns | 1/day |
| Daily login day 1-7 | 200, 350, 500, 400, 600, 800, 1,000 | 1/day (cycle) |
| Codes (active) | 2,000-5,000 | one-time |
| Robux packs | 100-25,000 | unlimited |

Active codes total: **16,500 Qubits + 1 Crown** (`MINORBUGFIXES1`, `COMPRESSORUPD`, `REBALANCING`,
`4500LIKES`, `DAILYREWARDS`). Codes require membership in group `16218376` and are one-time per account.

Daily login cycle total: **3,850 Qubits + 1 Crown over 7 days**.

Active daily play total (login + all 3 quests, averaged over the 7-day cycle): **about 5,550 Qubits + 3.1
Crowns per day**, or **38,850 Qubits + 22 Crowns per week** if quests are completed every day. This is the
dominant faucet, far above typical match payouts unless the player stacks modifiers heavily.

### 4.2 Qubit sinks and pricing

| Sink | Price | Notes |
|---|---:|---|
| Rune reroll | 100 Qubits | Flat cost; 9 rune slots |
| Box 1 | 100 Qubits | Common-heavy building gacha |
| Box 2 | 500 Qubits | Better odds |
| Box 3 | 2,500 Qubits | Best odds, worst relative value (see 4.4) |
| Lobby building shop | 400-40,000 Qubits | Price is rarity-based, not item-based |
| Crown shop | 2-15 Crowns | Not Qubits |

Lobby building prices are calculated as:

```
price = ceil(1 / Rarity.BaseChance) * 2 * 100
```

| Rarity | BaseChance | Qubit price |
|---|---:|---:|
| Common | 0.55 | 400 |
| Uncommon | 0.25 | 800 |
| Rare | 0.10 | 2,000 |
| Epic | 0.06 | 3,400 |
| Legendary | 0.035 | 5,800 |
| Mythic | 0.005 | 40,000 |
| Winter | 0.001 | 200,000 |

Consequences:

- All items of the same rarity cost the same in the lobby shop, regardless of power.
- The most expensive shop items (Mythic) cost 40,000 Qubits, roughly 8-10 hours of active daily income or
  400 typical Easy wins.
- Box 1 costs 100 Qubits and can roll a Mythic, creating a huge high-roll moment relative to the price.

### 4.3 Qubit pack value ladder (displayed prices)

From `RobuxShop.lua`:

| Pack | Robux | Qubits per Robux | Rolls (100 Qubits) |
|---|---:|---:|---:|
| 100 Qubits | 17 | 5.88 | 1 |
| 500 Qubits | 85 | 5.88 | 5 |
| 1,000 Qubits | 155 | 6.45 | 10 |
| 2,000 Qubits | 300 | 6.67 | 20 |
| 5,000 Qubits | 725 | 6.90 | 50 |
| 10,000 Qubits | 1,450 | 6.90 | 100 |
| 25,000 Qubits | 3,500 | 7.14 | 250 |

- Bulk discount is about 21% from the smallest to largest pack (5.88 to 7.14 Qubits per Robux).
- Each roll costs 100 Qubits, so the 25,000 pack is 250 rerolls.
- At 10,000/1,450, 100,000 Qubits (expected for a single Mythic-rarity drop) would cost about R$14,500 if
  bought only with Robux.
- The largest pack (25k) is smaller than one week of active daily quest income (38,850). Monetization is
  therefore aimed at impatience/whales, not at gating progression. If you copy this, decide whether that is
  intentional; many games make paid currency the faster route.

### 4.4 Building box expected value (analysis)

Box odds (`BuildingBoxData.lua`):

| Box | Price | Common | Uncommon | Rare | Epic | Legendary | Mythic |
|---|---:|---:|---:|---:|---:|---:|---:|
| Box 1 | 100 | 55% | 25% | 10% | 6.5% | 3% | 0.5% |
| Box 2 | 500 | 45% | 25% | 15% | 10% | 4.5% | 1% |
| Box 3 | 2,500 | 10% | 20% | 30% | 25% | 12.5% | 2.5% |

Box 1 and Box 3 weights sum to exactly 100. Box 2 weights sum to 100.5
(45 + 25 + 15 + 10 + 4.5 + 1), a minor data typo.

Using the shop Qubit price of each rarity as the "item value":

| Box | Expected shop value | Cost | Value / cost |
|---|---:|---:|---:|
| Box 1 | 1,215 | 100 | 12.15x |
| Box 2 | 1,681 | 500 | 3.36x |
| Box 3 | 3,375 | 2,500 | 1.35x |

This is the single most important balance observation: **the cheapest box has the best expected value by a
wide margin, and deeper boxes are less efficient in shop-value terms**. If you copy this system, either
price Box 1 higher, flatten the rarity-price curve, or make deeper boxes better EV to create a proper
"premium gacha" ladder.

Caveats:

- "Value" is the deterministic shop price, not real utility. Many rollable items are situational.
- Duplicates stack, so marginal value declines for collectors.
- Boxes are the only way to get some items, so EV is not the whole story.

### 4.5 Full lobby shop pool (Rollable)

`ItemData.Rollable` is `Items` minus `AlwaysAvailable`, `ToRemove`, and `CrownItems`. This means the lobby
shop/gacha pool is the high-end/luxury set, while the in-match shop sells the basics.

| Item | Rarity | Match cash price | Lobby Qubit price |
|---|---|---:|---:|
| Long Booster | Common | 200 | 400 |
| Super Wall | Common | 35 | 400 |
| Long Strong Booster | Uncommon | 250 | 800 |
| Long Super Booster | Uncommon | 350 | 800 |
| Frozen Upgrader | Rare | 5,000 | 2,000 |
| Mossy Upgrader | Rare | 10,000 | 2,000 |
| Fast Fat Conveyor | Epic | 200 | 3,400 |
| Pretty OP Conveyor | Epic | 400 | 3,400 |
| Large Golden Upgrader | Epic | 3,000 | 3,400 |
| Large Diamond Upgrader | Epic | 4,000 | 3,400 |
| OP Conveyor | Legendary | 600 | 5,800 |
| Small Pipe | Legendary | 1,500 | 5,800 |
| Medium Pipe | Legendary | 2,000 | 5,800 |
| Long Pipe | Legendary | 2,500 | 5,800 |
| Corner Pipe | Legendary | 2,000 | 5,800 |
| Square Dropper | Mythic | 1,500 | 40,000 |
| Pentagon Dropper | Mythic | 2,000 | 40,000 |
| Hexagon Dropper | Mythic | 2,500 | 40,000 |
| Circle Dropper | Mythic | 3,000 | 40,000 |
| Emerald Upgrader | Mythic | 20,000 | 40,000 |
| Ruby Upgrader | Mythic | 30,000 | 40,000 |
| Large Seller | Mythic | 50,000 | 40,000 |

Total to buy one of every Rollable item at lobby price: **329,000 Qubits** (about 8.5 weeks of active daily
income, or 3,290 Box 1 rolls in cost terms).

### 4.6 In-match cash shop (AlwaysAvailable)

These are bought with **per-run cash**, not Qubits:

| Item | Price ($) | Rarity |
|---|---:|---|
| Small Wall | 10 | Common |
| Small Conveyor | 15 | Common |
| Conveyor | 25 | Common |
| Wall | 25 | Common |
| Large Wall | 30 | Common |
| Large Conveyor | 40 | Common |
| Crafter | 100 | Common |
| Booster | 100 | Common |
| Strong Booster | 150 | Common |
| Super Booster | 200 | Common |
| Dropper | 450 | Common |
| Shape Compressor | 500 | Uncommon |
| Golden Pad | 600 | Common |
| Diamond Pad | 950 | Uncommon |
| Automatic Dropper | 1,000 | Common |
| Shiny Upgrader | 1,000 | Common |
| Golden Upgrader | 2,000 | Uncommon |
| Diamond Upgrader | 3,000 | Epic |
| Seller | 25,000 | Legendary |

The `Seller` at $25,000 is the big mid-run power spike. `ItemData.ToRemove` still lists legacy items that
are purged from persistent inventory, including basic conveyors, old pads, old upgraders, and `Seller`.
This means the meta inventory and the per-run shop intentionally use different item sets.

### 4.7 Crown currency

Crowns are **earned only** in this build:

- Daily quest 2: 1 Crown.
- Daily quest 3: 2 Crowns.
- Daily login day 7: 1 Crown.
- Code `DAILYREWARDS`: 1 Crown.

Crown shop (`ItemData.CrownItems`):

| Item | Crowns | Cash price field | Effect |
|---|---:|---:|---|
| Triple Pipe | 2 | 2,000 | Shapes can exit any of 3 other ends |
| Random Upgrader | 5 | 15,000 | Applies any upgrade in the game |
| Quantum Dropper | 8 | 2,000 | 75% chance to double produced shape |
| Scaling Seller | 10 | 50,000 | Seller scales with rounds |
| Quantum Seller | 10 | 50,000 | +$100 to every item sold |
| Quantum Dropper V2 | 15 | 2,500 | 75% double; clone can also double |
| Quantum Crafter | 15 | 2,000 | Doubles crafted items |

- The `Price` field on Crown items is cash, but `BuildingPurchase` uses the `Crowns` field for Crown items,
  so `Price` appears vestigial.
- Total to buy every Crown item: **65 Crowns** (about 3 weeks of daily quests + daily logins, or 65 weeks
  from daily login alone).
- Crowns have no Robux purchase path. This is a strong engagement lever: exclusives require showing up.
  It also leaves money on the table if you want to monetize completionists.

---

## 5. Rune system (gacha power progression)

### 5.1 Rune slots and unlocks

- 9 rune slots per player.
- Slot 1 starts unlocked; slots 2-9 are locked.
- Unlock by milestone (`RuneData.RunePrereqs`) or by Robux (`UNLOCK_SLOT_2`..`UNLOCK_SLOT_9`).
- The UI displays the Robux price as `index * 100` R$ (slot 2 = R$200 ... slot 9 = R$900). Actual product
  prices are configured on Roblox.

| Slot | Milestone unlock |
|---:|---|
| 1 | None |
| 2 | 100,000 total cash generated |
| 3 | 1 win |
| 4 | 4 wins |
| 5 | 10 wins |
| 6 | Beat every map (any difficulty) |
| 7 | Reach round 50 on any map/difficulty |
| 8 | Complete 250 rounds |
| 9 | Generate 500,000,000 total cash |

- Sum of displayed slot prices: 200 + 300 + ... + 900 = **R$4,400** to unlock all 8 paid slots. This is the
  largest direct power purchase in the game: a new player can jump from 1 to 9 rune slots immediately.
- Each unlocked slot is a permanent multiplier opportunity because rune effects stack (duplicates count).

### 5.2 Rune roll economics

- Flat cost: **100 Qubits per roll** on any unlocked slot.
- Roll can produce any rune rarity; duplicates are allowed and stack.
- No pity, no dupe protection, no guaranteed legendary counter.
- `Auto Roll` gamepass (R$25 displayed) lets the client automatically reroll with per-rarity filters.
- `Skip Roll` gamepass (R$150 displayed) removes the 4-second server-side reroll lock and the animation.
- Default auto-reroll filters: Mythic and Winter enabled, all others disabled. This turns the system into a
  targeted jackpot hunter.

### 5.3 Rarity weights and expected costs

`RuneData.RuneChances`:

| Rarity | Weight | Expected rolls per result | Expected Qubits |
|---|---:|---:|---:|
| Common | 55 | 1.82 | 182 |
| Uncommon | 25 | 4.0 | 400 |
| Rare | 10 | 10.0 | 1,000 |
| Epic | 6 | 16.7 | 1,667 |
| Legendary | 3.9 | 25.6 | 2,564 |
| Mythic | 0.1 | 1,000 | 100,000 |
| Winter | 0.5 | 200 | 20,000 |

Note: weights sum to 100.5 due to the Winter event bucket.

Specific rune expected cost (uniform within rarity):

| Rarity | Pool size | Expected Qubits for a specific rune |
|---|---:|---:|
| Common | 5 | ~909 |
| Uncommon | 4 | ~1,600 |
| Rare | 4 | ~4,000 |
| Epic | 8 | ~13,333 |
| Legendary | 7 | ~17,949 |
| Mythic | 5 | ~500,000 |
| Winter | 3 | ~60,000 |

Design implications:

- Legendary+ chance is 4.5% per roll. Any Legendary+ averages ~2,222 Qubits (22 rolls).
- Any Mythic averages ~100,000 Qubits (1,000 rolls): about 2.5 weeks of active daily income, or ~R$14,000
  in Qubit packs. A specific Mythic averages ~500,000 Qubits (~R$70,000). This is clearly whale/long-tail
  content, not a normal progression target.
- Duplicate protection is absent, so collecting all 36 runes is effectively not a realistic goal.

### 5.4 Rune catalog

Implementation status is mixed. Server modules exist for 27 of the 36 data runes, but several are empty
stubs or only set flags consumed by other systems; 9 runes have no module. Some effects live outside the
rune folder: Qubit Scavenger and Hoarder are read directly in `Player:CalcQubits`, Stack Overflow is read in
`Game.addQuotaCash`, and Shopping Frenzy is applied in `BoughtItem`.

Confirmed working in visible code:

- Capital Surge, Quickstride, Loose Change, Cog Pulse, Haste, Rush Hour, Long Arms, Markup
- Qubit Scavenger, Hoarder, Stack Overflow, Shopping Frenzy
- Midas, System Anomaly, Simple Start, Chronostasis, Turbo

Partially working / behavior differs from description:

- Conveyor Frenzy gives 1 Large, 1 regular, and 1 Small Conveyor (description says a medium + 2 small).
- Automatron gives 1 Automatic Dropper (description says 3).
- Jackpot sets `ExtraLuck`, but the visible card generator never reads it.
- Infinity Chain sets `InfinityChainChance`, but the spawn code that reads it is commented out and an unused
  `anyPlayerHasInfinityChain` helper exists.

Empty stubs or no visible implementation:

- Adrenaline Rush, Balanced Flow, Overclock, Smart Shopper, Relay Surge, Worthy Hand
- Lucky Step, Magic Mirror, Clockwork, Dealer, Scorched Hands, Automatic Start
- Snowstep, Frostbite, Frost Engine

The table below documents the **design intent** in `RuneData`.

| Rarity | Rune | Effect (data) |
|---|---|---|
| Common | Capital Surge | +15 cash at game start (data Value = 25) |
| Common | Quickstride | +10% walkspeed |
| Common | Balanced Flow | +15% walkspeed when not carrying shapes |
| Common | Loose Change | +20 cash at round start (data Value = 15) |
| Common | Cog Pulse | Main dropper 5% faster |
| Uncommon | Qubit Scavenger | +10% Qubits per copy |
| Uncommon | Haste | +20% walkspeed |
| Uncommon | Rush Hour | Droppers 7.5% faster |
| Uncommon | Long Arms | +20% pickup range |
| Rare | Lucky Step | 5% chance stepping on a shape collects it (no module) |
| Rare | Magic Mirror | Every 5 sold shapes, copy sold for 25% (no module) |
| Rare | Markup | +5% shape value |
| Rare | Shopping Frenzy | 15% off in-match shop |
| Epic | Clockwork | Last 10s of round double value (no module) |
| Epic | Adrenaline Rush | +35% speed while holding a triangle |
| Epic | Overclock | First 10s: droppers 25% faster |
| Epic | Conveyor Frenzy | Spawn with a medium + 2 small conveyors (data Name is "Conveyor Boss") |
| Epic | Turbo | Droppers and main dropper 13% faster |
| Epic | Midas | Shapes you touch turn gold |
| Epic | Scorched Hands | Shapes you touch turn molten (no module) |
| Epic | Simple Start | Spawn with a manual dropper |
| Legendary | Chronostasis | +6s round time |
| Legendary | Smart Shopper | 15% chance to keep money on shop purchase |
| Legendary | Jackpot | +10% card luck |
| Legendary | Automatic Start | Spawn with an automatic dropper (no module) |
| Legendary | System Anomaly | Spawn 3 high-tier shapes at round start |
| Legendary | Hoarder | +50% Qubits per copy |
| Legendary | Worthy Hand | First 10 sold shapes each round are 2x |
| Mythic | Automatron | Spawn with 3 automatic droppers |
| Mythic | Stack Overflow | Shapes 2x once quota is met for the rest of the round |
| Mythic | Relay Surge | Buying a shop item gives 2 |
| Mythic | Dealer | +1 card choice per round (no module) |
| Mythic | Infinity Chain | 10% chance droppers produce a second shape (data Value = 0.15) |
| Winter | Snowstep | +15% speed, 10% chance to double shape value (no module) |
| Winter | Frostbite | Shapes you touch turn snow (no module) |
| Winter | Frost Engine | Frosted shapes 25% chance to duplicate on sell at 50% value (no module) |

Data inconsistencies to note if copying:

- Descriptions and `Value` fields disagree in several places (Capital Surge 15 vs 25, Loose Change 20 vs 15,
  Infinity Chain 10% vs 15%).
- `RuneData.ActiveEvents.Christmas.Enabled` is `false`, but `RollRune` has an event-gating condition that
  does not skip Winter runes when the event is disabled (`not ActiveEvents[event] and not Enabled`). Winter
  runes are effectively always rollable. If you build events, test this logic carefully.
- Old rune names are migrated on load: `Profit Margin` -> `Markup`, `Conveyor Boss` -> `Conveyor Frenzy`,
  `Soft Launch` -> `Simple Start`.

---

## 6. Progression systems

### 6.1 Maps

- 13 maps including Tutorial; 12 selectable in the lobby.
- Unlock is account-wide wins via `Prerequisites.Any.Wins`.
- Each map has its own Qubit base, music, image, and per-difficulty stat table.
- Map stats (`data.Map[map][difficulty]`) are initialized on first play and track wins, losses, games,
  rounds, cash, highest round, highest cash.
- A map is "beaten" if any difficulty has wins > 0 (`MapData.CheckIfBeatenMap`).
- Tutorial is excluded from the normal map list and from statistics.

### 6.2 Difficulties

| Difficulty | Rounds | Round length | Start quota | Quota scale | Qubit multiplier | Unlock |
|---|---:|---:|---:|---:|---:|---|
| Tutorial | 3 | 86,400s | 15 | 1.0 | 1.0 | Special |
| Easy | 20 | 60s | 15 | 1.2 | 1.0 | None |
| Normal | 25 | 60s | 20 | 1.3 | 1.5 | Easy: 3,000 cash generated, round 8 |
| Hard | 30 | 60s | 25 | 1.5 | 2.0 | Normal: 25 rounds, 2 games, 15,000 cash, round 12, 8,000 highest cash |
| Insane | 40 | 60s | 30 | 2.0 | 3.0 | Easy 100,000 cash generated **AND** Hard: 3 games, 50,000 cash, round 15, 25,000 highest cash |
| Extreme | - | - | - | - | - | Defined but commented out |

Note on Insane: the prerequisite evaluator iterates all listed difficulty prerequisites and returns false if
any fail, so the Easy and Hard conditions are effectively AND, not OR. If you copy this, decide whether you
want "complete one of these paths" or "complete all".

### 6.3 Inventory slots

- 8 hotbar slots for buildings.
- Slots 1-5 are free; slots 6-8 unlock by milestones (`RuneData.InventorySlotPrereqs`):

| Slot | Requirement |
|---:|---|
| 1-5 | None |
| 6 | 3 wins |
| 7 | 100 rounds completed |
| 8 | 1,000,000,000 total cash generated |

- No Robux unlock path for inventory slots in this build.
- Inventory is divided into:
  - `Inventory` (owned, unequipped building counts, persistent)
  - `CurrentInventory` (8 equipped hotbar slots, persistent)
- Equipping moves one item from inventory to the first unlocked empty slot; unequipping returns it.
- The lobby shop only displays the `Rollable` pool; the in-match shop displays `AlwaysAvailable`. This split
  is a deliberate/accidental soft separation of meta and per-run power.

### 6.4 Titles

- 13 cosmetic titles, auto-unlocked on login and when the title update signal fires.
- Equipped title appears on the character and in chat (`TitleSchema` + `Shared/Chat.lua`).
- Requirements are a mix of progress, luck, and spending:

| Title | Requirement |
|---|---|
| Beginner | Play the game |
| Codebreaker | Redeem the old `TITLES` code (code is now commented out) |
| Hoarder | Equip more than 3 runes |
| Veteran | Play 25 games |
| Wealthy | Generate over 1,000,000 cash |
| Charitable Fellow | Donate any amount |
| Collector | Own at least 10 inventory items |
| Rune Master | Unlock every rune slot |
| Strategist | Complete 10 rounds on Normal or higher |
| Jackpot | Have 3 or more Jackpot runes |
| No Lifer | Have 10,000,000 Qubits |
| Frostbound | Play during the Christmas event |
| King | 100 wins |

- No title shop or paid title path. Titles are status rewards; `Charitable Fellow` is the direct
  monetization hook.
- `TitleSchema` order values contain duplicates and the client titles module is minimal; the UI is not a
  full collection screen in this snapshot.

### 6.5 Daily login rewards

7-day cycle (`Code.lua` `DailyRewards`):

| Day | Qubits | Crowns |
|---:|---:|---:|
| 1 | 200 | - |
| 2 | 350 | - |
| 3 | 500 | - |
| 4 | 400 | - |
| 5 | 600 | - |
| 6 | 800 | - |
| 7 | 1,000 | 1 |
| **Total** | **3,850** | **1** |

- Must claim in order; one claim per UTC day.
- If more than one UTC day is skipped, the streak resets to 0.
- `Data.PlayerAdded` also resets the streak on a new day if the streak is already 7, or if more than 48
  hours have passed.
- Day 4 is lower than day 3 (non-monotonic) and then ramps again; this may be intentional pacing or a typo.

### 6.6 Daily quests

- 3 quests per UTC day, deterministic via a date seed (`DailyQuests.GteSeedFromDate`).
- Each quest has a map, a difficulty, a list of modifiers, a win condition, and a reward.
- Point budget ramps per quest (30 points for quest 1, 60 for quest 2, 90 for quest 3).
- Modifiers cost `round((Multiplier - 1) * 30)` points; difficulty costs: Easy 0, Normal 15, Hard 30,
  Insane 45.
- Win conditions:

| Condition | Range | Reward |
|---|---|---:|
| GenerateCash | 10,000 to 100,000,000 | Quest 1: 5,000 Qubits |
| ReachRound | 20 to 75 | Quest 2: 1 Crown |
| - | - | Quest 3: 2 Crowns |

- ReachRound up to 75 is only achievable in endless mode (max 40 normal rounds), which makes the hardest
  quest a genuine endurance challenge.
- Completion is stored per user per UTC day in the `DailyQuests` DataStore as a 3-bool table. It is read on
  join and written on completion; `GetAsync`/`SetAsync` (not `UpdateAsync`) is used.
- Starting a quest teleports the player solo to a reserved server with the map and modifiers.
  `QuestReceive.StartQuest` does **not** pass the quest difficulty in `tpData`; the missing game loop may or
  may not infer it. If you copy this, include the difficulty explicitly.
- The rewards are flat per quest index, not scaled by the difficulty of the generated quest. This creates a
  known exploit/inefficiency: rerolling the daily seed is not possible, but the hardest quest (2 Crowns) is
  not necessarily 90 points; the point budget is a cap, not a guarantee.

### 6.7 Codes

Active codes (`Code.lua`):

| Code | Reward |
|---|---|
| MINORBUGFIXES1 | 2,000 Qubits |
| COMPRESSORUPD | 4,000 Qubits |
| REBALANCING | 5,000 Qubits |
| 4500LIKES | 3,500 Qubits |
| DAILYREWARDS | 2,000 Qubits + 1 Crown |

Rules:

- Must be in group `16218376`.
- Case-insensitive (uppercased).
- One-time per account (`UsedCodes`).
- 0.5s per-player cooldown.
- Past codes are commented out rather than deleted, which preserves history and makes it easy to re-enable
  for events.

This is a simple, effective retention/social mechanic tied to group membership and like milestones.

### 6.8 Leaderboards and tracked stats

Global leaderboards (`Data.Leaderboards`, `workspace.Leaderboards`):

- Donations (Robux, prefix `R$`)
- HighestRound (prefix `Round`)
- CashGenerated (prefix `$`)
- Wins (suffix ` Wins`)
- Qubits (suffix ` Qubits`)

Daily leaderboards (`workspace.LeaderboardsDaily`, stores keyed `Stat_YYYY-MM-DD` in UTC):

- HighestRound
- CashGenerated
- Wins

Update cadence:

- Player data pushed to global stores via `Data.QueueLeaderboardUpdate` and a 60-second queue loop.
- Physical boards refresh every 600 seconds (`Leaderboard.lua`).
- Daily `CashGenerated` keeps the best single-run total of the day; daily `HighestRound` keeps the best
  round; daily `Wins` accumulates.
- Global `CashGenerated` is the lifetime total, not the best run.

Per-player stats (`ProfileTemplate.Stat`):

- Wins, Losses, GamesPlayed
- Donations, HighestRound, CashGenerated
- TrianglesDropped, RoundsCompleted

Per-difficulty stats: RoundsCompleted, GamesPlayed, CashGenerated, HighestRound, HighestCash.
Per-map/per-difficulty stats: same set.

The profile is reconciled (`profile:Reconcile()`) so new fields are added automatically for existing
players. Versioned store names (`PlayerStore0006`, leaderboard stores `_0006`) allow a clean reset/migration.

### 6.9 Tutorial

- Offered to players with `Stat.GamesPlayed == 0` (`lobbyhud.lua`).
- Teleports solo to the Tutorial map with `TryTutorial`.
- Tutorial difficulty: 3 rounds, 86,400-second round time, starting quota 15, Qubit multiplier 1.
- Tutorial shop uses `ItemData.TutorialItems` (`Large Conveyor` only) and `TutorialItemData` re-prices
  Large Conveyor to $15.
- On the tutorial round end, the server grants 2 Large Conveyors, 1 Conveyor, 1 Small Conveyor
  (`TutorialEvent.lua`).
- Tutorial map base Qubits is 300, the highest in the game, making it a generous first-session reward.

### 6.10 Pets and gamepasses

- 4 cosmetic pets: Triangle, Circle, Cube, Star.
- Each is a gamepass at R$75 displayed, and also giftable through a dev product equivalent.
- Pets follow the player and are purely cosmetic.
- VIP is present in code paths (chat tag, `IsVip`) but disabled: no VIP gamepass ID, `IsVip` returns false.

---

## 7. Monetization catalog

### 7.1 Qubit packs (consumable currency)

- 100, 500, 1,000, 2,000, 5,000, 10,000, 25,000.
- Displayed prices: R$17, 85, 155, 300, 725, 1,450, 3,500.
- Bulk discount ~21%.
- Qubits buy rune rolls, boxes, and lobby buildings.

### 7.2 Gamepasses (permanent convenience/cosmetic)

| Gamepass | Displayed price | Effect | Category |
|---|---:|---|---|
| Auto Reroll | R$25 | Automatic rune rerolling with rarity filters | Convenience |
| Skip Rolls | R$150 | Skips rune/building roll animations and the 4s reroll lock | Convenience |
| Triangle Pet | R$75 | Cosmetic pet | Cosmetic |
| Circle Pet | R$75 | Cosmetic pet | Cosmetic |
| Cube Pet | R$75 | Cosmetic pet | Cosmetic |
| Star Pet | R$75 | Cosmetic pet | Cosmetic |

- Auto Reroll is cheap and high-impact for gacha engagement. Expect it to be the best-converting item.
- Skip Rolls is expensive relative to Auto Reroll but targets whales who roll hundreds of times.
- Pets are low-price cosmetic upsells.

### 7.3 Rune slot unlocks (direct power)

- Products `UNLOCK_SLOT_2` through `UNLOCK_SLOT_9`.
- UI displays R$200 to R$900 by slot index; total R$4,400 for all 8.
- Server sets `playerOb.data.RunesUnlocked[index] = true` and opens the Runes GUI.
- This is the main pay-for-power lever; a new player can skip 500M cash generation and 250 rounds with
  Robux.

### 7.4 Revives (pay-to-continue)

- Products `REVIVE_1` through `REVIVE_5`, plus `REVIVE_ALL`.
- Triggered from the game-over screen when the player lost:
  - `REVIVE_n` revives the purchaser, increments `Revives` (capped at 4), resets `CurrentlyHasLost`.
  - `REVIVE_ALL` revives all players, adds `#players` to a global revive counter, resets everyone's lost
    flag.
  - Both set game state to `intermission` and broadcast a client event.
- The client picks the next product from `math.min(4, revives) + 1`, so at 4 revives it prompts `REVIVE_5`;
  the server then caps the stored count at 4. This is a minor product-index inconsistency.
- Gifting a revive still applies the effect to the purchaser (`player`), not the gift target. If you copy
  gifting, handle target redirection per product type.
- Revive pricing is not in the repo; configure it as a high-value, high-friction impulse purchase.

### 7.5 Donations (status monetization)

- Products `DONATE_5`, `_10`, `_50`, `_100`, `_250`, `_500`, `_1,000`, `_5,000`, `_10,000`, `_100,000`.
- Adds the donation amount to `Stat.Donations` and updates the Donations leaderboard.
- Unlocks the `Charitable Fellow` title at any amount.
- No gameplay benefit.
- This is pure status/altruism monetization and works because of the public leaderboard and title.
- A gifting edge case: the `DONATE_` receipt branch always credits the purchaser, even if a gift target was
  set. If you build gifting, decide whether donations should be giftable.

### 7.6 Gifting

- Any shop item can be gifted via the Gift button.
- Flow:
  1. Client selects a target player (`SelectPlayer`).
  2. Client invokes `Remotes.Gift:InvokeServer(target)`; server stores `Gifts[purchaser] = target`.
  3. Client prompts the product.
  4. `ProcessReceipt` checks `Gifts[player]`, resolves `TARGET` and `targetOb`, then delivers.
  5. For Qubits, pets, Skip Rolls, and Auto Roll, the server broadcasts a chat message naming gifter and
     recipient.
- Gamepasses use dev product equivalents when gifted.
- The gift target is cleared after a successful receipt, but not if the purchase is canceled, so a stale
  target can persist into a later purchase. Clear it on `PromptProductPurchaseFinished` or with a timeout.
- Gifting creates social virality and lets whales spend on friends, which is usually a strong revenue and
  retention feature.

### 7.7 VIP (disabled)

- `IsVip` always returns false.
- Chat code supports a VIP tag.
- No VIP product is active. This is a ready-made future monetization hook.

### 7.8 Monetization summary by player motivation

| Motivation | Monetized items |
|---|---|
| Impatience / power | Qubit packs, rune slot unlocks |
| Convenience | Auto Reroll, Skip Rolls |
| Completion / collection | Qubit packs for boxes and runes, pets |
| Status | Donations, titles, chat tags, leaderboards |
| Social | Gifting, Revive All |
| Failure aversion | Revives |
| Cosmetics | Pets, titles, chat prefixes |

---

## 8. Economy flows and pacing analysis

### 8.1 Faucet/sink balance

Weekly active income (login + 3 daily quests every day): **38,850 Qubits + 22 Crowns**.
Weekly match income depends heavily on skill/modifiers; a casual player winning Plains Easy once per day adds
700 Qubits/week, while a modifier-stacking Underworld Insane group can add tens of thousands.

Weekly sinks:

- 9 rune rolls per day at 100 = 6,300 Qubits/week if the player rolls 9 times daily.
- Box 1 at 100 per roll: 700/week if one box daily.
- A single Mythic shop item = 40,000 Qubits (about one week of active income).
- All Rollable shop items = 329,000 Qubits (about 8.5 weeks).
- All Crown items = 65 Crowns (about 3 weeks of active dailies).

This creates a meta where daily quests, not matches, are the primary income. Matches supply the fun and the
run-based stats, but the daily quest rewards are ~50x a typical Easy win. If you copy this, either:
- lower the daily quest Qubit reward, or
- increase match payouts, or
- make daily quests significantly harder/time-gated.

### 8.2 Gacha economics

- Rune rolls: 100 Qubits, no pity, 0.1% Mythic, 4.5% Legendary+. The top-end is a whale sink.
- Building boxes: 100/500/2,500 Qubits, with EV inversions (Box 1 best value).
- Both gachas feed the same currency (Qubits), so players choose between runes (power multipliers) and
  buildings (run power/complexity).
- The `Auto Reroll` filter defaults to Mythic/Winter, which is a clever way to let players burn currency
  automatically while chasing the top rarity.

### 8.3 Power curve

- The largest early power jumps come from:
  1. Unlocking rune slots (milestones or Robux).
  2. Filling slots with Qubit Scavenger/Hoarder for payout, and Turbo/Rush Hour for production.
  3. Buying/gambling for higher-end conveyors and sellers.
  4. Learning modifier stacking for payout multipliers.
- The largest long-term goal is Mythic runes (500k Qubits average for a specific one), which is deliberately
  out of reach for casual players.
- Cards reset each run, so they are the moment-to-moment power curve; runes/buildings are the persistent
  curve.

### 8.4 Retention loops

- Session loop: queue -> run -> payout -> roll/buy -> queue.
- Daily loop: login reward, 3 daily quests, daily leaderboards, codes.
- Weekly loop: 7-day login crown, map/difficulty unlocks, leaderboard resets.
- Social loop: queue with friends, vote on modifiers/difficulty/cards, gift items, donate, revive all.
- Rejoin loop: `CheckExistingGame` uses MemoryStore sessions to offer reconnection to an in-progress private
  server; `SoftShutdown` teleports players to a new reserved server during migrations.
- No battle pass, season, or limited-time shop in this build; those are obvious future extensions.

---

## 9. What to borrow for your own game

### 9.1 Strong ideas worth adapting

1. **Separate per-run cash from persistent soft currency.** It lets you tune run economy (quota) and meta
   economy (Qubits) independently.
2. **Rarity-priced deterministic shop plus discounted gacha.** Players can choose certainty or variance.
   Fix the EV inversion if you copy the exact numbers.
3. **Modifiers as payout multipliers.** A simple menu of optional penalties can create huge replayability
   and lets skilled players opt into higher income.
4. **Daily quests with generated map/modifier/difficulty combinations.** This reuses existing content
   instead of requiring bespoke quest design.
5. **Cooperative card drafting.** Voting on run upgrades creates shared decisions and table talk.
6. **Earned premium currency with no direct purchase.** Crowns gate exclusives behind engagement, which
   boosts retention; add a paid path only if you need the revenue.
7. **Status monetization via donations and titles.** Cheap to build, high margin, and socially visible.
8. **Gifting and gift broadcasts.** Whales spend more when they can buy for friends and get public credit.
9. **Pay-to-continue revives at the failure moment.** High emotional impact; price carefully to avoid
   feeling predatory.
10. **Auto-reroll and skip-animation as paid convenience.** Low development cost, strong conversion on top
    of any gacha.
11. **Live-ops migrations with refunds.** Old items/runes are converted or refunded on login
    (`ToRemove`, `RuneConverts`), which protects trust when rebalancing.
12. **Versioned profile stores.** `PlayerStore0006` and `_0006` leaderboard suffixes make resets and
    migrations explicit.
13. **Rejoin and soft-shutdown flows.** These are retention features that players notice during outages.
14. **Daily leaderboards with UTC keys.** Low-cost competitive retention; separate "best run" and
    "cumulative" semantics for different stats.

### 9.2 Things to fix or avoid

1. **Box EV inversion**: the cheapest box is 12x value, the most expensive is 1.35x. Either accept it as an
   entry box or rebalance.
2. **Daily quests dwarf match income** (5,000 Qubits vs 100-1,050 typical win). Tune your primary loop to be
   the best income source if you want players to play matches, not just log in.
3. **No pity/dupe protection** on a 0.1% Mythic pool; completion is effectively impossible. Add a
   guaranteed Legendary+ counter, dupe conversion, or targeted crafting if you want collectors.
4. **Rune data/description mismatches, empty stub modules, and unimplemented runes.** Keep data, tooltips,
   and behavior in one place, and test every rune.
5. **Winter event gating bug**: event runes can roll while the event is disabled. Gate on a single
   `IsEnabled` check.
6. **Card caps commented out**: chance cards can exceed 100%. Enforce caps or make overcap convert to a
   different stat.
7. **Revive/gift target bugs**: gift revives and slot unlocks apply to the purchaser. Route all receipt
   effects through the resolved target.
8. **Stale gift target**: clear `Gifts[purchaser]` on purchase completion/cancellation and with a timeout.
9. **Donation gifting ambiguity**: decide whether donations credit the gifter or the recipient; currently
   they always credit the gifter.
10. **`GetData` hangs on falsy values** (`repeat until self.data[key]`) which is risky for 0/false values.
11. **No server-side rate limit for Skip Rolls owners**; each roll still costs 100 Qubits, but auto-roll can
    spam. Add a server cooldown independent of the paid skip if you care about load.
12. **Daily quest completion uses `SetAsync` without `UpdateAsync`**; concurrent sessions can clobber
    progress.
13. **Daily quest modifier costs can go negative.** `cost = round((Multiplier - 1) * 30)` makes modifiers
    below 1x (for example, Circular at 0.25x) *add* budget instead of costing it. Clamp costs to at least 0
    or use a proper budget solver.
14. **`CashGenerated` naming is ambiguous**: global is lifetime total, daily is best single run. Name them
    distinctly in your own schema.
15. **Insane difficulty prerequisites are AND, not OR**, despite reading like alternative paths.
16. **Crown shop `Price` fields are vestigial** and can confuse tooling; remove unused fields.
17. **The lobby shop only surfaces `Rollable` items**; basics exist only in the in-match shop. Make sure
    players can actually acquire what they need in the lobby.

### 9.3 A possible economy template derived from this game

```
Run currency: Cash
  Sources: selling output, start-of-round runes
  Sinks: per-run shop, quota gate
  Reset: every run

Soft currency: Qubits
  Sources: run payout (map base x difficulty x modifiers x runes), dailies, codes, packs
  Sinks: rune rolls (100), boxes (100/500/2500), deterministic shop (400-40000)
  Goal: permanent power and collection

Earned premium: Crowns
  Sources: daily login day 7, daily quests 2-3, codes
  Sinks: exclusive shop (2-15 Crowns)
  Goal: retention exclusives, no direct purchase

Paid: Robux
  Qubit packs, convenience gamepasses, rune slot unlocks, revives, donations, gifts
  Goal: impatience, convenience, status, continuation
```

---

## 10. Appendix: product and ID reference

### 10.1 Qubit products

| Product | ID |
|---|---:|
| QUBITS_100 | 3345730977 |
| QUBITS_500 | 3345731317 |
| QUBITS_1000 | 3345732005 |
| QUBITS_2000 | 3345732367 |
| QUBITS_5000 | 3345732502 |
| QUBITS_10000 | 3345732631 |
| QUBITS_25000 | 3345732812 |

### 10.2 Donation products

| Product | ID |
|---|---:|
| DONATE_5 | 3348962870 |
| DONATE_10 | 3348963186 |
| DONATE_50 | 3348963317 |
| DONATE_100 | 3348963446 |
| DONATE_250 | 3348963622 |
| DONATE_500 | 3348963855 |
| DONATE_1000 | 3348964057 |
| DONATE_5000 | 3348964320 |
| DONATE_10000 | 3348964541 |
| DONATE_100000 | 3348964699 |

### 10.3 Revive products

| Product | ID |
|---|---:|
| REVIVE_1 | 3345734210 |
| REVIVE_2 | 3345734338 |
| REVIVE_3 | 3345734448 |
| REVIVE_4 | 3345734606 |
| REVIVE_5 | 3345734747 |
| REVIVE_ALL | 3345734935 |

### 10.4 Rune slot products

| Product | ID |
|---|---:|
| UNLOCK_SLOT_2 | 3350151696 |
| UNLOCK_SLOT_3 | 3350151938 |
| UNLOCK_SLOT_4 | 3350152159 |
| UNLOCK_SLOT_5 | 3350152410 |
| UNLOCK_SLOT_6 | 3350152605 |
| UNLOCK_SLOT_7 | 3350153056 |
| UNLOCK_SLOT_8 | 3350153186 |
| UNLOCK_SLOT_9 | 3350153306 |

### 10.5 Gamepasses and gift equivalents

| Gamepass | Gamepass ID | Gift product ID | Displayed price |
|---|---:|---:|---:|
| SKIP_ROLL | 1415970481 | 3383867622 | R$150 |
| AUTO_ROLL | 1507329365 | 3420743448 | R$25 |
| TRIANGLE_PET | 1417647228 | 3383867723 | R$75 |
| CIRCLE_PET | 1419828116 | 3383867354 | R$75 |
| CUBE_PET | 1419953876 | 3383867473 | R$75 |
| STAR_PET | 1420204918 | 3383867238 | R$75 |

---

## 11. One-paragraph pitch of the design

Quantify's economy is a **run-based factory idle game feeding a gacha meta**. Each match is a short
exponential production puzzle gated by a quota; winning or progressing pays Qubits scaled by map,
difficulty, optional modifiers, and equipped runes. Qubits are spent in the lobby on slot-machine runes,
building boxes, or deterministic high-rarity buildings, then reinvested into harder maps and difficulties.
Daily quests, a 7-day login cycle, seeded codes, and daily leaderboards keep players returning, while
Crowns gate a small set of exclusive buildings behind consistent play. Monetization sells acceleration
(Qubit packs, rune slots), convenience (auto-reroll, skip animations), status (donations, gifts, pets), and
continues (revives). The strongest ideas to borrow are the run/meta currency split, modifier-multiplied
payouts, co-op card drafting, earned premium currency, and status/gifting monetization; the biggest pitfalls
are the inverted box EV, the daily-quest faucet dominating match income, and the no-pity 0.1% rune pool.
