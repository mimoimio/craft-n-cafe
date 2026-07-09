--!strict
-- shopsSlice.luau
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

export type ShopState = Types.ShopState

-- /// INITIALIZATION ///
local initialState: ShopState = {}

-- /// REDUCERS ///
local actions = {
	startPlayerSession = function(
		state: ShopState,
		playerId: string,
		data: PlayerData,
		payload: Types.StartPlayerSessionPayload
	)
		local newestSeed = payload.newestSeed
		local cycleSynced
		for seed, shopEntity in data.Shop do
			if newestSeed == seed then
				cycleSynced = true
				continue
			end
			data.Shop[seed] = nil
		end

		if not cycleSynced then
			data.Shop[newestSeed] = payload.newestShop
		end
		return Set(state, playerId, data.Shop)
	end,
	endPlayerSession = function(state: ShopState, playerId: string, data: PlayerData)
		return RemoveKey(state, playerId)
	end,
	refreshShop = function(state: ShopState, playerId, payload: Types.RefreshShopPayload)
		local playersShop = state[playerId]

		return state
	end,
}

return Reflex.createProducer(initialState, actions)
