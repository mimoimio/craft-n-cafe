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

-- NEW HOOK: Calculates a smooth sliding-window average rate over X seconds
local function useRollingRate(currentValue: number?, windowSeconds: number)
	-- FIX: useBinding prevents React from lagging out trying to render 60 times a second
	local rateBinding, setRateBinding = React.useBinding(0)

	local historyRef = React.useRef({})
	local latestValueRef = React.useRef(currentValue)
	local isFirstLoad = React.useRef(true)

	-- Update history whenever the raw value changes
	React.useEffect(function()
		if currentValue == nil then
			return
		end
		latestValueRef.current = currentValue

		-- IGNORE THE FIRST LOAD SPIKE (e.g. going from nil to 500,000 cash)
		if isFirstLoad.current then
			historyRef.current = { { t = workspace:GetServerTimeNow(), v = currentValue } }
			isFirstLoad.current = false
			return
		end

		table.insert(historyRef.current, { t = workspace:GetServerTimeNow(), v = currentValue })
	end, { currentValue })

	-- Constantly evaluate the rate over time, independent of value changes
	React.useEffect(function()
		local connection = RunService.Heartbeat:Connect(function()
			if isFirstLoad.current then
				return
			end

			local now = workspace:GetServerTimeNow()
			local history = historyRef.current

			-- Purge records older than the window
			while #history > 1 and (now - history[1].t > windowSeconds) do
				table.remove(history, 1)
			end

			if #history > 0 and latestValueRef.current then
				local oldest = history[1]
				local dt = now - oldest.t
				local diff = latestValueRef.current - oldest.v

				-- Smooth calculation
				if dt > 1 then
					setRateBinding(diff / dt)
				else
					setRateBinding(diff)
				end
			else
				setRateBinding(0)
			end
		end)

		return function()
			connection:Disconnect()
		end
	end, { windowSeconds })

	return rateBinding
end

local function CashRateCounter()
	local cash, setCash = React.useState(nil)

	React.useEffect(function()
		local unsub = GlobalState:subscribe(function(state: GlobalState.GlobalState)
			return state.Stats and state.Stats["MockUser"] and state.Stats["MockUser"].Cash or nil
		end, setCash)

		local state = GlobalState:getState()
		setCash(state.Stats and state.Stats["MockUser"] and state.Stats["MockUser"].Cash or nil)
		return unsub
	end, {})

	-- FIX: Increased window to 60 seconds so it doesn't instantly reset to 0 between slow customers
	local avgRate = useRollingRate(cash, 60)

	return e(SmallText, {
		Text = avgRate:map(function(rate)
			return `Cash: {Mionum.new(rate):toString()}/s`
		end),
	})
end

local function EXPRateCounter()
	local exp, setExp = React.useState(nil)

	React.useEffect(function()
		local unsub = GlobalState:subscribe(function(state: GlobalState.GlobalState)
			return state.Stats and state.Stats["MockUser"] and state.Stats["MockUser"].EXP or nil
		end, setExp)

		local state = GlobalState:getState()
		setExp(state.Stats and state.Stats["MockUser"] and state.Stats["MockUser"].EXP or nil)
		return unsub
	end, {})

	-- FIX: Increased window to 60 seconds
	local avgRate = useRollingRate(exp, 60)

	return e(SmallText, {
		Text = avgRate:map(function(rate)
			return `EXP: {Mionum.new(rate):toString()}/s`
		end),
	})
end

local function timer()
	local elapsed, setElapsed = React.useBinding(nil)

	React.useEffect(function()
		local t = 0
		local conn = RunService.Heartbeat:Connect(function(dt)
			t += dt
			setElapsed(t)
		end)
		return function()
			conn:Disconnect()
		end
	end, {})

	return e(SmallText, {
		Text = elapsed:map(function(elapsedTime)
			return `ELAPSED: {Mionum.new(elapsedTime or 0):toString()}`
		end),
	})
end

local AppWrapper = function()
	return e(React.Fragment, nil, {
		e(App),
		e(require(ReplicatedStorage.Shared.ReactComponents.ui.VStack), {
			VerticalFlex = "None",
			HorizontalFlex = "None",
			HorizontalAlignment = "Left",
		}, {
			e(CashRateCounter),
			e(EXPRateCounter),
			e(timer),
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

		-- -- Serialize Plot for Dev Workflow
		playersPlotString = formatValue(GlobalState:getState().Plot[mockUserId], 1)
		local PlotTemplate = ServerStorage:FindFirstChild("PlotTemplate")
		if PlotTemplate and playersPlotString then
			PlotTemplate.Source = `return \{\n{playersPlotString}\n}`
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
