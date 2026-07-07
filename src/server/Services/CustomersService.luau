--!strict
-- CustomersService.luau
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local CoffeeModule = require(ReplicatedStorage.Shared.CoffeeModule)

local SPAWN_INTERVAL = 10 -- Try to spawn a customer every 10 seconds
local rng = Random.new()

local function getPrice(drinkId: string): number
	local config = CoffeeModule.Config[drinkId]
	if config then
		local price = 0
		for i, ing in config.Ingredients do
			price += CoffeeModule.Config[ing].Price
		end
		return price
	end
	return 2
end

local CustomersService = {}
function CustomersService.SpawnCustomer(playerId: string)
	local state = GlobalState:getState()
	local customers = state.Customers
	local playersCustomers = customers[playerId]

	if not playersCustomers then
		warn(`player ({playerId})'s customers dont exist`)
		return
	end

	if not (type(playersCustomers) == "table" and #playersCustomers < 3) then
		print(`maxed customers: playersCustomers({typeof(playersCustomers)}), customers`)
		return
	end

	local uid = HttpService:GenerateGUID(false)
	GlobalState.spawnCustomer(playerId, {
		customerId = "",
		customerUid = uid,
	})

	return uid
end

function CustomersService.CustomerTakeItems(playerId: string, customerUid: string)
	local state = GlobalState:getState()
	local tables = state.Tables[playerId]
	local drinks = state.Drinks[playerId]

	if not drinks or not tables then
		print()
		return
	end

	local drinkLookup = {}
	for i, drink in drinks do
		drinkLookup[drink.id] = drink.drinkId
	end

	local availableDrinks = {}
	for tableUid, t in tables do
		for slotName, drinkUid in t.Slots do
			if drinkUid == "none" then
				continue
			end

			table.insert(availableDrinks, {
				drinkUid = drinkUid,
				drinkId = drinkLookup[drinkUid],
			})
		end
	end

	if #availableDrinks < 1 then
		print("no drinks placed")
		return
	end

	local drinkCount = rng:NextInteger(1, #availableDrinks)
	for i = #availableDrinks, 2, -1 do
		local j = rng:NextInteger(1, i)
		availableDrinks[i], availableDrinks[j] = availableDrinks[j], availableDrinks[i]
	end

	local drinksDeducted = {}
	local drinkIds = {}
	for i = 1, drinkCount do
		local drink = availableDrinks[i]
		drinksDeducted[drink.drinkUid] = 1
		table.insert(drinkIds, drink.drinkId)
	end
	local depletedDrinks = {}
	for i, drink in drinks do
		local deduct = drinksDeducted[drink.id]
		if deduct and (drink.stock - deduct <= 0) then
			depletedDrinks[drink.id] = true
		end
	end
	GlobalState.customerTakeItems(playerId, {
		customerUid = customerUid,
		drinkIds = drinkIds,
		drinksDeducted = drinksDeducted,
		depletedDrinks = depletedDrinks, -- Pass the depleted lookup table to the payload
	})
	return true
end

function CustomersService.TendCustomer(player: Player, uid: string)
	local playerId = tostring(player.UserId)
	local state = GlobalState:getState()
	local playersCustomers = state.Customers[playerId]
	local playersDrinks = state.Drinks[playerId]
	if not (playersCustomers and playersDrinks) then
		warn(
			`TendCustomer Failed: player({playerId})'s Customers({playersCustomers}) or ingredients({playersDrinks}) not found`
		)
		return
	end
	local found
	for i, customer in playersCustomers do
		if customer.id == uid then
			found = customer
			break
		end
	end
	if not (found and found.drinkIds) then
		-- warn(`customer {uid}, customer.drinkIds({found and found.drinkIds}) not found`)
		return
	end
	local drinkIds = found.drinkIds
	local total = 0
	for i, drinkId in drinkIds do
		total += getPrice(drinkId)
	end

	GlobalState.playerReceivePayment(playerId, {
		customerUid = uid,
		Cash = total,
	})
end

function CustomersService.initialize()
	Remotes.TendCustomer.OnServerEvent:Connect(CustomersService.TendCustomer)

	task.spawn(function()
		while task.wait(SPAWN_INTERVAL) do
			for index, player in game.Players:GetPlayers() do
				local playerId = tostring(player.UserId)
				-- will this task cause memory leak if waiting for that once? Yea basically. so
				--[[
				
				]]
				local son = task.spawn(function()
					-- customer spawned in front of cafe
					local uid: string? = CustomersService.SpawnCustomer(playerId)
					if not uid then
						return
					end

					-- wait for walking into cafe + looking at items
					task.wait(5)

					--[[
					doing it this way is unreliable. When user leave before
					the 5 seconds end, the customers cycle is not completed
					when player joins back, the customers are still there but
					is doing nothing, cannot even interact.

					customers have two states right now really.

					1. without .drinkIds:: { string }
					2. with .drinkIds

					without drinkIds, they either:
						is looking around
						is leaving

					with drinkIds, they
						is queuing to pay

					for the fix, I have added a new attribute in a customer entity. "customerAction".
					therefore we can reduce these to few actions finite state machine,
					with what to do if start with that exact customerAction state

						- spawnCustomer: customer just entered, and is looking around
							"entering" customer action. 
							when rendering, clone and pivot
							initially at entrance,
							walk to tables

						- customerTakeItems: queue customer in front of cashier to pay 
							"queueing" customer action.
							when rendering, 
							initially clone and pivot at cashier
							by queue. 
							if character model (which is a react state)
							is already cloned, pivot and set, walk to it's 
							calculated position.

						- playerReceivePayment: customer paid
							"paid" initially clone and pivot at position "after" 
							the position for 1st customer in the queue'd be .

						- removeCustomer: 
							customer is removed. no entity nor customerAction
					]]
					-- take items
					local success = CustomersService.CustomerTakeItems(playerId, uid)
					if not success then
						--  cafe empty, leave
						GlobalState.removeCustomer(playerId, uid)
						return
					end

					-- listen to customer's drinkIds being cleared (paid)
					GlobalState:once(function(state: GlobalState.GlobalState)
						local customers = state.Customers
						local playerCustomers = customers[playerId]
						if not playerCustomers then
							return nil
						end
						for i, customer in playerCustomers do
							if customer.id ~= uid then
								continue
							end
							if customer.drinkIds ~= nil then -- still haven't checked out
								return nil
							end
							return true
						end
						return nil
					end, function(done: boolean)
						-- warn(`player({playerId})'s customer({uid}) is DONE`)
						GlobalState.removeCustomer(playerId, uid)
					end)
				end)
			end
		end
	end)
end

return CustomersService
