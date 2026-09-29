-- GeneralHud.story.luau
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local UserInputService = game:GetService("UserInputService")
local React = require(ReplicatedStorage.Packages.React)
local e = React.createElement
local ReactRoblox = require(ReplicatedStorage.Packages.ReactRoblox)

local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local UIState = require(ReplicatedStorage.Shared.producers.UIState)
local Grid = require(ReplicatedStorage.Shared.Grid)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local PlaceablesModule = require(ReplicatedStorage.Shared.PlaceablesModule)
local ViewportController = require(ReplicatedStorage.Shared.Controllers.ViewportController)
local Main = require(ReplicatedStorage.Shared.ReactComponents.Main)
local App = require(ReplicatedStorage.Shared.ReactComponents.App)
local PlotConfig = require(ReplicatedStorage.Shared.Configs.PlotConfig:Clone())

local InputAdapter = require(ReplicatedStorage.Shared.Controllers.InputAdapter)

local CafeRenderingService = require(ServerScriptService.Server.Services.CafeRenderingService)

local function getPlot()
	PlotConfig.FirstPlot.plotSize = 32
	return PlotConfig.FirstPlot
end
local function story(frame: Frame)
	local inventory = {}
	for i, config in PlaceablesModule.Array do
		inventory[config.Id] = math.min(32, config.MaxAllowed)
	end
	UIState.toggle("shop")
	GlobalState.startPlayerSession("MockUser", {
		Plot = getPlot(),
		Stats = { EXP = 100, Level = 5, Cash = 500000 },
		Inventory = inventory,

		Ingredients = {},
		Customers = {},
		Workers = {},
		Cups = {},
	})

	local root = ReactRoblox.createRoot(frame)
	root:render(e(require(ReplicatedStorage.Shared.ReactComponents.ShopPanel)))
	ViewportController.initialize()

	return function()

		root:unmount()
		ViewportController.cleanup()
		GlobalState:resetState()
		UIState:resetState()
	end
end

return story
