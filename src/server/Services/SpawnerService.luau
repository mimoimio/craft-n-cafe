-- SpawnerService.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Remotes = require(ReplicatedStorage.Shared.Remotes)
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
	-- local lucklevel = playersStats.Luck -- 2.1/100
	-- local luck = 0.4 + (lucklevel * 2.1 / 100) -- [0.4, 2.5]
	local z = ((math.random() * math.random()) ^ (1 / 0.4))
	local num = (z * #CoffeeModule.IngredientConfigs) // 1 + 1
	-- local z = (math.random() * math.random()) ^ (1 / luck)
	local config = CoffeeModule.IngredientConfigs[num]
	-- warn(`{z}){config.Id}`)

	local lastRolled = playersSpawner.TimePulled or 0
	if not lastRolled then
		print("lastRolled not found")
		return
	end

	if lastRolled + playersStats.RollCooldown > workspace:GetServerTimeNow() then
		print("not yet")
		return
	end

	-- local currentSeed = playerShopState.currentSeed
	-- local seedString = tostring(currentSeed)

	-- -- retrieving seed from player's shops dictionary. Since it's a key, use string
	-- local currentShop = playerShopState.shops[seedString]

	-- if not currentShop then
	-- 	warn(`BuyIngredient Failed: No active shop for seed {seedString}`)
	-- 	return
	-- end

	-- Stock Validation
	-- local stock = currentShop[ingredientId] or 0
	-- if stock <= 0 then
	-- 	print(`{ingredientId} is currently out of stock!`)
	-- 	return
	-- end

	-- Cash Validation
	-- local cost = config.Cost
	-- if playersStats.Cash < cost then
	-- 	print("Not enough cash to buy ingredient!")
	-- 	return
	-- end

	GlobalState.rollIngredient(playerId, {
		ingredientId = config.Id,
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

	local id = playersSpawner.IngredientId

	local config = CoffeeModule.IngredientLookup[id]

	if not config then
		print("not config")
		return
	end
	-- Cash Validation
	local cost = config.Cost
	if playersStats.Cash < cost then
		print("Not enough cash to buy ingredient!")
		return
	end

	GlobalState.buyIngredientFromSpawner(playerId, {
		ingredientId = config.Id,
		cost = cost,
		timePulled = workspace:GetServerTimeNow(),
	})
end

function SpawnerService.initialize()
	Remotes.RollIngredient.OnServerEvent:Connect(SpawnerService.RollIngredient)
	Remotes.BuyIngredientFromSpawner.OnServerEvent:Connect(SpawnerService.BuyIngredientFromSpawner)
end
return SpawnerService
