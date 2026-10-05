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

local SPAWN_INTERVAL = 10
local MAX_WAITING_TIME = 20
local rng = Random.new()
local lastSpawnTimes = {}

local CustomersService = {}

function CustomersService.SpawnCustomer(playerId: string)
	local state = GlobalState:getState()
	local playerStats = state.Stats[playerId]
	local playersCustomers = state.Customers[playerId] or {}
	local plotState = state.Plot and state.Plot[playerId]

	if not playerStats or not plotState or not playerStats.CafeOpen then
		return
	end

	-- 1. Find all placed Cashiers using the Category
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
		return
	end

	-- FIX: Only lock the counter if the customer is actively walking to, queuing at, or waiting at it.
	-- If they are "sitting", "paid", or "leaving", the counter is free for the next person!
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

	lastSpawnTimes[playerId] = workspace:GetServerTimeNow()
	return uid
end

function CustomersService.ServeCustomer(player: Player, uid: string, workerUid: string)
	workerUid = workerUid or "player"
	local playerId = tostring(player.UserId)
	local state = GlobalState:getState()

	local playersCustomers = state.Customers[playerId]
	local playersStats = state.Stats[playerId]
	local playersWorkers = state.Workers[playerId]
	local playersCups = state.Cups[playerId]

	local cup = playersCups and playersCups[workerUid]
	local worker = playersWorkers and playersWorkers[workerUid]

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
		print("customer servedBy other")
		return
	end

	if cup.drinkId == found.order then
		local drinkConfig = CoffeeModule.Config[cup.drinkId]
		local cashReward = drinkConfig and (drinkConfig.Price * cup.score // #drinkConfig.Ingredients)
		local exp = playersStats.EXP + cup.status
		local level = LevelConfig.GetLevel(exp)

		-- 1. Get the player's plot data to scan for seats
		local plotState = state.Plot and state.Plot[playerId]
		local availableSeats = {}

		if plotState then
			local seatUuids = {}

			-- Collect all placed Grid seats
			for uuid, item in pairs(plotState.placedItems) do
				local config = PlaceablesModule.GetConfig(item.id)
				if config and config.Category == "Seat" then
					table.insert(seatUuids, uuid)
				end
			end

			-- Collect all Spatial seats
			for uuid, item in pairs(plotState.spatialItems) do
				local config = PlaceablesModule.GetConfig(item.id)
				if config and config.Category == "Seat" then
					table.insert(seatUuids, uuid)
				end
			end

			-- 2. Filter out seats that are already assigned to customers
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

		-- 3. Determine if they dine in (50% chance AND there must be an open seat)
		local willDineIn = (math.random() > 0.5) and #availableSeats > 0
		local chosenSeatUuid = nil

		if willDineIn then
			chosenSeatUuid = availableSeats[math.random(1, #availableSeats)]
		end

		-- 4. Fire the state update
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

-- HELPER: Figures out what drinks a player can actually make based on what they OWN
local function getValidMenu(playerId: string, state: any)
	local playerInventory = state.Inventory and state.Inventory[playerId] or {}
	local plotState = state.Plot and state.Plot[playerId] or { placedItems = {}, spatialItems = {} }

	local ownedItems = {}

	-- 1. Check Inventory
	for itemId, count in pairs(playerInventory) do
		if count > 0 then
			ownedItems[itemId] = true
		end
	end

	-- 2. Check Plot
	for _, item in pairs(plotState.placedItems) do
		ownedItems[item.id] = true
	end
	for _, item in pairs(plotState.spatialItems) do
		ownedItems[item.id] = true
	end

	local validDrinks = {}

	-- 3. Filter valid drinks
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

	return validDrinks
end

function CustomersService.TendCustomer(player: Player, uid: string, workerUid: string)
	workerUid = workerUid or "player"
	local playerId = tostring(player.UserId)
	local state = GlobalState:getState()

	local playersCustomers = state.Customers[playerId]
	local playersWorkers = state.Workers[playerId]

	if not (playersCustomers and playersWorkers) then
		return
	end

	local found
	for _, customer in ipairs(playersCustomers) do
		if customer.id == uid then
			found = customer
		end
		if customer.servedBy == workerUid then
			return
		end
	end

	if found.servedBy or found.customerAction ~= "queuing" then
		return
	end

	local validMenu = getValidMenu(playerId, state)
	if #validMenu == 0 then
		warn(`Player {playerId} owns no stations to make any drinks!`)
		return
	end

	local order = validMenu[math.random(1, #validMenu)]

	GlobalState.takeCustomerOrder(playerId, {
		order = order.Id,
		customerUid = uid,
		workerUid = workerUid,
		timestamp = workspace:GetServerTimeNow(),
	})
end

function CustomersService.initialize()
	Remotes.TendCustomer.OnServerEvent:Connect(CustomersService.TendCustomer)
	Remotes.ServeCustomer.OnServerEvent:Connect(CustomersService.ServeCustomer)

	task.spawn(function()
		while task.wait(1) do
			local now = workspace:GetServerTimeNow()
			local state = GlobalState:getState()

			for _, player in ipairs(game.Players:GetPlayers()) do
				local playerId = tostring(player.UserId)
				local playerStats = state.Stats[playerId]
				local playersCustomers = state.Customers[playerId]

				if not playerStats or not playersCustomers then
					continue
				end

				if playerStats.PlayerPhase ~= "playing" then
					continue
				end

				-- local CafeCapacity = playerStats.CafeCapacity or 4

				-- FIX: Count only customers in "pre-serve" states for capacity limits
				local preServeCustomerCount = 0
				local minOneCustomerWaiting = false

				for _, customer in playersCustomers do
					local action = customer.customerAction

					if action == "walking" or action == "entering" or action == "queuing" or action == "waiting" then
						preServeCustomerCount += 1
					end

					if action == "waiting" or action == "queuing" then
						minOneCustomerWaiting = true
					end
				end

				if minOneCustomerWaiting and playerStats.PlayerPhase == "playing" then
					GlobalState.tickCustomer(playerId)
				end

				local lastSpawn = lastSpawnTimes[playerId] or 0
				local randomInterval = (
					SPAWN_INTERVAL - (rng:NextNumber() * rng:NextNumber() * rng:NextNumber() * 8) // 1
				)

				-- Spawns ONLY if preServeCustomerCount is less than capacity
				if
					now - lastSpawn >= randomInterval
					-- and preServeCustomerCount < CafeCapacity
					and playerStats.CafeOpen
				then
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

					-- Handle Despawns (Updated: Now acts only as a 30s failsafe)
					if
						customer.customerAction == "paid"
						or customer.customerAction == "emptyHanded"
						or customer.customerAction == "leaving"
					then
						if timeInState >= 30 then
							warn(`[CustomersService] Failsafe: Force removing stuck leaving customer {customer.id}`)
							GlobalState.removeCustomer(playerId, customer.id)
							continue
						end
					end

					-- Handle Dining Timer
					if customer.customerAction == "sitting" then
						local MAX_DINING_TIME = 15 -- Time in seconds they spend eating
						if timeInState >= MAX_DINING_TIME then
							GlobalState.finishDining(playerId, {
								customerUid = customer.id,
								timestamp = now,
							})
							continue
						end
					end

					-- Handle Waiting Timeouts
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
end

return CustomersService
