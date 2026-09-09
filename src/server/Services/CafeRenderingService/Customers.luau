-- CafeRenderingService/Customers.luau -- server

local PathfindingService = game:GetService("PathfindingService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local React = require(ReplicatedStorage.Packages.React)
local Mionum = require(ReplicatedStorage.Packages.Mionum)
local Reflex = require(ReplicatedStorage.Packages.Reflex)
local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local Types = require(ReplicatedStorage.Shared.Types)
local CafeTypes = require(ReplicatedStorage.Shared.CafeTypes)
local CoffeeModule = require(ReplicatedStorage.Shared.CoffeeModule)
local CustomersService = require(ServerScriptService.Server.Services.CustomersService)
local VariationsConfig = require(ReplicatedStorage.Shared.Configs.VariationsConfig)
local DrinkModelUtil = require(ReplicatedStorage.Shared.Utils.DrinkModelUtil)

-- NEW: Require Grid and Models to calculate dynamic CFrames
local Grid = require(ReplicatedStorage.Shared.Grid)
local Models = ReplicatedStorage.Shared.Models

local e = React.createElement
local useEffect = React.useEffect
local useState = React.useState
local useRef = React.useRef

local disappointed = {
	"Where are the drinks?",
	"I'm thirsty...",
	"I thought this place sell drinks",
	-- "KILL YOURSELF",
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
		-- warn("NO CLONE TO OBSERVE")
		return nil
	end
	local conn = clone:GetPropertyChangedSignal("Parent"):Connect(function()
		-- warn(`Parent changed: {clone.Parent}`)
		return
	end)
	local conn2 = clone.Destroying:Connect(function()
		-- warn(`Clone destroying: {clone}`)
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

local function getCounterTargetCFrame(playerId: string, baseModel: CafeTypes.CafeBase): CFrame?
	local state = GlobalState:getState()
	local plotState = state.Plot and state.Plot[playerId]
	if not plotState then
		return nil
	end

	for _, item in pairs(plotState.placedItems) do
		if item.id == "Counter" then
			local prefab = Models:FindFirstChild(item.id)
			if not prefab then
				continue
			end

			local _, itemSize = prefab:GetBoundingBox()
			local plotCFrame, plotSize = baseModel.Part.CFrame, baseModel.Part.Size

			local rawX, rawZ = Grid.getFootprint(itemSize, 0)
			local snappedSize = Vector3.new(rawX * Grid.SIZE, itemSize.Y, rawZ * Grid.SIZE)

			local counterCF =
				Grid.gridToWorld(item.itemType or "Solid", item.x, item.z, plotCFrame, plotSize, snappedSize, item.r)

			-- Offset by half the counter's depth + 1 stud so they don't clip inside the model!
			return counterCF * CFrame.new(0, 0, -(itemSize.Z / 2 + 1))
		end
	end
	return nil
end

local original = workspace.Rig:Clone()
-- workspace.Rig:Destroy()

local function Customer(props: {
	PlayerId: string,
	CafeModel: CafeTypes.Cafe,
	Customer: Types.CustomerEntity,
	BaseModel: CafeTypes.CafeBase,
	numberInLine: number?,
})
	local rig: CafeTypes.CustomerRig, setRig = useState(nil)
	local prompt: ProximityPrompt, setPrompt = useState(nil)

	local actionRef = useRef(nil)

	useEffect(function()
		actionRef.current = props.Customer.customerAction
	end, { props.Customer })

	-- 1. Mounting: Clone the rig and Pivot to the deterministic start state
	useEffect(function()
		local clone = original:Clone() :: CafeTypes.CustomerRig
		local unsub = observeRigClone(clone)
		local tag = "Customer" .. props.PlayerId
		local rootPart = clone:FindFirstChild("HumanoidRootPart")

		clone:AddTag(tag)
		clone.Name = props.Customer.id
		clone.Parent = workspace
		if rootPart and rootPart:CanSetNetworkOwnership() then
			rootPart:SetNetworkOwner(nil)
		end

		setRig(clone)
		clone.TriggerPrompt.MaxActivationDistance = 15
		setPrompt(clone.TriggerPrompt)

		local entranceCF = props.BaseModel.Entrance:GetPivot()
		local action = props.Customer.customerAction

		-- FIX: Fetch dynamic spot CF, fallback to entrance if counter is missing
		local spotCF = getCounterTargetCFrame(props.PlayerId, props.BaseModel) or entranceCF

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

	-- 2. State Transition: Handle walking targets using PathfindingService
	useEffect(function()
		if not (rig and prompt) then
			return
		end

		local humanoid = rig:FindFirstChildOfClass("Humanoid")
		local rootPart = rig:FindFirstChild("HumanoidRootPart")
		local action = props.Customer.customerAction

		local entranceCF = props.BaseModel.Entrance:GetPivot()

		-- FIX: Fetch dynamic spot CF, fallback to entrance
		local spotCF = getCounterTargetCFrame(props.PlayerId, props.BaseModel) or entranceCF

		local targetPos = nil

		local holdingAnimation: AnimationTrack?
		local holdingAnimationThread: thread?

		if action == "walking" or action == "entering" then
			prompt.Enabled = false
			targetPos = spotCF.Position
		elseif action == "queuing" or action == "waiting" then
			prompt.Enabled = true
			targetPos = spotCF.Position
		elseif action == "paid" or action == "emptyHanded" then
			prompt.Enabled = false
			targetPos = entranceCF.Position
		end
		if action == "paid" then
			-- or action == "walking" or action == "queuing"
			local animation = ReplicatedStorage.Shared.Animations:FindFirstChild("HoldCup")
			-- local animation = ReplicatedStorage.Shared.Animations:FindFirstChild("_idle2")
			-- if not animation then
			-- 	animation = Instance.new("Animation", ReplicatedStorage.Shared.Animations)
			-- 	animation.Name = "_idle2"
			-- 	animation.AnimationId = "rbxassetid://92168447891089"
			-- end
			if rig and rig.Parent and animation then
				local animator: Animator = rig.Humanoid:FindFirstChildOfClass("Animator")

				if animator then
					holdingAnimation = animator:LoadAnimation(animation)
					holdingAnimation.Looped = true
					-- Priority ensures it plays OVER the default idle/walk animations
					holdingAnimation.Priority = Enum.AnimationPriority.Action
					holdingAnimation:Play(0.1, 1, 2)
				end
			end
		end

		-- A flag to safely cancel the pathfinding loop if the component unmounts or state changes
		local isNavigating = true

		if humanoid then
			humanoid:MoveTo(targetPos)
		end

		if humanoid and rootPart and targetPos then
			task.spawn(function()
				-- Create a custom pathfinding agent that cannot jump or climb
				local path = PathfindingService:CreatePath({
					AgentRadius = 2,
					AgentHeight = 5,
					AgentCanJump = false,
					AgentCanClimb = true, -- This prevents them from scaling objects!
				})

				local success, _ = pcall(function()
					path:ComputeAsync(rootPart.Position, targetPos)
				end)

				local broke, moveToFinished, failedpath
				if success and path.Status == Enum.PathStatus.Success then
					local waypoints = path:GetWaypoints()

					for _, waypoint in ipairs(waypoints) do
						-- Break out of the loop if the state changed while walking
						if not isNavigating then
							break
						end

						humanoid:MoveTo(waypoint.Position)

						-- Wait for the humanoid to reach the waypoint before continuing
						local start = tick()
						local moveSuccess = humanoid.MoveToFinished:Wait()
						local elapsed = tick()
						if not moveSuccess then
							if action == "walking" then
								warn("failed to move, queuing customer")
							end
							-- If they get stuck for longer than 8 seconds, break the loop
							broke = true
							break
						end
						if _ == #waypoints then
							moveToFinished = true
							-- put this here so it doesnt queueCustomer when they havent arrived to cashier yet
						end
					end
					-- humanoid:MoveTo(targetPos)
					-- local moveSuccess = humanoid.MoveToFinished:Wait()
					-- if not moveSuccess then
					-- 	if action == "walking" then
					-- 		warn("failed to move, queuing customer")
					-- 	end
					-- 	-- If they get stuck for longer than 8 seconds, break the loop
					-- 	broke = true
					-- else
					-- 	moveToFinished = true
					-- end
				else
					warn("failed path")
					failedpath = true
				end
				if broke then
					rig:PivotTo(CFrame.new(targetPos))
				end
				if action == "walking" and (failedpath or moveToFinished) then
					GlobalState.queueCustomer(props.PlayerId, {
						customerUid = props.Customer.id,
						timestamp = workspace:GetServerTimeNow(),
					})
				end
			end)
		end

		-- Cleanup function to stop the current pathfinding loop when state updates
		return function()
			isNavigating = false
			if holdingAnimation then
				holdingAnimation:Stop()
			end
			if holdingAnimationThread then
				task.cancel(holdingAnimationThread)
			end
		end
	end, { rig, prompt, props.Customer.customerAction, props.numberInLine, props.BaseModel, props.CafeModel })

	-- 3. drink models
	local paid = props.Customer.customerAction and props.Customer.customerAction == "paid"
	useEffect(function()
		local order = props.Customer.order
		if not (rig and rig.Parent and order and rig:FindFirstChild("Head") and paid) then
			return
		end

		local drinkModel, modelBasePart = DrinkModelUtil.BuildDrinkModel(order, "none", {
			Anchored = false,
			CanCollide = false,
		})

		drinkModel:PivotTo(rig.Head:GetPivot() + Vector3.new(0, 2, 0))
		drinkModel.Parent = workspace -- Parent to workspace BEFORE setting NetworkOwner!

		for _, part in drinkModel:GetDescendants() do
			if part:IsA("BasePart") then
				-- Crucial for preventing NPC stuttering
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
	end, { rig, paid or props.Customer.customerAction == "queuing" or props.Customer.customerAction == "walking" })

	-- 4. Chat
	useEffect(function()
		if not (rig and rig.Parent and rig:FindFirstChild("Head") and paid) then
			return
		end
		game:GetService("Chat"):Chat(rig.Head, "THANKS")
		return
	end, { rig, paid })
	local emptyHanded = props.Customer.customerAction == "emptyHanded"
	useEffect(function()
		if not (rig and rig.Parent and rig:FindFirstChild("Head") and emptyHanded) then
			return
		end
		game:GetService("Chat"):Chat(rig.Head, "Nevermind...")
		return
	end, { rig, emptyHanded })
	local order = props.Customer.order
	useEffect(function()
		if not (rig and rig.Parent and rig:FindFirstChild("Head") and order) then
			return
		end
		local config = CoffeeModule.Config[order]
		game:GetService("Chat"):Chat(rig.Head, `I'd like a {config and config.DisplayName or "👀"} please`)
		return
	end, { rig, order })

	return e(React.Fragment)
end

local selectCustomers = function(state)
	return state.Customers
end
local selectCustomersById = function(playerId: string)
	return Reflex.createSelector({ selectCustomers }, function(customers)
		return customers[playerId]
	end)
end

local function Customers(props: {
	PlayerId: string,
	CafeModel: CafeTypes.Cafe,
	BaseModel: CafeTypes.CafeBase,
})
	local player, setPlayer = useState(nil :: Player?)
	local customers, setCustomers = useState(nil :: { Types.CustomerEntity }?)

	useEffect(function()
		local currentPlayer = getPlayer(props.PlayerId)
		setPlayer(currentPlayer)

		local selectValues = selectCustomersById(props.PlayerId)
		local unsub = GlobalState:subscribe(selectValues, function(newCustomers)
			setCustomers(newCustomers)
		end)

		local state = GlobalState:getState()
		if state.Customers then
			setCustomers(state.Customers[props.PlayerId])
		end

		return function()
			unsub()
		end
	end, { props.PlayerId })

	local children = {}
	if player and customers then
		for _, customer in customers do
			local customerProps = {
				PlayerId = props.PlayerId,
				Customer = customer,
				CafeModel = props.CafeModel,
				BaseModel = props.BaseModel,
			}
			children[customer.id] = e(Customer, customerProps)
		end
	end

	return e(React.Fragment, nil, children)
end

return Customers
