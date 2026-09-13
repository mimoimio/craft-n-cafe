-- Server/Services/CustomersService.luau
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Promise = require(ReplicatedStorage.Packages.Promise)
local CoffeeModule = require(ReplicatedStorage.Shared.CoffeeModule)
local Types = require(ReplicatedStorage.Shared.Types)

local SPAWN_INTERVAL = 30
local rng = Random.new()

-- Dictionary to track when we last spawned a customer for a player
local lastSpawnTimes = {}

local function getPrice(): number
	return 5
end

local CustomersService = {}

function CustomersService.SpawnCustomer(playerId: string)
	local state = GlobalState:getState()
	local playerStats = state.Stats[playerId]
	local playersCustomers = state.Customers[playerId] or {}
	local plotState = state.Plot and state.Plot[playerId]

	if not playerStats or not plotState or not playerStats.CafeOpen then
		return
	end

	-- 1. Find all placed Counters
	local counterUuids = {}
	for uuid, item in pairs(plotState.placedItems) do
		-- Make sure "Counter" matches your exact Prefab ID for the counter!
		if item.id == "Counter" then
			table.insert(counterUuids, uuid)
		end
	end

	if #counterUuids == 0 then
		return -- No counters placed, so we cannot spawn customers
	end

	-- 2. Check which Counters are already occupied by active customers
	local occupiedCounters = {}
	for _, customer in pairs(playersCustomers) do
		if customer.targetCounterUuid then
			occupiedCounters[customer.targetCounterUuid] = true
		end
	end

	-- 3. Find the empty Counters
	local availableCounters = {}
	for _, uuid in ipairs(counterUuids) do
		if not occupiedCounters[uuid] then
			table.insert(availableCounters, uuid)
		end
	end

	if #availableCounters == 0 then
		return -- Cafe is at max capacity (all counters full)
	end

	-- Pick a random available counter
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
	local playersWorkers = state.Workers[playerId]
	local playersCups = state.Cups[playerId]

	local cup = playersCups[workerUid]
	local worker = playersWorkers[workerUid]

	if not (playersCustomers or worker or cup) then
		local nils = {}
		table.insert(nils, not playersCustomers and "playersCustomers" or nil)
		table.insert(nils, not worker and "worker" or nil)
		table.insert(nils, not cup and "cup" or nil)
		warn(`Not Found: {table.concat(nils, " and ")}`)
		return
	end

	local found
	for i, customer in ipairs(playersCustomers) do
		if customer.id == uid then
			found = customer
			break
		end
	end

	if not (found and found.order) then
		warn("not found", found, found and found.order)
		return
	end
	if not (found.customerAction == "waiting") then
		warn("customer not waiting")
		return
	end
	if not (found.servedBy == workerUid) then
		warn("not the one serving")
		return
	end
	if cup and cup.drinkId == found.order then
		print("correct order")
		GlobalState.serveCustomer(playerId, {
			customerUid = uid,
			cash = getPrice(),
			timestamp = workspace:GetServerTimeNow(),
			workerUid = workerUid,
		})
	elseif cup and cup.drinkId and cup.drinkId ~= found.order then
		print("not the correct order")
		GlobalState.wrongOrder(playerId, {
			customerUid = uid,
			timestamp = workspace:GetServerTimeNow(),
			workerUid = workerUid,
		})
	end
end
function CustomersService.TendCustomer(player: Player, uid: string, workerUid: string)
	workerUid = workerUid or "player"
	local playerId = tostring(player.UserId)
	local state = GlobalState:getState()

	local playersCustomers = state.Customers[playerId]
	local playersWorkers = state.Workers[playerId]
	local playersCups = state.Cups[playerId]

	local cup = playersCups[workerUid]
	local worker = playersWorkers[workerUid]

	if not (playersCustomers or worker or cup) then
		local nils = {}
		table.insert(nils, not playersCustomers and "playersCustomers" or nil)
		table.insert(nils, not worker and "worker" or nil)
		table.insert(nils, not cup and "cup" or nil)
		warn(`Not Found: {table.concat(nils, " and ")}`)
		return
	end

	local found, alreadyServing
	for i, customer in ipairs(playersCustomers) do
		if customer.id == uid then
			found = customer
		end
		if customer.servedBy == workerUid then
			warn("already serving")
			return
		end
	end

	local order = CoffeeModule.Array[(math.random() * #CoffeeModule.Array // 1 + 1)]
	if not order then
		warn("what")
		return
	end

	if found.servedBy then
		warn("customer already waiting")
		return
	end
	if not (found.customerAction == "queuing") then
		warn("customer not queuing")
		return
	end
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

	-- The FSM Deterministic Ticker
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

				local maxCustomersAtOnce = 100
				local CafeCapacity = playerStats.CafeCapacity

				for i, customer in playersCustomers do
					if customer.customerAction == "paid" then
						continue
					end
					table.insert(activePlayerCustomers, customer)
				end

				-- 1. Evaluate Spawning Phase
				local lastSpawn = lastSpawnTimes[playerId] or 0

				local randomInterval = (
					SPAWN_INTERVAL - (rng:NextNumber() * rng:NextNumber() * rng:NextNumber() * 8) // 1
				)

				if
					now - lastSpawn >= randomInterval
					and #activePlayerCustomers < CafeCapacity
					and playerStats.CafeOpen
				then
					Promise.defer(function(resolve, reject, onCancel)
						-- local amount = math.random() * maxCustomersAtOnce // 1 + 1
						local amount = 1
						for i = 1, amount do
							CustomersService.SpawnCustomer(playerId)
							task.wait(math.random() * SPAWN_INTERVAL)
							-- task.wait(math.random())
						end
						return resolve
					end):catch(function(err)
						warn(`spawn cust err: {err}`)
					end)
				end

				-- 2. Evaluate FSM Time-Delays for Existing Customers
				for _, customer in ipairs(playersCustomers) do
					local timeInState = now - (customer.actionStartTime or now)

					if
						-- customer.customerAction == "entering" then
						-- elseif
						customer.customerAction == "paid" or customer.customerAction == "emptyHanded"
					then
						-- Wait 2 seconds for visual cleanup before removing entity
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
