local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local e = React.createElement
local useState = React.useState
local ReactRoblox = require(ReplicatedStorage.Packages.ReactRoblox)

local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local UIState = require(ReplicatedStorage.Shared.producers.UIState)

local ViewportController = require(ReplicatedStorage.Shared.Controllers.ViewportController)
local PlacementController = require(ReplicatedStorage.Shared.Controllers.PlacementController)
local StoryApp = function()
	return e(require(ReplicatedStorage.Shared.ReactComponents.BuildPanel))
end

local PlotConfig = require(ReplicatedStorage.Shared.Configs.PlotConfig:Clone())
local function getPlot()
	PlotConfig.FirstPlot.plotSize = 32
	return PlotConfig.FirstPlot
end
local function story(frame: Frame)
	local root = ReactRoblox.createRoot(frame)
	UIState.selectBuildItem("PAINT_MODE")
	UIState.toggle("build")
	root:render(e(StoryApp))
	local mockUserId = "MockUser"

	-- 1. Initialize Mock State for UI Labs / Storybook
	local inventory = {}
	-- for _, config in ipairs(PlaceablesModule.Array) do
	-- 	inventory[config.Id] = math.min(32, config.MaxAllowed)
	-- end

	GlobalState.startPlayerSession(mockUserId, {
		Plot = getPlot(),
		Stats = {
			EXP = 100000,
			Level = 100000,
			Cash = 500000,
			TutorialCompleted = false,
			CafeOpen = true,
			PlayerPhase = "playing",
			OwnedGamePasses = {
				-- PremiumPaint = true,
			},
		},
		Inventory = inventory,
		Ingredients = {},
		Customers = {},
		Workers = {},
		Cups = {},
	})

	-- 5. Initialize Client Controllers
	ViewportController.initialize()
	PlacementController.initialize()
	PlacementController:setBuildMode(false)
	return function()
		root:unmount()
		-- Clear State
		-- Shutdown Client Controllers
		PlacementController:setBuildMode(false)
		PlacementController.cleanup()
		ViewportController.cleanup()

		-- Clear State
		GlobalState:resetState()
		UIState:resetState()
	end
end

return story
