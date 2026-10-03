-- CafeRenderingService/Customers.luau -- server
local PathfindingService = game:GetService("PathfindingService")
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

-- PURE FUNCTION: Calculates CFrame dynamically based on Cashier Grid/Spatial data
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
		-- Ensure spatial rotation is accurately parsed
		local spatialCFrame = if typeof(item.cframe) == "table"
			then CFrame.new(table.unpack(item.cframe))
			elseif typeof(item.cframe) == "CFrame" then item.cframe
			else CFrame.new(0, 0, 0)
		counterCF = Grid.spatialToWorld(spatialCFrame, plotCFrame, plotSize)
	end

	-- Offset by half the counter's depth + 1 stud so they stand perfectly in front of it
	local finalcf = counterCF * CFrame.new(0, 0, -(itemSize.Z / 2 + 1))
	return finalcf
end

local original = workspace.Rig:Clone()
local npcsFolder = workspace.NPCS

local function Customer(
	props: {
		PlayerId: string,
		CafeModel: CafeTypes.Cafe,
		Customer: Types.CustomerEntity,
		BaseModel: CafeTypes.CafeBase,
		CashierData: any?, -- NEW
		numberInLine: number?,
	}
)
	local rig: CafeTypes.CustomerRig, setRig = useState(nil)
	local prompt: ProximityPrompt, setPrompt = useState(nil)

	local actionRef = useRef(nil)

	useEffect(function()
		actionRef.current = props.Customer.customerAction
	end, { props.Customer })

	-- 1. Mounting
	useEffect(function()
		local npcs = npcsFolder:GetChildren()
		local selected = npcs[(#npcs * math.random() + 1 )// 1]
		local clone = selected:Clone() :: CafeTypes.CustomerRig
		
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

		if not clone:FindFirstChild("TriggerPrompt")  then
			local prompt = Instance.new("ProximityPrompt")
			prompt.Parent = clone
			prompt.Name = "TriggerPrompt"
		end
		
		setRig(clone)
		clone.TriggerPrompt.MaxActivationDistance = 15
		setPrompt(clone.TriggerPrompt)

		local entranceCF = props.BaseModel.Entrance:GetPivot()
		local action = props.Customer.customerAction

		-- FIX: Determine spot cleanly from props data
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

	-- 2. State Transition & Pathfinding
	-- Extract variables for the dependency array so they re-pathfind if the cashier is moved!
	local cashierX = props.CashierData and props.CashierData.itemData.x or nil
	local cashierZ = props.CashierData and props.CashierData.itemData.z or nil
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

		-- Determine target
		local spotCF = getCounterTargetCFrame(props.BaseModel, props.CashierData) or entranceCF
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
			local animation = ReplicatedStorage.Shared.Animations:FindFirstChild("HoldCup")
			if rig and rig.Parent and animation then
				local animator: Animator = rig.Humanoid:FindFirstChildOfClass("Animator")
				if animator then
					holdingAnimation = animator:LoadAnimation(animation)
					holdingAnimation.Looped = true
					holdingAnimation.Priority = Enum.AnimationPriority.Action
					holdingAnimation:Play(0.1, 1, 2)
				end
			end
		end

		local isNavigating = true

		if humanoid then
			humanoid:MoveTo(targetPos)
		end

		if humanoid and rootPart and targetPos then
			task.spawn(function()
				local path = PathfindingService:CreatePath({
					AgentRadius = 2,
					AgentHeight = 5,
					AgentCanJump = false,
					AgentCanClimb = true,
				})

				local success, _ = pcall(function()
					path:ComputeAsync(rootPart.Position, targetPos)
				end)

				local broke, moveToFinished, failedpath
				if success and path.Status == Enum.PathStatus.Success then
					local waypoints = path:GetWaypoints()

					for _, waypoint in ipairs(waypoints) do
						if not isNavigating then
							break
						end

						humanoid:MoveTo(waypoint.Position)
						local moveSuccess = humanoid.MoveToFinished:Wait()

						if not moveSuccess then
							if action == "walking" then
								warn("failed to move, queuing customer")
							end
							broke = true
							break
						end
						if _ == #waypoints then
							moveToFinished = true
						end
					end
				else
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

		return function()
			isNavigating = false
			if holdingAnimation then
				holdingAnimation:Stop()
			end
			if holdingAnimationThread then
				task.cancel(holdingAnimationThread)
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
	})

	-- 3. Drink Models
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
	end, { rig, paid or props.Customer.customerAction == "queuing" or props.Customer.customerAction == "walking" })

	-- 4. Chat
	useEffect(function()
		if not (rig and rig.Parent and rig:FindFirstChild("Head") and paid) then
			return
		end
		local promise = Promise.defer(function(resolve, reject, onCancel)
			local sound = Instance.new("Sound", rig:FindFirstChildWhichIsA("BasePart"))
			sound.SoundId = "rbxassetid://79020702281821"
			if not sound.IsLoaded then
				sound.Loaded:Wait()
			end

			return resolve(sound)
		end)
			:andThen(function(sound: Sound)
				sound:Play()
				sound.Ended:Wait()
				return sound
			end)
			:andThen(function(sound)
				sound:Destroy()
			end)
			:timeout(10)
			:catch(print)

		game:GetService("Chat"):Chat(rig.Head, "THANKS")
		return function()
			promise:cancel()
		end
	end, { rig, paid })

	local emptyHanded = props.Customer.customerAction == "emptyHanded"
	useEffect(function()
		if not (rig and rig.Parent and rig:FindFirstChild("Head") and emptyHanded) then
			return
		end
		local promise = Promise.defer(function(resolve, reject, onCancel)
			local sound = Instance.new("Sound", rig:FindFirstChildWhichIsA("BasePart"))
			sound.SoundId = "rbxassetid://133313033428402"
			if not sound.IsLoaded then
				sound.Loaded:Wait()
			end

			return resolve(sound)
		end)
			:andThen(function(sound: Sound)
				sound:Play()
				sound.Ended:Wait()
				return sound
			end)
			:andThen(function(sound)
				sound:Destroy()
			end)
			:timeout(10)
			:catch(print)

		game:GetService("Chat"):Chat(rig.Head, "Nevermind...")
		return function()
			promise:cancel()
		end
	end, { rig, emptyHanded })

	local order = props.Customer.order
	useEffect(function()
		if not (rig and rig.Parent and rig:FindFirstChild("Head") and order) then
			return
		end
		local config = CoffeeModule.Config[order]

		local promise = Promise.defer(function(resolve, reject, onCancel)
			local sound = Instance.new("Sound", rig:FindFirstChildWhichIsA("BasePart"))
			sound.SoundId = "rbxassetid://132299423186452"
			if not sound.IsLoaded then
				sound.Loaded:Wait()
			end

			return resolve(sound)
		end)
			:andThen(function(sound: Sound)
				sound:Play()
				sound.Ended:Wait()
				return sound
			end)
			:andThen(function(sound)
				sound:Destroy()
			end)
			:timeout(10)
			:catch(print)

		game:GetService("Chat"):Chat(rig.Head, `I'd like a {config and config.DisplayName or "👀"} please`)
		return function()
			promise:cancel()
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

local function Customers(
	props: {
		PlayerId: string,
		CafeModel: CafeTypes.Cafe,
		BaseModel: CafeTypes.CafeBase,
		Cashiers: { [string]: any }, -- NEW
	}
)
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
				CashierData = props.Cashiers[customer.targetCounterUuid], -- Safely pass specific cashier!
			}
			children[customer.id] = e(Customer, customerProps)
		end
	end

	return e(React.Fragment, nil, children)
end

return Customers
