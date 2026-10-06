-- CafeRenderingService/Customers.luau -- server
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local TweenService = game:GetService("TweenService")

local React = require(ReplicatedStorage.Packages.React)
local Promise = require(ReplicatedStorage.Packages.Promise)
local Mionum = require(ReplicatedStorage.Packages.Mionum)
local Reflex = require(ReplicatedStorage.Packages.Reflex)
local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local Types = require(ReplicatedStorage.Shared.Types)
local CafeTypes = require(ReplicatedStorage.Shared.CafeTypes)
local CoffeeModule = require(ReplicatedStorage.Shared.CoffeeModule)
local CustomersService = require(ServerScriptService.Server.Services.CustomersService)
local VariationsConfig = require(ReplicatedStorage.Shared.Configs.VariationsConfig)
local DrinkModelUtil = require(ReplicatedStorage.Shared.Utils.DrinkModelUtil)

local Grid = require(ReplicatedStorage.Shared.Grid)
local Models = ReplicatedStorage.Shared.Models
local AStar = require(ReplicatedStorage.Shared.AStar)

local e = React.createElement
local useEffect = React.useEffect
local useState = React.useState
local useRef = React.useRef

local CUSTOMER_WALK_SPEED = 6

local disappointed = {
	"Where are the drinks?",
	"I'm thirsty...",
	"I thought this place sell drinks",
}

local function getPlayer(playerId: string): Player?
	local userId = tonumber(playerId)
	if not userId then
		return nil
	end
	return Players:GetPlayerByUserId(userId)
end

local observeRigClone = function(clone: Model): (() -> ())?
	if not clone then
		return nil
	end
	local conn = clone:GetPropertyChangedSignal("Parent"):Connect(function()
		return
	end)
	local conn2 = clone.Destroying:Connect(function()
		return
	end)
	return function()
		if conn then
			conn:Disconnect()
		end
		if conn2 then
			conn2:Disconnect()
		end
	end
end

-- PURE FUNCTION: Calculates Counter CFrame (NOW FACING 180 DEGREES)
local function getCounterTargetCFrame(baseModel: CafeTypes.CafeBase, cashierData: any?): CFrame?
	if not cashierData then
		return nil
	end

	local item = cashierData.itemData
	local placementType = cashierData.type

	local prefab = Models:FindFirstChild(item.id)
	if not prefab then
		return nil
	end

	local _, itemSize = Grid.getModelBounds(prefab)
	local plotCFrame = baseModel.Part.CFrame
	local plotSize = baseModel.Part.Size

	local counterCF
	if placementType == "Grid" then
		local rawX, rawZ = Grid.getFootprint(itemSize, 0)
		local snappedSize = Vector3.new(rawX * Grid.SIZE, itemSize.Y, rawZ * Grid.SIZE)
		counterCF =
			Grid.gridToWorld(item.itemType or "Solid", item.x, item.z, plotCFrame, plotSize, snappedSize, item.r)
	else
		local spatialCFrame = if typeof(item.cframe) == "table"
			then CFrame.new(table.unpack(item.cframe))
			elseif typeof(item.cframe) == "CFrame" then item.cframe
			else CFrame.new(0, 0, 0)
		counterCF = Grid.spatialToWorld(spatialCFrame, plotCFrame, plotSize)
	end

	return counterCF * CFrame.new(0, 0, -4) * CFrame.Angles(0, math.pi, 0)
end

