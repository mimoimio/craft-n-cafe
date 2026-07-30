-- SpawnerService.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Sift = require(ReplicatedStorage.Packages.Sift)
local Array = Sift.Array
local ArrayMerge = Array.merge
local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local CoffeeModule = require(ReplicatedStorage.Shared.CoffeeModule)
local LevelConfig = require(ReplicatedStorage.Shared.Configs.LevelConfig)
local Types = require(ReplicatedStorage.Shared.Types)
local ShopCycle = require(ReplicatedStorage.Shared.ShopCycle)

local SpawnerService = {}

--

function SpawnerService.RollIngredient(player: Player)
	local playerId = tostring(player.UserId)

	local state = GlobalState:getState()
	local playersStats = state.Stats[playerId]
	local playersSpawner = state.Spawner[playerId]

	if not playersStats or not playersSpawner then
		warn(`RollIngredient Failed: player({playerId}) state not found`)
		return
	end
	local lucklevel = playersStats.Luck
	local luck = 1 + (lucklevel * 1.5 / 100)

	local earlyLuck = 1.2 -- no late
	local midLuck = 1.8 -- most balanced.
	local lateLuck = 5 -- no early

	local lastRolled = playersSpawner.TimePulled or 0
	if not lastRolled then
		print("lastRolled not found")
		return
	end

	if lastRolled + playersStats.RollCooldown > workspace:GetServerTimeNow() then
		print("not yet")
		return
	end

	if not playersStats.TutorialCompleted then
		local ingredients = state.Ingredients[playerId]
		local espresso = ingredients.espresso
		local milk = ingredients.milk

		warn(`espresso ({espresso}), milk ({milk})`)

		if not espresso or espresso < 2 then
			GlobalState.rollIngredient(playerId, {
				ingredientIds = { "espresso" },
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

	if luck >= lateLuck then
		local z = ((math.random() * math.random()) ^ (1 / midLuck))
		local num = (z * #CoffeeModule.IngredientConfigs) // 1 + 1
		local config = CoffeeModule.IngredientConfigs[num]
		table.insert(ingredientIds, config.Id)
	end
	if luck >= midLuck then
		local z = ((math.random() * math.random()) ^ (1 / earlyLuck))
		local num = (z * #CoffeeModule.IngredientConfigs) // 1 + 1
		local config = CoffeeModule.IngredientConfigs[num]
		table.insert(ingredientIds, config.Id)
	end
	-- lastly, the unfiltered
	local z = ((math.random() * math.random()) ^ (1 / luck))
	local num = (z * #CoffeeModule.IngredientConfigs) // 1 + 1
	-- get from a drink.
	local config = CoffeeModule.Array[num]
	ingredientIds = ArrayMerge(ingredientIds, config.Ingredients)

	-- warn(`{z}){config.Id}`)
	GlobalState.rollIngredient(playerId, {
		ingredientIds = ingredientIds,
		-- cost = cost,
		timePulled = workspace:GetServerTimeNow(),
	})
end
function SpawnerService.BuyIngredientFromSpawner(player: Player)
	local playerId = tostring(player.UserId)

	local state = GlobalState:getState()
	local playersStats = state.Stats[playerId]
	local playersSpawner = state.Spawner[playerId]

	if not playersStats or not playersSpawner then
		warn(`BuyIngredientFromSpawner Failed: player({playerId}) state not found`)
		return
	end

	local ids = playersSpawner.IngredientIds

	local cost
	for i, id in ids do
		local config = CoffeeModule.IngredientLookup[id]
		cost = (cost or 0) + config.Cost
	end

	if not cost then
		print("not cost")
		return
	end

	if playersStats.Cash < cost then
		print("Not enough cash to buy ingredient!")
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
