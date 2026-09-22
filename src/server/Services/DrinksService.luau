-- Server/Services/DrinksService.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local CoffeeModule = require(ReplicatedStorage.Shared.CoffeeModule)
local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)

local DrinksService = {}

function DrinksService.GetCup(player: Player)
	local playerId = tostring(player.UserId)
	local state = GlobalState:getState()

	local playersCups = state.Cups[playerId]
	local cup = playersCups.player

	if cup then
		print("cup already")
		return
	end
	GlobalState.getCup(playerId)
end
function DrinksService.TrashCup(player: Player, workerUid: string?)
	workerUid = workerUid or "player"

	local playerId = tostring(player.UserId)
	local state = GlobalState:getState()

	local playersCups = state.Cups[playerId]
	local cup = playersCups[workerUid]

	if not cup then
		print("not cup")
		return
	end

	GlobalState.trashCup(playerId, { workerUid = workerUid })
end
function DrinksService.AddIngredient(player: Player, ingredient: string, workerUid: string?, score: number): number?
	workerUid = workerUid or "player"
	if not ingredient then
		return
	end

	local playerId = tostring(player.UserId)
	local state = GlobalState:getState()

	local playersCups = state.Cups[playerId]
	local cup = playersCups[workerUid]

	if not cup then
		print("not cup")
		return "no cup"
	end
	local drinkId = cup.drinkId

	local config = drinkId and drinkId ~= "none" and CoffeeModule.Config[drinkId] or nil
	local ingredients = config and table.clone(config.Ingredients) or {}
	table.insert(ingredients, ingredient)
	local result = CoffeeModule.Craft(ingredients)
	if not result then
		print("invalid drink:", table.concat(ingredients, ","))
		return "invalid"
	end

	if score < 1 then
		print("failed")
		return "failed"
	end

	GlobalState.addIngredient(playerId, {
		ingredientId = ingredient,
		newDrinkId = result.Id,
		score = score,
	})
	return score
end
local function calculateScore(ratio): number
	if ratio <= 0.1 then
		return 0
	elseif ratio <= 0.25 then
		return 1
	elseif ratio <= 0.425 then
		return 2
	elseif ratio <= 0.575 then
		return 3
	elseif ratio <= 0.75 then
		return 2
	elseif ratio <= 0.9 then
		return 1
	else
		return 0
	end
end
function DrinksService.initialize()
	Remotes.GetCup.OnServerEvent:Connect(DrinksService.GetCup)
	Remotes.UseStation.OnServerInvoke = function(player, itemId, ratio)
		local playerId = tostring(player.UserId)
		local playersPlot = GlobalState:getState().Plot[playerId]
		local placedItems = playersPlot.placedItems
		local spatialItems = playersPlot.spatialItems

		local score = calculateScore(ratio)
		local item = placedItems[itemId] or spatialItems[itemId]
		local itemName = item.id
		local station = string.match(itemName, "^(.+)_station$")
		if not station then
			print("not station")
			return
		end

		if station == "cup" or station == "trash" then
			print("cup/trash")
			return
		end

		local found = CoffeeModule.IngredientLookup[station]
		if not found then
			print(station, "is not an ingredient")
			return
		end

		return DrinksService.AddIngredient(player, station, nil, score) :: (number | "invalid:")?
	end
end

return DrinksService
