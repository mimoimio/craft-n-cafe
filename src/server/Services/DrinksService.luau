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
	local cup = playersCups[playerId]

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
function DrinksService.AddIngredient(player: Player, ingredient: string, workerUid: string?)
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
		return
	end
	local drinkId = cup.drinkId

	local config = drinkId and drinkId ~= "none" and CoffeeModule.Config[drinkId] or nil
	local ingredients = config and table.clone(config.Ingredients) or {}
	table.insert(ingredients, ingredient)
	local result = CoffeeModule.Craft(ingredients)
	if not result then
		warn("invalid drink:", table.concat(ingredients, ","))
		return
	end

	GlobalState.addIngredient(playerId, {
		ingredientId = ingredient,
		newDrinkId = result.Id,
	}) --, score = score
end
function DrinksService.initialize()
	Remotes.GetCup.OnServerEvent:Connect(DrinksService.GetCup)
	-- Remotes.AddIngredient.OnServerEvent:Connect(DrinksService.AddIngredient)
end

return DrinksService
