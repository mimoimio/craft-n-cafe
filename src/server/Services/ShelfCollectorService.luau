-- Server/Services/ShelfCollectorService.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local CoffeeModule = require(ReplicatedStorage.Shared.CoffeeModule)
local VariationsConfig = require(ReplicatedStorage.Shared.Configs.VariationsConfig)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local MAX_ACCUMULATION_SECONDS = 8 * 60 * 60 -- 8 hours

local ShelfCollectorService = {}

-- Helper to dynamically calculate total rate from the shelf
local function calculateTotalShelfRate(playerId: string): number
	local state = GlobalState:getState()
	local shelves = state.Shelves[playerId]
	if not shelves then
		return 0
	end

	local totalRate = 0

	for _, shelf in shelves do
		for _, slotData in shelf.Slots do
			if type(slotData) == "table" and slotData.drinkId then
				local config = CoffeeModule.Config[slotData.drinkId]
				local variation = VariationsConfig[slotData.variationId] or VariationsConfig["none"]

				if config and config.Rate then
					totalRate += (config.Rate * variation.Multiplier)
				end
			end
		end
	end

	return totalRate
end
function ShelfCollectorService.Claim(player: Player)
	local playerId = tostring(player.UserId)
	local state = GlobalState:getState()
	local collectorState = state.ShelfCollector[playerId]

	if not collectorState then
		return
	end

	local currentTime = workspace:GetServerTimeNow()
	local lastClaimTime = collectorState.LastClaimTime

	local rawTimePassed = currentTime - lastClaimTime
	local timePassed = math.min(rawTimePassed, MAX_ACCUMULATION_SECONDS)

	local totalRatePerSecond = calculateTotalShelfRate(playerId)
	local amountToClaim = math.floor(timePassed * totalRatePerSecond)

	-- CRITICAL FIX: Always reset the timer, even if the claim amount is 0.
	-- This prevents retroactive time exploits when placing the first drink!
	GlobalState.claimShelfCollector(playerId, {
		amount = amountToClaim,
		timestamp = currentTime,
	})
end

function ShelfCollectorService.initialize()
	Remotes.ClaimShelfCollector.OnServerEvent:Connect(function(player: Player)
		ShelfCollectorService.Claim(player)
	end)
end

return ShelfCollectorService
