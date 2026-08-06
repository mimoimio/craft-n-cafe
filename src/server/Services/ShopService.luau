-- ShopService.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local CoffeeModule = require(ReplicatedStorage.Shared.CoffeeModule)
local LevelConfig = require(ReplicatedStorage.Shared.Configs.LevelConfig)
local MixerConfig = require(ReplicatedStorage.Shared.Configs.MixerConfig)
local Types = require(ReplicatedStorage.Shared.Types)
local ShopCycle = require(ReplicatedStorage.Shared.ShopCycle)

local ShopService = {}

-- Generates a shop predeterministically based on the cycle seed
function ShopService.GenerateDeterministicShop(seed: number): Types.ShopEntity
	local seedString = tostring(seed) or "0"
	local seedNumber = tonumber(seed) or 0
	local rng = Random.new(seedNumber)
	local shopEntity = {}

	-- Randomly select 5 ingredients and assign a random stock between 3 and 15
	for i, config in CoffeeModule.IngredientConfigs do
		shopEntity[config.Id] = math.max(0, rng:NextInteger(config.Min, config.Max))
	end

	return shopEntity
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
		-- unlockedMixers = unlockedMixers,
	})
end
function ShopService.BuyMixer(player: Player, mixerName: string)
	-- Your existing LevelUp logic remains completely unchanged here
	local playerId = tostring(player.UserId)
	local state = GlobalState:getState()
	local playersStats = state.Stats[playerId]

	if not playersStats then
		return
	end

	local cost = MixerConfig[mixerName]

	if playersStats.Cash < cost then
		print("not enough")
		return
	end

	GlobalState.buyMixer(playerId, {
		cost = cost,
		mixerId = mixerName,
	})
end
function ShopService.UpgradeLuck(player: Player, increment: number?)
	local playerId = tostring(player.UserId)
	local state = GlobalState:getState()
	local playersStats = state.Stats[playerId]

	increment = increment or 1

	if not playersStats then
		return
	end

	local cost = 0
	for i = 1, increment do
		cost += ((playersStats.Luck + increment) * 10) ^ 1.2 // 1
	end

	if playersStats.Cash < cost then
		print("not enough")
		return
	end

	GlobalState.upgradeLuck(playerId, {
		cost = cost,
		increment = increment,
	})
end
function ShopService.UpgradeCafeCapacity(player: Player, increment: number?)
	local playerId = tostring(player.UserId)
	local state = GlobalState:getState()
	local playersStats = state.Stats[playerId]

	increment = increment or 1

	if not playersStats then
		return
	end

	local cost = increment * 100

	if playersStats.Cash < cost then
		print("not enough")
		return
	end

	GlobalState.upgradeCafeCapacity(playerId, {
		cost = cost,
		increment = increment,
	})
end

function ShopService.ShortenRollCooldown(player: Player)
	local playerId = tostring(player.UserId)
	local state = GlobalState:getState()
	local playersStats = state.Stats[playerId]

	if not playersStats then
		return
	end

	GlobalState.shortenRoll(playerId)
end
function ShopService.initialize()
    Remotes.LevelUp.OnServerEvent:Connect(ShopService.LevelUp)
    Remotes.UpgradeLuck.OnServerEvent:Connect(ShopService.UpgradeLuck)
    Remotes.UpgradeCafeCapacity.OnServerEvent:Connect(ShopService.UpgradeCafeCapacity)

    -- Spin up a background thread to watch for seed changes!
    task.spawn(function()
        local currentSeed = nil
        local VariationService = require(ServerScriptService.Server.Services.VariationService)

        while true do
            local activeCycle = ShopCycle.getCurrentState()
            local newSeed = activeCycle.seed

            if currentSeed ~= newSeed then
                if currentSeed ~= nil then
                    print(`Shop Cycle advanced! Generating new shop for seed: {newSeed}`)
                    local newShopBlueprint = ShopService.GenerateDeterministicShop(newSeed)
                    local state = GlobalState:getState()
                    local variation = VariationService.GetCurrentVariationEvent()

                    for playerId, _ in state.Shop do
                        GlobalState.refreshShop(playerId, {
                            variationEvent = variation and variation.VariationId or nil,
                            newestShop = newShopBlueprint,
                            newestSeed = newSeed,
                        })
                    end
                end
                currentSeed = newSeed
            end
            task.wait(1)
        end
    end)
end
return ShopService
