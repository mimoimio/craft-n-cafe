--!strict
-- cupsSlice.luau
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
export type CupEntity = Types.CupEntity

export type CupsState = Types.CupsState

export type StatsActions = {}

-- /// INITIALIZATION ///
local initialState: CupsState = {}

--[[
]]

-- /// REDUCERS ///
local actions = {
	startPlayerSession = function(state: CupsState, playerId: string, data: PlayerData)
		-- warn("stats", state)
		return Set(state, playerId, data.Cups)
	end,
	endPlayerSession = function(state: CupsState, playerId: string, data: PlayerData)
		return RemoveKey(state, playerId)
	end,
	serveCustomer = function(state: CupsState, playerId: string, payload: Types.ServeCustomerPayload)
		-- empties the cup
		local playersCups = state[playerId]
		if not playersCups then
			return state
		end
		local workerUid = payload.workerUid or "player"
		return Set(state, playerId, Set(playersCups, workerUid, nil))
	end,
	wrongOrder = function(state: CupsState, playerId: string, payload: Types.WrongOrderPayload)
		-- empties the cup
		local playersCups = state[playerId]
		if not playersCups then
			return state
		end
		local workerUid = payload.workerUid or "player"
		return Set(state, playerId, Set(playersCups, workerUid, nil))
	end,
	trashCup = function(state: CupsState, playerId: string, payload: Types.TrashCupPayload)
		-- empties the cup
		local playersCups = state[playerId]
		if not playersCups then
			return state
		end
		local workerUid = payload.workerUid or "player"
		return Set(state, playerId, Set(playersCups, workerUid, nil))
	end,
	getCup = function(state: CupsState, playerId: string, workerUid)
		local playersCups = state[playerId]
		if not playersCups then
			return state
		end

		workerUid = workerUid or "player"
		return Set(
			state,
			playerId,
			Set(playersCups, workerUid, {
				drinkId = "none",
				score = 0,
			})
		)
	end,
	addIngredient = function(state: CupsState, playerId: string, payload: Types.AddIngredientPayload)
		local playersCups = state[playerId]
		if not playersCups then
			return state
		end

		local workerUid = payload.workerUid or "player"
		return Set(
			state,
			playerId,
			Set(playersCups, workerUid, {
				drinkId = payload.newDrinkId,
				score = 3,
			})
		)
	end,
}

return Reflex.createProducer(initialState, actions)
