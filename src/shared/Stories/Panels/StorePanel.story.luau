-- StorePanel.story.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local e = React.createElement
local ReactRoblox = require(ReplicatedStorage.Packages.ReactRoblox)

local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local UIState = require(ReplicatedStorage.Shared.producers.UIState)
local ViewportController = require(ReplicatedStorage.Shared.Controllers.ViewportController)
local StorePanel = require(ReplicatedStorage.Shared.ReactComponents.StorePanel)

local function story(frame: Frame)
	UIState.toggle("store")
	GlobalState.startPlayerSession("MockUser", {
		Plot = {
			grid = {},
			placedItems = {},
			spatialItems = {},
			plotSize = 32,
			nextId = 1,
		},
		Stats = {
			EXP = 100,
			Level = 5,
			Cash = 5000,
			OwnedGamePasses = {},
			PurchasedProducts = {},
			LifetimeCash = 0,
		},
		Inventory = {},
		Ingredients = {},
		Customers = {},
		Workers = {},
		Cups = {},
	})

	local root = ReactRoblox.createRoot(frame)
	root:render(e(StorePanel))
	ViewportController.initialize()

	return function()
		root:unmount()
		ViewportController.cleanup()
		GlobalState:resetState()
		UIState:resetState()
	end
end

return story
