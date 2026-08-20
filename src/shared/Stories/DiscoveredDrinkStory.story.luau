local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local e = React.createElement
local useState = React.useState
local ReactRoblox = require(ReplicatedStorage.Packages.ReactRoblox)
local DefaultScrollFrame = require(ReplicatedStorage.Shared.ReactComponents.DefaultScrollFrame)
local SmallText = require(ReplicatedStorage.Shared.ReactComponents.ui.SmallText)
local Grid = require(ReplicatedStorage.Shared.ReactComponents.ui.Grid)
local DiscoveredDrink = require(ReplicatedStorage.Shared.ReactComponents.DiscoveredDrink)
local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local ShopCycle = require(ReplicatedStorage.Shared.ShopCycle)

local data = {
	Stats = {
		Sfx = 0.5,
		Music = 0.5,
		SecondsPlayed = 0,
		Cash = 30,
		CafeOpen = false,
		Luck = 1,
		TutorialCompleted = false,
		CafeCapacity = 5,
		RollCooldown = 2,
	},
	Tables = {
		Table1 = {
			TableId = "woodentable",
			Slots = { Slot1 = "none", Slot2 = "none", Slot3 = "none", Slot4 = "none" },
		},
	},
	Drinks = {
		-- {
		-- 	id = "abc",
		-- 	variationId = "starlight",
		-- 	drinkId = "volcafrappuccino",
		-- 	stock = 999_999_999,
		-- },
		-- {
		-- 	id = "addbc",
		-- 	variationId = "starlight",
		-- 	drinkId = "volcafrappuccino",
		-- 	stock = 999_999_999,
		-- },
	},
	Mixers = {
		Mixer1 = { drinkId = "none" },
	},
	Ingredients = {
		-- milk = 100,
	},
	Customers = {},
	Shop = { shops = {} }, -- CRITICAL: Added so Reflex updates sync to the Profile!
	DiscoveredDrinks = {},
	Daily = {
		day = 1,
	},
	Spawner = {},
}

local function story(frame: Frame)
	local root = ReactRoblox.createRoot(frame)
	-- Require ShopService to access the deterministic generator
	local ShopService = require(game.ServerScriptService.Server.Services.ShopService)
	local shopCycleState = ShopCycle.getCurrentState()

	local currentSeed = shopCycleState.seed
	local seedString = tostring(currentSeed)
	local generatedShop = ShopService.GenerateDeterministicShop(currentSeed)

	local VariationService = require(game.ServerScriptService.Server.Services.VariationService)
	local variation = VariationService.GetCurrentVariationEvent() or nil
	GlobalState.startPlayerSession("", data, {
		variationEvent = variation and variation.VariationId or nil,
		newestShop = generatedShop,
		newestSeed = currentSeed,
	})
	root:render(e(DiscoveredDrink))

	return function()
		root:unmount()
	end
end

return story
