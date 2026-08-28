-- SpawnerService.luau
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Sift = require(ReplicatedStorage.Packages.Sift)
local Array = Sift.Array
local ArrayMerge = Array.merge
local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local CoffeeModule = require(ReplicatedStorage.Shared.CoffeeModule)
local Types = require(ReplicatedStorage.Shared.Types)
local ShopCycle = require(ReplicatedStorage.Shared.ShopCycle)
local LuckModule = require(ReplicatedStorage.Shared.LuckModule)
local SpawnerService = {}

local function warnInsufficientCash(player: Player)
	print(`Spawner purchase skipped for {player.Name}: insufficient cash`)
end

--

function SpawnerService.RollIngredient(player: Player)
	local playerId = tostring(player.UserId)

	local state = GlobalState:getState()
	local playersStats = state.Stats[playerId]
	local playersSpawner = state.Spawner[playerId] or {}

	if not playersStats then
		warn(`RollIngredient Failed: player({playerId}) state not found`)
		return
	end

	local luckLevel = tonumber(playersStats.Luck) or 1

	-- Unified Conversion Here
	local luck = LuckModule.GetMultiplier(luckLevel)

	local earlyLuck = 1.2
	local midLuck = 1.8
	local lateLuck = 5

	local lastRolled = playersSpawner.TimePulled or 0
	if not lastRolled then
		print("lastRolled not found")
		return
	end

	local rollCooldown = math.max(0, tonumber(playersStats.RollCooldown) or 2)
	if lastRolled + rollCooldown > workspace:GetServerTimeNow() then
		print("not yet")
		return
	end
	if not playersStats.TutorialCompleted then
		local playerIngredients = state.Ingredients[playerId] or {}
		local espresso = playerIngredients.espresso
		local milk = playerIngredients.milk

		if not espresso or espresso < 1 then
			GlobalState.rollIngredient(playerId, {
				ingredientIds = { "espresso", "espresso", "milk" },
				timePulled = workspace:GetServerTimeNow(),
			})
			return
		end
		if not milk or milk < 1 then
			GlobalState.rollIngredient(playerId, {
				ingredientIds = { "milk" },
				timePulled = workspace:GetServerTimeNow(),
			})
			return
		end
	end

	local ingredientIds = {}
	local maxIngredients = #CoffeeModule.IngredientConfigs
	local maxDrinks = #CoffeeModule.Array

	if luck >= lateLuck then
		local num = LuckModule.RollIndex(midLuck, maxIngredients)
		local config = CoffeeModule.IngredientConfigs[num]
		if config then
			table.insert(ingredientIds, config.Id)
		end
	end

	if luck >= midLuck then
		local num = LuckModule.RollIndex(earlyLuck, maxIngredients)
		local config = CoffeeModule.IngredientConfigs[num]
		if config then
			table.insert(ingredientIds, config.Id)
		end
	end

	local num = LuckModule.RollIndex(luck, maxDrinks)
	local config = CoffeeModule.Array[num]
	if config and config.Ingredients then
		ingredientIds = ArrayMerge(ingredientIds, config.Ingredients)
	end

	GlobalState.rollIngredient(playerId, {
		ingredientIds = ingredientIds,
		timePulled = workspace:GetServerTimeNow(),
	})
end
function SpawnerService.BuyIngredientFromSpawner(player: Player)
	local playerId = tostring(player.UserId)

	local state = GlobalState:getState()
	local playersStats = state.Stats[playerId]
	local playersSpawner = state.Spawner[playerId] or {}

	if not playersStats then
		warn(`BuyIngredientFromSpawner Failed: player({playerId}) state not found`)
		return
	end

	local ids = playersSpawner.IngredientIds

	local cost
	for i, id in ids or {} do
		local config = CoffeeModule.IngredientLookup[id]
		cost = (cost or 0) + config.Cost
	end

	if not cost then
		print("not cost")
		return
	end

	if playersStats.Cash < cost then
		warnInsufficientCash(player)
		return
	end

	GlobalState.buyIngredientFromSpawner(playerId, {
		ingredientIds = ids,
		cost = cost,
		timePulled = workspace:GetServerTimeNow(),
	})
end

function SpawnerService.initialize()
	Remotes.RollIngredient.OnServerEvent:Connect(SpawnerService.RollIngredient)
	Remotes.BuyIngredientFromSpawner.OnServerEvent:Connect(SpawnerService.BuyIngredientFromSpawner)
end
return SpawnerService
