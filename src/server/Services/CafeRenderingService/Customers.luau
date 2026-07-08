-- CafeRenderingService/Customers.luau

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local React = require(ReplicatedStorage.Packages.React)
local Reflex = require(ReplicatedStorage.Packages.Reflex)
local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local Types = require(ReplicatedStorage.Shared.Types)
local CafeTypes = require(ReplicatedStorage.Shared.CafeTypes)
local CustomersService = require(ServerScriptService.Server.Services.CustomersService)

local e = React.createElement
local useEffect = React.useEffect
local useState = React.useState

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
		local clone = workspace.Rig:Clone() :: CafeTypes.CustomerRig
		local tag = "Customer" .. props.PlayerId -- player dont change so ok no dependency for this useEffect right
		clone.Parent = workspace
		clone:AddTag(tag)

		setRig(clone)
		setPrompt(clone.TriggerPrompt)

		local entranceCF = props.BaseModel.Entrance:GetPivot()
		local cashierCF = props.CafeModel.Cashier.Part:GetPivot()
		local action = props.Customer.customerAction

		-- Default start is the entrance
		local targetCF = entranceCF

		-- If a chunk loads while they are already mid-action, spawn them in their current domain
		if action == "queuing" then
			-- Queue spans outward from the front of the cashier (using LookVector)
			-- Assuming Cashier.Part's Front faces the line
			local lineOffset = cashierCF.LookVector * (4 * (props.numberInLine or 1))
			targetCF = cashierCF + lineOffset
			-- Make them face the cashier
			targetCF = CFrame.lookAt(targetCF.Position, cashierCF.Position)
		elseif action == "paid" then
			-- Start them right at the cashier so they can begin their walk out
			targetCF = cashierCF + (cashierCF.LookVector * 4)
		end

		clone:PivotTo(targetCF)

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

	-- 2. State Transition Effect: Handle walking targets based on CFrame vectors
	useEffect(function()
		if not (rig and prompt) then
			return
		end

		local humanoid = rig:FindFirstChildOfClass("Humanoid")
		local action = props.Customer.customerAction

		local tables = props.BaseModel.Cafe.Tables:GetChildren()
		local random = Random.new():NextInteger(1, #tables)

		local tableCF = tables[random]:GetPivot()
		local entranceCF = props.BaseModel.Entrance:GetPivot()
		local cashierCF = props.CafeModel.Cashier.Part:GetPivot()

		if action == "entering" then
			prompt.Enabled = false
			if humanoid then
				-- Walk towards a waiting area (e.g., to the side of the cashier)
				-- Uses RightVector to fan them out so they don't clump perfectly on one spot
				local randomOffset = (math.random() - 0.5) * 10
				local targetPos = tableCF.Position + (tableCF.RightVector * randomOffset) + (tableCF.LookVector * 15)
				humanoid:MoveTo(targetPos)
			end
		elseif action == "queuing" then
			prompt.Enabled = (props.numberInLine == 1)
			if humanoid then
				-- Walk smoothly into their exact slot in the cashier line
				local lineOffset = cashierCF.LookVector * (4 * (props.numberInLine or 1))
				local targetPos = cashierCF.Position + lineOffset
				humanoid:MoveTo(targetPos)
			end
		elseif action == "paid" then
			prompt.Enabled = false
			if humanoid then
				-- Walk out of the cafe entirely (using the Entrance's LookVector to go outside)
				local exitPos = entranceCF.Position + (entranceCF.LookVector * 25)
				humanoid:MoveTo(exitPos)
			end
		end
	end, { rig, prompt, props.Customer.customerAction, props.numberInLine, props.BaseModel, props.CafeModel })

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

			if customer.drinkIds then
				customerProps.numberInLine = numberInLine
				numberInLine += 1
			end

			children[customer.id] = e(Customer, customerProps)
		end
	end

	return e(React.Fragment, nil, children)
end

return Customers
