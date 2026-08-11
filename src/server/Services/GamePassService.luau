-- Server/Services/GamePassService.luau
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)

local GamePassService = {}

-- Define all your Game Pass IDs here
GamePassService.Passes = {
	Summon2xSpeed = 1943515533,
	Summon2x = 1940563582,
	Brewing2xSpeed = 1940413596,
}

-- Gather all IDs into a list for iteration
local PASS_IDS = {}
for _, id in pairs(GamePassService.Passes) do
	table.insert(PASS_IDS, id)
end

-- 1. Check ownership on data load (Transparent Batching)
function GamePassService.CheckPassesForPlayer(player: Player)
	local playerId = tostring(player.UserId)
	local owned = {}
	local remaining = #PASS_IDS

	local function check(passId)
		local success, ownsPass = pcall(function()
			return MarketplaceService:UserOwnsGamePassAsync(player.UserId, passId)
		end)

		if success and ownsPass then
			owned[tostring(passId)] = true
		end

		remaining -= 1
	end

	-- Spawn concurrently so Roblox automatically batches the HTTP requests
	for _, passId in PASS_IDS do
		task.spawn(check, passId)
	end

	-- Yield until all checks finish
	while remaining > 0 do
		task.wait()
	end

	-- Update Reflex state
	GlobalState.setOwnedGamePasses(playerId, { passes = owned })
end

-- 2. Handle mid-session purchases
local function onPromptGamePassPurchaseFinished(player: Player, gamePassId: number, wasPurchased: boolean)
	if not wasPurchased then
		return
	end

	local stringPassId = tostring(gamePassId)
	local playerId = tostring(player.UserId)

	-- Update Reflex state immediately so UI and game logic can react
	GlobalState.grantGamePass(playerId, { passId = stringPassId })

	print(`{player.Name} successfully purchased Game Pass {gamePassId}!`)

	-- NOTE: If your game pass gives an immediate tangible item (like a tool in backpack)
	-- or triggers a one-time effect, execute that logic here. Passive perks (like 2x cash)
	-- should just read directly from the Reflex state whenever cash is awarded.
end

function GamePassService.initialize()
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(onPromptGamePassPurchaseFinished)
end

return GamePassService
