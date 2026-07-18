--!strict
-- mixersSlice.luau
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

export type MixersState = Types.MixersState

-- /// INITIALIZATION ///
local initialState: MixersState = {}

-- /// REDUCERS ///
local actions = {
	startPlayerSession = function(state: MixersState, playerId: string, data: PlayerData)
		return Set(state, playerId, data.Mixers)
	end,
	endPlayerSession = function(state: MixersState, playerId: string, data: PlayerData)
		return RemoveKey(state, playerId)
	end,
	mixDrink = function(state: MixersState, playerId: string, payload: Types.MixDrinkPayload)
		local playersMixers = state[playerId]
		if not playersMixers then
			return state
		end
		local mixerId: string = payload.mixer
		local oldMixer = playersMixers[mixerId]

		local mixer = {}
		mixer.drinkId = payload.drinkId
		mixer.startTime = payload.startTime
		mixer.variationId = payload.variationId

		return Set(state, playerId, Set(playersMixers, mixerId, mixer))
	end,
	pickUpDrinkFromMixer = function(state: MixersState, playerId: string, payload: Types.PickUpPayload)
		local playersMixers = state[playerId]
		if not playersMixers then
			return state
		end
		local mixerId: string = payload.mixer
		local newMixer = Merge(playersMixers[mixerId], {
			drinkId = "none",
		})
		newMixer.startTime = nil
		return Set(state, playerId, Set(playersMixers, mixerId, newMixer))
	end,
	levelUp = function(state: MixersState, playerId: string, payload: Types.LevelUpPayload)
		local playerMixers = state[playerId]
		if not playerMixers then
			warn(`player {playerId}'s Mixers not found`)
			return state
		end

		local newMixers = {}
		for i, mixer: string in payload.unlockedMixers do
			newMixers[mixer] = {
				drinkId = "none",
			}
		end

		return Set(state, playerId, Merge(playerMixers, newMixers))
	end,
}

return Reflex.createProducer(initialState, actions)
