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
	levelUp = function(state: StatsState, playerId: string, payload: Types.LevelUpPayload)
		local playerStats = state[playerId]
		return Set(
			state,
			playerId,
			Merge(playerStats, {
				Level = payload.level,
				Cash = playerStats.Cash - payload.cost,
				MaxCustomersAtOnce = 4 + payload.level,
				MaxDrinksPerCustomer = 2 + payload.level,
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
	claimShelfCollector = function(state: StatsState, playerId: string, payload: Types.ClaimShelfCollectorPayload)
		local playersStats = state[playerId]
		if not playersStats then
			return state
		end

		return Set(state, playerId, Set(playersStats, "Cash", playersStats.Cash + payload.amount))
	end,
	buyIngredientFromSpawner = function(
		state: StatsState,
		playerId: string,
		payload: Types.BuyIngredientFromSpawnerPayload
	)
		local playersStats = state[playerId]
		if not playersStats then
			return state
		end

		return Set(state, playerId, Set(playersStats, "Cash", playersStats.Cash - payload.cost))
	end,
	buyMixer = function(state: StatsState, playerId: string, payload: Types.BuyMixerPayload)
		local playersStats = state[playerId]
		if not playersStats then
			return state
		end

		return Set(state, playerId, Set(playersStats, "Cash", playersStats.Cash - payload.cost))
	end,
	upgradeLuck = function(state: StatsState, playerId: string, payload: Types.UpgradeLuckPayload)
		local playersStats = state[playerId]
		if not playersStats then
			return state
		end

		return Set(
			state,
			playerId,
			Merge(playersStats, {
				Luck = (playersStats.Luck or 1) + payload.increment,
				Cash = playersStats.Cash - payload.cost,
			})
		)
	end,
	upgradeCafeCapacity = function(state: StatsState, playerId: string, payload: Types.UpgradeCafeCapacityPayload)
		local playersStats = state[playerId]
		if not playersStats then
			return state
		end

		return Set(
			state,
			playerId,
			Merge(playersStats, {
				CafeCapacity = (playersStats.CafeCapacity or 1) + payload.increment,
				Cash = playersStats.Cash - payload.cost,
			})
		)
	end,
	shortenRoll = function(state: StatsState, playerId: string)
		local playersStats = state[playerId]
		if not playersStats then
			return state
		end

		return Set(state, playerId, Set(playersStats, "RollCooldown", 1))
	end,
	setPendingSkipMixer = function(state: StatsState, playerId: string, payload: Types.SetPendingSkipMixerPayload)
		local playersStats = state[playerId]
		if not playersStats then
			return state
		end
		return Set(state, playerId, Set(playersStats, "PendingSkipMixer", payload.mixer))
	end,

	addSkipTickets = function(state: StatsState, playerId: string, payload: Types.AddSkipTicketsPayload)
		local playersStats = state[playerId]
		if not playersStats then
			return state
		end
		return Set(state, playerId, Set(playersStats, "SkipTickets", (playersStats.SkipTickets or 0) + payload.amount))
	end,

	consumeSkipTicket = function(state: StatsState, playerId: string)
		local playersStats = state[playerId]
		if not playersStats or (playersStats.SkipTickets or 0) <= 0 then
			return state
		end
		return Set(state, playerId, Set(playersStats, "SkipTickets", playersStats.SkipTickets - 1))
	end,
	-- Add to your actions table:
	setOwnedGamePasses = function(state: StatsState, playerId: string, payload: Types.SetGamePassesPayload)
		local playersStats = state[playerId]
		if not playersStats then
			return state
		end
		return Set(
			state,
			playerId,
			Merge(playersStats, {
				OwnedGamePasses = payload.passes,
			})
		)
	end,

	grantGamePass = function(state: StatsState, playerId: string, payload: Types.GrantGamePassPayload)
		local playersStats = state[playerId]
		if not playersStats then
			return state
		end

		local currentPasses = playersStats.OwnedGamePasses or {}
		local updatedPasses = Merge(currentPasses, {
			[payload.passId] = true,
		})

		return Set(state, playerId, Set(playersStats, "OwnedGamePasses", updatedPasses))
	end,
}

return Reflex.createProducer(initialState, actions)
