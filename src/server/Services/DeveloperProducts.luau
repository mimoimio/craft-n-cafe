-- Server/Services/DeveloperProducts.luau
local MarketplaceService = game:GetService("MarketplaceService")
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local CoffeeModule = require(ReplicatedStorage.Shared.CoffeeModule)

-- Separate datastore specifically for tracking purchases to prevent double-grants
local purchaseHistoryStore = DataStoreService:GetDataStore("PurchaseHistory")

local DeveloperProducts = {}

export type ReceiptInfo = {
	PurchaseId: number,
	PlayerId: number,
	ProductId: number,
	PlaceIdWherePurchased: number,
	CurrencySpent: number,
	CurrencyType: Enum.CurrencyType,
	ProductPurchaseChannel: Enum.ProductPurchaseChannel,
}

local productIdByName = {
	eightHoursMoney = 3701221514,
	oneHourMoney = 3701216848,
	bigSkipBrew = 3701205415,
	mediumSkipBrew = 3701204675,
	smallSkipBrew = 3701204007,
}
DeveloperProducts.productIdByName = productIdByName

local grantPurchaseHandlerByProductId = {
	[productIdByName.smallSkipBrew] = function(_receipt, player)
		local playerId = tostring(player.UserId)
		local state = GlobalState:getState()
		local playerStats = state.Stats[playerId]

		local targetMixerId = playerStats and playerStats.PendingSkipMixer

		-- Always clear the pending intent regardless of outcome
		if targetMixerId then
			GlobalState.setPendingSkipMixer(playerId, { mixer = nil })
		end

		local playersMixers = state.Mixers[playerId]
		local targetMixer = playersMixers and playersMixers[targetMixerId]

		-- Validation check: Is the mixer still occupied and mixing?
		local isMixerValid = false
		if targetMixer then
			local mixerDrink = targetMixer.drinkId
			local occupied = mixerDrink and mixerDrink ~= "none"
			if occupied then
				local config = CoffeeModule.Config[mixerDrink]
				if workspace:GetServerTimeNow() < targetMixer.startTime + config.Duration then
					isMixerValid = true
				end
			end
		end

		if targetMixerId and isMixerValid then
			-- Success: Apply the skip
			local config = CoffeeModule.Config[targetMixer.drinkId]
			local newTime = workspace:GetServerTimeNow() - config.Duration

			GlobalState.skipMix(playerId, {
				mixer = targetMixerId,
				newTime = newTime,
			})
		else
			-- Fallback: The drink finished, or cache was lost. Grant a Skip Ticket.
			GlobalState.addSkipTickets(playerId, { amount = 1 })
		end

		return true
	end,
}

-- The core ProcessReceipt callback function
local function processReceipt(receiptInfo: ReceiptInfo)
	local success, result = pcall(
		purchaseHistoryStore.UpdateAsync,
		purchaseHistoryStore,
		receiptInfo.PurchaseId,
		function(isPurchased)
			if isPurchased then
				-- This purchase was already recorded as granted, return true to avoid granting twice
				return true
			end

			local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
			if not player then
				-- Avoids granting the purchase if the player is not in the server
				return nil
			end

			local grantPurchaseHandler = grantPurchaseHandlerByProductId[receiptInfo.ProductId]
			if not grantPurchaseHandler then
				warn(`No purchase handler defined for product ID '{receiptInfo.ProductId}'`)
				return nil
			end

			local handlerSucceeded, handlerResult = pcall(grantPurchaseHandler, receiptInfo, player)
			if not handlerSucceeded then
				warn(
					`Grant purchase handler errored while processing purchase from '{player.Name}' of product ID '{receiptInfo.ProductId}': {handlerResult}`
				)
				return nil
			end

			local didHandlerGrantPurchase = handlerResult == true
			if not didHandlerGrantPurchase then
				-- The handler did not grant the purchase, so record it as not granted
				return nil
			end

			-- The purchase is now granted to the player, so record it as granted
			return true
		end
	)

	if not success then
		warn(`Failed to process receipt due to data store error: {result}`)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local didGrantPurchase = result == true
	return if didGrantPurchase
		then Enum.ProductPurchaseDecision.PurchaseGranted
		else Enum.ProductPurchaseDecision.NotProcessedYet
end

function DeveloperProducts.initialize()
	MarketplaceService.ProcessReceipt = processReceipt
end

return DeveloperProducts
