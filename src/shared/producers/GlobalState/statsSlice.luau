--!strict
-- statsSlice.luau
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

--[[
]]

-- /// REDUCERS ///
local actions = {
	startPlayerSession = function(state: StatsState, playerId: string, data: PlayerData)
		return Set(state, playerId, data.Stats)
	end,
	endPlayerSession = function(state: StatsState, playerId: string, data: PlayerData)
		return RemoveKey(state, playerId)
	end,
	Add500 = function(state: StatsState, playerId: string)
		local playerStats = state[playerId]
		return Set(
			state,
			playerId,
			Merge(playerStats, {
				Cash = playerStats.Cash + 500000,
			})
		)
	end,
	toggleCafeOpen = function(state: StatsState, playerId: string)
		local playersStats = state[playerId]
		if not playersStats then
			return state
		end
		return Set(state, playerId, Set(playersStats, "CafeOpen", not playersStats.CafeOpen))
	end,
	toggleMusic = function(state: StatsState, playerId: string)
		local playersStats = state[playerId]
		if not playersStats then
			return state
		end
		return Set(state, playerId, Set(playersStats, "MusicOn", not playersStats.MusicOn))
	end,
	toggleSfx = function(state: StatsState, playerId: string)
		local playersStats = state[playerId]
		if not playersStats then
			return state
		end
		return Set(state, playerId, Set(playersStats, "SfxOn", not playersStats.SfxOn))
	end,
	toggleParticle = function(state: StatsState, playerId: string)
		local playersStats = state[playerId]
		if not playersStats then
			return state
		end
		return Set(state, playerId, Set(playersStats, "ParticleOn", not playersStats.ParticleOn))
	end,
	setMusicVolume = function(state: StatsState, playerId: string, volume: number)
		local playersStats = state[playerId]
		if not playersStats then
			return state
		end
		return Set(state, playerId, Set(playersStats, "MusicVolume", volume))
	end,
	setSfxVolume = function(state: StatsState, playerId: string, volume: number)
		local playersStats = state[playerId]
		if not playersStats then
			return state
		end
		return Set(state, playerId, Set(playersStats, "MusicVolume", volume))
	end,
	completeTutorial = function(state: StatsState, playerId: string)
		local playersStats = state[playerId]
		if not playersStats then
			return state
		end
		return Set(state, playerId, Set(playersStats, "TutorialCompleted", true))
	end,
	buyIngredient = function(
		state: StatsState,
		playerId: string,
		payload: { ingredientId: string, amount: number, cost: number }
	)
		local playersStats = state[playerId]
		if not playersStats then
			return state
		end

		return Set(state, playerId, Set(playersStats, "Cash", playersStats.Cash - payload.cost))
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

	serveCustomer = function(state: StatsState, playerId: string, payload: Types.ServeCustomerPayload)
		-- empties the cup
		local playersStats = state[playerId]
		if not playersStats then
			return state
		end
		return Set(
			state,
			playerId,
			Merge(playersStats, {
				Cash = playersStats.Cash + payload.cash,
				EXP = payload.EXP,
				Level = payload.level,
			})
		)
	end,
	buyItem = function(state, playerId: string, payload: Types.BuyItemPayload)
		local nextState = table.clone(state)
		local playerStats = table.clone(nextState[playerId])

		-- Deduct the cash
		playerStats.Cash = math.max(0, playerStats.Cash - payload.totalCost)

		nextState[playerId] = playerStats
		return nextState
	end,
	expandPlot = function(state, playerId: string, payload: Types.ExpandPlotPayload)
		local nextState = table.clone(state)
		local playerStats = table.clone(nextState[playerId])

		playerStats.Cash = math.max(0, playerStats.Cash - payload.cost)

		nextState[playerId] = playerStats
		return nextState
	end,
}

return Reflex.createProducer(initialState, actions)
