-- ShopService.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local CoffeeModule = require(ReplicatedStorage.Shared.CoffeeModule)
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

function ShopService.BuyMixer(player: Player, mixerName: string)
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
		cost += ((playersStats.Luck + i) * 10) ^ 1.8 // 1
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

	local cost = 0
	local cafeCapacity = playersStats.CafeCapacity
	for i = 1, increment do
		cost += 10 ^ (cafeCapacity - 3 + i)
	end

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
					local newShopBlueprint = {} --ShopService.GenerateDeterministicShop(newSeed)
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
