local AnalyticsService = game:GetService("AnalyticsService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local PlaceablesModule = require(ReplicatedStorage.Shared.PlaceablesModule)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local TelemetryService = {}
TelemetryService._connections = {}

local MAX_LEVEL = 20
local ONBOARDING_FUNNEL = {
	[1] = "Joined",
	[2] = "Play Pressed",
	[3] = "Customer Arrived",
	[4] = "Order Taken",
	[5] = "Cup Taken",
	[6] = "First Ingredient",
	[7] = "First Customer Served",
	[8] = "Second Customer Served",
	[9] = "Tutorial Complete",
}

local onboardingActive = {}
local onboardingDone = {}
local levelDone = {}
local shopSessionIds = {}

local function isStudio(): boolean
	return RunService:IsStudio()
end

local function getPlayer(playerId: string): Player?
	return Players:GetPlayerByUserId(tonumber(playerId) or 0)
end

local function onboardingKey(playerId: string): { [number]: boolean }
	onboardingDone[playerId] = onboardingDone[playerId] or {}
	return onboardingDone[playerId]
end

local function logOnboarding(player: Player, step: number)
	local playerId = tostring(player.UserId)
	if not onboardingActive[playerId] then
		return
	end

	local done = onboardingKey(playerId)
	if done[step] then
		return
	end
	done[step] = true

	local stepName = ONBOARDING_FUNNEL[step]
	if not stepName then
		return
	end

	if isStudio() then
		print(`[Analytics] Onboarding {step} - {stepName} ({player.Name})`)
		return
	end

	pcall(function()
		AnalyticsService:LogOnboardingFunnelStepEvent(player, step, stepName)
	end)
end

local function logLevels(player: Player, previousLevel: number?, nextLevel: number?)
	if not previousLevel or not nextLevel or nextLevel <= previousLevel then
		return
	end

	local playerId = tostring(player.UserId)
	levelDone[playerId] = levelDone[playerId] or {}

	local firstLevel = math.max(2, previousLevel + 1)
	local lastLevel = math.min(nextLevel, MAX_LEVEL)

	for level = firstLevel, lastLevel do
		if not levelDone[playerId][level] then
			levelDone[playerId][level] = true
			local step = level - 1
			local stepName = `Level {level}`

			if isStudio() then
				print(`[Analytics] Level Progression {step} - {stepName} ({player.Name})`)
			else
				pcall(function()
					AnalyticsService:LogFunnelStepEvent(player, "Level Progression", playerId, step, stepName)
				end)
			end
		end
	end
end

local function logCustom(player: Player, eventName: string, value: number, customFields: any?)
	if isStudio() then
		print(`[Analytics] Custom {eventName} = {value} ({player.Name})`)
		return
	end

	pcall(function()
		AnalyticsService:LogCustomEvent(player, eventName, value, customFields)
	end)
end

local function logShopStep(player: Player, step: number, stepName: string, customFields: any?)
	local playerId = tostring(player.UserId)
	local sessionId = shopSessionIds[playerId]
	if not sessionId then
		sessionId = HttpService:GenerateGUID(false)
		shopSessionIds[playerId] = sessionId
	end

	if isStudio() then
		print(`[Analytics] Shop {step} - {stepName} ({player.Name})`)
		return
	end

	pcall(function()
		AnalyticsService:LogFunnelStepEvent(player, "Shop", sessionId, step, stepName, customFields)
	end)
end

function TelemetryService.LogShopPurchase(player: Player, productKey: string)
	logShopStep(player, 3, "Purchase Completed", { ProductKey = productKey })
	shopSessionIds[tostring(player.UserId)] = nil
end

local function handleStartPlayerSession(args, _prevState, _nextState)
	local player = getPlayer(args[1])
	local data = args[2]
	if not player or type(data) ~= "table" then
		return
	end

	if data.Stats and data.Stats.TutorialCompleted == true then
		onboardingActive[tostring(player.UserId)] = nil
		return
	end

	onboardingActive[tostring(player.UserId)] = true
	logOnboarding(player, 1)
end

local function handleSetPlayerPhase(args, _prevState, _nextState)
	local player = getPlayer(args[1])
	if player and args[2] == "playing" then
		logOnboarding(player, 2)
	end
end

local function handleSpawnCustomer(args, _prevState, _nextState)
	local player = getPlayer(args[1])
	if player then
		logOnboarding(player, 3)
	end
end

local function handleTakeOrder(args, _prevState, _nextState)
	local player = getPlayer(args[1])
	local payload = args[2]
	if player and payload and (payload.workerUid == nil or payload.workerUid == "player") then
		logOnboarding(player, 4)
	end
end

local function handleGetCup(args, _prevState, _nextState)
	local player = getPlayer(args[1])
	local workerUid = args[2]
	if player and (workerUid == nil or workerUid == "player") then
		logOnboarding(player, 5)
	end
end

local function handleAddIngredient(args, _prevState, _nextState)
	local player = getPlayer(args[1])
	local payload = args[2]
	if player and payload and (payload.workerUid == nil or payload.workerUid == "player") then
		logOnboarding(player, 6)
	end
end

local function handleServeCustomer(args, prevState, nextState)
	local player = getPlayer(args[1])
	local payload = args[2]
	if not player or not payload then
		return
	end

	local playerId = tostring(player.UserId)
	local prevStats = prevState.Stats and prevState.Stats[playerId]
	local nextStats = nextState.Stats and nextState.Stats[playerId]

	if payload.workerUid == nil or payload.workerUid == "player" then
		local served = nextStats and nextStats.PlayerCustomersServed or 0
		if served >= 1 then
			logOnboarding(player, 7)
		end
		if served >= 2 then
			logOnboarding(player, 8)
		end
	end

	if prevStats and nextStats then
		logLevels(player, prevStats.Level, nextStats.Level)
	end
end

local function handleAddExp(args, prevState, nextState)
	local player = getPlayer(args[1])
	if not player then
		return
	end

	local playerId = tostring(player.UserId)
	local prevStats = prevState.Stats and prevState.Stats[playerId]
	local nextStats = nextState.Stats and nextState.Stats[playerId]
	if prevStats and nextStats then
		logLevels(player, prevStats.Level, nextStats.Level)
	end
end

local function handleCompleteTutorial(args, _prevState, _nextState)
	local player = getPlayer(args[1])
	if player then
		logOnboarding(player, 9)
		onboardingActive[tostring(player.UserId)] = nil
	end
end

local function handleHireCashier(args, _prevState, nextState)
	local player = getPlayer(args[1])
	local playerId = args[1]
	if not player then
		return
	end

	local workers = nextState.Workers and nextState.Workers[playerId] or {}
	logCustom(player, "WorkerHired", 1, { WorkerCount = tostring(#workers) })
end

local function handleExpandPlot(args, _prevState, _nextState)
	local player = getPlayer(args[1])
	local payload = args[2]
	if player and payload then
		logCustom(player, "PlotExpanded", payload.newSize or 1, { NewSize = tostring(payload.newSize or 0) })
	end
end

local function handleBuyItem(args, _prevState, _nextState)
	local player = getPlayer(args[1])
	local payload = args[2]
	if not player or not payload or (payload.totalCost or 0) <= 0 then
		return
	end

	local config = PlaceablesModule.GetConfig(payload.itemId)
	if config and config.Category == "Station" then
		logCustom(player, "StationPurchased", 1, { StationId = payload.itemId })
	end
end

local actionHandlers = {
	startPlayerSession = handleStartPlayerSession,
	setPlayerPhase = handleSetPlayerPhase,
	spawnCustomer = handleSpawnCustomer,
	takeCustomerOrder = handleTakeOrder,
	getCup = handleGetCup,
	addIngredient = handleAddIngredient,
	serveCustomer = handleServeCustomer,
	_addExp = handleAddExp,
	completeTutorial = handleCompleteTutorial,
	hireCashier = handleHireCashier,
	expandPlot = handleExpandPlot,
	buyItem = handleBuyItem,
}

local function applyGlobalStateMiddleware()
	if TelemetryService._middlewareApplied then
		return
	end
	TelemetryService._middlewareApplied = true

	GlobalState:applyMiddleware(function(producer)
		return function(dispatch, actionName)
			return function(...)
				local args = { ... }
				local prevState = producer:getState()
				local result = dispatch(...)
				local nextState = producer:getState()
				local handler = actionHandlers[actionName]

				if handler then
					local ok, err = pcall(handler, args, prevState, nextState)
					if not ok then
						warn(`[TelemetryService] {actionName} failed: {err}`)
					end
				end

				return result
			end
		end
	end)
end

applyGlobalStateMiddleware()

function TelemetryService.initialize()
	table.insert(
		TelemetryService._connections,
		Remotes.LogShopFunnel.OnServerEvent:Connect(function(player, step)
			if step == 1 then
				logShopStep(player, 1, "Opened Premium")
			elseif step == 2 then
				logShopStep(player, 2, "Selected Product")
			end
		end)
	)

	table.insert(
		TelemetryService._connections,
		Players.PlayerRemoving:Connect(function(player)
			local playerId = tostring(player.UserId)
			onboardingActive[playerId] = nil
			onboardingDone[playerId] = nil
			levelDone[playerId] = nil
			shopSessionIds[playerId] = nil
		end)
	)
end

function TelemetryService.cleanup()
	for _, connection in ipairs(TelemetryService._connections) do
		connection:Disconnect()
	end
	table.clear(TelemetryService._connections)
	table.clear(onboardingActive)
	table.clear(onboardingDone)
	table.clear(levelDone)
	table.clear(shopSessionIds)
end

return TelemetryService
