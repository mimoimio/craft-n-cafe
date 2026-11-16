-- Shared/ReactComponents/WorkerWarnings.luau
--[[
TODO: repeat the warning every 3 secs once worker wants it
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)

local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local PlaceablesModule = require(ReplicatedStorage.Shared.PlaceablesModule)
local Toasts = require(script.Parent.Toasts)

local useEffect = React.useEffect
local useRef = React.useRef

local player = Players.LocalPlayer
local playerId = player and tostring(player.UserId) or "MockUser"

local function getPlacedStations(state)
	local placed = {}
	local plot = state.Plot and state.Plot[playerId]
	if not plot then
		return placed
	end

	for _, item in pairs(plot.placedItems or {}) do
		placed[item.id] = true
	end
	for _, item in pairs(plot.spatialItems or {}) do
		placed[item.id] = true
	end

	return placed
end

local function collectRequiredStations(worker)
	local required = {}

	if worker.action == "walkingToStation" and worker.targetUuid then
		table.insert(required, worker.targetUuid)
	end

	for _, stationId in ipairs(worker.recipeQueue or {}) do
		table.insert(required, stationId)
	end

	return required
end

local function WorkerWarnings()
	local toast = Toasts.useToast()
	local warnedRef = useRef({})

	useEffect(function()
		if not toast then
			return
		end

		local function check()
			local state = GlobalState:getState()
			local workers = state.Workers and state.Workers[playerId] or {}
			local inventory = state.Inventory and state.Inventory[playerId] or {}
			local placed = getPlacedStations(state)

			local currentMissing = {}

			for _, worker in ipairs(workers) do
				if worker.action ~= "idle" then
					for _, stationId in ipairs(collectRequiredStations(worker)) do
						if not placed[stationId] and (inventory[stationId] or 0) > 0 then
							currentMissing[stationId] = true

							if not warnedRef.current[stationId] then
								warnedRef.current[stationId] = true

								local config = PlaceablesModule.GetConfig(stationId)
								local displayName = config and config.DisplayName or stationId
								toast.open(
									`Place your {displayName} so your barista can work!`,
									4,
									Color3.fromRGB(255, 190, 80)
								)
							end
						end
					end
				end
			end

			-- Allow the same warning to appear again if the station is placed
			-- and later removed from the plot.
			for stationId in pairs(warnedRef.current) do
				if not currentMissing[stationId] then
					warnedRef.current[stationId] = nil
				end
			end
		end

		local unsubWorkers = GlobalState:subscribe(function(state)
			return state.Workers and state.Workers[playerId] or nil
		end, check)
		local unsubPlot = GlobalState:subscribe(function(state)
			return state.Plot and state.Plot[playerId] or nil
		end, check)
		local unsubInventory = GlobalState:subscribe(function(state)
			return state.Inventory and state.Inventory[playerId] or nil
		end, check)

		check()

		return function()
			unsubWorkers()
			unsubPlot()
			unsubInventory()
		end
	end, { toast })

	return nil
end

return WorkerWarnings
