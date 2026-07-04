local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local CoffeeModule = require(ReplicatedStorage.Shared.CoffeeModule)

local ShopService = {}

function ShopService.BuyIngredient(player: Player, ingredientId: string)
	if not ingredientId then
		warn(`BuyIngredient Failed: ingredientId is nil`)
		return
	end

	-- ensure ingredient
	local playerId = tostring(player.UserId)
	local config = CoffeeModule.Config[ingredientId]
	if not config then
		warn(`BuyIngredient Failed: {ingredientId} is not a valid drink`)
		return
	end
	if config.Ingredients and #config.Ingredients > 1 then
		warn("That's not an ingredient")
		return
	end

	-- ensure player
	local state = GlobalState:getState()
	local playersIngredients = state.Ingredients[playerId]
	if not playersIngredients then
		warn(`BuyIngredient Failed: player({playerId})'s ingredients not found`)
		return
	end

	-- local cost = config.Price -- no price rn, later config price
	local cost = 2

	warn("Bought")

	GlobalState.buyIngredient(playerId, ingredientId, 1, cost)
end
local tables = {
	[1] = {
		"Table1",
	},
	[2] = {
		"Table2",
	},
	[3] = {
		"Table3",
		"Table4",
	},
	[4] = {
		"Table5",
		"Table6",
	},
	[5] = {
		"Table7",
		"Table8",
	},
	[6] = {
		"Table9",
		"Table10",
	},
	[7] = {
		"Table11",
		"Table12",
	},
	[8] = {
		"Table13",
		"Table14",
		"Table15",
	},
	[9] = {
		"Table16",
		"Table17",
		"Table18",
	},
}
local ingredients = {
	[1] = {
		"espresso",
		"water",
		"milk",
	},
	[2] = {
		"foam",
	},
	[3] = {
		"ice",
		"chocolate",
	},
	[4] = {
		"teabag",
	},
	[5] = {
		"lemon",
	},
	[6] = {
		"carbonator",
	},
	[7] = {
		"icecream",
	},
	[8] = {
		"matcha",
		"boba",
	},
	[9] = {
		"cookies",
	},
}
function ShopService.initialize()
	Remotes.BuyIngredient.OnServerEvent:Connect(ShopService.BuyIngredient)
	Remotes.LevelUp.OnServerEvent:Connect(function(player)
		local playerId = tostring(player.UserId)
		local state = GlobalState:getState()
		local playersStats = state.Stats[playerId]
		local level = playersStats.Level + 1

		if level > 9 then
			print("maxxed")
			return
		end
		local unlockedTables = tables[level]
		local unlockedIngredients = ingredients[level]

		GlobalState.levelUp(playerId, {
			level = level,
			unlockedTables = unlockedTables,
			unlockedIngredients = unlockedIngredients,
		})
	end)
end
return ShopService
