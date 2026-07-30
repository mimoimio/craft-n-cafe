--!strict
-- spawnerSlice.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Reflex = require(ReplicatedStorage.Packages.Reflex)
local Sift = require(ReplicatedStorage.Packages.Sift)
local Types = require(ReplicatedStorage.Shared.Types)

local Dictionary = Sift.Dictionary
local Merge = Dictionary.merge
local Set = Dictionary.set
local RemoveKey = Dictionary.removeKey

-- /// TYPES ///
type PlayerData = Types.PlayerData
export type SpawnerState = Types.SpawnerState

type PlayerId = string

export type StatsActions = {}

-- /// INITIALIZATION ///
local initialState: SpawnerState = {}

-- /// REDUCERS ///
local actions = {
	startPlayerSession = function(state: SpawnerState, playerId: string, data: PlayerData)
		return Set(state, playerId, data.Spawner)
	end,
	endPlayerSession = function(state: SpawnerState, playerId: string, data: PlayerData)
		return RemoveKey(state, playerId)
	end,
	rollIngredient = function(state: SpawnerState, playerId: string, payload: Types.RollIngredientPayload)
		local playersSpawner = state[playerId]
		return Set(
			state,
			playerId,
			Merge(playersSpawner, {
				IngredientIds = payload.ingredientIds,
				TimePulled = payload.timePulled,
			})
		)
	end,
	buyIngredientFromSpawner = function(
		state: SpawnerState,
		playerId: string,
		payload: Types.BuyIngredientFromSpawnerPayload
	)
		local playersSpawner = state[playerId]
		return Set(state, playerId, Set(playersSpawner, "IngredientIds", {}))
	end,
}

return Reflex.createProducer(initialState, actions)
