-- cashiersSlice.luau
--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Reflex = require(ReplicatedStorage.Packages.Reflex)
local Sift = require(ReplicatedStorage.Packages.Sift)
local Types = require(ReplicatedStorage.Shared.Types)

local Dictionary = Sift.Dictionary
local Set = Dictionary.set
local Merge = Dictionary.merge
local RemoveKey = Dictionary.removeKey

-- /// TYPES ///
type PlayerData = Types.PlayerData
export type WorkersState = Types.WorkersState

-- /// INITIALIZATION ///
local initialState: WorkersState = {}

-- /// REDUCERS ///
local actions = {
	startPlayerSession = function(state: WorkersState, playerId: string, data: PlayerData)
		return Set(state, playerId, data.Cashiers)
	end,
	endPlayerSession = function(state: WorkersState, playerId: string)
		return RemoveKey(state, playerId)
	end,
	hireCashier = function(state: WorkersState, playerId: string, payload: Types.HireCashierPayload)
		local cashiers = state[playerId]
		if not cashiers then
			return state
		end

		return Set(state, playerId, Sift.Array.insert(cashiers, #cashiers + 1, { id = payload.id, lastTend = 0 }))
	end,
	fireCashier = function(state: WorkersState, playerId: string, payload: Types.FireCashierPayload)
		local cashiers = state[playerId]
		if not cashiers then
			return state
		end

		local id, cashier
		for i, _cashier in cashiers do
			if _cashier.id == payload.cashierUid then
				cashier = _cashier
				id = i
				break
			end
		end
		if not cashier then
			return state
		end

		return Set(state, playerId, Sift.Array.removeIndex(cashiers, id))
	end,
	playerReceivePayment = function(state: WorkersState, playerId: string, payload: Types.PaymentPayload)
		local cashiers = state[playerId]
		if not cashiers then
			return state
		end
		local id, cashier
		for i, _cashier in cashiers do
			if _cashier.id == payload.cashierUid then
				cashier = _cashier
				id = i
				break
			end
		end
		if not cashier then
			return state
		end

		return Set(state, playerId, Set(cashiers, id, Set(cashier, "lastTend", payload.timestamp)))
	end,
}

return Reflex.createProducer(initialState, actions)
