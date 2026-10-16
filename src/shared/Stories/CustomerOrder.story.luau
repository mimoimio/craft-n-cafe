-- GeneralHud.story.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

local React = require(ReplicatedStorage.Packages.React)
local e = React.createElement
local ReactRoblox = require(ReplicatedStorage.Packages.ReactRoblox)
local Mionum = require(ReplicatedStorage.Packages.Mionum)

local PlaceablesModule = require(ReplicatedStorage.Shared.PlaceablesModule)
local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local UIState = require(ReplicatedStorage.Shared.producers.UIState)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local LevelConfig = require(ReplicatedStorage.Shared.Configs.LevelConfig)
local PlotConfig = require(ReplicatedStorage.Shared.Configs.PlotConfig:Clone())

local ViewportController = require(ReplicatedStorage.Shared.Controllers.ViewportController)
local PlacementController = require(ReplicatedStorage.Shared.Controllers.PlacementController)
local App = require(ReplicatedStorage.Shared.ReactComponents.App)
local SmallText = require(ReplicatedStorage.Shared.ReactComponents.ui.SmallText)
local SmallButton = require(ReplicatedStorage.Shared.ReactComponents.ui.SmallButton)

-- Services
local CafeRenderingService = require(ServerScriptService.Server.Services.CafeRenderingService)
local PlacementService = require(ServerScriptService.Server.Services.PlacementService)
local ShopService = require(ServerScriptService.Server.Services.ShopService)
local WorkersService = require(ServerScriptService.Server.Services.WorkersService)
local CustomersService = require(ServerScriptService.Server.Services.CustomersService)
local DrinksService = require(ServerScriptService.Server.Services.DrinksService)
local StatsService = require(ServerScriptService.Server.Services.StatsService)

local playersPlotString


local AppWrapper = function()
	return e(React.Fragment, nil, {
		e(require(ReplicatedStorage.Shared.ReactComponents.CustomersOrder)),
		e(require(ReplicatedStorage.Shared.ReactComponents.ui.VStack), {
			VerticalFlex = "None",
			HorizontalFlex = "None",
			HorizontalAlignment = "Left",
		}, {
			-- e(CashRateCounter),
			-- e(EXPRateCounter),
			-- e(timer),
			e(SmallButton, {
				[React.Event.Activated] = function()
					GlobalState.hireCashier("MockUser", {
						id = "son2" .. tostring(math.random()),
					})
				end,
				Text = "Hire cashier",
			}),
		}),
	})
end

local function story(frame: Frame)
	local mockUserId = "MockUser"

	-- 1. Initialize Mock State for UI Labs / Storybook
	local inventory = {}
	-- for _, config in ipairs(PlaceablesModule.Array) do
	-- 	inventory[config.Id] = math.min(32, config.MaxAllowed)
	-- end

	GlobalState.startPlayerSession(mockUserId, {
		Stats = {
			EXP = 1,
			Level = 1,
			Cash = 500000,
			TutorialCompleted = false,
			CafeOpen = true,
			PlayerPhase = "playing",
		},
		Inventory = inventory,
		Ingredients = {},
		Customers = {},
		Workers = {},
		Cups = {},
	})

	-- 2. Mock EXP Loop
	local exploop = function()
		while task.wait(1) do
			local state = GlobalState:getState()
			local playersStats = state.Stats[mockUserId]
			if playersStats then
				local exp = playersStats.EXP + 1
				local level = LevelConfig.GetLevel(exp)
				exp += level * 5
				GlobalState._addExp(mockUserId, exp, level)
			end
		end
	end

	-- local expThread = task.defer(exploop)
	local expThread = task.defer(function()
		GlobalState.hireCashier(mockUserId, {
			id = "son",
		})
	end)

	-- 3. Initialize REAL Services (They now seamlessly support MockUser via our updates!)
	CafeRenderingService.initialize()
	PlacementService.initialize()
	ShopService.initialize()
	WorkersService.initialize()
	CustomersService.initialize()
	DrinksService.initialize()
	StatsService.initialize()

	-- 4. Render UI
	local root = ReactRoblox.createRoot(frame)
	root:render(e(AppWrapper))

	-- 5. Initialize Client Controllers
	ViewportController.initialize()
	PlacementController.initialize()
	PlacementController:setBuildMode(false)

	-- 6. Cleanup function when story unmounts
	return function()
		if expThread then
			task.cancel(expThread)
		end

		-- Shutdown Client Controllers
		PlacementController:setBuildMode(false)
		PlacementController.cleanup()
		ViewportController.cleanup()
		root:unmount()

		-- Shutdown Server Services cleanly using their new cleanup methods
		CafeRenderingService.cleanup()
		PlacementService.cleanup()
		ShopService.cleanup()
		WorkersService.cleanup()
		CustomersService.cleanup()

		-- Clear State
		GlobalState:resetState()
		UIState:resetState()
	end
end

return story
