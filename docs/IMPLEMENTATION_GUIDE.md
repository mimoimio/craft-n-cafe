# Craft n' Cafe Implementation Guide

## Purpose

This document captures the current implementation of Craft n' Cafe so development can continue without losing context. It is intended as a practical handoff reference for gameplay systems, architecture, data flow, and next steps.

## Project Summary

Craft n' Cafe is a Roblox game prototype built with Luau, Rojo, Reflex, and ReactRoblox. The current design mixes two ideas:

- a cafe management loop where players brew and serve drinks
- a collection-style progression loop where players unlock ingredients, drinks, upgrades, and cafe capacity

The prototype already has a working state-driven foundation for player progression, drink crafting, customer flow, shop rotation, daily rewards, and UI panels.

## Current Status

The game is in an early-to-mid prototype state. Core systems are implemented, but several features are still partial, stubbed, or intended for future expansion.

Implemented systems include:

- player profile loading and persistence
- Reflex-based global state management
- drink mixing and pickup flow
- customer spawning, queueing, and payment flow
- deterministic shop-cycle state
- ingredient rolling and spawner purchasing
- daily reward progression
- level-based unlocks for tables, ingredients, and mixers
- React-based UI panels and HUD elements

Still incomplete or partially wired include:

- some legacy remote actions that are disabled or stubbed
- progression balancing and economy tuning
- richer customer behavior and visual polish
- deeper recipe and ingredient content expansion
- more complete multiplayer/session edge-case handling

## High-Level Architecture

### 1. Client-Server Split

The game uses a standard Roblox server/client pattern:

- Server services own authoritative game logic
- The client renders UI and sends requests through RemoteEvents
- Reflex state is broadcast to the client so UI can react to shared state

### 2. State Management

The game uses Reflex producers to manage global state. All major player data is stored in a combined global state tree.

The main state entry point is:

- [src/shared/producers/GlobalState/init.luau](../src/shared/producers/GlobalState/init.luau)

This combines the following slices:

- Stats
- Tables
- Drinks
- Ingredients
- Mixers
- Customers
- DiscoveredDrinks
- Shop
- Daily
- Spawner

### 3. UI Architecture

The UI is built using ReactRoblox and is mounted from the client bootstrap script.

The main UI entry is:

- [src/client/init.client.luau](../src/client/init.client.luau)

The UI components live under:

- [src/shared/ReactComponents](../src/shared/ReactComponents)

## Core Game Loop

The current game loop is:

1. Player joins the game
2. Server loads or creates their profile data
3. Server hydrates the shared global state from the saved profile
4. Client connects to the broadcast receiver and mounts the UI
5. Player can:
   - roll for ingredients
   - purchase ingredients from the spawner
   - mix drinks using mixers
   - place drinks on tables
   - serve customers
   - earn cash and unlock progression

## Main Systems

### Player Profile and Persistence

The server-side profile system is centered in:

- [src/server/Services/PlayerDataService.luau](../src/server/Services/PlayerDataService.luau)

Key responsibilities:

- loads player profile data using ProfileStore
- deep-reconciles profile data with a template so older saves keep newer fields
- hydrates global Reflex state when the player starts a session
- syncs profile changes back into the saved data structure

The profile template defines the initial structure for:

- Stats
- Tables
- Drinks
- Mixers
- Ingredients
- Customers
- Shop
- Daily
- Spawner

This is the primary persistence boundary of the game.

### Shared Types

All major data structures are defined in:

- [src/shared/Types.luau](../src/shared/Types.luau)

This file defines the shape of player data, slice state, payloads, and remote actions. If a new feature is added, the type definitions should be updated first.

### Global State Slices

Each slice owns one part of the player state.

#### Stats Slice

- [src/shared/producers/GlobalState/statsSlice.luau](../src/shared/producers/GlobalState/statsSlice.luau)

Handles:

- cash
- tutorial completion
- cafe open/closed state
- unlock and progression values
- luck
- cafe capacity
- roll cooldown

#### Tables Slice

- [src/shared/producers/GlobalState/tablesSlice.luau](../src/shared/producers/GlobalState/tablesSlice.luau)

Handles:

- table ownership
- placed drinks on table slots
- table unlocks from leveling

#### Drinks Slice

- [src/shared/producers/GlobalState/drinksSlice.luau](../src/shared/producers/GlobalState/drinksSlice.luau)

