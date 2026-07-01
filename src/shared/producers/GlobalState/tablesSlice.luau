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
export type TableEntity = Types.TableEntity

export type TablesState = {
	[string]: TableEntity,
}

export type StatsActions = {}

-- /// INITIALIZATION ///
local initialState: TablesState = {}

-- /// REDUCERS ///
local actions = {
	startPlayerSession = function(state: TablesState, playerId: string, data: PlayerData)
		return Set(state, playerId, data.Tables)
	end,
	endPlayerSession = function(state: TablesState, playerId: string, data: PlayerData)
		return RemoveKey(state, playerId)
	end,
	setDrink = function(state: TablesState, playerId)
		local new = table.clone(state[playerId])
		return Set(state, playerId, Set(new, "Table1", Set(new.Table1, "Slots", Set(new.Table1.Slots, "Slot1", "abc"))))
	end,
}

return Reflex.createProducer(initialState, actions)
