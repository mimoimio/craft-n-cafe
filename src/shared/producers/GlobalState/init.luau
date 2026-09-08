--!strict
-- Shared/producers/GlobalState/init.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Reflex = require(ReplicatedStorage.Packages.Reflex)
local Types = require(ReplicatedStorage.Shared.Types)

local statsSlice = require(script.statsSlice)
local ingredientsSlice = require(script.ingredientsSlice)
local customersSlice = require(script.customersSlice)
local workersSlice = require(script.workersSlice)
local cupsSlice = require(script.cupsSlice)
local plotSlice = require(script.plotSlice)

export type CombinedActions = Types.CombinedActions

export type GlobalState = {
	Stats: statsSlice.StatsState,
	Ingredients: ingredientsSlice.IngredientsState,
	Customers: customersSlice.CustomersState,
	Workers: workersSlice.WorkersState,
	Cups: cupsSlice.CupsState,
	Plot: plotSlice.PlotState,
}

export type Stats = statsSlice.StatsState
export type PlayerData = Types.PlayerData

local producer = Reflex.combineProducers({
	Stats = statsSlice,
	Ingredients = ingredientsSlice,
	Customers = customersSlice,
	Workers = workersSlice,
	Cups = cupsSlice,
	Plot = plotSlice,
}) :: Reflex.Producer<GlobalState, CombinedActions>

return producer
