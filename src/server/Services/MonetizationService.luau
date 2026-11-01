-- ServerScriptService/Server/Services/MonetizationService.luau
local AnalyticsService = game:GetService("AnalyticsService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local MonetizationConfig = require(ReplicatedStorage.Shared.Configs.MonetizationConfig)
local PlaceablesModule = require(ReplicatedStorage.Shared.PlaceablesModule)
local PlayerDataService = require(script.Parent.PlayerDataService)

local MonetizationService = {}

local MAX_RECEIPT_HISTORY = 100
local SAVE_TIMEOUT = 8

local function getProfile(player: Player)
	return PlayerDataService:GetProfile(player)
end

local function ensureProfileTables(profile)
	profile.Data.Stats = profile.Data.Stats or {}
	profile.Data.Inventory = profile.Data.Inventory or {}
	profile.Data.PurchaseHistory = profile.Data.PurchaseHistory or {}
	profile.Data.Stats.OwnedGamePasses = profile.Data.Stats.OwnedGamePasses or {}
	profile.Data.Stats.PurchasedProducts = profile.Data.Stats.PurchasedProducts or {}
	profile.Data.Stats.LifetimeCash = profile.Data.Stats.LifetimeCash or 0
end

local function pruneReceiptHistory(profile)
	local history = profile.Data.PurchaseHistory
	if not history then
		return
	end

	local entries = {}
	for receiptId, timestamp in pairs(history) do
		table.insert(entries, { id = receiptId, timestamp = timestamp })
	end

	if #entries <= MAX_RECEIPT_HISTORY then
		return
	end

	table.sort(entries, function(a, b)
		return a.timestamp < b.timestamp
	end)

	for index = 1, #entries - MAX_RECEIPT_HISTORY do
		history[entries[index].id] = nil
	end
end

local function saveProfile(profile): boolean
	if not profile:IsActive() then
		return false
	end

	local saved = false
	local connection = profile.OnAfterSave:Connect(function()
		saved = true
	end)

	local ok = pcall(function()
		profile:Save()
	end)

	if not ok then
		connection:Disconnect()
		return false
	end

	local deadline = os.clock() + SAVE_TIMEOUT
	while not saved and os.clock() < deadline do
		task.wait(0.1)
	end

	connection:Disconnect()
	return saved
end

local function logPurchase(player: Player, productKey: string, cash: number)
	pcall(function()
		AnalyticsService:LogEconomyEvent(
			player,
			Enum.AnalyticsEconomyFlowType.Source,
			"Cash",
			cash,
			player.leaderstats and player.leaderstats.Cash and player.leaderstats.Cash.Value or cash,
			Enum.AnalyticsEconomyTransactionType.RobuxPurchase,
			productKey,
			{ ProductKey = productKey }
		)
	end)
end

local function countOwnedItem(data, itemId: string): number
	local count = data.Inventory and data.Inventory[itemId] or 0
	local plot = data.Plot or {}

	for _, item in pairs(plot.placedItems or {}) do
		if item.id == itemId then
			count += 1
		end
	end
	for _, item in pairs(plot.spatialItems or {}) do
		if item.id == itemId then
			count += 1
		end
	end

	return count
end

local function grantStarterItems(data, items: { string }): (number, { string })
	local extraCash = 0
	local granted = {}

	for _, itemId in ipairs(items) do
		local config = PlaceablesModule.GetConfig(itemId)
		if not config then
			warn(`[MonetizationService] Starter item '{itemId}' has no PlaceablesConfig entry.`)
			continue
		end

		local owned = countOwnedItem(data, itemId)
		local maxAllowed = config.MaxAllowed or math.huge

		if owned >= maxAllowed then
			extraCash += config.Price or 0
		else
			data.Inventory[itemId] = (data.Inventory[itemId] or 0) + 1
			table.insert(granted, itemId)
		end
	end

	return extraCash, granted
end

local function applyProductGrant(profile, product): (number, { string }, boolean)
	local data = profile.Data
	ensureProfileTables(profile)

	if MonetizationConfig.GetCashProductByProductId(product.ProductId) == product then
		data.Stats.Cash = (data.Stats.Cash or 0) + product.Cash
		return product.Cash, {}, false
	end

	if MonetizationConfig.IsStarterProduct(product.ProductId) then
		local starter = MonetizationConfig.StarterProduct
		local alreadyOwned = data.Stats.PurchasedProducts[starter.Key] == true
		local cash = starter.Cash
		local grantedItems = {}

		if not alreadyOwned then
			local extraCash, items = grantStarterItems(data, starter.Items)
			cash += extraCash
			grantedItems = items
			data.Stats.PurchasedProducts[starter.Key] = true
		end

		data.Stats.Cash = (data.Stats.Cash or 0) + cash
		return cash, grantedItems, not alreadyOwned
	end

	return 0, {}, false
end

local function syncGamePasses(player: Player)
	local profile = getProfile(player)
	if not profile then
		return
	end

	ensureProfileTables(profile)

	for _, pass in pairs(MonetizationConfig.GamePasses) do
		if MonetizationConfig.IsConfigured(pass.PassId) then
			local ok, owns = pcall(function()
				return MarketplaceService:UserOwnsGamePassAsync(player.UserId, pass.PassId)
			end)

			if ok then
				profile.Data.Stats.OwnedGamePasses[pass.Key] = owns == true
				GlobalState.setGamePassOwnership(tostring(player.UserId), {
					passKey = pass.Key,
					owned = owns == true,
				})
			else
				warn(`[MonetizationService] Failed to check gamepass {pass.Key}: {owns}`)
			end
		end
	end
end

local function syncGamePassesWhenReady(player: Player)
	task.spawn(function()
		local deadline = os.clock() + 10
		local profile = getProfile(player)

		while not profile and os.clock() < deadline do
			task.wait(0.1)
			profile = getProfile(player)
		end

		if profile then
			syncGamePasses(player)
		end
	end)
end

local function handleGamePassPurchase(player: Player, passId: number, wasPurchased: boolean)
	if not wasPurchased then
		return
	end

	local pass = MonetizationConfig.GetGamePassByProductId(passId)
	if not pass then
		warn(`[MonetizationService] Purchased unknown gamepass {passId}.`)
		return
	end

	task.spawn(function()
		local ok, owns = pcall(function()
			return MarketplaceService:UserOwnsGamePassAsync(player.UserId, passId)
		end)

		if not ok or not owns then
			warn(`[MonetizationService] Could not verify gamepass {pass.Key} after purchase.`)
			return
		end

		local profile = getProfile(player)
		if not profile then
			return
		end

		ensureProfileTables(profile)
		profile.Data.Stats.OwnedGamePasses[pass.Key] = true
		profile:Save()

		GlobalState.setGamePassOwnership(tostring(player.UserId), {
			passKey = pass.Key,
			owned = true,
		})
	end)
end

local function handleReceipt(receiptInfo)
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local profile = getProfile(player)
	if not profile or not profile:IsActive() then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	ensureProfileTables(profile)

	local receiptId = tostring(receiptInfo.PurchaseId)
	if profile.Data.PurchaseHistory[receiptId] then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	local productId = receiptInfo.ProductId
	if not MonetizationConfig.IsConfigured(productId) then
		warn(`[MonetizationService] Receipt for unconfigured product ID {productId} from {player.Name}.`)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local product = MonetizationConfig.GetCashProductByProductId(productId)
	if not product and MonetizationConfig.IsStarterProduct(productId) then
		product = MonetizationConfig.StarterProduct
	end

	if not product then
		warn(`[MonetizationService] Unknown product ID {productId} for {player.Name}.`)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local cashGranted, grantedItems, starterClaimed = applyProductGrant(profile, product)

	profile.Data.PurchaseHistory[receiptId] = os.time()
	pruneReceiptHistory(profile)

	if not saveProfile(profile) then
		warn(`[MonetizationService] Failed to save receipt {receiptId} for {player.Name}.`)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local playerId = tostring(player.UserId)

	if cashGranted > 0 then
		GlobalState.grantCash(playerId, {
			Cash = cashGranted,
			Source = product.Key,
		})
	end

	for _, itemId in ipairs(grantedItems) do
		GlobalState.buyItem(playerId, {
			itemId = itemId,
			amount = 1,
			totalCost = 0,
		})
	end

	if starterClaimed then
		GlobalState.markProductPurchased(playerId, {
			productKey = MonetizationConfig.StarterProduct.Key,
		})
	end

	logPurchase(player, product.Key, cashGranted)

	return Enum.ProductPurchaseDecision.PurchaseGranted
end

MonetizationService._connections = {}

function MonetizationService.initialize()
	if MonetizationService.initialized then
		return
	end
	MonetizationService.initialized = true

	for _, pass in pairs(MonetizationConfig.GamePasses) do
		if not MonetizationConfig.IsConfigured(pass.PassId) then
			warn(`[MonetizationService] Gamepass '{pass.Key}' has no PassId yet.`)
		end
	end
	for _, product in ipairs(MonetizationConfig.CashProducts) do
		if not MonetizationConfig.IsConfigured(product.ProductId) then
			warn(`[MonetizationService] Cash product '{product.Key}' has no ProductId yet.`)
		end
	end
	if not MonetizationConfig.IsConfigured(MonetizationConfig.StarterProduct.ProductId) then
		warn(`[MonetizationService] Starter product '{MonetizationConfig.StarterProduct.Key}' has no ProductId yet.`)
	end

	table.insert(
		MonetizationService._connections,
		PlayerDataService.ProfileCreated:Connect(function(player: Player)
			task.spawn(syncGamePasses, player)
		end)
	)

	table.insert(
		MonetizationService._connections,
		Players.PlayerAdded:Connect(syncGamePassesWhenReady)
	)

	for _, player in Players:GetPlayers() do
		syncGamePassesWhenReady(player)
	end

	table.insert(
		MonetizationService._connections,
		MarketplaceService.PromptGamePassPurchaseFinished:Connect(handleGamePassPurchase)
	)

	MarketplaceService.ProcessReceipt = handleReceipt
end

function MonetizationService.cleanup()
	for _, connection in ipairs(MonetizationService._connections) do
		connection:Disconnect()
	end
	table.clear(MonetizationService._connections)
end

return MonetizationService
