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
local discoveredDrinksSlice = require(script.discoveredDrinksSlice)
local shopSlice = require(script.shopSlice)
local shelvesSlice = require(script.shelvesSlice)
local dailySlice = require(script.dailySlice)
local spawnerSlice = require(script.spawnerSlice)
local workersSlice = require(script.workersSlice)

export type CombinedActions = Types.CombinedActions

export type GlobalState = {
	Stats: statsSlice.StatsState,
	Ingredients: ingredientsSlice.IngredientsState,
	Customers: customersSlice.CustomersState,
	Daily: dailySlice.DailyState,
	Workers: workersSlice.WorkersState,
}

export type Stats = statsSlice.StatsState
export type PlayerData = Types.PlayerData

local producer = Reflex.combineProducers({
	Stats = statsSlice,
	Ingredients = ingredientsSlice,
	Customers = customersSlice,
	Daily = dailySlice,
	Workers = workersSlice,
}) :: Reflex.Producer<GlobalState, CombinedActions>

return producer