-- PURE FUNCTION: Calculates Seat CFrame
local function getSeatTargetCFrame(baseModel: CafeTypes.CafeBase, seatData: any?): CFrame?
	if not seatData then
		return nil
	end

	local item = seatData.itemData
	local placementType = seatData.type

	local prefab = Models:FindFirstChild(item.id)
	if not prefab then
		return nil
	end

	local _, itemSize = Grid.getModelBounds(prefab)
	local plotCFrame = baseModel.Part.CFrame
	local plotSize = baseModel.Part.Size

	local seatCF
	if placementType == "Grid" then
		local rawX, rawZ = Grid.getFootprint(itemSize, 0)
		local snappedSize = Vector3.new(rawX * Grid.SIZE, itemSize.Y, rawZ * Grid.SIZE)
		seatCF = Grid.gridToWorld(item.itemType or "Solid", item.x, item.z, plotCFrame, plotSize, snappedSize, item.r)
	else
		local spatialCFrame = if typeof(item.cframe) == "table"
			then CFrame.new(table.unpack(item.cframe))
			elseif typeof(item.cframe) == "CFrame" then item.cframe
			else CFrame.new(0, 0, 0)
		seatCF = Grid.spatialToWorld(spatialCFrame, plotCFrame, plotSize)
	end

	return seatCF * CFrame.new(0, 1.5, 0)
end

local original = workspace.Rig:Clone()
local npcsFolder = workspace:FindFirstChild("NPCS")

