-- dailySlice.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Reflex = require(ReplicatedStorage.Packages.Reflex)
local Sift = require(ReplicatedStorage.Packages.Sift)
local Dictionary = Sift.Dictionary
local Set = Dictionary.set
local Merge = Dictionary.merge
local RemoveKey = Dictionary.removeKey

local Types = require(ReplicatedStorage.Shared.Types)

local initialState = {}
export type DailyState = Types.DailyState

local actions = {
	startPlayerSession = function(state: DailyState, playerId: string, data: Types.PlayerData)
		return Set(state, playerId, data.Daily)
	end,
	endPlayerSession = function(state: DailyState, playerId: string)
		return RemoveKey(state, playerId)
	end,
	claimDailyReward = function(state: DailyState, playerId: string, payload: Types.DailyClaimPayload)
		local playerStats = state[playerId]
		return Set(
			state,
			playerId,
			Merge(playerStats, {
				lastClaimedDaily = payload.lastClaimedDaily,
				day = payload.nextDay,
			})
		)
	end,
	updateDailyDay = function(state: DailyState, playerId: string, today: number)
		local playerStats = state[playerId]
		if not playerStats then
			return state
		end
		return Set(
			state,
			playerId,
			Merge(playerStats, {
				today = today,
			})
		)
	end,
}

return Reflex.createProducer(initialState, actions)
