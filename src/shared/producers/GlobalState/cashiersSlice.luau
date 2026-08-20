-- cashiersSlice.luau
--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Reflex = require(ReplicatedStorage.Packages.Reflex)
local Sift = require(ReplicatedStorage.Packages.Sift)
local Types = require(ReplicatedStorage.Shared.Types)

local Dictionary = Sift.Dictionary
local Set = Dictionary.set
local Merge = Dictionary.merge
local RemoveKey = Dictionary.removeKey

-- /// TYPES ///
type PlayerData = Types.PlayerData
export type CashiersState = Types.CashiersState

-- /// INITIALIZATION ///
local initialState: CashiersState = {}

-- /// REDUCERS ///
local actions = {
	startPlayerSession = function(state: CashiersState, playerId: string, data: PlayerData)
		return Set(state, playerId, data.Customers)
	end,
	endPlayerSession = function(state: CashiersState, playerId: string)
		return RemoveKey(state, playerId)
	end,
}

return Reflex.createProducer(initialState, actions)
