-- GeneralHud.story.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

local React = require(ReplicatedStorage.Packages.React)
local e = React.createElement
local ReactRoblox = require(ReplicatedStorage.Packages.ReactRoblox)

local PlaceablesModule = require(ReplicatedStorage.Shared.PlaceablesModule)
local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local UIState = require(ReplicatedStorage.Shared.producers.UIState)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local LevelConfig = require(ReplicatedStorage.Shared.Configs.LevelConfig)
local PlotConfig = require(ReplicatedStorage.Shared.Configs.PlotConfig:Clone())

local ViewportController = require(ReplicatedStorage.Shared.Controllers.ViewportController)
local PlacementController = require(ReplicatedStorage.Shared.Controllers.PlacementController)
local App = require(ReplicatedStorage.Shared.ReactComponents.App)

-- Services
local CafeRenderingService = require(ServerScriptService.Server.Services.CafeRenderingService)
local PlacementService = require(ServerScriptService.Server.Services.PlacementService)
local ShopService = require(ServerScriptService.Server.Services.ShopService)
local WorkersService = require(ServerScriptService.Server.Services.WorkersService)
local CustomersService = require(ServerScriptService.Server.Services.CustomersService)
local DrinksService = require(ServerScriptService.Server.Services.DrinksService)
local StatsService = require(ServerScriptService.Server.Services.StatsService)

local playersPlotString

local function getPlot()
	PlotConfig.FirstPlot.plotSize = 32
	return PlotConfig.FirstPlot
end

-- Helper for plot serialization
local function formatValue(value, depth)
	local indent = string.rep("\t", depth)
	if type(value) == "table" then
		local results = {}
		for k, v in value do
			if type(v) == "table" then
				table.insert(
					results,
					string.format("%s%s = {", indent, if type(k) == "string" then `["{tostring(k)}"]` else tostring(k))
				)
				table.insert(results, formatValue(v, depth + 1))
				table.insert(results, indent .. "},")
			else
				local cFrameText
				local isCFrame = typeof(v) == "CFrame"
				if isCFrame then
					local components = { v:GetComponents() }
					local texts = {}
					for i, num in components do
						table.insert(texts, `[{i}]=num,`)
					end
					cFrameText = table.concat(texts)
				end
				table.insert(
					results,
					string.format(
						"%s%s=%s,",
						indent,
						if type(k) == "string"
							then `["{tostring(k)}"]`
							elseif type(k) == "number" then `[{tostring(k)}]`
							else tostring(k),
						if isCFrame then cFrameText elseif type(v) == "string" then `"{v}"` else tostring(v)
					)
				)
			end
		end
		return table.concat(results, "\n")
	else
		return string.format("%s%s,", indent, tostring(value))
	end
end

local function story(frame: Frame)
	local mockUserId = "MockUser"

	-- 1. Initialize Mock State for UI Labs / Storybook
	local inventory = {}
	-- for _, config in ipairs(PlaceablesModule.Array) do
	-- 	inventory[config.Id] = math.min(32, config.MaxAllowed)
	-- end

	GlobalState.startPlayerSession(mockUserId, {
		Plot = getPlot(),
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
	local expThread = task.defer(function()
		while task.wait(1) do
			local state = GlobalState:getState()
			local playersStats = state.Stats[mockUserId]
			if playersStats then
				local exp = playersStats.EXP + 1
				local level = LevelConfig.GetLevel(exp)
				exp += level * 2
				GlobalState._addExp(mockUserId, exp, level)
			end
		end
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
	root:render(e(App))

	-- 5. Initialize Client Controllers
	ViewportController.initialize()
	PlacementController.initialize()
	PlacementController:setBuildMode(false)

	-- 6. Cleanup function when story unmounts
	return function()
		-- Serialize Plot for Dev Workflow
		playersPlotString = formatValue(GlobalState:getState().Plot[mockUserId], 1)
		local PlotTemplate = ServerStorage:FindFirstChild("PlotTemplate")
		if PlotTemplate and playersPlotString then
			PlotTemplate.Source = `return \{\n{playersPlotString}\n}`
		end

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
