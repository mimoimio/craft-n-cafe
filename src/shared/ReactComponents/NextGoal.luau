-- Shared/ReactComponents/NextGoal.luau
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)
local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local LevelConfig = require(ReplicatedStorage.Shared.Configs.LevelConfig)
local PlaceablesModule = require(ReplicatedStorage.Shared.PlaceablesModule)

local SmallText = require(ReplicatedStorage.Shared.ReactComponents.ui.SmallText)
local useBreakpoint = require(ReplicatedStorage.Shared.Hooks.useBreakpoint)

local e = React.createElement
local useEffect = React.useEffect
local useState = React.useState

local player = Players.LocalPlayer
local playerId = player and tostring(player.UserId) or "MockUser"

local function countPlaced(plotState, itemId: string): number
	local count = 0
	if not plotState then
		return count
	end

	for _, item in pairs(plotState.placedItems or {}) do
		if item.id == itemId then
			count += 1
		end
	end
	for _, item in pairs(plotState.spatialItems or {}) do
		if item.id == itemId then
			count += 1
		end
	end

	return count
end

local function nextPlaceableUnlock(level: number): any?
	local nextConfig = nil

	for _, config in ipairs(PlaceablesModule.Array) do
		local isProgressionItem = config.Category == "Station" or config.Category == "Cashier"
		if isProgressionItem and config.UnlockLevel > level then
			if not nextConfig or config.UnlockLevel < nextConfig.UnlockLevel then
				nextConfig = config
			end
		end
	end

	return nextConfig
end

local function NextGoal(props)
	local xs, sm, md = useBreakpoint()
	local mobile = xs or sm or md

	local stats, setStats = useState(nil)
	local inventory, setInventory = useState(nil)
	local plot, setPlot = useState(nil)
	local workers, setWorkers = useState(nil)

	useEffect(function()
		local unsubStats = GlobalState:subscribe(function(state: GlobalState.GlobalState)
			return state.Stats[playerId]
		end, setStats)
		local unsubInventory = GlobalState:subscribe(function(state: GlobalState.GlobalState)
			return state.Inventory[playerId]
		end, setInventory)
		local unsubPlot = GlobalState:subscribe(function(state: GlobalState.GlobalState)
			return state.Plot[playerId]
		end, setPlot)
		local unsubWorkers = GlobalState:subscribe(function(state: GlobalState.GlobalState)
			return state.Workers[playerId]
		end, setWorkers)

		local state = GlobalState:getState()
		setStats(state.Stats[playerId])
		setInventory(state.Inventory[playerId])
		setPlot(state.Plot[playerId])
		setWorkers(state.Workers[playerId])

		return function()
			unsubStats()
			unsubInventory()
			unsubPlot()
			unsubWorkers()
		end
	end, {})

	if not stats or stats.TutorialCompleted ~= true then
		return nil
	end

	local level = stats.Level or 1
	local exp = stats.EXP or 0
	local expToNext = math.max(0, LevelConfig.GetExpOnLevel(level) - exp)

	local function expToLevel(targetLevel: number): number
		return math.max(0, LevelConfig.GetExpOnLevel(targetLevel - 1) - exp)
	end

	local playerInventory = inventory or {}
	local cashier2Owned = (playerInventory["Cashier2"] or 0) + countPlaced(plot, "Cashier2")
	local cashier2Placed = countPlaced(plot, "Cashier2")
	local workerCount = workers and #workers or 0
	local plotSize = plot and plot.plotSize or 32

	local goal
	if level < 4 then
		goal = `Next: Level 4 ({expToLevel(4)} EXP)`
	elseif cashier2Placed == 0 then
		goal = if cashier2Owned > 0 then "Next: Place Register #2" else "Next: Buy Register #2"
	elseif level < 6 then
		goal = `Next: Level 6 ({expToLevel(6)} EXP)`
	elseif workerCount == 0 then
		goal = "Next: Hire your first barista"
	elseif plotSize < 48 then
		goal = "Next: Expand your cafe"
	elseif level < 7 then
		goal = `Next: Level 7 ({expToLevel(7)} EXP)`
	else
		local nextConfig = nextPlaceableUnlock(level)
		goal = if nextConfig
			then `Next: {nextConfig.DisplayName} · Level {nextConfig.UnlockLevel}`
			else `Next: Level {level + 1} ({expToNext} EXP)`
	end

	return e(SmallText, {
		Text = goal,
		TextSize = mobile and 14 or 18,
		TextColor3 = Color3.fromRGB(255, 232, 170),
		TextXAlignment = Enum.TextXAlignment.Center,
		TextStrokeTransparency = 0.35,
		AutomaticSize = Enum.AutomaticSize.XY,
		LayoutOrder = props.LayoutOrder,
	})
end

return NextGoal
