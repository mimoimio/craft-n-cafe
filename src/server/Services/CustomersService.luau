-- Server/Services/CustomersService.luau
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local CoffeeModule = require(ReplicatedStorage.Shared.CoffeeModule)
local VariationsConfig = require(ReplicatedStorage.Shared.Configs.VariationsConfig)
local Types = require(ReplicatedStorage.Shared.Types)

type DrinkEntity = Types.DrinkEntity

local SPAWN_INTERVAL = 10
local rng = Random.new()

type CustomerDrink = {
	drinkId: string,
	variationId: string?,
}

-- Dictionary to track when we last spawned a customer for a player
local lastSpawnTimes = {}

local function getPrice(drinkId: string): number
	local config = CoffeeModule.Config[drinkId]
	-- if config then
	-- 	local price = 0
	-- 	for i, ing in config.Ingredients do
	-- 		price += CoffeeModule.Config[ing].Price
	-- 	end
	-- 	return price
	-- end
	return config.Price
end

local CustomersService = {}

function CustomersService.SpawnCustomer(playerId: string)
	local state = GlobalState:getState()
	local customers = state.Customers
	local playersCustomers = customers[playerId]

	if not playersCustomers then
		return
	end
	local playerStats = state.Stats[playerId]

	local maxCustomersAtOnce = playerStats.MaxCustomersAtOnce

	if type(playersCustomers) == "table" and #playersCustomers >= maxCustomersAtOnce then
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

	if not drinks or not tables then
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
			table.insert(availableDrinks, drink)
			totalDrinkAmount += drink.stock
		end
	end

	if totalDrinkAmount < 1 then
		return false
	end
	local MaxDrinksPerCustomer = playersStats.MaxDrinksPerCustomer

	local drinkCount = rng:NextInteger(1, math.min(MaxDrinksPerCustomer, totalDrinkAmount))
	-- maxDrinksPerCustomer: number later use this. first level is nothing
	-- then a tray
	-- then a basket
	-- then a shopping cart

	for i = #availableDrinks, 2, -1 do
		local j = rng:NextInteger(1, i)
		availableDrinks[i], availableDrinks[j] = availableDrinks[j], availableDrinks[i]
	end

	local drinksDeducted = {}
	local drinkEntities = {}

	local drinksTaken = 0

	-- warn(`MaxDrinksPerCustomer: {MaxDrinksPerCustomer}`)
	local moderate = totalDrinkAmount > 20
	local lots = totalDrinkAmount > 40

	for i, drink in availableDrinks do
		local drinksLeft = MaxDrinksPerCustomer - drinksTaken
		local max = math.min(drink.stock, MaxDrinksPerCustomer, drinksLeft)

		-- the more the available drinks, the lesser the possibility to haul it all
		-- local skewedToLeast = (rng:NextNumber() * rng:NextNumber() * rng:NextNumber() * max) -- 3x
		-- local normal = (rng:NextNumber() * rng:NextNumber() * max) -- 2x
		-- local possibleAmount = lots and skewedToLeast or moderate and normal or max

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
			})
		end
		drinksTaken += randomAmount
		if drinksTaken >= MaxDrinksPerCustomer then
			-- warn(`broke. drinksTaken: {drinksTaken}`)
			break
		end
	end
	-- warn(`total drinkEntities: {#drinkEntities}`)

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

		total += getPrice(customerDrink.drinkId) * mult
	end

	local bonus = 1

	for variationId, drinksOfVariation in playersDiscoveredDrinks do
		for drinkId, _ in drinksOfVariation do
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

				local maxCustomersAtOnce = playerStats.MaxCustomersAtOnce

				for i, customer in playersCustomers do
					if customer.customerAction == "paid" then
						continue
					end
					table.insert(activePlayerCustomers, customer)
				end

				-- Cafe Open Check. If Spawning is toggled off, skip the spawn. Keep other actions.
				-- 1. Evaluate Spawning Phase
				local lastSpawn = lastSpawnTimes[playerId] or 0

				-- local randomInterval = 0
				local randomInterval = (
					SPAWN_INTERVAL - (rng:NextNumber() * rng:NextNumber() * rng:NextNumber() * 8) // 1
				) -- later I should change random based on something else

				if
					now - lastSpawn >= randomInterval
					and #activePlayerCustomers < maxCustomersAtOnce
					and playerStats.CafeOpen
				then
					CustomersService.SpawnCustomer(playerId)
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
									-- reason = reason,
								})
							end
						end
					elseif customer.customerAction == "paid" or customer.customerAction == "emptyHanded" then
						-- Wait 2 seconds for visual cleanup before removing entity
						if timeInState >= 2 then
							GlobalState.removeCustomer(playerId, customer.id)
						end
					end

					-- Notice we don't have an automatic check for "queuing".
					-- They are stuck in that state indefinitely until `TendCustomer` fires.
				end
			end
		end
	end)
end

return CustomersService
