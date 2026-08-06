-- TablesService.luau
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local CoffeeModule = require(ReplicatedStorage.Shared.CoffeeModule)

local log = function(message: string)
	warn(`[TablesService]: {message}`)
end

local TablesService = {}

function TablesService.PlaceDrink(player: Player, drinkUid: string?, tableUid: string, slot: string)
	if not (tableUid and slot) then
		log(`PlaceDrink Failed: tableUid({tostring(tableUid)}) or slot({tostring(slot)}) is nil`)
		return
	end
	local typeDrink = type(drinkUid)
	if not (typeDrink == "string" or typeDrink == "nil") then
		log(`PlaceDrink Failed: drinkUid expected string or nil, got {typeDrink}`)
		return
	end

	local playerId = tostring(player.UserId)

	local validSlot = slot == "Slot1" or slot == "Slot2" or slot == "Slot3" or slot == "Slot4"
	if not validSlot then
		log(`PlaceDrink Failed: {slot} is not a valid slot`)
		return
	end

	-- ensure player
	local state = GlobalState:getState()
	local playersDrinks = state.Drinks[playerId]
	local playersTables = state.Tables[playerId]

	if not playersDrinks then
		log(`PlaceDrink Failed: player({playerId})'s Drinks not found`)
		return
	end
	if not playersTables or not playersTables[tableUid] then
		log(`PlaceDrink Failed: player({playerId})'s Tables not found`)
		return
	end

	-- ensuring player has the drink
	local found
	if drinkUid == nil then
		found = true
	else
		for i, drink in playersDrinks do
			found = drink.id == drinkUid
			if found then
				break
			end
		end
	end
	if not found then
		log(`PlaceDrink Failed: drinkUid ({drinkUid}) is not found in player's Drinks`)
		return
	end
	GlobalState.placeDrinkToTableSlot(playerId, {
		drinkUid = drinkUid,
		tableUid = tableUid,
		slot = slot,
	})
end

function TablesService.Restock(player: Player)
	local playerId = tostring(player.UserId)
	local state = GlobalState:getState()

	local drinks = state.Drinks[playerId]
	local tables = state.Tables[playerId]

	if not drinks or not tables then
		log(`Restock Failed: player({playerId})'s Drinks or Tables not found`)
		return
	end

	-- 1. Find all placed drink UIDs
	local placedUids = {}
	for _, tableEntity in tables do
		for _, drinkUid in tableEntity.Slots do
			if drinkUid ~= "none" then
				placedUids[drinkUid] = true
			end
		end
	end

	-- 2. Map placed drinks to their signature (drinkId + variationId)
	-- We only store the first one we find to merge everything into it.
	local placedSignatureMap = {}
	for _, drink in drinks do
		if placedUids[drink.id] then
			local signature = `{drink.drinkId}_{tostring(drink.variationId)}`
			if not placedSignatureMap[signature] then
				placedSignatureMap[signature] = drink.id
			end
		end
	end

	-- 3. Calculate stock additions and removals
	local stockToAdd = {}
	local drinksToRemove = {}
	local hasChanges = false

	for _, drink in drinks do
		if not placedUids[drink.id] then
			-- This is an unplaced drink
			local signature = `{drink.drinkId}_{tostring(drink.variationId)}`
			local targetPlacedUid = placedSignatureMap[signature]

			-- If there is a matching placed drink, we merge the stock
			if targetPlacedUid then
				stockToAdd[targetPlacedUid] = (stockToAdd[targetPlacedUid] or 0) + drink.stock
				drinksToRemove[drink.id] = true
				hasChanges = true
			end
		end
	end

	-- 4. Dispatch the action if we have valid merges
	if hasChanges then
		GlobalState.restockDrinks(playerId, {
			stockToAdd = stockToAdd,
			drinksToRemove = drinksToRemove,
		})
	else
		log(`Restock: No unplaced drinks matched with placed drinks for player({playerId})`)
	end
end

-- Remember to connect this function to a RemoteEvent in initialize()

function TablesService.initialize()
	Remotes.PlaceDrink.OnServerEvent:Connect(TablesService.PlaceDrink)
	Remotes.Restock.OnServerEvent:Connect(function(player) end)
	Remotes.Restock.OnServerEvent:Connect(TablesService.Restock)
end
return TablesService
