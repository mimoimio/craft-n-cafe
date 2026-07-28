--!strict
-- discoveredDrinksSlice.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Reflex = require(ReplicatedStorage.Packages.Reflex)
local Sift = require(ReplicatedStorage.Packages.Sift)
local Types = require(ReplicatedStorage.Shared.Types)

local Dictionary = Sift.Dictionary
local Array = Sift.Array
local Merge = Dictionary.merge
local Set = Dictionary.set
local RemoveKey = Dictionary.removeKey

-- /// TYPES ///
type PlayerData = Types.PlayerData

export type DiscoveredDrinksState = Types.DiscoveredDrinksState

export type StatsActions = {}

-- /// INITIALIZATION ///
local initialState: DiscoveredDrinksState = {}

-- /// REDUCERS ///
local actions = {
	startPlayerSession = function(state: DiscoveredDrinksState, playerId: string, data: PlayerData)
		return Set(state, playerId, data.DiscoveredDrinks)
	end,
	endPlayerSession = function(state: DiscoveredDrinksState, playerId: string, data: PlayerData)
		return RemoveKey(state, playerId)
	end,
	pickUpDrinkFromMixer = function(state: DiscoveredDrinksState, playerId: string, payload: Types.PickUpPayload)
		local playersDiscoveredDrinks = state[playerId]
		if not playersDiscoveredDrinks then
			warn("discoveredDrinksSlice: pickUpDrinkFromMixer failed: not playersStats")
			return state
		end

		local variationId = payload.variationId or "none"

		local drinksOfVariation = playersDiscoveredDrinks[variationId] or {}
		local drink = drinksOfVariation[payload.drinkId]
		if drink then
			-- warn(`already unlocked {payload.drinkId}`)
			return state
		end

		local newDrinksOfVariation = Set(drinksOfVariation, payload.drinkId, true)
		local newDDs = Set(playersDiscoveredDrinks, variationId, newDrinksOfVariation)
		return Set(state, playerId, newDDs)
	end,
}

return Reflex.createProducer(initialState, actions)
