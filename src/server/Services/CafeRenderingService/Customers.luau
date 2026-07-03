-- CafeRenderingService/Drinks.luau

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)
local Reflex = require(ReplicatedStorage.Packages.Reflex)
local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local Types = require(ReplicatedStorage.Shared.Types)
local CafeTypes = require(ReplicatedStorage.Shared.CafeTypes)

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

local function buildDrinkTool(player: Player, drink: DrinkEntity): Tool?
	local drinkModel = ReplicatedStorage.Shared.Models:FindFirstChild(drink.drinkId)
	if not drinkModel then
		warn(`Drink tool render failed: model {drink.id} not found for {player.Name}`)
		return nil
	end

	local tool = Instance.new("Tool")
	tool.Name = drink.id
	tool.RequiresHandle = true
	tool.CanBeDropped = false
	local ingredientPackageLink = drinkModel:FindFirstChildWhichIsA("PackageLink", true)
	if ingredientPackageLink then
		local numericId = string.match(tostring(ingredientPackageLink.PackageId), "%d+")
		tool.TextureId = string.format("rbxthumb://type=Asset&id=%s&w=150&h=150", numericId)
	end

	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Anchored = false
	handle.CanCollide = false
	handle.Massless = true
	handle.Parent = tool
	handle.Transparency = 1

	local clonedModel = drinkModel:Clone()
	clonedModel.Parent = tool

	local modelBasePart = clonedModel:FindFirstChildWhichIsA("BasePart", true)
	if not modelBasePart then
		warn(`Drink tool render failed: {drink.id} has no BasePart to weld`)
		tool:Destroy()
		return nil
	end

	for _, descendant in clonedModel:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Anchored = false
		end
	end

	modelBasePart.Anchored = false
	handle.CFrame = modelBasePart.CFrame

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = handle
	weld.Part1 = modelBasePart
	weld.Parent = handle

	return tool
end

local function Customer(props: {
	PlayerId: string,
	CafeModel: CafeTypes.Cafe,
	Customer: Types.CustomerEntity,
	BaseModel: CafeTypes.CafeBase,
})
	local rig, setRig = useState(nil)
	useEffect(function()
		local clone = workspace.Rig:Clone()
		clone:PivotTo(props.BaseModel.Entrance:GetPivot())
		clone.Parent = workspace
		setRig(clone)

		return function()
			if clone and clone.Parent then
				clone:Destroy()
			end
			setRig(nil)
		end
	end, { props.Customer.id, props.BaseModel })

	-- useEffect(function()
	-- end, { props.CafeModel })

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
		for _, customer in customers do
			-- warn(`customer ({customer.id}, {customer.customerId}, {customer.drinkIds})`, customers)
			children[customer.id] = e(Customer, {
				PlayerId = props.PlayerId,
				Customer = customer,
				CafeModel = props.CafeModel,
				BaseModel = props.BaseModel,
			})
		end
	end

	return e(React.Fragment, nil, children)
end

return Customers
