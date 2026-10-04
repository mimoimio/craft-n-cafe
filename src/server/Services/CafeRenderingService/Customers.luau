-- CafeRenderingService/Customers.luau -- server
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

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
local AStar = require(ReplicatedStorage.Shared.AStar) -- NEW: Custom Pathfinder

local e = React.createElement
local useEffect = React.useEffect
local useState = React.useState
local useRef = React.useRef

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

-- PURE FUNCTION: Calculates Counter CFrame
local function getCounterTargetCFrame(baseModel: CafeTypes.CafeBase, cashierData: any?): CFrame?
	if not cashierData then
		warn("[Customers-CFrame] cashierData is nil")
		return nil
	end

	local item = cashierData.itemData
	local placementType = cashierData.type

	local prefab = Models:FindFirstChild(item.id)
	if not prefab then
		warn("[Customers-CFrame] Failed to find Prefab model for counter:", item.id)
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

	local finalcf = counterCF * CFrame.new(0, 0, -4)
	-- local finalcf = counterCF * CFrame.new(0, 0, -(itemSize.Z / 2 + 1))
	print(`[Customers-CFrame] Counter Target for {item.id}: {tostring(finalcf.Position)}`)
	return finalcf
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
		warn("[Customers-CFrame] Failed to find Prefab model for seat:", item.id)
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

	local finalcf = seatCF * CFrame.new(0, 1.5, 0)
	print(`[Customers-CFrame] Seat Target for {item.id}: {tostring(finalcf.Position)}`)
	return finalcf
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

	print(`[Customer-Render] Rendered {props.Customer.id} | Action: {props.Customer.customerAction}`)

	useEffect(function()
		actionRef.current = props.Customer.customerAction
	end, { props.Customer })

	-- 1. Mounting the Rig
	useEffect(function()
		print(`[Customers-Rig] Spawning rig for {props.Customer.id}...`)
		local clone
		if npcsFolder and #npcsFolder:GetChildren() > 0 then
			local npcs = npcsFolder:GetChildren()
			local selected = npcs[(#npcs * math.random() + 1) // 1]
			clone = selected:Clone()
		else
			clone = original:Clone()
		end

		local unsub = observeRigClone(clone)
		local tag = "Customer" .. props.PlayerId
		local rootPart = clone:FindFirstChild("HumanoidRootPart")

		clone:AddTag(tag)
		clone.Name = props.Customer.id
		clone.Parent = workspace
		if rootPart and rootPart:CanSetNetworkOwnership() then
			rootPart:SetNetworkOwner(nil)
		end
		for i, desc: BasePart in clone:GetDescendants() do
			if desc:IsA("BasePart") then
				desc.CollisionGroup = "Characters"
				desc.Anchored = false
			end
		end

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
		local targetCF = entranceCF + Vector3.new(0, 4, 0)

		if action == "queuing" then
			targetCF = spotCF
		elseif action == "paid" or action == "emptyHanded" then
			targetCF = spotCF + (spotCF.LookVector * 4)
		end

		clone:PivotTo(targetCF)
		clone.TriggerPrompt.RequiresLineOfSight = false
		clone.TriggerPrompt.ActionText = "Tend Customer"
		clone.TriggerPrompt.Style = Enum.ProximityPromptStyle.Default

		local conn = clone.TriggerPrompt.Triggered:Connect(function(player: Player)
			print(`[Customers-Interact] Prompt triggered on {props.Customer.id} by {player.Name}`)
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
			print(`[Customers-Rig] Destroying rig for {props.Customer.id}`)
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

	-- 2. State Transition & Custom A* Pathfinding
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
		local rootPart = rig:FindFirstChild("HumanoidRootPart")
		local action = props.Customer.customerAction
		local entranceCF = props.BaseModel.Entrance:GetPivot()

		local spotCF = getCounterTargetCFrame(props.BaseModel, props.CashierData) or entranceCF
		local seatCF = getSeatTargetCFrame(props.BaseModel, props.SeatData)
		local targetPos = nil

		local holdingAnimation: AnimationTrack?
		local sittingAnimation: AnimationTrack?

		print(`[Customers-State] {props.Customer.id} routing state: {action}`)

		-- Determine target
		if action == "walking" or action == "entering" then
			prompt.Enabled = false
			targetPos = spotCF.Position
		elseif action == "queuing" or action == "waiting" then
			prompt.Enabled = true
			targetPos = spotCF.Position
		elseif action == "sitting" then
			prompt.Enabled = false
			targetPos = seatCF and seatCF.Position or entranceCF.Position
		elseif action == "paid" or action == "emptyHanded" or action == "leaving" then
			prompt.Enabled = false
			targetPos = entranceCF.Position
		end

		print(`[Customers-Nav] {props.Customer.id} Target Position: {tostring(targetPos)}`)

		-- Handle hold cup animations
		if action == "paid" or action == "sitting" or action == "leaving" then
			local animation = ReplicatedStorage.Shared.Animations:FindFirstChild("HoldCup")
			if rig and rig.Parent and animation and humanoid then
				local animator: Animator = humanoid:FindFirstChildOfClass("Animator")
				if animator then
					print(`[Customers-Anim] Playing HoldCup for {props.Customer.id}`)
					holdingAnimation = animator:LoadAnimation(animation)
					holdingAnimation.Looped = true
					holdingAnimation.Priority = Enum.AnimationPriority.Action
					holdingAnimation:Play(0.1, 1, 2)
				end
			end
		end

		local isNavigating = true

		-- A* Grid Pathfinding Execution
		if humanoid and rootPart and targetPos then
			task.spawn(function()
				print(`[Customers-Nav] Calculating Grid Path for {props.Customer.id}...`)

				-- 1. Convert to logical Grid Cells
				local startX, startZ = Grid.worldToCell(rootPart.Position, props.BaseModel.Part.CFrame)
				local endX, endZ = Grid.worldToCell(targetPos, props.BaseModel.Part.CFrame)
				print(`[Customers-Nav] Grid Cells -> Start: ({startX}, {startZ}) | End: ({endX}, {endZ})`)

				-- 2. Execute A* search
				local path = AStar.compute(startX, startZ, endX, endZ, props.PlotState, props.BaseModel.Part.Size.X)

				local broke = false
				local moveToFinished = false
				local failedpath = false

				if path then
					print(`[Customers-Nav] A* Success! {#path} nodes found for {props.Customer.id}`)
					local waypoints = {}

					-- Translate grid nodes to world centers
					for _, node in ipairs(path) do
						table.insert(
							waypoints,
							Grid.cellToWorld(node.x, node.z, props.BaseModel.Part.CFrame, props.BaseModel.Part.Size)
						)
					end
					table.insert(waypoints, targetPos) -- Snap exactly to final destination

					for i, wp in ipairs(waypoints) do
						if not isNavigating then
							print(`[Customers-Nav] Cancelled mid-path for {props.Customer.id}`)
							break
						end

						humanoid:MoveTo(wp + Vector3.new(0, 2, 0))
						local moveSuccess = humanoid.MoveToFinished:Wait()

						if not moveSuccess then
							warn(`[Customers-Nav] {props.Customer.id} got stuck at waypoint {i}!`)
							broke = true
							break
						end

						if i == #waypoints then
							print(`[Customers-Nav] {props.Customer.id} reached destination!`)
							moveToFinished = true
						end
					end
				else
					warn(
						`[Customers-Nav] A* FAILED to find path for {props.Customer.id} from ({startX}, {startZ}) to ({endX}, {endZ})`
					)
					failedpath = true
				end

				-- Failsafe Teleport
				if broke or failedpath then
					print(`[Customers-Nav] Failsafe triggered. Teleporting {props.Customer.id} to target.`)
					rig:PivotTo(CFrame.new(targetPos))
				end

				-- Queue logic after walking to counter
				if action == "walking" and (failedpath or moveToFinished or broke) then
					print(`[Customers-State] Dispatching queueCustomer for {props.Customer.id}`)
					GlobalState.queueCustomer(props.PlayerId, {
						customerUid = props.Customer.id,
						timestamp = workspace:GetServerTimeNow(),
					})
				end

				-- Sit execution
				if action == "sitting" and (moveToFinished or failedpath or broke) and seatCF then
					print(`[Customers-Anim] Executing Sit sequence for {props.Customer.id}`)
					rig:PivotTo(seatCF)
					local sitAnim = ReplicatedStorage.Shared.Animations:FindFirstChild("Sit")
					if sitAnim and humanoid then
						local animator = humanoid:FindFirstChildOfClass("Animator")
						if animator then
							sittingAnimation = animator:LoadAnimation(sitAnim)
							sittingAnimation.Priority = Enum.AnimationPriority.Action2
							sittingAnimation.Looped = true
							sittingAnimation:Play()
						end
					end
				end
			end)
		end

		return function()
			isNavigating = false
			if holdingAnimation then
				holdingAnimation:Stop()
			end
			if sittingAnimation then
				sittingAnimation:Stop()
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
	useEffect(function()
		local order = props.Customer.order
		if not (rig and rig.Parent and order and rig:FindFirstChild("Head") and hasDrink) then
			return
		end

		print(`[Customers-Drink] Attaching drink '{order}' to {props.Customer.id}`)
		local drinkModel, modelBasePart = DrinkModelUtil.BuildDrinkModel(order, "none", {
			Anchored = false,
			CanCollide = false,
		})

		drinkModel:PivotTo(rig.Head:GetPivot() + Vector3.new(0, 2, 0))
		drinkModel.Parent = workspace

		for _, part in drinkModel:GetDescendants() do
			if part:IsA("BasePart") then
				part:SetNetworkOwner(nil)
			end
		end

		if modelBasePart then
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = modelBasePart
			weld.Part1 = rig.Head
			weld.Parent = modelBasePart
		end

		return function()
			drinkModel:Destroy()
		end
	end, { rig, hasDrink, props.Customer.order })

	-- 4. Chat logic
	local justServed = action == "paid" or action == "sitting"
	useEffect(function()
		if not (rig and rig.Parent and rig:FindFirstChild("Head") and justServed) then
			return
		end
		print(`[Customers-Chat] Thanks -> {props.Customer.id}`)
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
		print(`[Customers-Chat] EmptyHanded -> {props.Customer.id}`)
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
		print(`[Customers-Chat] Order -> {props.Customer.id} | Drink: {config and config.DisplayName}`)

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
	local player, setPlayer = useState(nil :: Player?)
	local customers, setCustomers = useState(nil :: { Types.CustomerEntity }?)
	local plotState, setPlotState = useState(nil)

	useEffect(function()
		print(`[Customers-Container] Initializing Customers container for {props.PlayerId}`)
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
	if player and customers then
		for _, customer in customers do
			local seatData = nil
			if customer.targetSeatUuid and plotState then
				if plotState.placedItems[customer.targetSeatUuid] then
					seatData = { type = "Grid", itemData = plotState.placedItems[customer.targetSeatUuid] }
				elseif plotState.spatialItems[customer.targetSeatUuid] then
					seatData = { type = "Spatial", itemData = plotState.spatialItems[customer.targetSeatUuid] }
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
