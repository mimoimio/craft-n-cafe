-- Shared/producers/statsSlice.luau
--!strict
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
		local stats = table.clone(data.Stats)
		stats.PlayerPhase = "mainMenu"
		stats.Upgrades = stats.Upgrades and table.clone(stats.Upgrades) or {}
		return Set(state, playerId, stats)
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
		return Set(state, playerId, Set(playersStats, "SfxVolume", volume))
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
	setPlayerPhase = function(state: StatsState, playerId: string, playerPhase: Types.PlayerPhase)
		local playersStats = state[playerId]
		if not playersStats then
			return state
		end

		return Set(state, playerId, Set(playersStats, "PlayerPhase", playerPhase))
	end,

	serveCustomer = function(state: StatsState, playerId: string, payload: Types.ServeCustomerPayload)
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
				CustomersServed = (playersStats.CustomersServed or 0) + 1,
			})
		)
	end,
	buyItem = function(state: StatsState, playerId: string, payload: Types.BuyItemPayload)
		local playersStats = state[playerId]
		if not playersStats then
			return state
		end

		return Set(state, playerId, Set(playersStats, "Cash", math.max(0, playersStats.Cash - payload.totalCost)))
	end,
	expandPlot = function(state: StatsState, playerId: string, payload: Types.ExpandPlotPayload)
		local playersStats = state[playerId]
		if not playersStats then
			return state
		end

		return Set(state, playerId, Set(playersStats, "Cash", math.max(0, playersStats.Cash - payload.cost)))
	end,
	buyUpgrade = function(state: StatsState, playerId: string, payload: Types.BuyUpgradePayload)
		local playersStats = state[playerId]
		if not playersStats then
			return state
		end

		local currentUpgrades = playersStats.Upgrades or {}
		local currentLevel = currentUpgrades[payload.upgradeId] or 0
		local nextUpgrades = Set(currentUpgrades, payload.upgradeId, currentLevel + 1)

		return Set(
			state,
			playerId,
			Merge(playersStats, {
				Cash = math.max(0, playersStats.Cash - payload.cost),
				Upgrades = nextUpgrades,
			})
		)
	end,
	upgradeWorker = function(state: StatsState, playerId: string, payload: Types.UpgradeWorkerPayload)
		local playersStats = state[playerId]
		if not playersStats then
			return state
		end

		return Set(state, playerId, Set(playersStats, "Cash", math.max(0, playersStats.Cash - payload.cost)))
	end,
	_addExp = function(state: StatsState, playerId: string, exp, lvl)
		local playersStats = state[playerId]
		if not playersStats then
			return state
		end

		return Set(
			state,
			playerId,
			Merge(playersStats, {
				EXP = exp,
				Level = lvl,
			})
		)
	end,
}

return Reflex.createProducer(initialState, actions)