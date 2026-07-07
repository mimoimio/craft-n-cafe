--!strict
-- Shared/producers/GlobalState/init.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Reflex = require(ReplicatedStorage.Packages.Reflex)
local Types = require(ReplicatedStorage.Shared.Types)

local statsSlice = require(script.statsSlice)
local tablesSlice = require(script.tablesSlice)
local drinksSlice = require(script.drinksSlice)
local ingredientsSlice = require(script.ingredientsSlice)
local mixersSlice = require(script.mixersSlice)
local customersSlice = require(script.customersSlice)

export type CombinedActions = Types.CombinedActions

export type GlobalState = {
	Stats: statsSlice.StatsState,
	Tables: tablesSlice.TablesState,
	Drinks: drinksSlice.DrinksState,
	Ingredients: ingredientsSlice.IngredientsState,
	Mixers: mixersSlice.MixersState,
	Customers: customersSlice.CustomersState,
	UnlockedIngredients: {},
	DiscoveredDrinks: {},
}

export type Stats = statsSlice.StatsState

export type PlayerData = Types.PlayerData

local producer = Reflex.combineProducers({
	Stats = statsSlice,
	Tables = tablesSlice,
	Drinks = drinksSlice,
	Ingredients = ingredientsSlice,
	Mixers = mixersSlice,
	Customers = customersSlice,
}) :: Reflex.Producer<GlobalState, CombinedActions>

return producer
