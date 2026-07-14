-- ShopService.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local CoffeeModule = require(ReplicatedStorage.Shared.CoffeeModule)
local LevelConfig = require(ReplicatedStorage.Shared.Configs.LevelConfig)
local Types = require(ReplicatedStorage.Shared.Types)
local ShopCycle = require(ReplicatedStorage.Shared.ShopCycle)

local ShopService = {}

-- Generates a shop predeterministically based on the cycle seed
function ShopService.GenerateDeterministicShop(seed: string): Types.ShopEntity
	local seedNumber = tonumber(seed) or 0
	local rng = Random.new(seedNumber)
	local shopEntity = {}

	-- Randomly select 5 ingredients and assign a random stock between 3 and 15
	for i, config in CoffeeModule.IngredientConfigs do
		shopEntity[config.Id] = math.max(0, rng:NextInteger(config.Min, config.Max))
	end

	return shopEntity
end

function ShopService.BuyIngredient(player: Player, ingredientId: string)
	if not ingredientId then
		warn(`BuyIngredient Failed: ingredientId is nil`)
		return
	end

	local playerId = tostring(player.UserId)
	local config = CoffeeModule.IngredientLookup[ingredientId]

	if not config or (config.Ingredients and #config.Ingredients > 1) then
		warn(`BuyIngredient Failed: {ingredientId} is not a valid base ingredient`)
		return
	end

	local state = GlobalState:getState()
	local playersStats = state.Stats[playerId]
	local playerShopState = state.Shop[playerId]

	if not playersStats or not playerShopState then
		warn(`BuyIngredient Failed: player({playerId}) state not found`)
		return
	end

	-- Level validation
	local level = playersStats.Level
	local unlocked = LevelConfig[level].Ingredients[ingredientId]
	if not unlocked then
		warn(`BuyIngredient Failed: player({playerId}) hasn't unlocked yet`)
		return
	end

	local currentSeed = playerShopState.currentSeed
	local currentShop = playerShopState.shops[currentSeed]

	if not currentShop then
		warn(`BuyIngredient Failed: No active shop for seed {currentSeed}`)
		return
	end

	-- Stock Validation
	local stock = currentShop[ingredientId] or 0
	if stock <= 0 then
		print(`{ingredientId} is currently out of stock!`)
		return
	end

	-- Cash Validation
	local cost = config.Cost
	if playersStats.Cash < cost then
		print("Not enough cash to buy ingredient!")
		return
	end

	GlobalState.buyIngredient(playerId, {
		ingredientId = ingredientId,
		amount = 1,
		cost = cost,
		seed = currentSeed,
	})
end

function ShopService.LevelUp(player: Player)
	-- Your existing LevelUp logic remains completely unchanged here
	local playerId = tostring(player.UserId)
	local state = GlobalState:getState()
	local playersStats = state.Stats[playerId]

	if not playersStats then
		return
	end
	local level = playersStats.Level + 1

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

	-- Spin up a background thread to watch for seed changes!
	task.spawn(function()
		local currentSeed = nil

		while true do
			-- Assuming your ShopCycle module has a way to get the active cycle data
			-- Adjust the function call to match exactly how your ShopCycle module works
			local activeCycle = ShopCycle.getCurrentState()
			local newSeed = tostring(activeCycle.seed)

			if currentSeed ~= newSeed then
				if currentSeed ~= nil then
					-- The seed has changed! Let's generate the new deterministic stock
					print(`Shop Cycle advanced! Generating new shop for seed: {newSeed}`)
					local newShopBlueprint = ShopService.GenerateDeterministicShop(newSeed)

					local state = GlobalState:getState()

					-- Dispatch the refresh action for every player currently in the session
					for playerId, _ in state.Shop do
						GlobalState.refreshShop(playerId, {
							newestShop = newShopBlueprint,
							newestSeed = newSeed,
						})
					end
				end

				-- Update our tracker to the new seed
				currentSeed = newSeed
			end

			-- Check every second (adjust this polling rate if you want it faster/slower)
			task.wait(1)
		end
	end)
end
return ShopService