Handles:

- drink inventory objects
- adding newly brewed drinks
- stock depletion and restock logic

#### Ingredients Slice

- [src/shared/producers/GlobalState/ingredientsSlice.luau](../src/shared/producers/GlobalState/ingredientsSlice.luau)

Handles:
- ingredient counts owned by the player
- ingredient consumption during mixing
- ingredient gains from spawner purchases and daily rewards

#### Mixers Slice

- [src/shared/producers/GlobalState/mixersSlice.luau](../src/shared/producers/GlobalState/mixersSlice.luau)

Handles:

- mixer state
- whether a mixer is currently occupied by a drink
- drink start time and variation assignment
- pickup and skip behavior

#### Customers Slice

- [src/shared/producers/GlobalState/customersSlice.luau](../src/shared/producers/GlobalState/customersSlice.luau)

Handles:

- customer entities
- spawn state
- queueing state
- payment state
- removal state

#### Discovered Drinks Slice

- [src/shared/producers/GlobalState/discoveredDrinksSlice.luau](../src/shared/producers/GlobalState/discoveredDrinksSlice.luau)

Tracks unlocked/discovered drink combinations by variation.

#### Shop Slice

- [src/shared/producers/GlobalState/shopSlice.luau](../src/shared/producers/GlobalState/shopSlice.luau)

Tracks:

- active shop seed
- current variation event
- shop inventory per cycle

#### Daily Slice

- [src/shared/producers/GlobalState/dailySlice.luau](../src/shared/producers/GlobalState/dailySlice.luau)

Tracks:

- last daily claim
- current day index
- day progression state

#### Spawner Slice

- [src/shared/producers/GlobalState/spawnerSlice.luau](../src/shared/producers/GlobalState/spawnerSlice.luau)

Tracks:

- currently rolled ingredient offer
- last pull time

## Server Services

The server-side logic is split into service modules.

### Drinks Service

- [src/server/Services/DrinksService.luau](../src/server/Services/DrinksService.luau)

Handles:

- drink mixing requests
- ingredient validation
- mixer occupancy validation
- drink pickup timing
- skip-mix handling

### Customers Service

- [src/server/Services/CustomersService.luau](../src/server/Services/CustomersService.luau)

Handles:

- customer spawning
- customer drink selection from table inventory
- customer state transitions
- payment calculation
- customer removal after serving or leaving

### Shop Service

- [src/server/Services/ShopService.luau](../src/server/Services/ShopService.luau)

Handles:

- deterministic shop generation from a seed
- leveling progression and unlocks
- upgrade actions like luck and cafe capacity
- shop-cycle refreshes for active players

### Spawner Service

- [src/server/Services/SpawnerService.luau](../src/server/Services/SpawnerService.luau)

Handles:

- ingredient roll generation
- spawner purchase cost evaluation
- applying newly purchased ingredients

### Daily Service

- [src/server/Services/DailyService.luau](../src/server/Services/DailyService.luau)

Handles:

- daily reward claims
- day cycle updates
- reward configuration loading

### Tables Service

- [src/server/Services/TablesService.luau](../src/server/Services/TablesService.luau)

Handles:

- placing drinks onto table slots
- restocking table inventory behavior

## Content and Economy Systems

### Recipes and Ingredients

The game’s content definitions live in:

- [src/shared/Configs/CoffeeConfig.luau](../src/shared/Configs/CoffeeConfig.luau)
- [src/shared/Configs/IngredientsConfig.luau](../src/shared/Configs/IngredientsConfig.luau)

These files define:

- drink recipes
- ingredient costs
- ingredient rarity and shop stock ranges
- display names and item tips

The central content module is:

- [src/shared/CoffeeModule.luau](../src/shared/CoffeeModule.luau)

This module builds:

- recipe lookup tables from ingredient combinations
- drink metadata
- ingredient lookup tables
- recipe path helpers used by the UI

### Progression and Levels

The leveling system is defined in:

- [src/shared/Configs/LevelConfig.luau](../src/shared/Configs/LevelConfig.luau)

The level config maps:

- new tables unlocked per level
- new ingredients unlocked per level
- new mixers unlocked per level
- level costs

### Shop Cycle and Daily Cycle

The economy loop is driven by:

- [src/shared/ShopCycle.luau](../src/shared/ShopCycle.luau)

