-- Shared/producers/customersSlice.luau
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

type PlayerData = Types.PlayerData
export type CustomerEntity = Types.CustomerEntity
export type CustomersState = Types.CustomersState

local initialState: CustomersState = {}

local actions = {
	startPlayerSession = function(state: CustomersState, playerId: string, data: PlayerData)
		return Set(state, playerId, data.Customers)
		-- return Set(state, playerId, {})
	end,
	endPlayerSession = function(state: CustomersState, playerId: string, data: PlayerData)
		return RemoveKey(state, playerId)
	end,
	spawnCustomer = function(state: CustomersState, playerId: string, payload: Types.SpawnCustomerPayload)
		local playersCustomers = state[playerId] or {}
		return Set(
			state,
			playerId,
			Insert(playersCustomers, #playersCustomers + 1, {
				id = payload.customerUid,
				customerId = payload.customerId,
				customerAction = "entering",
				actionStartTime = payload.timestamp,
			})
		)
	end,
	customerTakeItems = function(state: CustomersState, playerId: string, payload: Types.CustomerItemPayload)
		local playersCustomers = state[playerId] or {}

		local index
		for i, customer in playersCustomers do
			if customer.id == payload.customerUid then
				index = i
				break
			end
		end
		if not index then
			return state
		end

		return Set(
			state,
			playerId,
			Update(playersCustomers, index, function(customer: Types.CustomerEntity)
				local new = table.clone(customer)
				new.drinkEntities = payload.drinkEntities
				new.customerAction = "walking"
				new.actionStartTime = payload.timestamp
				return new
			end)
		)
	end,
	queueCustomer = function(state: CustomersState, playerId: string, payload: Types.QueueCustomerPayload)
		local playersCustomers = state[playerId] or {}
		local index
		for i, customer in playersCustomers do
			if customer.id == payload.customerUid then
				index = i
				break
			end
		end
		if not index then
			return state
		end

		return Set(
			state,
			playerId,
			Update(playersCustomers, index, function(customer: Types.CustomerEntity)
				local new = table.clone(customer)
				new.customerAction = "queuing"
				new.actionStartTime = payload.timestamp
				return new
			end)
		)
	end,
	playerReceivePayment = function(
		state: CustomersState,
		playerId: string,
		payload: { customerUid: string, Cash: number, timestamp: number }
	)
		local playersCustomers = state[playerId] or {}

		local index
		for i, customer in playersCustomers do
			if customer.id == payload.customerUid then
				index = i
				break
			end
		end
		if not index then
			return state
		end

		return Set(
			state,
			playerId,
			Update(playersCustomers, index, function(customer: Types.CustomerEntity)
				local new = table.clone(customer)
				new.drinkEntities = nil
				new.customerAction = "paid"
				new.actionStartTime = payload.timestamp
				return new
			end)
		)
	end,
	customerLeaveEmptyHanded = function(
		state: CustomersState,
		playerId: string,
		payload: { customerUid: string, timestamp: number }
	)
		local playersCustomers = state[playerId] or {}

		local index
		for i, customer in playersCustomers do
			if customer.id == payload.customerUid then
				index = i
				break
			end
		end
		if not index then
			return state
		end

		return Set(
			state,
			playerId,
			Update(playersCustomers, index, function(customer: Types.CustomerEntity)
				local new = table.clone(customer)
				new.drinkEntities = nil
				new.customerAction = "emptyHanded"
				new.actionStartTime = payload.timestamp
				return new
			end)
		)
	end,
	removeCustomer = function(state: CustomersState, playerId: string, uid: string)
		local playersCustomers = state[playerId] or {}

		local index
		for i, customer in playersCustomers do
			if customer.id == uid then
				index = i
				break
			end
		end

		if index then
			return Set(state, playerId, Array.removeIndex(playersCustomers, index))
		end
		return state
	end,
}

return Reflex.createProducer(initialState, actions)
