-- CafeRenderingService/Workers.luau -- server
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local TweenService = game:GetService("TweenService")

local React = require(ReplicatedStorage.Packages.React)
local Reflex = require(ReplicatedStorage.Packages.Reflex)
local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local Types = require(ReplicatedStorage.Shared.Types)
local CafeTypes = require(ReplicatedStorage.Shared.CafeTypes)
local DrinkModelUtil = require(ReplicatedStorage.Shared.Utils.DrinkModelUtil)

local Grid = require(ReplicatedStorage.Shared.Grid)
local Models = ReplicatedStorage.Shared.Models
local AStar = require(ReplicatedStorage.Shared.AStar)

-- Services
local CustomersService = require(ServerScriptService.Server.Services.CustomersService)
local DrinksService = require(ServerScriptService.Server.Services.DrinksService)
local WorkersService = require(ServerScriptService.Server.Services.WorkersService)

local e = React.createElement
local useEffect = React.useEffect
local useState = React.useState
local useRef = React.useRef

-- local LOGENABLED = true
local Log = LOGENABLED and warn or function() end

-- local WORKER_WALK_SPEED = 200
-- LEAVE THIS HERE 14 IS FAST
local WORKER_WALK_SPEED = 4
-- local WORKER_WALK_SPEED = 14
local STATION_DURATION = 0.1
-- local STATION_DURATION = 1.5

local function getPlayer(playerId: string): Player?
	if playerId == "MockUser" then
		-- for UILabs story
		return {
			UserId = "MockUser",
			Name = "MockUser",
		} :: any
	end
	local userId = tonumber(playerId)
	if not userId then
		return nil
	end
	return Players:GetPlayerByUserId(userId)
end

local function getCustomerByUid(playerId: string, uid: string?)
	if not uid then
		return nil
	end
	local state = GlobalState:getState()
	local customers = state.Customers[playerId]
	if not customers then
		return nil
	end
	for _, c in ipairs(customers) do
		if c.id == uid then
			return c
		end
	end
	return nil
end

local function getTargetCFrame(
	baseModel: CafeTypes.CafeBase,
	plotState: any,
	targetUuid: string?,
	action: string
): CFrame?
	if not targetUuid or not plotState then
		return nil
	end

	local itemData = plotState.placedItems[targetUuid] or plotState.spatialItems[targetUuid]
	if not itemData then
		return nil
	end

	local placementType = plotState.placedItems[targetUuid] and "Grid" or "Spatial"
	local prefab = Models:FindFirstChild(itemData.id)
	if not prefab then
		return nil
	end

	local _, itemSize = Grid.getModelBounds(prefab)
	local plotCFrame = baseModel.Part.CFrame
	local plotSize = baseModel.Part.Size

	local targetCF
	local frontOffset = 4
	local backOffset = 4

	if placementType == "Grid" then
		local rawX, rawZ = Grid.getFootprint(itemSize, 0)
		local snappedSize = Vector3.new(rawX * Grid.SIZE, itemSize.Y, rawZ * Grid.SIZE)
		targetCF = Grid.gridToWorld(
			itemData.itemType or "Solid",
			itemData.x,
			itemData.z,
			plotCFrame,
			plotSize,
			snappedSize,
			itemData.r
		)

		frontOffset = (snappedSize.Z / 2) + (Grid.SIZE / 2)
		backOffset = (snappedSize.Z / 2) + (Grid.SIZE / 2)
	else
		local spatialCFrame = if typeof(itemData.cframe) == "table"
			then CFrame.new(table.unpack(itemData.cframe))
			elseif typeof(itemData.cframe) == "CFrame" then itemData.cframe
			else CFrame.new(0, 0, 0)
		targetCF = Grid.spatialToWorld(spatialCFrame, plotCFrame, plotSize)
	end

	if action == "walkingToCashier" or action == "serving" then
		return targetCF * CFrame.new(0, 0, backOffset)
	else
		return targetCF * CFrame.new(0, 0, -frontOffset) * CFrame.Angles(0, math.pi, 0)
	end
end

local original = workspace:WaitForChild("Rig")

