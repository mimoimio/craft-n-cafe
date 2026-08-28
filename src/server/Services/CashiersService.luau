-- Server/Services/CashiersService.luau
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
local CustomersService = require(ServerScriptService.Server.Services.CustomersService)

type DrinkEntity = Types.DrinkEntity

local SPAWN_INTERVAL = 10
local rng = Random.new()

local lastSpawnTimes = {}

local CashiersService = {}

function CashiersService.initialize()
	Remotes.HireCashier.OnServerEvent:Connect(function(player)
		local playerId = tostring(player.UserId)
		local state = GlobalState:getState()
		local cashiers = state.Cashiers[playerId]
		if not cashiers then
			return
		end
		if #cashiers >= 3 then
			return
		end

		local payload = {
			cost = 100,
			id = HttpService:GenerateGUID(),
		}
		GlobalState.hireCashier(playerId, payload)
	end)
	Remotes.FireCashier.OnServerEvent:Connect(function(player, cashierUid)
		local payload = {
			cashierUid = cashierUid,
		}
		GlobalState.fireCashier(tostring(player.UserId), payload)
	end)
	task.spawn(function()
		task.wait(1)
		while task.wait(1 / 15) do
			local now = workspace:GetServerTimeNow()

			for _, player in ipairs(game.Players:GetPlayers()) do
				local playerId = tostring(player.UserId)
				local state = GlobalState:getState()
				if not state.Cashiers then
					-- Cashiers slice might not even loaded yet, should use observe
					warn(`not state.Cashiers`)
					continue
				end
				local playersCashiers = state.Cashiers[playerId]
				if not playersCashiers then
					warn(`not playersCashiers`)
					continue
				end
				for _, cashier in ipairs(playersCashiers) do
					if now < cashier.lastTend + 3 then
						continue
					end
					local state = GlobalState:getState()
					local playerStats = state.Stats[playerId]
					local playersCustomers = state.Customers[playerId]

					if not playerStats or not playersCustomers then
						warn("[CashiersService] not  playerStats or not playersCustomers")
						break
					end

					local firstCustomer = nil
					for i, customer in playersCustomers do
						if customer.customerAction == "queuing" then
							firstCustomer = customer
							break
						end
					end

					if not firstCustomer then
						-- warn("[CashiersService] not firstCustomer")
						break
					end
					CustomersService.TendCustomer(player, firstCustomer.id, cashier.id)
					-- if there's two customers, the first one tended only when Customers.luau's walkto completed.
					-- It calls GlobalState.queueCustomer. onto the customer who just turned from "walking" to "queuing"
					-- But the second one, which was still "walking" seemingly, but the tending warn above this
					-- says the customer is queuing already, and not walking
				end
			end
		end
	end)
end

return CashiersService
