-- CafeRenderingService/Drinks.luau

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

export type DrinkEntity = Types.DrinkEntity
export type TableEntity = Types.TableEntity

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
	useEffect(function()
		local clone: CafeTypes.CustomerRig = workspace.Rig:Clone()
		clone:PivotTo(props.BaseModel.Entrance:GetPivot())
		clone.Parent = workspace
		setRig(clone)
		setPrompt(clone.TriggerPrompt)
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
	end, { props.Customer.id, props.BaseModel })

	useEffect(function()
		if not (prompt and rig) then
			return
		end
		if not props.numberInLine then
			prompt.Enabled = false
			return
		end
		if props.numberInLine == 1 then
			prompt.Enabled = true
		else
			prompt.Enabled = false
		end
		rig:PivotTo(props.BaseModel.Entrance:GetPivot() + Vector3.new(10, 0, 5 * props.numberInLine))
	end, { props.numberInLine, prompt, rig })

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
	local customers: { Types.CustomerEntity }, setCustomers = useState(nil :: { Types.CustomerEntity }?)

	useEffect(function()
		local currentPlayer = getPlayer(props.PlayerId)
		setPlayer(currentPlayer)

		if not currentPlayer then
			warn(`Drink renderer could not find player for id {props.PlayerId}`)
		end
		local selectValues = selectCustomersById(props.PlayerId)
		local unsub = GlobalState:subscribe(selectValues, function(newCustomers: { Types.CustomerEntity })
			setCustomers(newCustomers)
		end)

		local state = GlobalState:getState()
		setCustomers(state.Customers[props.PlayerId])

		return function()
			unsub()
		end
	end, { props.PlayerId })

	local children = {}
	if player and customers then
		local numberInLine = 1
		for _, customer in customers do
			-- warn(`customer ({customer.id}, {customer.customerId}, {customer.drinkIds})`, customers)
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
