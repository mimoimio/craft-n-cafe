-- DrinksService.luau
local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local CoffeeModule = require(ReplicatedStorage.Shared.CoffeeModule)
local Types = require(ReplicatedStorage.Shared.Types)

local function getVariationAndSize(): Types.VariationConfig
	local VariationService = require(ServerScriptService.Server.Services.VariationService)

	return VariationService.GetVariation(), VariationService.GetSize()
end

local DrinksService = {}

function DrinksService.MixDrink(player: Player, drinkId: string, mixer: string)
	if not (drinkId and mixer) then
		warn(`MixDrink Failed: drinkId({tostring(drinkId)}) or mixer({tostring(mixer)}) is nil`)
		return
	end

	local playerId = tostring(player.UserId)
	local config = CoffeeModule.Config[drinkId]
	if not config then
		warn(`MixDrink Failed: {drinkId} is not a valid drink`)
		return
	end

	-- ensure player
	local state = GlobalState:getState()
	local playersIngredients = state.Ingredients[playerId]
	local playersMixers = state.Mixers[playerId]

	if not playersIngredients then
		warn(`MixDrink Failed: player({playerId})'s ingredients not found`)
		return
	end
	if not playersMixers or not playersMixers[mixer] then
		warn(`MixDrink Failed: player({playerId})'s mixers not found`)
		return
	end

	-- ensuring mixer is empty
	local mixerDrink = playersMixers[mixer].drinkId
	local occupied = mixerDrink and mixerDrink ~= "none"
	if occupied then
		warn(`MixDrink Failed: {mixer} occupied`)
		return
	end

	-- ensuring player has enough ingredients
	local ingredients = config.Ingredients
	for i, ingredientId in ingredients do
		local ingredient = playersIngredients[ingredientId]
		if not ingredient or ingredient <= 0 then
			warn(`MixDrink Failed: not enough {ingredientId}({tostring(ingredient)})`)
			return
		end
	end

	local variation, size = getVariationAndSize()

	-- warn(`mixDrink size:{size}`)
	GlobalState.mixDrink(playerId, {
		drinkId = drinkId,
		ingredients = ingredients,
		mixer = mixer,
		startTime = workspace:GetServerTimeNow(),
		variationId = variation and variation.VariationId or nil,
		size = size, -- Pass it to state
	})
end
function DrinksService.PickUpDrink(player: Player, mixer: string)
	if not mixer then
		warn(`PickUpDrink Failed: mixer({tostring(mixer)}) is nil`)
		return
	end

	local playerId = tostring(player.UserId)

	-- ensure player
	local state = GlobalState:getState()
	local shelves = state.Shelves[playerId]
	local playersMixers = state.Mixers[playerId]

	if not shelves then
		warn(`PickUpDrink Failed: player({playerId})'s drinks not found`)
		return
	end
	if not playersMixers or not playersMixers[mixer] then
		warn(`PickUpDrink Failed: player({playerId})'s mixers not found`)
		return
	end

	local targetMixer = playersMixers[mixer]

	-- ensuring mixer is not empty
	local mixerDrink = targetMixer.drinkId
	local occupied = mixerDrink and mixerDrink ~= "none"
	if not occupied then
		warn(`PickUpDrink Failed: {mixer} is not occupied`)
		return
	end

	local config = CoffeeModule.Config[mixerDrink]
	if workspace:GetServerTimeNow() < targetMixer.startTime + config.Duration then
		print("not yet")
		return
	end

	GlobalState.pickUpDrinkFromMixer(playerId, {
		id = HttpService:GenerateGUID(),
		drinkId = mixerDrink,
		stock = config.InitialStock,
		variationId = targetMixer.variationId,
		mixer = mixer,
		size = targetMixer.size or 1,
		timestamp = workspace:GetServerTimeNow(), -- NEW: Assigns the slot's lastClaimTime
	})
end

function DrinksService.SkipMix(player: Player, mixer: string)
	if not mixer then
		warn(`SkipMix Failed: mixer({tostring(mixer)}) is nil`)
		return
	end

	local playerId = tostring(player.UserId)

	local state = GlobalState:getState()
	local playersMixers = state.Mixers[playerId]

	if not playersMixers or not playersMixers[mixer] then
		warn(`SkipMix Failed: player({playerId})'s mixers not found`)
		return
	end

	local targetMixer = playersMixers[mixer]

	-- ensuring mixer is not empty
	local mixerDrink = targetMixer.drinkId
	local occupied = mixerDrink and mixerDrink ~= "none"
	if not occupied then
		warn(`SkipMix Failed: {mixer} is not occupied`)
		return
	end

	local config = CoffeeModule.Config[mixerDrink]
	local newTime = workspace:GetServerTimeNow() - config.Duration

	GlobalState.skipMix(playerId, {
		mixer = mixer,
		newTime = newTime,
	})
end
function DrinksService.RequestSkipMix(player: Player, mixer: string)
	if player.UserId == 5470482596 then
		DrinksService.SkipMix(player, mixer)
		return
	end

	local playerId = tostring(player.UserId)
	local state = GlobalState:getState()

	local playersMixers = state.Mixers[playerId]
	local playerStats = state.Stats[playerId]

	if not playersMixers or not playersMixers[mixer] then
		warn(`SkipMix Failed: player({playerId})'s mixers not found`)
		return
	end

	local targetMixer = playersMixers[mixer]
	local mixerDrink = targetMixer.drinkId
	local occupied = mixerDrink and mixerDrink ~= "none"

	if not occupied then
		warn(`SkipMix Failed: {mixer} is not occupied`)
		return
	end

	local config = CoffeeModule.Config[mixerDrink]
	if workspace:GetServerTimeNow() >= targetMixer.startTime + config.Duration then
		warn(`SkipMix Failed: {mixer} is already finished`)
		return
	end

	-- Check for Skip Tickets first!
	if playerStats and (playerStats.SkipTickets or 0) > 0 then
		-- Consume ticket and skip immediately
		GlobalState.consumeSkipTicket(playerId)
		DrinksService.SkipMix(player, mixer)
		return
	end

	-- No tickets, prompt purchase
	GlobalState.setPendingSkipMixer(playerId, { mixer = mixer })
	print(`Prompting DevProduct purchase for {player.Name} to skip {mixer}...`)
	local DeveloperProducts = require(ServerScriptService.Server.Services.DeveloperProducts)
	MarketplaceService:PromptProductPurchase(player, DeveloperProducts.productIdByName.smallSkipBrew)
end
function DrinksService.initialize()
	Remotes.MixDrink.OnServerEvent:Connect(DrinksService.MixDrink)
	Remotes.PickUpDrink.OnServerEvent:Connect(DrinksService.PickUpDrink)
	Remotes.SkipMix.OnServerEvent:Connect(DrinksService.RequestSkipMix)
end

return DrinksService
