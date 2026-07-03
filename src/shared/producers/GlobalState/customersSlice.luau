--!strict
-- customersSlice.luau
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Reflex = require(ReplicatedStorage.Packages.Reflex)
local Sift = require(ReplicatedStorage.Packages.Sift)
local Types = require(ReplicatedStorage.Shared.Types)

local Dictionary = Sift.Dictionary
local Array = Sift.Array
local Update = Array.update
local Insert = Array.insert
local Merge = Dictionary.merge
local Set = Dictionary.set
local RemoveKey = Dictionary.removeKey

-- /// TYPES ///
type PlayerData = Types.PlayerData
export type CustomerEntity = Types.CustomerEntity
export type CustomersState = Types.CustomersState

export type StatsActions = {}

-- /// INITIALIZATION ///
local initialState: CustomersState = {}

-- /// REDUCERS ///
local actions = {
	startPlayerSession = function(state: CustomersState, playerId: string, data: PlayerData)
		return Set(state, playerId, data.Customers)
	end,
	endPlayerSession = function(state: CustomersState, playerId: string, data: PlayerData)
		return RemoveKey(state, playerId)
	end,
	spawnCustomer = function(state: CustomersState, playerId: string, payload: Types.SpawnCustomerPayload)
		local playersCustomers = state[playerId]
		if not playersCustomers then
			return state
		end
		local new = Set(
			state,
			playerId,
			Insert(playersCustomers, #playersCustomers + 1, {
				id = payload.customerUid,
				customerId = payload.customerId,
			})
		)
		return new
	end,
	customerTakeItems = function(state: CustomersState, playerId: string, payload: Types.CustomerItemPayload)
		local playersCustomers = state[playerId]
		if not playersCustomers then
			return state
		end

		local index
		for i, customer in playersCustomers do
			if customer.id == payload.customerUid then
				index = i
				break
			end
		end
		local new = Set(
			state,
			playerId,
			Update(playersCustomers, index, function(customer: Types.CustomerEntity, i)
				local new = table.clone(customer)
				new.drinkIds = payload.drinkIds
				return new
			end)
		)
		return new
	end,
	playerReceivePayment = function(
		state: CustomersState,
		playerId: string,
		payload: {
			customerUid: string,
			Cash: number,
		}
	)
		local playersCustomers = state[playerId]
		if not playersCustomers then
			return state
		end
		local index
		for i, customer in playersCustomers do
			if customer.id == payload.customerUid then
				index = i
				break
			end
		end
		return Set(
			state,
			playerId,
			Update(playersCustomers, index, function(customer: Types.CustomerEntity, i)
				local new = table.clone(customer)
				new.drinkIds = nil
				return new
			end)
		)
	end,
	removeCustomer = function(state: CustomersState, playerId: string, uid: string)
		local playersCustomers = state[playerId]
		if not playersCustomers then
			return state
		end
		local index
		for i, customer in playersCustomers do
			if customer.id == uid then
				index = i
				break
			end
		end
		return Set(state, playerId, Array.removeIndex(playersCustomers, index))
	end,
}

return Reflex.createProducer(initialState, actions)
