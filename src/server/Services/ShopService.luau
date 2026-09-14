-- ServerScriptService/Server/Services/ShopService.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage.Shared.Remotes)
local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local PlaceablesModule = require(ReplicatedStorage.Shared.PlaceablesModule)

local ShopService = {}

function ShopService.BuyItem(player: Player, payload: any) -- Use Types.BuyItemRemotePayload
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

	-- All guards passed! Dispatch the purchase action
	GlobalState.buyItem(playerId, {
		itemId = config.Id,
		amount = amount,
		totalCost = totalCost,
	})
end

local PlotExpansionsConfig = require(ReplicatedStorage.Shared.Configs.PlotExpansionsConfig)

function ShopService.BuyPlotExpansion(player: Player)
	local playerId = tostring(player.UserId)
	local state = GlobalState:getState()

	local playerStats = state.Stats and state.Stats[playerId]
	local plotState = state.Plot and state.Plot[playerId]
	if not playerStats or not plotState then
		return
	end

	local currentSize = plotState.plotSize

	-- Find the NEXT tier
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

	-- Guards
	if playerStats.Level < nextTier.UnlockLevel then
		warn(`ShopService: {playerId} is too low level to expand.`)
		return
	end
	if playerStats.Cash < nextTier.Cost then
		warn(`ShopService: {playerId} cannot afford plot expansion.`)
		return
	end

	-- Dispatch! Deducts cash (Stats) and expands grid (Plot) simultaneously
	GlobalState.expandPlot(playerId, {
		newSize = nextTier.Size,
		cost = nextTier.Cost,
	})
end

-- Inside
function ShopService.initialize()
	Remotes.ExpandPlot.OnServerEvent:Connect(ShopService.BuyPlotExpansion) -- Make sure to define Remotes.BuyItem in your Shared/Remotes.luau!
	if Remotes.BuyItem then
		Remotes.BuyItem.OnServerEvent:Connect(ShopService.BuyItem)
	else
		warn("Remotes.BuyItem is not defined yet.")
	end
end


return ShopService
