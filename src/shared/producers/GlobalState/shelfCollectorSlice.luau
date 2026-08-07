-- producers/shelfCollectorSlice.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Reflex = require(ReplicatedStorage.Packages.Reflex)
local Sift = require(ReplicatedStorage.Packages.Sift)
local Types = require(ReplicatedStorage.Shared.Types)

local Dictionary = Sift.Dictionary
local Set = Dictionary.set
local RemoveKey = Dictionary.removeKey

-- /// TYPES ///
type PlayerData = Types.PlayerData
export type ShelfCollectorState = Types.ShelfCollectorState

local initialState: ShelfCollectorState = {}

local actions = {
	startPlayerSession = function(state: ShelfCollectorState, playerId: string, data: PlayerData)
		-- Ensure the profile has this data, fallback to now if new
		local collectorData = data.ShelfCollector or { LastClaimTime = workspace:GetServerTimeNow() }
		return Set(state, playerId, collectorData)
	end,

	endPlayerSession = function(state: ShelfCollectorState, playerId: string, data: PlayerData)
		return RemoveKey(state, playerId)
	end,

	claimShelfCollector = function(
		state: ShelfCollectorState,
		playerId: string,
		payload: Types.ClaimShelfCollectorPayload
	)
		local playerCollector = state[playerId]
		if not playerCollector then
			return state
		end

		local newCollector = Set(playerCollector, "LastClaimTime", payload.timestamp)
		return Set(state, playerId, newCollector)
	end,
}

return Reflex.createProducer(initialState, actions)
