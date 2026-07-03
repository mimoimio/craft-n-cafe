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

function TablesService.initialize()
	Remotes.PlaceDrink.OnServerEvent:Connect(TablesService.PlaceDrink)
end
return TablesService