This module defines shop rotation timing with:

- small cycles
- large cycles
- special-event state
- daily progression state

This is the backbone for timed shop refreshes and daily reward cadence.

## Remote Events and Network Flow

The remote layer is defined in:

- [src/shared/Remotes.luau](../src/shared/Remotes.luau)

Important remotes include:

- start
- dispatch
- MixDrink
- PickUpDrink
- PlaceDrink
- TendCustomer
- BuyIngredient
- LevelUp
- ToggleCafeOpen
- ClaimDaily
- RollIngredient
- BuyIngredientFromSpawner
- UpgradeLuck
- UpgradeCafeCapacity

### Client Dispatch Flow

The client boot script listens for dispatched actions from the server and feeds them into a Reflex broadcast receiver:

- [src/client/init.client.luau](../src/client/init.client.luau)

This enables the client to stay synced with the shared gameplay state.

## UI and Interaction Layer

The React-based UI is organized into many panels and visual systems:

- App shell
- Cafe panel
- Mixer panel
- Shop panel
- Recipe panel
- Daily claim popup
- Tutorial flow
- Customer nodes
- Table nodes
- Spawner UI
- Upgrade UI

The available components are listed under:

- [src/shared/ReactComponents](../src/shared/ReactComponents)

The UI uses global UI state from:

- [src/shared/producers/UIState.luau](../src/shared/producers/UIState.luau)

This producer holds UI-specific state such as:

- active panel
- selected mixer
- spawner prompt state
- table slot visibility
- button references and interactive instances

## Known Implementation Notes and Technical Debt

Several parts of the codebase are functional but still rough around the edges.

### 1. Legacy or Disabled Logic

Some earlier systems were left behind or disabled, including:

- old BuyIngredient shop flow
- old mix-skip request flow
- some placeholder purchase prompts

These should be reviewed before expanding gameplay systems.

### 2. Economy Balance Is Not Fully Tuned

Ingredient prices, drink prices, level costs, and progression pacing are still early estimates. This is likely one of the first things to refine once content is stable.

### 3. Some Systems Are Only Partially Integrated

A few features are implemented in the state layer but still need stronger UI and service wiring. Examples include advanced upgrade paths and some version of the mixer and cafe expansion experience.

### 4. Save Compatibility Needs Care

The profile reconciliation logic is already fairly robust, but future schema changes should be handled carefully to avoid breaking older saves.

### 5. Some Mocking and Debug Paths Exist

The Remotes module includes a mock mode for UI Labs, which is useful for development but should not be treated as production behavior.

## Recommended Continuation Plan

### Phase 1: Stabilize the Core Loop

Focus on:

- making the tutorial and first-session onboarding consistent
- ensuring mixing, customers, and payments all flow cleanly
- validating that saving and loading works reliably

### Phase 2: Polish the Economy

Focus on:

- balancing ingredient costs
- tuning drink profit values
- making progression feel satisfying
- ensuring the shop cycle and daily cycle feel meaningful

### Phase 3: Expand Gameplay Depth

Focus on:

- more drink recipes and ingredient tiers
- event-based shop variations
- richer customer behavior
- more progression and upgrade content

### Phase 4: Production Hardening

Focus on:

- better validation and anti-exploit checks
- test coverage for services and state transitions
- better UX and UI polish
- performance profiling if the player count grows

## Suggested Next Tasks for the Next Contributor

1. Review all service modules and identify any disabled or stale logic.
2. Confirm that the server and client are both using the same action names and payload shapes.
3. Add a small playtest checklist for the current core loop.
4. Build one new feature at a time, preferably by extending an existing slice and its service together.
5. Keep new content config-driven where possible so recipes, ingredients, and progression remain easy to expand.

## Practical Development Notes

- When adding new gameplay features, update the relevant slice, service, remote event, and type definitions together.
- Prefer config-driven content for recipes, ingredients, and progression rather than hard-coding one-off values.
- Keep the server authoritative for state changes and use the client mostly for input and UI feedback.
- If you add new state fields, make sure they are included in the profile template and reconciliation logic.

## Short Version

The game already has a strong skeleton for a cafe-style collection sim:

- players gather ingredients
- brew drinks
- place drinks on tables
- serve customers
- earn cash and unlock more content

The next major value will come from tightening the economy, expanding content, and polishing the progression loop rather than rebuilding the foundation.
