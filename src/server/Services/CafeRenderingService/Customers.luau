-- CafeRenderingService/Customers.luau

local PathfindingService = game:GetService("PathfindingService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local React = require(ReplicatedStorage.Packages.React)
local Reflex = require(ReplicatedStorage.Packages.Reflex)
local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local Types = require(ReplicatedStorage.Shared.Types)
local CafeTypes = require(ReplicatedStorage.Shared.CafeTypes)
local CustomersService = require(ServerScriptService.Server.Services.CustomersService)
local VariationsConfig = require(ReplicatedStorage.Shared.Configs.VariationsConfig)
local DrinkModelUtil = require(ReplicatedStorage.Shared.Utils.DrinkModelUtil)

local e = React.createElement
local useEffect = React.useEffect
local useState = React.useState

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

local function Customer(props: {
	PlayerId: string,
	CafeModel: CafeTypes.Cafe,
	Customer: Types.CustomerEntity,
	BaseModel: CafeTypes.CafeBase,
	numberInLine: number?,
})
	local rig: CafeTypes.CustomerRig, setRig = useState(nil)
	local prompt: ProximityPrompt, setPrompt = useState(nil)

	-- 1. Mounting Effect: Clone the rig and Pivot to the deterministic start state
	useEffect(function()
		-- warn(`props.CafeModel {props.CafeModel}`)
		local clone = workspace.Rig:Clone() :: CafeTypes.CustomerRig
		local tag = "Customer" .. props.PlayerId
		clone.Parent = workspace
		clone:AddTag(tag)
		clone.Name = props.Customer.id

		-- FIX: Force the server to handle the physics so the NPC doesn't stutter!
		local rootPart = clone:FindFirstChild("HumanoidRootPart")
		if rootPart and rootPart:CanSetNetworkOwnership() then
			rootPart:SetNetworkOwner(nil)
		end

		setRig(clone)
		clone.TriggerPrompt.MaxActivationDistance = 15
		setPrompt(clone.TriggerPrompt)

		local entranceCF = props.BaseModel.Entrance:GetPivot()
		local cashierCF = props.CafeModel.Cashier:GetPivot()
		local action = props.Customer.customerAction

		-- ... [The rest of your mounting effect remains exactly the same]
		-- Default start is the entrance
		local targetCF = entranceCF + Vector3.new(0, 4, 0)

		-- If a chunk loads while they are already mid-action, spawn them in their current domain
		if action == "queuing" then
			-- Queue spans outward from the front of the cashier (using LookVector)
			-- Assuming Cashier.Part's Front faces the line
			local lineOffset = cashierCF.LookVector * 3
				+ (cashierCF * CFrame.Angles(0, math.pi / -2, 0)).LookVector * (3 * (props.numberInLine or 1 - 1))
			targetCF = cashierCF + lineOffset
			-- Make them face the cashier
			targetCF = CFrame.lookAt(targetCF.Position, cashierCF.Position)
		elseif action == "paid" or action == "emptyHanded" then
			-- Start them right at the cashier so they can begin their walk out
			targetCF = cashierCF + (cashierCF.LookVector * 4)
		end

		clone:PivotTo(targetCF)

		clone.TriggerPrompt.RequiresLineOfSight = false
		clone.TriggerPrompt.ActionText = "Tend Customer"

		local conn = clone.TriggerPrompt.Triggered:Connect(function(player: Player)
			if tostring(player.UserId) ~= props.PlayerId then
				return
			end
			CustomersService.TendCustomer(player, props.Customer.id)
		end)

		return function()
			if clone and clone.Parent then
				clone:Destroy()
			end
			if conn then
				conn:Disconnect()
			end
			setRig(nil)
			setPrompt(nil)
		end
	end, { props.Customer.id, props.BaseModel, props.CafeModel })

	-- Customers.luau

	-- 2. State Transition Effect: Handle walking targets using PathfindingService
	useEffect(function()
		if not (rig and prompt) then
			return
		end

		local humanoid = rig:FindFirstChildOfClass("Humanoid")
		local rootPart = rig:FindFirstChild("HumanoidRootPart")
		local action = props.Customer.customerAction

		local standSpots = props.BaseModel.Cafe:FindFirstChild("StandSpots")
		local spots = standSpots:GetChildren()
		local random = Random.new():NextInteger(1, #spots)
		local randomSpot = spots[random]
		local tableCF = randomSpot:GetPivot()

		local entranceCF = props.BaseModel.Entrance:GetPivot()
		local cashierCF = props.CafeModel.Cashier.Part:GetPivot()

		local targetPos = nil

		-- Determine the ultimate target position based on the action state
		local holdingAnimation: AnimationTrack?
		local holdingAnimationThread: thread?
		if action == "entering" then
			prompt.Enabled = false
			local randomOffset = (math.random() - 0.5) * 10
			targetPos = tableCF.Position
		elseif action == "queuing" then
			prompt.Enabled = (props.numberInLine == 1)
			local lineOffset = cashierCF.LookVector * (4 * (props.numberInLine or 1))
			targetPos = cashierCF.Position + lineOffset
		elseif action == "paid" or action == "emptyHanded" then
			prompt.Enabled = false
			targetPos = entranceCF.Position
		end
		if action == "queuing" or action == "paid" then
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
					holdingAnimation:Play(0.1, 0.2, 2)
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

				if success and path.Status == Enum.PathStatus.Success then
					local waypoints = path:GetWaypoints()

					for _, waypoint in ipairs(waypoints) do
						-- Break out of the loop if the state changed while walking
						if not isNavigating then
							break
						end

						humanoid:MoveTo(waypoint.Position)

						-- Wait for the humanoid to reach the waypoint before continuing
						local moveSuccess = humanoid.MoveToFinished:Wait()
						if not moveSuccess then
							-- If they get stuck for longer than 8 seconds, break the loop
							break
						end
					end
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
	local paid = props.Customer.customerAction and props.Customer.customerAction == "paid"
	useEffect(function()
		local drinkEntities = props.Customer.drinkEntities
		if not (rig and rig.Parent and drinkEntities and #drinkEntities > 0 and rig:FindFirstChild("Head")) then
			return
		end

		local instances = {}

		for i, drink in drinkEntities do
			local drinkModel, modelBasePart = DrinkModelUtil.BuildDrinkModel(drink.drinkId, drink.variationId, {
				Anchored = false,
				CanCollide = false,
				Size = drink.Size,
			})

			drinkModel:PivotTo(rig.Head:GetPivot() + Vector3.new(0, 2 * i, 0))
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

			table.insert(instances, drinkModel)
		end

		return function()
			for _, instance in instances do
				if instance and instance.Parent then
					instance:Destroy()
				end
			end
		end
	end, { rig, paid or props.Customer.customerAction == "queuing" })

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
		-- game:GetService("Chat"):Chat(rig.Head, disappointed[Random.new():NextInteger(1, #disappointed)])
		game:GetService("Chat"):Chat(rig.Head, "Nevermind...")
		return
	end, { rig, emptyHanded })

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
		local numberInLine = 1
		for _, customer in customers do
			local customerProps = {
				PlayerId = props.PlayerId,
				Customer = customer,
				CafeModel = props.CafeModel,
				BaseModel = props.BaseModel,
			}

			if customer.drinkEntities then
				customerProps.numberInLine = numberInLine
				numberInLine += 1
			end

			children[customer.id] = e(Customer, customerProps)
		end
	end

	return e(React.Fragment, nil, children)
end

return Customers
