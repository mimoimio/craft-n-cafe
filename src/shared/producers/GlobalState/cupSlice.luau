--!strict
-- cupslice.luau
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

export type CupState = Types.CupState

-- /// INITIALIZATION ///
local initialState: CupState = {}

-- /// REDUCERS ///
local actions = {
	startPlayerSession = function(state: CupState, playerId: string, data: PlayerData)
		return Set(state, playerId, data.Cup)
	end,
	endPlayerSession = function(state: CupState, playerId: string, data: PlayerData)
		return RemoveKey(state, playerId)
	end,
}

return Reflex.createProducer(initialState, actions)
