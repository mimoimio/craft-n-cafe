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

	local occupiedCounters = {}
	for _, customer in pairs(playersCustomers) do
		if customer.targetCounterUuid then
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
		-- warn("playersCustomers", playersCustomers)
		-- warn("worker", worker)
		-- warn("cup", cup, cup and cup.drinkId)
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
		local exp = playersStats.EXP + 1
		local level = LevelConfig.GetLevel(exp)
		GlobalState.serveCustomer(playerId, {
			customerUid = uid,
			cash = cashReward,
			EXP = exp,
			level = level,
			timestamp = workspace:GetServerTimeNow(),
			workerUid = workerUid,
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
				-- Expects PlaceablesConfig IDs to follow the "[IngredientId]_station" pattern
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

	-- ONLY ORDER FROM THE VALID MENU
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
				local activePlayerCustomers = {}

				if not playerStats or not playersCustomers then
					continue
				end

				local CafeCapacity = playerStats.CafeCapacity

				for _, customer in playersCustomers do
					if customer.customerAction == "paid" then
						continue
					end
					table.insert(activePlayerCustomers, customer)
				end

				local lastSpawn = lastSpawnTimes[playerId] or 0
				local randomInterval = (
					SPAWN_INTERVAL - (rng:NextNumber() * rng:NextNumber() * rng:NextNumber() * 8) // 1
				)

				if
					now - lastSpawn >= randomInterval
					and #activePlayerCustomers < CafeCapacity
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
					if customer.customerAction == "paid" or customer.customerAction == "emptyHanded" then
						if timeInState >= 2 then
							GlobalState.removeCustomer(playerId, customer.id)
						end
					end
				end
			end
		end
	end)
end

return CustomersService
