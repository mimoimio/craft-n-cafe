--!strict
-- playersSlice.luau
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
export type DrinkEntity = Types.DrinkEntity

export type TablesState = {
	[string]: DrinkEntity,
}

export type StatsActions = {}

-- /// INITIALIZATION ///
local initialState: TablesState = {}

-- /// REDUCERS ///
local actions = {
	startPlayerSession = function(state: TablesState, playerId: string, data: PlayerData)
		return Set(state, playerId, data.Drinks)
	end,
	endPlayerSession = function(state: TablesState, playerId: string, data: PlayerData)
		return RemoveKey(state, playerId)
	end,
	pickUpDrinkFromMixer = function(state: TablesState, playerId, payload)
		local new = table.clone(state[playerId])
		table.insert(new, {
			id = payload.id,
			stock = payload.stock,
			drinkId = payload.drinkId,
		})
		return Set(state, playerId, new)
	end,
}

return Reflex.createProducer(initialState, actions)
