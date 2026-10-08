-- ServerScriptService/Server/Services/CustomersService.luau
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Promise = require(ReplicatedStorage.Packages.Promise)
local CoffeeModule = require(ReplicatedStorage.Shared.CoffeeModule)
local LevelConfig = require(ReplicatedStorage.Shared.Configs.LevelConfig)
local Types = require(ReplicatedStorage.Shared.Types)
local PlaceablesModule = require(ReplicatedStorage.Shared.PlaceablesModule)

local SPAWN_INTERVAL = 1
local MAX_WAITING_TIME = 20
local rng = Random.new()
local lastSpawnTimes = {}

local LOGENABLED = true
local Log = LOGENABLED and print or function() end

local CustomersService = {}

function CustomersService.SpawnCustomer(playerId: string)
	local state = GlobalState:getState()
	local playerStats = state.Stats[playerId]
	local playersCustomers = state.Customers[playerId] or {}
	local plotState = state.Plot and state.Plot[playerId]

	if not playerStats or not plotState or not playerStats.CafeOpen then
		Log("not playerStats or not plotState or not playerStats.CafeOpen")
		return
	end

	local counterUuids = {}
	for uuid, item in pairs(plotState.placedItems) do
		local config = PlaceablesModule.GetConfig(item.id)
		if config and config.Category == "Cashier" then
			table.insert(counterUuids, uuid)
		end
	end
	for uuid, item in pairs(plotState.spatialItems) do
		local config = PlaceablesModule.GetConfig(item.id)
		if config and config.Category == "Cashier" then
			table.insert(counterUuids, uuid)
		end
	end

	if #counterUuids == 0 then
		Log("#counterUuids == 0")
		return
	end

	local occupiedCounters = {}
	for _, customer in pairs(playersCustomers) do
		local action = customer.customerAction
		if
			customer.targetCounterUuid
			and (action == "walking" or action == "entering" or action == "queuing" or action == "waiting")
		then
			occupiedCounters[customer.targetCounterUuid] = true
		end
	end

	local availableCounters = {}
	for _, uuid in ipairs(counterUuids) do
		if not occupiedCounters[uuid] then
			table.insert(availableCounters, uuid)
		end
	end

	if #availableCounters == 0 then
		return
	end

	local chosenCounterUuid = availableCounters[math.random(1, #availableCounters)]
	local uid = HttpService:GenerateGUID(false)

	GlobalState.spawnCustomer(playerId, {
		customerId = "",
		customerUid = uid,
		targetCounterUuid = chosenCounterUuid,
		timestamp = workspace:GetServerTimeNow(),
	})
	Log("#spawnedCustomer")

	lastSpawnTimes[playerId] = workspace:GetServerTimeNow()
	return uid
end

function CustomersService.ServeCustomer(player: Player?, uid: string, workerUid: string)
	workerUid = workerUid or "player"
	local playerId = tostring(player.UserId)
	local state = GlobalState:getState()

	local playersCustomers = state.Customers[playerId]
	local playersStats = state.Stats[playerId]
	local playersWorkers = state.Workers[playerId]
	local playersCups = state.Cups[playerId]

	local cup = playersCups and playersCups[workerUid]
	local worker

	for i, _worker in playersWorkers or {} do
		if _worker.id == workerUid then
			worker = _worker
		end
	end

	if
		not (playersCustomers and cup and cup.drinkId)
		or (not worker and workerUid ~= "player")
		or (cup and cup.drinkId == "none")
	then
		return
	end

	local found
	for _, customer in ipairs(playersCustomers) do
		if customer.id == uid then
			found = customer
			break
		end
	end

	if not (found and found.order and found.customerAction == "waiting" and found.servedBy == workerUid) then
		if workerUid ~= "player" then
			local WorkersService = require(script.Parent.WorkersService)
			local trashUuid = WorkersService.GetStationUuid(state.Plot[playerId], "trash_station")
			GlobalState.wrongOrder(playerId, {
				customerUid = uid,
				timestamp = workspace:GetServerTimeNow(),
				workerUid = workerUid,
				nextTargetUuid = trashUuid,
			})
		end
		return
	end

	if cup.drinkId == found.order then
		local drinkConfig = CoffeeModule.Config[cup.drinkId]
		local cashReward = drinkConfig and (drinkConfig.Price * cup.score // #drinkConfig.Ingredients)
		local exp = playersStats.EXP + cup.status
		local level = LevelConfig.GetLevel(exp)

		local plotState = state.Plot and state.Plot[playerId]
		local availableSeats = {}

		if plotState then
			local seatUuids = {}
			for uuid, item in pairs(plotState.placedItems) do
				local config = PlaceablesModule.GetConfig(item.id)
				if config and config.Category == "Seat" then
					table.insert(seatUuids, uuid)
				end
			end
			for uuid, item in pairs(plotState.spatialItems) do
				local config = PlaceablesModule.GetConfig(item.id)
				if config and config.Category == "Seat" then
					table.insert(seatUuids, uuid)
				end
			end

			local occupiedSeats = {}
			for _, c in ipairs(playersCustomers) do
				if c.targetSeatUuid then
					occupiedSeats[c.targetSeatUuid] = true
				end
			end

			for _, uuid in ipairs(seatUuids) do
				if not occupiedSeats[uuid] then
					table.insert(availableSeats, uuid)
				end
			end
		end

		local willDineIn = (math.random() > 0.5) and #availableSeats > 0
		local chosenSeatUuid = nil

		if willDineIn then
			chosenSeatUuid = availableSeats[math.random(1, #availableSeats)]
		end

		GlobalState.serveCustomer(playerId, {
			customerUid = uid,
			cash = cashReward,
			EXP = exp,
			level = level,
			timestamp = workspace:GetServerTimeNow(),
			workerUid = workerUid,
			targetSeatUuid = chosenSeatUuid,
		})
	elseif cup.drinkId ~= found.order then
		GlobalState.wrongOrder(playerId, {
			customerUid = uid,
			timestamp = workspace:GetServerTimeNow(),
			workerUid = workerUid,
		})
	end
end

local function getValidMenu(playerId: string, state: any)
	local playerInventory = state.Inventory and state.Inventory[playerId] or {}
	local plotState = state.Plot and state.Plot[playerId] or { placedItems = {}, spatialItems = {} }

	local ownedItems = {}

	for itemId, count in pairs(playerInventory) do
		if count > 0 then
			ownedItems[itemId] = true
		end
	end

	for _, item in pairs(plotState.placedItems) do
		ownedItems[item.id] = true
	end
	for _, item in pairs(plotState.spatialItems) do
		ownedItems[item.id] = true
	end

	local validDrinks = {}

	for _, drinkConfig in ipairs(CoffeeModule.Array) do
		local canMake = true
		if drinkConfig.Ingredients then
			for _, ingId in ipairs(drinkConfig.Ingredients) do
				local requiredStationId = ingId .. "_station"
				if not ownedItems[requiredStationId] then
					canMake = false
					break
				end
			end
		end

		if canMake then
			table.insert(validDrinks, drinkConfig)
		end
	end

	if #validDrinks == 0 then
		table.insert(validDrinks, CoffeeModule.Config["espresso"])
	end

	return validDrinks
end

function CustomersService.TendCustomer(player: Player?, uid: string, workerUid: string?)
	Log("[TendCustomer]", player, uid, workerUid)
	workerUid = workerUid or "player"
	local playerId = tostring(player.UserId)
	local state = GlobalState:getState()

	local playersCustomers = state.Customers[playerId]
	if not playersCustomers then
		Log("[TendCustomer] playersCustomers is missing")
		if workerUid ~= "player" then
			GlobalState.resetWorker(playerId, { workerUid = workerUid })
		end
		return
	end

	local targetCustomer = nil
	local isBusyWithSomeoneElse = false

	for _, customer in ipairs(playersCustomers) do
		if customer.id == uid then
			targetCustomer = customer
		end

		if
			customer.id ~= uid
			and customer.servedBy == workerUid
			and (customer.customerAction == "waiting" or customer.customerAction == "queuing")
		then
			isBusyWithSomeoneElse = true
		end
	end

	if isBusyWithSomeoneElse then
		Log("[TendCustomer] Rejected! Worker/Player", workerUid, "is already busy with another customer.")
		if workerUid ~= "player" then
			GlobalState.resetWorker(playerId, { workerUid = workerUid })
		end
		return
	end

	if
		not targetCustomer
		or (targetCustomer.servedBy and targetCustomer.servedBy ~= workerUid)
		or targetCustomer.customerAction ~= "queuing"
	then
		Log("[TendCustomer] Customer missing, stolen, or not queuing.")
		if workerUid ~= "player" then
			GlobalState.resetWorker(playerId, { workerUid = workerUid })
		end
		return
	end

	local validMenu = getValidMenu(playerId, state)
	if #validMenu == 0 then
		Log("[TendCustomer] #validMenu == 0")
		if workerUid ~= "player" then
			GlobalState.resetWorker(playerId, { workerUid = workerUid })
		end
		return
	end

	local order = validMenu[math.random(1, #validMenu)]
	local recipeQueue = nil
	local nextTargetUuid = nil

	if workerUid ~= "player" then
		local WorkersService = require(script.Parent.WorkersService)
		local fullQueue = WorkersService.CalculateRecipeQueue(playerId, order.Id)

		if fullQueue and #fullQueue > 0 then
			nextTargetUuid = table.remove(fullQueue, 1)
			recipeQueue = fullQueue
		else
			Log("[TendCustomer] CalculateRecipeQueue failed to generate a queue")
			GlobalState.resetWorker(playerId, { workerUid = workerUid })
			return
		end
	end

	Log("[TendCustomer] takeCustomerOrder successfully dispatched")

	GlobalState.takeCustomerOrder(playerId, {
		order = order.Id,
		customerUid = uid,
		workerUid = workerUid,
		timestamp = workspace:GetServerTimeNow(),
		recipeQueue = recipeQueue,
		nextTargetUuid = nextTargetUuid,
	})
end

CustomersService._connections = {}
CustomersService._threads = {}

function CustomersService.initialize()
	table.insert(
		CustomersService._connections,
		Remotes.TendCustomer.OnServerEvent:Connect(function(player, ...)
			CustomersService.TendCustomer(player, ...)
		end)
	)
	table.insert(
		CustomersService._connections,
		Remotes.ServeCustomer.OnServerEvent:Connect(function(player, ...)
			CustomersService.ServeCustomer(player, ...)
		end)
	)

	table.insert(
		CustomersService._threads,
		task.spawn(function()
			while task.wait(1) do
				local now = workspace:GetServerTimeNow()
				local state = GlobalState:getState()

				if not state.Stats then
					continue
				end

				for playerId, playerStats in pairs(state.Stats) do
					local playersCustomers = state.Customers[playerId]
					local plotState = state.Plot and state.Plot[playerId]

					if not playersCustomers or not plotState then
						continue
					end
					if playerStats.PlayerPhase ~= "playing" then
						continue
					end

					local preServeCustomerCount = 0
					local minOneCustomerWaiting = false

					for _, customer in playersCustomers do
						local action = customer.customerAction

						-- DELETED CASH REGISTER FAILSAFE: Boot customer immediately if their register is gone!
						local cashierExists = true
						if customer.targetCounterUuid then
							if
								not plotState.placedItems[customer.targetCounterUuid]
								and not plotState.spatialItems[customer.targetCounterUuid]
							then
								cashierExists = false
							end
						end

						if
							not cashierExists and (action == "walking" or action == "queuing" or action == "waiting")
						then
							Log(
								`[CustomersService] 🚨 Cashier {customer.targetCounterUuid} was deleted! Booting customer.`
							)
							local WorkersService = require(script.Parent.WorkersService)
							local trashUuid = WorkersService.GetStationUuid(plotState, "trash_station")

							GlobalState.wrongOrder(playerId, {
								customerUid = customer.id,
								timestamp = now,
								workerUid = customer.servedBy,
								nextTargetUuid = trashUuid,
							})
							continue
						end

						-- Normal loop logic
						if
							action == "walking"
							or action == "entering"
							or action == "queuing"
							or action == "waiting"
						then
							preServeCustomerCount += 1
						end
						if action == "waiting" or action == "queuing" then
							minOneCustomerWaiting = true
						end
					end

					if
						minOneCustomerWaiting
						and playerStats.PlayerPhase == "playing"
						and playerStats.TutorialCompleted
					then
						GlobalState.tickCustomer(playerId)
					end

					local lastSpawn = lastSpawnTimes[playerId] or 0
					local randomInterval = (
						SPAWN_INTERVAL - (rng:NextNumber() * rng:NextNumber() * rng:NextNumber() * 8) // 1
					)

					if now - lastSpawn >= randomInterval and playerStats.CafeOpen then
						Promise.defer(function(resolve)
							local amount = 1
							for i = 1, amount do
								CustomersService.SpawnCustomer(playerId)
								task.wait(math.random() * SPAWN_INTERVAL)
							end
							return resolve
						end):catch(function(err)
							warn(`spawn cust err: {err}`)
						end)
					end

					for _, customer in ipairs(playersCustomers) do
						local timeInState = now - (customer.actionStartTime or now)

						if
							customer.customerAction == "paid"
							or customer.customerAction == "emptyHanded"
							or customer.customerAction == "leaving"
						then
							if timeInState >= 30 then
								GlobalState.removeCustomer(playerId, customer.id)
								continue
							end
						end

						if customer.customerAction == "sitting" then
							local MAX_DINING_TIME = 50
							if timeInState >= MAX_DINING_TIME then
								GlobalState.finishDining(playerId, {
									customerUid = customer.id,
									timestamp = now,
								})
								continue
							end
						end

						if
							(customer.customerAction == "waiting" or customer.customerAction == "queuing")
							and customer.secondsWaited
						then
							if customer.secondsWaited > MAX_WAITING_TIME then
								GlobalState.timeOut(playerId, {
									customerUid = customer.id,
									timestamp = workspace:GetServerTimeNow(),
								})
								continue
							end
						end
					end
				end
			end
		end)
	)
end

function CustomersService.cleanup()
	for _, conn in ipairs(CustomersService._connections) do
		conn:Disconnect()
	end
	for _, t in ipairs(CustomersService._threads) do
		task.cancel(t)
	end
	table.clear(CustomersService._connections)
	table.clear(CustomersService._threads)
end

return CustomersService
