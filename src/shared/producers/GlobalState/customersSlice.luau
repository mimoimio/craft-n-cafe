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
	end,
	endPlayerSession = function(state: CustomersState, playerId: string, data: PlayerData)
		return RemoveKey(state, playerId)
	end,
	spawnCustomer = function(state: CustomersState, playerId: string, payload: Types.SpawnCustomerPayload)
		local playersCustomers = state[playerId] or {}

		-- FIX: Map targetCounterUuid from the payload to the state
		return Set(
			state,
			playerId,
			Insert(playersCustomers, #playersCustomers + 1, {
				id = payload.customerUid,
				customerId = payload.customerId,
				targetCounterUuid = payload.targetCounterUuid,
				customerAction = "walking",
				actionStartTime = payload.timestamp,
			})
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
	takeCustomerOrder = function(state: CustomersState, playerId: string, payload: Types.TakeCustomerOrderPayload)
		local playersCustomers = state[playerId]
		if not playersCustomers then
			warn("not players customers")
			return state
		end
		local index
		for i, customer in playersCustomers do
			if customer.id == payload.customerUid then
				index = i
				break
			end
		end
		if not index then
			warn("not index")
			return state
		end
		return Set(
			state,
			playerId,
			Update(playersCustomers, index, function(customer: Types.CustomerEntity)
				local new = table.clone(customer)
				new.customerAction = "waiting"
				new.servedBy = payload.workerUid or "player"
				new.actionStartTime = payload.timestamp
				new.order = payload.order
				return new
			end)
		)
	end,
	serveCustomer = function(
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
				new.customerAction = "paid"
				new.servedBy = nil
				new.actionStartTime = payload.timestamp
				return new
			end)
		)
	end,
	wrongOrder = function(state: CustomersState, playerId: string, payload: { customerUid: string, timestamp: number })
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

		local newCustomers = Update(playersCustomers, index, function(customer: Types.CustomerEntity)
			local new = table.clone(customer)
			new.customerAction = "emptyHanded"
			new.actionStartTime = payload.timestamp
			new.servedBy = nil
			new.order = nil
			return new
		end)

		return Set(state, playerId, newCustomers)
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
