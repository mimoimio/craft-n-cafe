-- Shared/producers/workersSlice.luau
--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Reflex = require(ReplicatedStorage.Packages.Reflex)
local Sift = require(ReplicatedStorage.Packages.Sift)
local Types = require(ReplicatedStorage.Shared.Types)

local Dictionary = Sift.Dictionary
local Array = Sift.Array
local Set = Dictionary.set
local RemoveKey = Dictionary.removeKey

-- /// TYPES ///
type PlayerData = Types.PlayerData
export type WorkersState = Types.WorkersState

-- /// INITIALIZATION ///
local initialState: WorkersState = {}

local function findWorkerIndex(workers: { Types.WorkerEntity }, uid: string): number?
	for i, worker in ipairs(workers) do
		if worker.id == uid then
			return i
		end
	end
	return nil
end

-- /// REDUCERS ///
local actions = {
	startPlayerSession = function(state: WorkersState, playerId: string, data: PlayerData)
		local loadedWorkers = {}
		for i, w in ipairs(data.Workers or {}) do
			local worker = table.clone(w)
			worker.name = worker.name or `Barista #{i}`
			worker.walkSpeedLevel = worker.walkSpeedLevel or 1
			worker.craftSpeedLevel = worker.craftSpeedLevel or 1
			worker.qualityLevel = worker.qualityLevel or 1
			table.insert(loadedWorkers, worker)
		end
		return Set(state, playerId, loadedWorkers)
	end,

	endPlayerSession = function(state: WorkersState, playerId: string)
		return RemoveKey(state, playerId)
	end,

	hireCashier = function(state: WorkersState, playerId: string, payload: Types.HireWorkerPayload)
		local workers = state[playerId] or {}

		local newWorker: Types.WorkerEntity = {
			id = payload.id,
			name = payload.name or `Barista #{#workers + 1}`,
			action = "idle",
			targetUuid = nil,
			assignedCustomerUid = nil,
			recipeQueue = {},
			lastTend = 0,
			walkSpeedLevel = 1,
			craftSpeedLevel = 1,
			qualityLevel = 1,
		}

		return Set(state, playerId, Array.insert(workers, #workers + 1, newWorker))
	end,

	fireCashier = function(state: WorkersState, playerId: string, payload: Types.FireWorkerPayload)
		local workers = state[playerId]
		if not workers then
			return state
		end

		local index = findWorkerIndex(workers, payload.workerUid)
		if not index then
			return state
		end

		return Set(state, playerId, Array.removeIndex(workers, index))
	end,

	upgradeWorker = function(state: WorkersState, playerId: string, payload: Types.UpgradeWorkerPayload)
		local workers = state[playerId]
		if not workers then
			return state
		end

		local index = findWorkerIndex(workers, payload.workerUid)
		if not index then
			return state
		end

		return Set(
			state,
			playerId,
			Array.update(workers, index, function(worker)
				local new = table.clone(worker)
				if payload.statType == "walkSpeed" then
					new.walkSpeedLevel = (new.walkSpeedLevel or 1) + 1
				elseif payload.statType == "craftSpeed" then
					new.craftSpeedLevel = (new.craftSpeedLevel or 1) + 1
				elseif payload.statType == "quality" then
					new.qualityLevel = (new.qualityLevel or 1) + 1
				end
				return new
			end)
		)
	end,

	assignWorkerTask = function(state: WorkersState, playerId: string, payload: Types.AssignWorkerTaskPayload)
		local workers = state[playerId]
		if not workers then
			return state
		end

		local index = findWorkerIndex(workers, payload.workerUid)
		if not index then
			return state
		end

		return Set(
			state,
			playerId,
			Array.update(workers, index, function(worker)
				local new = table.clone(worker)
				new.action = "walkingToCashier"
				new.assignedCustomerUid = payload.customerUid
				new.targetUuid = payload.targetCounterUuid
				return new
			end)
		)
	end,

	-- ==========================================
	-- SHARED AI ACTIONS (Intercepted from other slices)
	-- ==========================================

	takeCustomerOrder = function(state: WorkersState, playerId: string, payload: Types.TakeCustomerOrderPayload)
		if not payload.workerUid or payload.workerUid == "player" then
			return state
		end

		local workers = state[playerId]
		if not workers then
			return state
		end
		local index = findWorkerIndex(workers, payload.workerUid)
		if not index then
			return state
		end

		return Set(
			state,
			playerId,
			Array.update(workers, index, function(worker)
				local new = table.clone(worker)
				new.action = "walkingToStation"
				new.recipeQueue = payload.recipeQueue or {}
				new.targetUuid = payload.nextTargetUuid
				return new
			end)
		)
	end,

	serveCustomer = function(state: WorkersState, playerId: string, payload: Types.ServeCustomerPayload)
		if not payload.workerUid or payload.workerUid == "player" then
			return state
		end

		local workers = state[playerId]
		if not workers then
			return state
		end
		local index = findWorkerIndex(workers, payload.workerUid)
		if not index then
			return state
		end

		return Set(
			state,
			playerId,
			Array.update(workers, index, function(worker)
				local new = table.clone(worker)
				new.action = "idle"
				new.targetUuid = nil
				new.assignedCustomerUid = nil
				new.recipeQueue = {}
				new.lastTend = payload.timestamp
				return new
			end)
		)
	end,

	wrongOrder = function(state: WorkersState, playerId: string, payload: Types.WrongOrderPayload)
		if not payload.workerUid or payload.workerUid == "player" then
			return state
		end

		local workers = state[playerId]
		if not workers then
			return state
		end
		local index = findWorkerIndex(workers, payload.workerUid)
		if not index then
			return state
		end

		return Set(
			state,
			playerId,
			Array.update(workers, index, function(worker)
				local new = table.clone(worker)
				new.action = "trashing"
				new.targetUuid = payload.nextTargetUuid
				new.recipeQueue = {}
				return new
			end)
		)
	end,

	trashCup = function(state: WorkersState, playerId: string, payload: Types.TrashCupPayload)
		if not payload.workerUid or payload.workerUid == "player" then
			return state
		end

		local workers = state[playerId]
		if not workers then
			return state
		end
		local index = findWorkerIndex(workers, payload.workerUid)
		if not index then
			return state
		end

		return Set(
			state,
			playerId,
			Array.update(workers, index, function(worker)
				local new = table.clone(worker)
				new.action = "idle"
				new.targetUuid = nil
				new.assignedCustomerUid = nil
				return new
			end)
		)
	end,

	-- ==========================================
	-- INTERNAL AI ROUTING ACTIONS
	-- ==========================================

	updateWorkerAction = function(state: WorkersState, playerId: string, payload: Types.UpdateWorkerActionPayload)
		local workers = state[playerId]
		if not workers then
			return state
		end

		local index = findWorkerIndex(workers, payload.workerUid)
		if not index then
			return state
		end

		return Set(
			state,
			playerId,
			Array.update(workers, index, function(worker)
				local new = table.clone(worker)
				new.action = payload.action
				if payload.targetUuid ~= nil then
					new.targetUuid = payload.targetUuid
				end
				return new
			end)
		)
	end,

	setWorkerRecipe = function(state: WorkersState, playerId: string, payload: Types.SetWorkerRecipePayload)
		local workers = state[playerId]
		if not workers then
			return state
		end

		local index = findWorkerIndex(workers, payload.workerUid)
		if not index then
			return state
		end

		return Set(
			state,
			playerId,
			Array.update(workers, index, function(worker)
				local new = table.clone(worker)
				new.recipeQueue = table.clone(payload.recipeQueue)
				return new
			end)
		)
	end,

	popWorkerRecipe = function(state: WorkersState, playerId: string, payload: Types.PopWorkerRecipePayload)
		local workers = state[playerId]
		if not workers then
			return state
		end

		local index = findWorkerIndex(workers, payload.workerUid)
		if not index then
			return state
		end

		return Set(
			state,
			playerId,
			Array.update(workers, index, function(worker)
				local new = table.clone(worker)
				if #new.recipeQueue > 0 then
					new.recipeQueue = Array.removeIndex(new.recipeQueue, 1)
				end
				if payload.nextTargetUuid ~= nil then
					new.targetUuid = payload.nextTargetUuid
				end
				return new
			end)
		)
	end,

	resetWorker = function(state: WorkersState, playerId: string, payload: Types.ResetWorkerPayload)
		local workers = state[playerId]
		if not workers then
			return state
		end

		local index = findWorkerIndex(workers, payload.workerUid)
		if not index then
			return state
		end

		return Set(
			state,
			playerId,
			Array.update(workers, index, function(worker)
				local new = table.clone(worker)
				new.action = "idle"
				new.targetUuid = nil
				new.assignedCustomerUid = nil
				new.recipeQueue = {}
				new.lastTend = workspace:GetServerTimeNow()
				return new
			end)
		)
	end,
}

return Reflex.createProducer(initialState, actions)