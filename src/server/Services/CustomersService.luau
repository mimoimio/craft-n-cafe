-- Server/Services/CustomersService.luau
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Promise = require(ReplicatedStorage.Packages.Promise)
local CoffeeModule = require(ReplicatedStorage.Shared.CoffeeModule)
local VariationsConfig = require(ReplicatedStorage.Shared.Configs.VariationsConfig)
local Types = require(ReplicatedStorage.Shared.Types)
local VariationService = require(ServerScriptService.Server.Services.VariationService)

type DrinkEntity = Types.DrinkEntity

local SPAWN_INTERVAL = 10
local rng = Random.new()

type CustomerDrink = {
	drinkId: string,
	variationId: string?,
	size: number?, -- NEW: Ensure size is tracked per drink for the customer
}

-- Dictionary to track when we last spawned a customer for a player
local lastSpawnTimes = {}

local function getPrice(drinkId: string): number
	local config = CoffeeModule.Config[drinkId]
	return config.Price
end

local CustomersService = {}

function CustomersService.SpawnCustomer(playerId: string)
	local state = GlobalState:getState()
	local customers = state.Customers or {}
	local playersCustomers = customers[playerId] or {}
	local playerStats = state.Stats[playerId]
	if not playerStats then
		return
	end

	local cafeCapacity = math.max(1, playerStats.CafeCapacity or 1)
	if type(playersCustomers) == "table" and #playersCustomers >= cafeCapacity then
		return
	end

	local uid = HttpService:GenerateGUID(false)
	GlobalState.spawnCustomer(playerId, {
		customerId = "",
		customerUid = uid,
		timestamp = workspace:GetServerTimeNow(), -- Pass deterministic time
	})

	lastSpawnTimes[playerId] = workspace:GetServerTimeNow()
	return uid
end

function CustomersService.CustomerTakeItems(playerId: string, customerUid: string)
	local state = GlobalState:getState()
	local playersStats = state.Stats[playerId]
	local tables = state.Tables[playerId]
	local drinks = state.Drinks[playerId]

	if not playersStats or not drinks or not tables then
		return false
	end

	local drinkLookup: { [string]: DrinkEntity } = {}
	for i, drink in pairs(drinks) do
		drinkLookup[drink.id] = drink
	end

	local availableDrinks: { DrinkEntity } = {}
	local totalDrinkAmount = 0
	for tableUid, t in pairs(tables) do
		for slotName, drinkUid in pairs(t.Slots) do
			if drinkUid == "none" then
				continue
			end
			local drink = drinkLookup[drinkUid]
			if not drink or not drink.stock or drink.stock <= 0 then
				continue
			end
			table.insert(availableDrinks, drink)
			totalDrinkAmount += drink.stock
		end
	end

	if totalDrinkAmount < 1 then
		return false
	end
	local maxDrinksPerCustomer = 3

	for i = #availableDrinks, 2, -1 do
		local j = rng:NextInteger(1, i)
		availableDrinks[i], availableDrinks[j] = availableDrinks[j], availableDrinks[i]
	end

	local drinksDeducted = {}
	local drinkEntities = {}

	local drinksTaken = 0

	for i, drink in availableDrinks do
		local drinksLeft = maxDrinksPerCustomer - drinksTaken
		local max = math.min(drink.stock, maxDrinksPerCustomer, drinksLeft)

		local possibleAmount = max
		local randomAmount = math.round(rng:NextNumber() * possibleAmount)

		if randomAmount < 1 then
			continue
		end
		drinksDeducted[drink.id] = randomAmount
		for j = 1, randomAmount do
			table.insert(drinkEntities, {
				drinkId = drink.drinkId,
				variationId = drink.variationId,
				size = drink.size or 1, -- NEW: Customer snags the size of the drink from the table
			})
		end
		drinksTaken += randomAmount
		if drinksTaken >= maxDrinksPerCustomer then
			break
		end
	end

	local depletedDrinks = {}
	for i, drink in pairs(drinks) do
		local deduct = drinksDeducted[drink.id]
		if deduct and (drink.stock - deduct <= 0) then
			depletedDrinks[drink.id] = true
		end
	end

	if #drinkEntities <= 0 then
		return false
	end

	GlobalState.customerTakeItems(playerId, {
		customerUid = customerUid,
		drinkEntities = drinkEntities,
		drinksDeducted = drinksDeducted,
		depletedDrinks = depletedDrinks,
		timestamp = workspace:GetServerTimeNow(),
	})

	return true
end

function CustomersService.TendCustomer(player: Player, uid: string)
	local playerId = tostring(player.UserId)
	local state = GlobalState:getState()
	local playersCustomers = state.Customers[playerId]
	local playersDrinks = state.Drinks[playerId]
	local playersDiscoveredDrinks = state.DiscoveredDrinks[playerId]

	if not (playersCustomers and playersDrinks) then
		return
	end

	local found
	for i, customer in ipairs(playersCustomers) do
		if customer.id == uid then
			found = customer
			break
		end
	end

	if not (found and found.drinkEntities) then
		return
	end

	local total = 0
	for i, customerDrink: CustomerDrink in ipairs(found.drinkEntities) do
		local variationId = customerDrink.variationId
		local variation = variationId and VariationsConfig[variationId] or nil
		local mult = variation and variation.Multiplier or 1
		local sizeMult = customerDrink.size or 1 -- NEW: Multiply by the drink's size

		total += getPrice(customerDrink.drinkId) * mult * sizeMult
	end

	local bonus = 1

	for variationId, drinksOfVariation in playersDiscoveredDrinks or {} do
		for drinkId, _ in drinksOfVariation or {} do
			bonus += 0.05
		end
	end
	total *= bonus
	total //= 1
	GlobalState.playerReceivePayment(playerId, {
		customerUid = uid,
		Cash = total,
		timestamp = workspace:GetServerTimeNow(),
	})
end

function CustomersService.initialize()
	Remotes.TendCustomer.OnServerEvent:Connect(CustomersService.TendCustomer)

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
						local amount = math.random() * maxCustomersAtOnce // 1 + 1
						-- local amount = 1
						for i = 1, amount do
							CustomersService.SpawnCustomer(playerId)
							task.wait(math.random() * SPAWN_INTERVAL)
						end
						return resolve
					end):catch(function(err)
						warn(`spawn cust err: {err}`)
					end)
				end

				-- 2. Evaluate FSM Time-Delays for Existing Customers
				for _, customer in ipairs(playersCustomers) do
					local timeInState = now - (customer.actionStartTime or now)

					if customer.customerAction == "entering" then
						-- Wait 5 seconds after they spawn before grabbing drinks
						if timeInState >= 5 then
							local success, reason = CustomersService.CustomerTakeItems(playerId, customer.id)
							if not success then
								-- Cafe empty, they leave empty handed
								GlobalState.customerLeaveEmptyHanded(playerId, {
									customerUid = customer.id,
									timestamp = workspace:GetServerTimeNow(),
								})
							end
						end
					elseif customer.customerAction == "paid" or customer.customerAction == "emptyHanded" then
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
