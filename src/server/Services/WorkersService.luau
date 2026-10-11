-- ServerScriptService/Server/Services/WorkersService.luau
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local CoffeeModule = require(ReplicatedStorage.Shared.CoffeeModule)
local WorkersConfig = require(ReplicatedStorage.Shared.Configs.WorkersConfig)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Types = require(ReplicatedStorage.Shared.Types)

local WorkersService = {}

-- local LOGENABLED = true
local Log = LOGENABLED and print or function() end

function WorkersService.HireWorker(player: Player)
	local playerId = tostring(player.UserId)
	local state = GlobalState:getState()
	local stats = state.Stats[playerId]
	local workers = state.Workers[playerId] or {}

	if not stats then
		return
	end

	local currentWorkerCount = #workers
	local nextTier = WorkersConfig[currentWorkerCount + 1]

	if not nextTier or stats.Level < nextTier.UnlockLevel or stats.Cash < nextTier.Cost then
		return
	end

	GlobalState.buyItem(playerId, {
		itemId = "Worker_Hire",
		amount = 1,
		totalCost = nextTier.Cost,
	})

	local newWorkerId = HttpService:GenerateGUID(false)
	GlobalState.hireCashier(playerId, {
		id = newWorkerId,
		name = nextTier.Title,
	})
end

function WorkersService.UpgradeWorker(player: Player, payload: Types.UpgradeWorkerRemotePayload)
	if type(payload) ~= "table" or type(payload.workerUid) ~= "string" or type(payload.statType) ~= "string" then
		return
	end

	local playerId = tostring(player.UserId)
	local state = GlobalState:getState()
	local stats = state.Stats and state.Stats[playerId]
	local workers = state.Workers and state.Workers[playerId]

	if not stats or not workers then
		return
	end

	local targetWorker = nil
	for _, w in ipairs(workers) do
		if w.id == payload.workerUid then
			targetWorker = w
			break
		end
	end

	if not targetWorker then
		return
	end

	local currentLevel = 1
	if payload.statType == "walkSpeed" then
		currentLevel = targetWorker.walkSpeedLevel or 1
	elseif payload.statType == "craftSpeed" then
		currentLevel = targetWorker.craftSpeedLevel or 1
	elseif payload.statType == "quality" then
		currentLevel = targetWorker.qualityLevel or 1
	else
		return
	end

	local _, nextEntry = WorkersConfig.GetNextUpgrade(payload.statType, currentLevel)
	if not nextEntry or stats.Cash < nextEntry.Cost then
		return
	end

	GlobalState.upgradeWorker(playerId, {
		workerUid = targetWorker.id,
		statType = payload.statType :: Types.WorkerStatType,
		cost = nextEntry.Cost,
	})
end

function WorkersService.GetStationUuid(plotState: any, stationType: string): string?
	if not plotState then
		return nil
	end
	for uuid, item in pairs(plotState.placedItems or {}) do
		if item.id == stationType then
			return uuid
		end
	end
	for uuid, item in pairs(plotState.spatialItems or {}) do
		if item.id == stationType then
			return uuid
		end
	end
	return nil
end

function WorkersService.CalculateRecipeQueue(playerId: string, drinkId: string): { string }?
	local queue = {}
	table.insert(queue, "cup_station")

	local config = CoffeeModule.Config[drinkId]
	if config and config.Ingredients then
		for _, ing in ipairs(config.Ingredients) do
			table.insert(queue, ing .. "_station")
		end
	end

	return queue
end

function WorkersService.Tick()
	local state = GlobalState:getState()
	if not state.Stats then
		return
	end

	for playerId, _ in pairs(state.Stats) do
		local customers = state.Customers[playerId]
		local workers = state.Workers[playerId]

		if not customers or not workers then
			Log(customers)
			Log(workers)
			continue
		end

		local idleWorkers = {}
		for _, worker in ipairs(workers) do
			if worker.action == "idle" then
				table.insert(idleWorkers, worker)
			end
		end

		if #idleWorkers == 0 then
			Log("#idleWorkers == 0 ")
			continue
		end

		local assignedThisTick = false
		for _, customer in pairs(customers) do
			if customer.customerAction == "queuing" and not customer.servedBy then
				local worker = table.remove(idleWorkers, 1)

				if worker then
					GlobalState.assignWorkerTask(playerId, {
						workerUid = worker.id,
						customerUid = customer.id,
						targetCounterUuid = customer.targetCounterUuid,
					})
					assignedThisTick = true
				end

				if assignedThisTick then
					break
				end
			end
		end
		Log("ticked", playerId)
	end
end

WorkersService._connections = {}
WorkersService._threads = {}

function WorkersService.initialize()
	table.insert(WorkersService._connections, Remotes.HireWorker.OnServerEvent:Connect(WorkersService.HireWorker))
	if Remotes.UpgradeWorker then
		table.insert(
			WorkersService._connections,
			Remotes.UpgradeWorker.OnServerEvent:Connect(WorkersService.UpgradeWorker)
		)
	end

	table.insert(
		WorkersService._threads,
		task.spawn(function()
			while task.wait(1) do
				WorkersService.Tick()
			end
		end)
	)
end

function WorkersService.cleanup()
	for _, conn in ipairs(WorkersService._connections) do
		conn:Disconnect()
	end
	for _, t in ipairs(WorkersService._threads) do
		task.cancel(t)
	end
	table.clear(WorkersService._connections)
	table.clear(WorkersService._threads)
end

return WorkersService