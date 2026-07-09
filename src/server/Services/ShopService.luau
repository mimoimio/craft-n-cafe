local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local CoffeeModule = require(ReplicatedStorage.Shared.CoffeeModule)
local LevelConfig = require(ReplicatedStorage.Shared.Configs.LevelConfig)

local ShopService = {}

function ShopService.BuyIngredient(player: Player, ingredientId: string)
	if not ingredientId then
		warn(`BuyIngredient Failed: ingredientId is nil`)
		return
	end

	-- ensure ingredient
	local playerId = tostring(player.UserId)
	local config = CoffeeModule.IngredientLookup[ingredientId]
	if not config then
		warn(`BuyIngredient Failed: {ingredientId} is not a valid ingredient`)
		return
	end
	if config.Ingredients and #config.Ingredients > 1 then
		warn("That's not an ingredient")
		return
	end

	-- ensure player
	local state = GlobalState:getState()
	local playersIngredients = state.Ingredients[playerId]
	local playersStats = state.Stats[playerId]
	if not playersStats then
		warn(`BuyIngredient Failed: player({playerId})'s stats not found`)
		return
	end
	if not playersIngredients then
		warn(`BuyIngredient Failed: player({playerId})'s ingredients not found`)
		return
	end

	local cash = playersStats.Cash
	local cost = config.Cost

	if cash - cost < 0 then
		print("not enough")
		return
	end

	GlobalState.buyIngredient(playerId, ingredientId, 1, cost)
end
function ShopService.LevelUp(player: Player)
	local playerId = tostring(player.UserId)
	local state = GlobalState:getState()
	local playersStats = state.Stats[playerId]
	local level = playersStats.Level + 1

	if not playersStats then
		return
	end

	if level > 9 then
		print("maxxed")
		return
	end
	local cost = LevelConfig[level].Cost
	local unlockedTables = LevelConfig[level].Tables
	local unlockedIngredients = LevelConfig[level].Ingredients
	local unlockedMixers = LevelConfig[level].Mixers

	if playersStats.Cash < cost then
		print("not enough")
		return
	end

	GlobalState.levelUp(playerId, {
		level = level,
		cost = cost,
		unlockedTables = unlockedTables,
		unlockedIngredients = unlockedIngredients,
		unlockedMixers = unlockedMixers,
	})
end
function ShopService.initialize()
	Remotes.BuyIngredient.OnServerEvent:Connect(ShopService.BuyIngredient)
	Remotes.LevelUp.OnServerEvent:Connect(ShopService.LevelUp)
end
return ShopService
