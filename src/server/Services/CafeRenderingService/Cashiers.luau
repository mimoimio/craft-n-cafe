-- CafeRenderingService/Cashiers.luau -- cashiers

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
local CustomersService = require(ServerScriptService.Server.Services.CustomersService)
local VariationsConfig = require(ReplicatedStorage.Shared.Configs.VariationsConfig)
local DrinkModelUtil = require(ReplicatedStorage.Shared.Utils.DrinkModelUtil)

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

local original = workspace.Skeleton:Clone()

local function Cashier(props: {
	PlayerId: string,
	CafeModel: CafeTypes.Cafe,
	Cashier: Types.CashierEntity,
	BaseModel: CafeTypes.CafeBase,
	numberInLine: number?,
	i: number,
})
	local rig: Model, setRig = useState(nil)

	useEffect(function()
		local clone = original:Clone() :: Model
		local unsub = observeRigClone(clone)
		local tag = "Cashier" .. props.PlayerId
		local rootPart = clone:FindFirstChild("HumanoidRootPart")

		clone:AddTag(tag)
		clone.Name = props.Cashier.id
		clone.Parent = workspace
		if rootPart and rootPart:CanSetNetworkOwnership() then
			rootPart:SetNetworkOwner(nil)
		end

		setRig(clone)
		local cashierCF = props.CafeModel.Cashier:GetPivot():ToWorldSpace(CFrame.new(4 * props.i, 0, 4))

		local targetCF = cashierCF

		clone:PivotTo(targetCF)

		return function()
			if clone and clone.Parent then
				clone:Destroy()
			end
			if unsub then
				unsub()
			end
			setRig(nil)
		end
	end, { props.Cashier.id, props.BaseModel, props.CafeModel })

	return e(React.Fragment)
end

local selectCashiers = function(state)
	return state.Cashiers
end
local selectCashiersById = function(playerId: string)
	return Reflex.createSelector({ selectCashiers }, function(cashiers)
		return cashiers[playerId]
	end)
end

local function Cashiers(props: {
	PlayerId: string,
	CafeModel: CafeTypes.Cafe,
	BaseModel: CafeTypes.CafeBase,
})
	local player, setPlayer = useState(nil :: Player?)
	local cashiers, setCashiers = useState(nil :: { Types.CustomerEntity }?)

	useEffect(function()
		local currentPlayer = getPlayer(props.PlayerId)
		setPlayer(currentPlayer)

		local selectValues = selectCashiersById(props.PlayerId)
		local unsub = GlobalState:subscribe(selectValues, function(newCustomers)
			setCashiers(newCustomers)
		end)

		local state = GlobalState:getState()
		if state.Cashiers then
			setCashiers(state.Cashiers[props.PlayerId])
		end

		return function()
			unsub()
		end
	end, { props.PlayerId })

	local children = {}
	if player and cashiers then
		local numberInLine = 1
		for _, cashier in cashiers do
			local customerProps = {
				PlayerId = props.PlayerId,
				Cashier = cashier,
				CafeModel = props.CafeModel,
				BaseModel = props.BaseModel,
				i = _,
			}

			children[cashier.id] = e(Cashier, customerProps)
		end
	end

	return e(React.Fragment, nil, children)
end

return Cashiers