local function Worker(props: {
	PlayerId: string,
	WorkerData: Types.WorkerEntity,
	BaseModel: CafeTypes.CafeBase,
	PlotState: any,
	CupData: Types.CupEntity?,
	Stations: any,
	CustomersState: any,
})
	local rig, setRig = useState(nil)
	local actionRef = useRef(nil)

	useEffect(function()
		actionRef.current = props.WorkerData.action
	end, { props.WorkerData })

	useEffect(function()
		local clone = original:Clone()
		local rootPart = clone:FindFirstChild("HumanoidRootPart")
		if rootPart then
			clone.PrimaryPart = rootPart
		end
		clone.Name = "Worker_" .. props.WorkerData.id
		clone.Parent = workspace

		if rootPart and rootPart:CanSetNetworkOwnership() then
			rootPart:SetNetworkOwner(nil)
		end

		for _, desc in clone:GetDescendants() do
			if desc:IsA("BasePart") then
				desc.CollisionGroup = "Characters"
				desc.Anchored = (desc.Name == "HumanoidRootPart")
			end
		end

		local humanoid = clone:FindFirstChildOfClass("Humanoid")
		if humanoid and not humanoid:FindFirstChildOfClass("Animator") then
			local animator = Instance.new("Animator")
			animator.Parent = humanoid
		end

		local feetOffset = 3
		if humanoid and rootPart and humanoid.RigType == Enum.HumanoidRigType.R15 then
			feetOffset = humanoid.HipHeight + (rootPart.Size.Y / 2)
		end
		clone:SetAttribute("FeetOffset", feetOffset)

		-- local billboard = Instance.new("BillboardGui")
		-- billboard.Size = UDim2.new(4, 0, 1, 0)
		-- billboard.StudsOffset = Vector3.new(0, 3, 0)
		-- local textLabel = Instance.new("TextLabel")
		-- textLabel.Size = UDim2.new(1, 0, 1, 0)
		-- textLabel.BackgroundTransparency = 1
		-- textLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
		-- textLabel.TextScaled = true
		-- textLabel.Text = "Barista"
		-- textLabel.Parent = billboard
		-- billboard.Parent = clone:FindFirstChild("Head")

		local spawnPos = props.BaseModel.Part.Position + Vector3.new(0, props.BaseModel.Part.Size.Y / 2 + feetOffset, 0)
		clone:PivotTo(CFrame.new(spawnPos))

		setRig(clone)

		return function()
			if clone and clone.Parent then
				clone:Destroy()
			end
			setRig(nil)
		end
	end, { props.WorkerData.id, props.BaseModel })

	-- STATE MACHINE LOOP
	useEffect(function()
		if not rig then
			return
		end

		local worker = props.WorkerData
		local action = worker.action

		Log(`\n======================================`)
		Log(`[Workers-AI] 🤖 STATE MACHINE RENDER TRIGGERED`)
		Log(`Worker ID: {worker.id:sub(1, 8)}...`)
		Log(`Current Action: {action}`)
		Log(`Target Data: {tostring(worker.targetUuid)}`)
		Log(`Assigned Customer: {tostring(worker.assignedCustomerUid)}`)
		Log(`Recipe Queue Length: {#worker.recipeQueue}`)
		Log(`======================================\n`)

		if action == "idle" then
			return
		end

		local rootPart = rig:FindFirstChild("HumanoidRootPart")
		local humanoid = rig:FindFirstChildOfClass("Humanoid")
		local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
		local feetOffset = rig:GetAttribute("FeetOffset") or 3

		local plotPart = props.BaseModel.Part
		local floorY = plotPart.Position.Y + (plotPart.Size.Y / 2)

		-- 1. Check if the Customer Timed Out
		local customer = getCustomerByUid(props.PlayerId, worker.assignedCustomerUid)
		local isCustomerValid = false

		if customer then
			if
				action == "walkingToCashier"
				and customer.customerAction == "queuing"
				and customer.servedBy == worker.id
			then
				isCustomerValid = true
			elseif
				(action == "walkingToStation" or action == "serving")
				and customer.customerAction == "waiting"
				and customer.servedBy == worker.id
			then
				isCustomerValid = true
			end
		end

		if not isCustomerValid and action ~= "trashing" then
			Log(`[Workers-AI] 🚨 Customer timed out! Throwing away drink.`)
			if action == "walkingToCashier" then
				GlobalState.resetWorker(props.PlayerId, { workerUid = worker.id })
			else
				local trashUuid = props.Stations and props.Stations["trash_station"]
					or WorkersService.GetStationUuid(props.PlotState, "trash_station")
				GlobalState.wrongOrder(props.PlayerId, {
					customerUid = worker.assignedCustomerUid,
					workerUid = worker.id,
					timestamp = workspace:GetServerTimeNow(),
					nextTargetUuid = trashUuid,
				})
			end
			return
		end

		-- 2. Resolve Physical Target
		local physicalTargetUuid = worker.targetUuid
		if action == "walkingToStation" then
			physicalTargetUuid = props.Stations[worker.targetUuid]
			Log(
				`[Workers-AI] 🔍 Resolving Station Name '{worker.targetUuid}' -> Physical UUID: {tostring(
					physicalTargetUuid
				)}`
			)
		end

		local targetCF = getTargetCFrame(props.BaseModel, props.PlotState, physicalTargetUuid, action)
		if not targetCF then
			if action == "walkingToStation" then
				Log(
					`[Workers-AI] 🛑 HALT: Station '{worker.targetUuid}' is missing from plot! Worker halted until placed.`
				)
				return
			elseif action == "trashing" then
				Log(`[Workers-AI] 🗑️ Trash bin missing! Magically deleting cup and resetting to idle.`)
				DrinksService.TrashCup(getPlayer(props.PlayerId), worker.id)
				GlobalState.resetWorker(props.PlayerId, { workerUid = worker.id })
				return
			else
				warn(`[Workers-AI] 🚨 Target UUID missing in PlotState! Forcing Wrong Order.`)
				if worker.assignedCustomerUid then
					local trashUuid = props.Stations and props.Stations["trash_station"]
						or WorkersService.GetStationUuid(props.PlotState, "trash_station")
					GlobalState.wrongOrder(props.PlayerId, {
						customerUid = worker.assignedCustomerUid,
						workerUid = worker.id,
						timestamp = workspace:GetServerTimeNow(),
						nextTargetUuid = trashUuid,
					})
				else
					GlobalState.resetWorker(props.PlayerId, { workerUid = worker.id })
				end
				return
			end
		end

		local targetFloorPos = Vector3.new(targetCF.Position.X, floorY, targetCF.Position.Z)

		local activeTween = nil
		local walkingAnimation: AnimationTrack = nil
		local isNavigating = true

		if humanoid and rootPart then
			task.spawn(function()
				Log(`[Workers-AI] 🚶‍♂️ Starting Pathfinding calculation...`)
				local startX, startZ = Grid.worldToCell(rootPart.Position, plotPart.CFrame)
				local endX, endZ = Grid.worldToCell(targetFloorPos, plotPart.CFrame)

				local path = AStar.compute(startX, startZ, endX, endZ, props.PlotState, plotPart.Size.X)
				if not path then
					Log(`[Workers-AI] ⚠️ Standard path failed, attempting ghost path...`)
					path = AStar.compute(startX, startZ, endX, endZ, props.PlotState, plotPart.Size.X, true)
				end

				local broke = false
				local moveToFinished = false

				if path then
					Log(`[Workers-AI] 🗺️ Path found! Length: {#path} steps. Proceeding to tween.`)
					local waypoints = {}
					for _, node in ipairs(path) do
						table.insert(waypoints, Grid.cellToWorld(node.x, node.z, plotPart.CFrame, plotPart.Size))
					end
					table.insert(waypoints, targetFloorPos)

					local walkAnim = ReplicatedStorage.Shared.Animations:FindFirstChild("Walk")
					if animator and walkAnim then
						Log(`[Workers-AI] 🎬 LoadAnimation: Creating Walk Track for {worker.id:sub(1, 8)}...`)
						walkingAnimation = (animator :: Animator):LoadAnimation(walkAnim);
						(walkingAnimation):AdjustSpeed(WORKER_WALK_SPEED / 8)
						walkingAnimation.Priority = Enum.AnimationPriority.Movement
						walkingAnimation.Looped = true
						walkingAnimation:Play(0.1, 1, WORKER_WALK_SPEED / 8)
					end

					for i, wp in ipairs(waypoints) do
						if not isNavigating then
							Log(
								`[Workers-AI] 🛑 Tween Interrupted! isNavigating = false. (Component unmounted or state changed)`
							)
							break
						end

						local startPos = rootPart.Position
						local targetP = Vector3.new(wp.X, floorY + feetOffset, wp.Z)
						local dist = (targetP - startPos).Magnitude

						if dist > 0.1 then
							local timeToTake = dist / WORKER_WALK_SPEED
							local targetCFrame

							if i == #waypoints then
								targetCFrame = CFrame.new(targetP) * targetCF.Rotation
							else
								local lookVector = (targetP - startPos).Unit
								local lookFlat = Vector3.new(lookVector.X, 0, lookVector.Z)
								if lookFlat.Magnitude > 0.001 then
									local lookAtCF = CFrame.lookAt(startPos, startPos + lookFlat)
									targetCFrame = CFrame.new(targetP) * lookAtCF.Rotation
									rootPart.CFrame = CFrame.new(startPos) * lookAtCF.Rotation
								else
									targetCFrame = CFrame.new(targetP) * rootPart.CFrame.Rotation
								end
							end

							activeTween = TweenService:Create(
								rootPart,
								TweenInfo.new(timeToTake, Enum.EasingStyle.Linear),
								{ CFrame = targetCFrame }
							)
							activeTween:Play()
							activeTween.Completed:Wait()
							activeTween = nil
						else
							if i == #waypoints then
								local tCF = CFrame.new(startPos) * targetCF.Rotation
								activeTween = TweenService:Create(
									rootPart,
									TweenInfo.new(0.2, Enum.EasingStyle.Linear),
									{ CFrame = tCF }
								)
								activeTween:Play()
								activeTween.Completed:Wait()
								activeTween = nil
							end
						end

						if i == #waypoints then
							moveToFinished = true
						end
					end

					-- THE FIX: Animation must be destroyed when the path loop finishes successfully!
					if walkingAnimation then
						Log(`[Workers-AI] 🏁 Destroying Walk Track (Path finished or aborted)`)
						walkingAnimation:Stop()
						walkingAnimation:Destroy()
						walkingAnimation = nil
					end
				else
					Log(`[Workers-AI] ❌ Path completely blocked! Failsafe Teleporting.`)
					broke = true
				end

				if broke then
					rootPart.CFrame = CFrame.new(targetFloorPos + Vector3.new(0, feetOffset, 0)) * targetCF.Rotation
					moveToFinished = true
				end

				if not moveToFinished then
					return
				end

				Log(`[Workers-AI] 📍 Worker reached destination. Proceeding to execute state Action...`)

				local player = getPlayer(props.PlayerId)

				if not player then
					return
				end

				if action == "walkingToCashier" then
					Log(`[Workers-AI] 🔄 Dispatching TendCustomer`)
					CustomersService.TendCustomer(player, worker.assignedCustomerUid, worker.id)
				elseif action == "walkingToStation" then
					local itemData = props.PlotState.placedItems[physicalTargetUuid]
						or props.PlotState.spatialItems[physicalTargetUuid]
					if itemData then
						local stationId = itemData.id

						Log(`[Workers-AI] ⏳ Waiting at station {stationId} for {STATION_DURATION}s...`)
						task.wait(STATION_DURATION)

						if not isNavigating then
							Log(`[Workers-AI] 🛑 Wait completed but isNavigating = false! Aborting dispatch.`)
							return
						end

						-- FRESH FAILSAFE CHECK: Did the customer time out while we were waiting?
						local freshCustomer = getCustomerByUid(props.PlayerId, worker.assignedCustomerUid)
						if
							not freshCustomer
							or freshCustomer.customerAction ~= "waiting"
							or freshCustomer.servedBy ~= worker.id
						then
							Log(`[Workers-AI] 🛑 Customer vanished while we were waiting! Aborting to trash.`)
							local trashUuid = props.Stations and props.Stations["trash_station"]
								or WorkersService.GetStationUuid(props.PlotState, "trash_station")
							GlobalState.wrongOrder(props.PlayerId, {
								customerUid = worker.assignedCustomerUid,
								workerUid = worker.id,
								timestamp = workspace:GetServerTimeNow(),
								nextTargetUuid = trashUuid,
							})
							return
						end

						Log(`[Workers-AI] ▶️ Wait finished, dispatching ingredient addition...`)

						if stationId == "cup_station" then
							GlobalState.getCup(props.PlayerId, worker.id)
						else
							local ingredient = stationId:gsub("_station$", "")
							DrinksService.AddIngredient(player, ingredient, worker.id, 3)
						end

						if #worker.recipeQueue > 0 then
							GlobalState.popWorkerRecipe(props.PlayerId, {
								workerUid = worker.id,
								nextTargetUuid = worker.recipeQueue[1],
							})
						else
							if freshCustomer then
								GlobalState.updateWorkerAction(props.PlayerId, {
									workerUid = worker.id,
									action = "serving",
									targetUuid = freshCustomer.targetCounterUuid,
								})
							end
						end
					end
				elseif action == "serving" then
					Log(`[Workers-AI] 📦 Dispatching ServeCustomer`)
					CustomersService.ServeCustomer(player, worker.assignedCustomerUid, worker.id)
				elseif action == "trashing" then
					Log(`[Workers-AI] 🗑️ Dispatching TrashCup and resetWorker`)
					DrinksService.TrashCup(player, worker.id)
					GlobalState.resetWorker(props.PlayerId, { workerUid = worker.id })
				end
			end)
		end

		return function()
			isNavigating = false
			if activeTween then
				activeTween:Cancel()
			end
			-- FIX: Redundancy check in case component unmounts mid-walk
			if walkingAnimation then
				Log(`[Workers-AI] 🧹 Destroying Walk Track (Cleanup Phase)`)
				walkingAnimation:Stop()
				walkingAnimation:Destroy()
				walkingAnimation = nil
			end
		end
	end, { rig, props.WorkerData.action, props.WorkerData.targetUuid, props.Stations })

	useEffect(function()
		local cup = props.CupData
		local head = rig and rig:FindFirstChild("Head")

		if not (rig and rig.Parent and cup and cup.drinkId and cup.drinkId ~= "none" and head) then
			return
		end

		local drinkModel, modelBasePart = DrinkModelUtil.BuildDrinkModel(cup.drinkId, "none", {
			Anchored = false,
			CanCollide = false,
		})

		drinkModel:PivotTo(head.CFrame * CFrame.new(0, -1, -1))
		drinkModel.Parent = workspace

		for _, part in drinkModel:GetDescendants() do
			if part:IsA("BasePart") then
				part:SetNetworkOwner(nil)
			end
		end

		if modelBasePart then
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = modelBasePart
			weld.Part1 = head
			weld.Parent = modelBasePart
		end

		return function()
			drinkModel:Destroy()
		end
	end, { rig, props.CupData })

	return e(React.Fragment)
