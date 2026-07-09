--!strict
-- unlockedIngredientsSlice.luau
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

export type UnlockedIngredientsState = Types.UnlockedIngredientsState

export type StatsActions = {}

-- /// INITIALIZATION ///
local initialState: UnlockedIngredientsState = {}

-- /// REDUCERS ///
local actions = {
	startPlayerSession = function(state: UnlockedIngredientsState, playerId: string, data: PlayerData)
		return Set(state, playerId, data.UnlockedIngredients)
	end,
	endPlayerSession = function(state: UnlockedIngredientsState, playerId: string, data: PlayerData)
		return RemoveKey(state, playerId)
	end,
	levelUp = function(state: UnlockedIngredientsState, playerId: string, payload: Types.LevelUpPayload)
		local playerStats = state[playerId]
		if not playerStats then
			warn("unlockedIngredientsSlice failed: levelUp: not playersStats")
			return state
		end
		return Set(state, playerId, Merge(playerStats, payload.unlockedIngredients))
	end,
}

return Reflex.createProducer(initialState, actions)
