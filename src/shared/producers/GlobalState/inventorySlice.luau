-- Shared/producers/inventorySlice.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Reflex = require(ReplicatedStorage.Packages.Reflex)
local Types = require(ReplicatedStorage.Shared.Types)

local initialState: Types.InventoryState = {}

local inventorySlice = Reflex.createProducer(initialState, {
	startPlayerSession = function(state, playerId: string, data: Types.PlayerData)
		local nextState = table.clone(state)
		nextState[playerId] = data.Inventory or {}
		return nextState
	end,

	endPlayerSession = function(state, playerId: string)
		local nextState = table.clone(state)
		nextState[playerId] = nil
		return nextState
	end,

	-- When a player buys an item, add it to their inventory
	buyItem = function(state, playerId: string, payload: Types.BuyItemPayload)
		local nextState = table.clone(state)
		local playerInventory = table.clone(nextState[playerId] or {})

		local currentAmount = playerInventory[payload.itemId] or 0
		playerInventory[payload.itemId] = currentAmount + payload.amount

		nextState[playerId] = playerInventory
		return nextState
	end,

	-- When a player places an item, deduct it from their inventory
	placeItem = function(state, playerId: string, payload: Types.PlaceItemPayload)
		local nextState = table.clone(state)
		local playerInventory = table.clone(nextState[playerId] or {})

		local currentAmount = playerInventory[payload.itemId] or 0
		playerInventory[payload.itemId] = math.max(0, currentAmount - 1)

		nextState[playerId] = playerInventory
		return nextState
	end,

	-- When a player deletes an item from the plot, return it to their inventory
	destroyItem = function(state, playerId: string, payload: Types.DestroyItemPayload)
		local nextState = table.clone(state)
		local playerInventory = table.clone(nextState[playerId] or {})

		local currentAmount = playerInventory[payload.itemId] or 0
		playerInventory[payload.itemId] = currentAmount + 1

		nextState[playerId] = playerInventory
		return nextState
	end,
})

return inventorySlice