local function Customer(props: {
	PlayerId: string,
	CafeModel: CafeTypes.Cafe,
	Customer: Types.CustomerEntity,
	BaseModel: CafeTypes.CafeBase,
	CashierData: any?,
	SeatData: any?,
	PlotState: any?,
	numberInLine: number?,
})
	local rig: CafeTypes.CustomerRig, setRig = useState(nil)
	local prompt: ProximityPrompt, setPrompt = useState(nil)
	local actionRef = useRef(nil)

	-- print(`[Customer-Render] Rendered {props.Customer.id} | Action: {props.Customer.customerAction}`)

	useEffect(function()
		actionRef.current = props.Customer.customerAction
	end, { props.Customer })

	-- 1. Mounting the Rig
	useEffect(function()
		-- print(`[Customers-Rig] Spawning rig for {props.Customer.id}...`)
		local clone

		-- Safely filter out broken models in NPCS folder
		local validNpcs = {}
		if npcsFolder then
			for _, child in ipairs(npcsFolder:GetChildren()) do
				if
					child:IsA("Model")
					and child:FindFirstChild("HumanoidRootPart")
					and child:FindFirstChildOfClass("Humanoid")
				then
					table.insert(validNpcs, child)
				end
			end
		end

		if #validNpcs > 0 then
			local selected = validNpcs[(#validNpcs * math.random() + 1) // 1]
			clone = selected:Clone()
		else
			clone = original:Clone()
		end

		local unsub = observeRigClone(clone)
		local tag = "Customer" .. props.PlayerId
		local rootPart = clone:FindFirstChild("HumanoidRootPart")

		if rootPart then
			clone.PrimaryPart = rootPart
		end
		clone:AddTag(tag)
		clone.Name = props.Customer.id
		clone.Parent = workspace

		if rootPart and rootPart:CanSetNetworkOwnership() then
			rootPart:SetNetworkOwner(nil)
		end

		for i, desc: BasePart in clone:GetDescendants() do
			if desc:IsA("BasePart") then
				desc.CollisionGroup = "Characters"
				if desc.Name == "HumanoidRootPart" then
					desc.Anchored = true
				else
					desc.Anchored = false
				end
			end
		end

		local humanoid = clone:FindFirstChildOfClass("Humanoid")

		-- FIX: Ensure Animator exists so load animations don't crash
		if humanoid and not humanoid:FindFirstChildOfClass("Animator") then
			local animator = Instance.new("Animator")
			animator.Parent = humanoid
		end

		local feetOffset = 3
		if humanoid and rootPart then
			if humanoid.RigType == Enum.HumanoidRigType.R15 then
				feetOffset = humanoid.HipHeight + (rootPart.Size.Y / 2)
			end
		end
		clone:SetAttribute("FeetOffset", feetOffset)

		if not clone:FindFirstChild("TriggerPrompt") then
			local newPrompt = Instance.new("ProximityPrompt")
			newPrompt.Parent = clone
			newPrompt.Name = "TriggerPrompt"
		end

		setRig(clone)
		clone.TriggerPrompt.MaxActivationDistance = 15
		setPrompt(clone.TriggerPrompt)

		local entranceCF = props.BaseModel.Entrance:GetPivot()
		local action = props.Customer.customerAction

		local spotCF = getCounterTargetCFrame(props.BaseModel, props.CashierData) or entranceCF

		local plotPart = props.BaseModel.Part
		local floorY = plotPart.Position.Y + (plotPart.Size.Y / 2)

		local spotFloorPos = Vector3.new(spotCF.Position.X, floorY, spotCF.Position.Z)
		local entranceFloorPos = Vector3.new(entranceCF.Position.X, floorY, entranceCF.Position.Z)

		-- FIX: Calculate spawn exactly on the floor
		local spawnPos = entranceFloorPos - (entranceCF.LookVector * 2)
		local spawnRot = entranceCF.Rotation

		if action == "queuing" then
			spawnPos = spotFloorPos
			spawnRot = spotCF.Rotation
		elseif action == "paid" or action == "emptyHanded" then
			spawnPos = spotFloorPos + (spotCF.LookVector * 4)
			spawnRot = spotCF.Rotation
		end

		clone:PivotTo(CFrame.new(spawnPos + Vector3.new(0, feetOffset, 0)) * spawnRot)

		clone.TriggerPrompt.RequiresLineOfSight = false
		clone.TriggerPrompt.ActionText = "Tend Customer"
		clone.TriggerPrompt.Style = Enum.ProximityPromptStyle.Default

		local conn = clone.TriggerPrompt.Triggered:Connect(function(player: Player)
			if tostring(player.UserId) ~= props.PlayerId then
				return
			end
			if actionRef.current == "waiting" then
				CustomersService.ServeCustomer(player, props.Customer.id)
			elseif actionRef.current == "queuing" then
				CustomersService.TendCustomer(player, props.Customer.id)
			end
		end)

		return function()
			if clone and clone.Parent then
				clone:Destroy()
			end
			if conn then
				conn:Disconnect()
			end
			if unsub then
				unsub()
			end
			setRig(nil)
			setPrompt(nil)
		end
	end, { props.Customer.id, props.BaseModel, props.CafeModel })

	-- 2. State Transition & Custom Tween Pathfinding
	local cashierX = props.CashierData and props.CashierData.itemData.x or nil
	local cashierZ = props.CashierData and props.CashierData.itemData.z or nil
	local seatX = props.SeatData and props.SeatData.itemData.x or nil
	local seatZ = props.SeatData and props.SeatData.itemData.z or nil
	local spatialCFStr = props.CashierData
			and props.CashierData.type == "Spatial"
			and typeof(props.CashierData.itemData.cframe) == "table"
			and tostring(props.CashierData.itemData.cframe[1])
		or nil

	useEffect(function()
		if not (rig and prompt) then
			return
		end

		local humanoid = rig:FindFirstChildOfClass("Humanoid")
		local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
		local rootPart = rig:FindFirstChild("HumanoidRootPart")
		local feetOffset = rig:GetAttribute("FeetOffset") or 3

		local action = props.Customer.customerAction
		local entranceCF = props.BaseModel.Entrance:GetPivot()

		local plotPart = props.BaseModel.Part
		local floorY = plotPart.Position.Y + (plotPart.Size.Y / 2)

		local spotCF = getCounterTargetCFrame(props.BaseModel, props.CashierData)
		local seatCF = getSeatTargetCFrame(props.BaseModel, props.SeatData)

		local targetFloorPos = entranceCF.Position
		local finalCF = entranceCF

		local holdingAnimation: AnimationTrack?
		local sittingAnimation: AnimationTrack?
		local walkingAnimation: AnimationTrack?

		-- Tween reference for cleanup
		local activeTween = nil
		local isNavigating = true

		if action == "walking" or action == "entering" then
			prompt.Enabled = false
			targetFloorPos = spotCF and Vector3.new(spotCF.Position.X, floorY, spotCF.Position.Z) or entranceCF.Position
			finalCF = spotCF or entranceCF
		elseif action == "queuing" or action == "waiting" then
			prompt.Enabled = true
			targetFloorPos = spotCF and Vector3.new(spotCF.Position.X, floorY, spotCF.Position.Z) or entranceCF.Position
			finalCF = spotCF or entranceCF
		elseif action == "sitting" then
			prompt.Enabled = false
			targetFloorPos = seatCF and Vector3.new(seatCF.Position.X, floorY, seatCF.Position.Z) or entranceCF.Position
			finalCF = seatCF or entranceCF
		elseif action == "paid" or action == "emptyHanded" or action == "leaving" then
			prompt.Enabled = false
			targetFloorPos = Vector3.new(entranceCF.Position.X, floorY, entranceCF.Position.Z)
			finalCF = entranceCF
		end

		if action == "paid" or action == "leaving" then
			local animation = ReplicatedStorage.Shared.Animations:FindFirstChild("HoldCup")
			if animator and animation then
				holdingAnimation = animator:LoadAnimation(animation)
				holdingAnimation.Looped = true
				holdingAnimation.Priority = Enum.AnimationPriority.Action
				holdingAnimation:Play(0.1, 1, 2)
			end
		end

		if humanoid and rootPart and targetFloorPos then
			task.spawn(function()
				if humanoid.Sit then
					humanoid.Sit = false
					task.wait(0.1)
					rootPart.Anchored = true
					local currPos = rootPart.Position
					rootPart.CFrame = CFrame.new(currPos.X, floorY + feetOffset, currPos.Z)
				end

				local startX, startZ = Grid.worldToCell(rootPart.Position, props.BaseModel.Part.CFrame)
				local endX, endZ = Grid.worldToCell(targetFloorPos, props.BaseModel.Part.CFrame)

				local path = AStar.compute(startX, startZ, endX, endZ, props.PlotState, props.BaseModel.Part.Size.X)

				if not path then
					path = AStar.compute(startX, startZ, endX, endZ, props.PlotState, props.BaseModel.Part.Size.X, true)
				end

				local broke = false
				local moveToFinished = false
				local failedpath = false

				if path then
					local waypoints = {}
					for _, node in ipairs(path) do
						table.insert(
							waypoints,
							Grid.cellToWorld(node.x, node.z, props.BaseModel.Part.CFrame, props.BaseModel.Part.Size)
						)
					end
					table.insert(waypoints, targetFloorPos)

					local walkAnim = ReplicatedStorage.Shared.Animations:FindFirstChild("Walk")
					if animator and walkAnim then
						walkingAnimation = animator:LoadAnimation(walkAnim)
						walkingAnimation.Priority = Enum.AnimationPriority.Movement
						walkingAnimation.Looped = true
						walkingAnimation:Play()
					end

					for i, wp in ipairs(waypoints) do
						if not isNavigating then
							break
						end

						local startPos = rootPart.Position
						local targetP = Vector3.new(wp.X, floorY + feetOffset, wp.Z)
						local dist = (targetP - startPos).Magnitude

						if dist > 0.1 then
							local timeToTake = dist / CUSTOMER_WALK_SPEED
							local targetCFrame

							if i == #waypoints and finalCF then
								targetCFrame = CFrame.new(targetP) * finalCF.Rotation
							else
								local lookVector = (targetP - startPos).Unit
								local lookFlat = Vector3.new(lookVector.X, 0, lookVector.Z)

								-- FIX: Protect CFrame.lookAt from math crash
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
							if i == #waypoints and finalCF then
								local targetCFrame = CFrame.new(startPos) * finalCF.Rotation
								activeTween = TweenService:Create(
									rootPart,
									TweenInfo.new(0.2, Enum.EasingStyle.Linear),
									{ CFrame = targetCFrame }
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

					if walkingAnimation then
						walkingAnimation:Stop()
					end
				else
					failedpath = true
				end

				if broke or failedpath then
					rootPart.CFrame = CFrame.new(targetFloorPos + Vector3.new(0, feetOffset, 0))
						* (finalCF and finalCF.Rotation or CFrame.Angles(0, 0, 0))
				end

				if action == "walking" and (failedpath or moveToFinished or broke) then
					GlobalState.queueCustomer(props.PlayerId, {
						customerUid = props.Customer.id,
						timestamp = workspace:GetServerTimeNow(),
					})
				end

				if
					(action == "paid" or action == "emptyHanded" or action == "leaving")
					and (failedpath or moveToFinished or broke)
				then
					GlobalState.removeCustomer(props.PlayerId, props.Customer.id)
				end

				if action == "sitting" and (moveToFinished or failedpath or broke) and seatCF then
					local seatInstance = nil
					if props.SeatData and props.SeatData.uuid then
						local seatModel = props.BaseModel:FindFirstChild(props.SeatData.uuid, true)
						if seatModel then
							seatInstance = seatModel:FindFirstChildWhichIsA("Seat", true)
						end
					end

					if seatInstance then
						rootPart.Anchored = false
						seatInstance.Disabled = false
						seatInstance:Sit(humanoid)
					else
						rootPart.CFrame = seatCF
					end

					local sitAnim = ReplicatedStorage.Shared.Animations:FindFirstChild("Sit")
					if sitAnim and animator then
						sittingAnimation = animator:LoadAnimation(sitAnim)
						sittingAnimation.Priority = Enum.AnimationPriority.Action2
						sittingAnimation.Looped = true
						sittingAnimation:Play()
					end
				end
			end)
		end

		return function()
			isNavigating = false
			if activeTween then
				activeTween:Cancel()
			end
			if holdingAnimation then
				holdingAnimation:Stop()
			end
			if sittingAnimation then
				sittingAnimation:Stop()
			end
			if walkingAnimation then
				walkingAnimation:Stop()
			end
		end
	end, {
		rig,
		prompt,
		props.Customer.customerAction,
		props.numberInLine,
		props.BaseModel,
		props.CafeModel,
		cashierX,
		cashierZ,
		spatialCFStr,
		seatX,
		seatZ,
	})

	local action = props.Customer.customerAction

	-- 3. Drink Models
	local hasDrink = action == "paid" or action == "sitting" or action == "leaving"
	local isSitting = action == "sitting"

	useEffect(function()
		local order = props.Customer.order
		local head = rig and rig:FindFirstChild("Head")
		local rootPart = rig and rig:FindFirstChild("HumanoidRootPart")

		if not (rig and rig.Parent and order and head and rootPart and hasDrink) then
			return
		end

		local drinkModel, modelBasePart = DrinkModelUtil.BuildDrinkModel(order, "none", {
			Anchored = false,
			CanCollide = false,
		})

		local attachPart = isSitting and rootPart or head
		local offsetCFrame = isSitting and CFrame.new(0, 0.5, -2) or CFrame.new(0, 2, 0)

		drinkModel:PivotTo(attachPart.CFrame * offsetCFrame)
		drinkModel.Parent = workspace

		for _, part in drinkModel:GetDescendants() do
			if part:IsA("BasePart") then
				part:SetNetworkOwner(nil)
			end
		end

		if modelBasePart then
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = modelBasePart
			weld.Part1 = attachPart
			weld.Parent = modelBasePart
		end

		return function()
			drinkModel:Destroy()
		end
	end, { rig, hasDrink, isSitting, props.Customer.order })

	-- 4. Chat logic
	local justServed = action == "paid" or action == "sitting"
	useEffect(function()
		if not (rig and rig.Parent and rig:FindFirstChild("Head") and justServed) then
			return
		end
		local sound = Instance.new("Sound", rig:FindFirstChildWhichIsA("BasePart"))
		sound.SoundId = "rbxassetid://79020702281821"
		if not sound.IsLoaded then
			sound.Loaded:Wait()
		end
		sound:Play()
		game:GetService("Chat"):Chat(rig.Head, "THANKS")

		return function()
			sound:Destroy()
		end
	end, { rig, justServed })

	local emptyHanded = props.Customer.customerAction == "emptyHanded"
	useEffect(function()
		if not (rig and rig.Parent and rig:FindFirstChild("Head") and emptyHanded) then
			return
		end
		local sound = Instance.new("Sound", rig:FindFirstChildWhichIsA("BasePart"))
		sound.SoundId = "rbxassetid://133313033428402"
		if not sound.IsLoaded then
			sound.Loaded:Wait()
		end
		sound:Play()
		game:GetService("Chat"):Chat(rig.Head, "Nevermind...")

		return function()
			sound:Destroy()
		end
	end, { rig, emptyHanded })

	local order = props.Customer.order
	useEffect(function()
		if not (rig and rig.Parent and rig:FindFirstChild("Head") and order) then
			return
		end
		local config = CoffeeModule.Config[order]
		local sound = Instance.new("Sound", rig:FindFirstChildWhichIsA("BasePart"))
		sound.SoundId = "rbxassetid://132299423186452"
		if not sound.IsLoaded then
			sound.Loaded:Wait()
		end
		sound:Play()
		game:GetService("Chat"):Chat(rig.Head, `I'd like a {config and config.DisplayName or "👀"} please`)

		return function()
			sound:Destroy()
		end
	end, { rig, order })

	return e(React.Fragment)
end

local selectCustomersById = function(playerId: string)
	return Reflex.createSelector(function(state)
		return state.Customers
	end, function(customers)
		return customers[playerId]
	end)
end

local selectPlotById = function(playerId: string)
	return Reflex.createSelector(function(state)
		return state.Plot
	end, function(plots)
		return plots and plots[playerId]
	end)
end

local function Customers(props: {
	PlayerId: string,
	CafeModel: CafeTypes.Cafe,
	BaseModel: CafeTypes.CafeBase,
	Cashiers: { [string]: any },
})
	local player: Player?, setPlayer = useState(nil :: Player?)
	local customers, setCustomers = useState(nil :: { Types.CustomerEntity }?)
	local plotState, setPlotState = useState(nil)

	useEffect(function()
		setPlayer(getPlayer(props.PlayerId))

		local unsubCust = GlobalState:subscribe(selectCustomersById(props.PlayerId), setCustomers)
		local unsubPlot = GlobalState:subscribe(selectPlotById(props.PlayerId), setPlotState)

		local state = GlobalState:getState()
		if state.Customers then
			setCustomers(state.Customers[props.PlayerId])
		end
		if state.Plot then
			setPlotState(state.Plot[props.PlayerId])
		end

		return function()
			unsubCust()
			unsubPlot()
		end
	end, { props.PlayerId })

	local children = {}
	-- if player and customers then -- dont need
	if customers then
		for _, customer in customers do
			local seatData = nil
			if customer.targetSeatUuid and plotState then
				if plotState.placedItems[customer.targetSeatUuid] then
					seatData = {
						uuid = customer.targetSeatUuid,
						type = "Grid",
						itemData = plotState.placedItems[customer.targetSeatUuid],
					}
				elseif plotState.spatialItems[customer.targetSeatUuid] then
					seatData = {
						uuid = customer.targetSeatUuid,
						type = "Spatial",
						itemData = plotState.spatialItems[customer.targetSeatUuid],
					}
				end
			end

			local customerProps = {
				PlayerId = props.PlayerId,
				Customer = customer,
				CafeModel = props.CafeModel,
				BaseModel = props.BaseModel,
				CashierData = props.Cashiers[customer.targetCounterUuid],
				SeatData = seatData,
				PlotState = plotState,
			}
			children[customer.id] = e(Customer, customerProps)
		end
	end

	return e(React.Fragment, nil, children)
end

return Customers
