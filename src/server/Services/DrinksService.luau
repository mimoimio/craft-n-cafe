-- DrinksService.luau
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local CoffeeModule = require(ReplicatedStorage.Shared.CoffeeModule)
local Types = require(ReplicatedStorage.Shared.Types)

local function getVariation(): Types.VariationConfig
	local VariationService = require(ServerScriptService.Server.Services.VariationService)

	return VariationService.GetVariation()
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

	local variation = getVariation()
	GlobalState.mixDrink(playerId, {
		drinkId = drinkId,
		ingredients = ingredients,
		mixer = mixer,
		startTime = workspace:GetServerTimeNow(),
		variationId = variation and variation.VariationId or nil,
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
	local playersDrinks = state.Drinks[playerId]
	local playersMixers = state.Mixers[playerId]

	if not playersDrinks then
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
    -- [[ SYSTEM CONTROLLED: Client calls this to initiate purchase ]]
    -- TODO: Integrate MarketplaceService:PromptProductPurchase here!
    -- For now, we will mock the successful purchase for your testing UserId:
    if player.UserId == 5470482596 then
        DrinksService.SkipMix(player, mixer)
    else
        print(`Prompting DevProduct purchase for {player.Name} to skip {mixer}...`)
    end
end

function DrinksService.initialize()
    Remotes.MixDrink.OnServerEvent:Connect(DrinksService.MixDrink)
    Remotes.PickUpDrink.OnServerEvent:Connect(DrinksService.PickUpDrink)
    Remotes.SkipMix.OnServerEvent:Connect(DrinksService.RequestSkipMix)
end

return DrinksService