end

local selectWorkersById = function(playerId: string)
	return Reflex.createSelector(function(state)
		return state.Workers
	end, function(workers)
		return workers[playerId]
	end)
end

local selectPlotById = function(playerId: string)
	return Reflex.createSelector(function(state)
		return state.Plot
	end, function(plots)
		return plots and plots[playerId]
	end)
end

local selectCupsById = function(playerId: string)
	return Reflex.createSelector(function(state)
		return state.Cups
	end, function(cups)
		return cups[playerId]
	end)
end

local function Workers(props: { PlayerId: string, BaseModel: CafeTypes.CafeBase, Stations: any })
	local workers, setWorkers = useState(nil)
	local plotState, setPlotState = useState(nil)
	local cupsState, setCupsState = useState(nil)

	useEffect(function()
		local unsubWorkers = GlobalState:subscribe(selectWorkersById(props.PlayerId), setWorkers)
		local unsubPlot = GlobalState:subscribe(selectPlotById(props.PlayerId), setPlotState)
		local unsubCups = GlobalState:subscribe(selectCupsById(props.PlayerId), setCupsState)

		local state = GlobalState:getState()
		if state.Workers then
			setWorkers(state.Workers[props.PlayerId])
		end
		if state.Plot then
			setPlotState(state.Plot[props.PlayerId])
		end
		if state.Cups then
			setCupsState(state.Cups[props.PlayerId])
		end

		return function()
			unsubWorkers()
			unsubPlot()
			unsubCups()
		end
	end, { props.PlayerId })

	local children = {}
	if workers and plotState then
		for _, workerData in ipairs(workers) do
			local cupData = cupsState and cupsState[workerData.id]

			children[workerData.id] = e(Worker, {
				PlayerId = props.PlayerId,
				WorkerData = workerData,
				BaseModel = props.BaseModel,
				PlotState = plotState,
				CupData = cupData,
				Stations = props.Stations,
			})
		end
	end

	return e(React.Fragment, nil, children)
end

return Workers
