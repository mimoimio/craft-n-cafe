-- Shared/ReactComponents/CustomerManager.luau
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)

local CustomerNode = require(script.Parent.CustomerNode)
local e = React.createElement

local player = game.Players.LocalPlayer
local playerId = player and tostring(player.UserId) or ""

local function CustomerManager(props)
	local customersState, setCustomersState = React.useState({})
	local customerInstances, setCustomerInstances = React.useState({})

	-- 1. Subscribe strictly to the Customers state slice
	React.useEffect(function()
		local unsub = GlobalState:subscribe(function(state)
			return state.Customers[playerId]
		end, function(newCustomers)
			setCustomersState(newCustomers or {})
		end)

		local state = GlobalState:getState()
		if state.Customers and state.Customers[playerId] then
			setCustomersState(state.Customers[playerId])
		end

		return unsub
	end, { playerId })

	-- 2. Sync Table instances from CollectionService generically
	React.useEffect(function()
		local tag = "Customer" .. playerId

		local function syncInstances()
			local currentInstances = {}
			for _, inst in ipairs(CollectionService:GetTagged(tag)) do
				-- Discern specific table via its Name property (e.g. Table1, Table2)
				currentInstances[inst.Name] = inst
			end
			setCustomerInstances(currentInstances)
		end

		syncInstances()

		local connAdd = CollectionService:GetInstanceAddedSignal(tag):Connect(syncInstances)
		local connRem = CollectionService:GetInstanceRemovedSignal(tag):Connect(syncInstances)

		return function()
			connAdd:Disconnect()
			connRem:Disconnect()
		end
	end, { playerId })

	local children = {}

	for i, customerData in pairs(customersState) do
		-- warn(i, customerData)
		children[customerData.id] = e(CustomerNode, {
			CustomerUid = customerData.id,
			CustomerData = customerData,
			Instance = customerInstances[customerData.id],
		})
	end

	return e(React.Fragment, nil, children)
end

return CustomerManager
