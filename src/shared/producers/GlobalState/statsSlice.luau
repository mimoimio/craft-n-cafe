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

--[[

luck:

local luck = 1.65 -- best maxxed at 2.5, so [0.4, 2.5]
local range = 20
local chances = {}
for b=1, 1 do
	local ts = {}
	for i=1, 1000 do
		--table.insert(ts, (math.random() * math.random())^(1/luck))
		local t = (math.random() * math.random())^(1/luck)
		local num = t*range//1
		--warn(num)
		ts[`{num}`] = (ts[`{num}`] or 0) + 1
	end
	--table.insert(chances, math.max(table.unpack(ts)))
	local texts = {"\n"}
	for i=0, range-1 do
		local p = math.log( (ts[`{i}`] or 0), 1.5)//1
		local t = `{i} \t: {ts[`{i}`]} \t\t{string.rep(`[] `,p)}`
		table.insert(texts, t)
	end
	warn(table.concat(texts,"\n"))
	
end

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
}

return Reflex.createProducer(initialState, actions)
