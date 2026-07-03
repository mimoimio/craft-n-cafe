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
export type StatsEntity = Types.StatsEntity

export type StatsState = {
	[string]: StatsEntity,
}

export type StatsActions = {}

-- /// INITIALIZATION ///
local initialState: StatsState = {}

-- /// REDUCERS ///
local actions = {
	startPlayerSession = function(state: StatsState, playerId: string, data: PlayerData)
		return Set(state, playerId, data.Stats)
	end,
	endPlayerSession = function(state: StatsState, playerId: string, data: PlayerData)
		return RemoveKey(state, playerId)
	end,
	levelUp = function(state: StatsState, playerId: string, payload: Types.LevelUpPayload)
		local playerStats = state[playerId]
		local Level = state[playerId].Level
		return Set(
			state,
			playerId,
			Merge(playerStats, {
				Level = Level + 1,
			})
		)
	end,
	buyIngredient = function(state: StatsState, playerId: string, ingredientId: string, amount: number, cost: number)
		local playersStats = state[playerId]
		if not playersStats then
			return state
		end

		return Set(state, playerId, Set(playersStats, "Cash", playersStats.Cash - cost))
	end,
	playerReceivePayment = function(
		state: StatsState,
		playerId: string,
		payload: {
			customerUid: string,
			Cash: number,
		}
	)
		local playersStats = state[playerId]
		if not playersStats then
			return state
		end

		return Set(state, playerId, Set(playersStats, "Cash", playersStats.Cash + payload.Cash))
	end,
}

return Reflex.createProducer(initialState, actions)
