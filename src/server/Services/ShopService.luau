-- ServerScriptService/Server/Services/ShopService.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage.Shared.Remotes)
local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local PlaceablesModule = require(ReplicatedStorage.Shared.PlaceablesModule)
local PlotExpansionsConfig = require(ReplicatedStorage.Shared.Configs.PlotExpansionsConfig)
local UpgradesConfig = require(ReplicatedStorage.Shared.Configs.UpgradesConfig)
local Types = require(ReplicatedStorage.Shared.Types)

local ShopService = {}

function ShopService.BuyItem(player: Player, payload: Types.BuyItemRemotePayload)
	local playerId = tostring(player.UserId)
	local amount = payload.amount or 1
	if amount <= 0 then
		return
	end

	local config = PlaceablesModule.GetConfig(payload.itemId)
	if not config then
		warn(`ShopService: Player {playerId} tried to buy unknown item: {payload.itemId}`)
		return
	end

	local state = GlobalState:getState()
	local playerStats = state.Stats and state.Stats[playerId]
	local playerInventory = state.Inventory and state.Inventory[playerId] or {}
	local plotState = state.Plot and state.Plot[playerId]

	if not playerStats or not plotState then
		return
	end

	-- Guard 1: Level Check
	if playerStats.Level < config.UnlockLevel then
		warn(`ShopService: {playerId} does not meet level requirement for {config.Id}`)
		return
	end

	-- Guard 2: Affordability Check
	local totalCost = config.Price * amount
	if playerStats.Cash < totalCost then
		warn(`ShopService: {playerId} cannot afford {amount}x {config.Id}`)
		return
	end

	-- Guard 3: MaxAllowed Limit Check (Placed + Inventory)
	if config.MaxAllowed and config.MaxAllowed ~= math.huge then
		local totalOwned = playerInventory[config.Id] or 0

		for _, item in pairs(plotState.placedItems) do
			if item.id == config.Id then
				totalOwned += 1
			end
		end
		for _, item in pairs(plotState.spatialItems) do
			if item.id == config.Id then
				totalOwned += 1
			end
		end

		if (totalOwned + amount) > config.MaxAllowed then
			warn(`ShopService: {playerId} reached limit for {config.Id}. Owns {totalOwned}/{config.MaxAllowed}`)
			return
		end
	end

	GlobalState.buyItem(playerId, {
		itemId = config.Id,
		amount = amount,
		totalCost = totalCost,
	})
end

function ShopService.BuyPlotExpansion(player: Player)
	local playerId = tostring(player.UserId)
	local state = GlobalState:getState()

	local playerStats = state.Stats and state.Stats[playerId]
	local plotState = state.Plot and state.Plot[playerId]
	if not playerStats or not plotState then
		return
	end

	local currentSize = plotState.plotSize

	local nextTier = nil
	for i, tier in ipairs(PlotExpansionsConfig) do
		if tier.Size > currentSize then
			nextTier = tier
			break
		end
	end

	if not nextTier then
		warn(`ShopService: {playerId} is already at max plot size!`)
		return
	end

	if playerStats.Level < nextTier.UnlockLevel then
		warn(`ShopService: {playerId} is too low level to expand.`)
		return
	end
	if playerStats.Cash < nextTier.Cost then
		warn(`ShopService: {playerId} cannot afford plot expansion.`)
		return
	end

	GlobalState.expandPlot(playerId, {
		newSize = nextTier.Size,
		cost = nextTier.Cost,
	})
end

function ShopService.BuyUpgrade(player: Player, payload: Types.BuyUpgradeRemotePayload)
	if type(payload) ~= "table" or type(payload.upgradeId) ~= "string" then
		return
	end

	local playerId = tostring(player.UserId)
	local state = GlobalState:getState()
	local playerStats = state.Stats and state.Stats[playerId]
	if not playerStats then
		return
	end

	local config = UpgradesConfig.GetConfig(payload.upgradeId)
	if not config then
		warn(`ShopService: Unknown upgradeId '{payload.upgradeId}'`)
		return
	end

	-- Match Ingredient upgrade unlock level to its station's unlock level if available
	local requiredLevel = config.UnlockLevel
	if config.IngredientId then
		local stationCfg = PlaceablesModule.GetConfig(config.IngredientId .. "_station")
		if stationCfg then
			requiredLevel = math.max(requiredLevel, stationCfg.UnlockLevel)
		end
	end

	if playerStats.Level < requiredLevel then
		return
	end

	local currentUpgrades = playerStats.Upgrades or {}
	local currentLevel = currentUpgrades[config.Id] or 0
	if currentLevel >= config.MaxLevel then
		return
	end

	local nextLevel = currentLevel + 1
	local cost = config.GetCost(nextLevel)
	if playerStats.Cash < cost then
		return
	end

	GlobalState.buyUpgrade(playerId, {
		upgradeId = config.Id,
		cost = cost,
	})
end

ShopService._connections = {}

function ShopService.initialize()
	table.insert(ShopService._connections, Remotes.ExpandPlot.OnServerEvent:Connect(ShopService.BuyPlotExpansion))
	if Remotes.BuyItem then
		table.insert(ShopService._connections, Remotes.BuyItem.OnServerEvent:Connect(ShopService.BuyItem))
	end
	if Remotes.BuyUpgrade then
		table.insert(ShopService._connections, Remotes.BuyUpgrade.OnServerEvent:Connect(ShopService.BuyUpgrade))
	end
end

function ShopService.cleanup()
	for _, conn in ipairs(ShopService._connections) do
		conn:Disconnect()
	end
	table.clear(ShopService._connections)
end

return ShopService
