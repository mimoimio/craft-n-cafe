local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local useEffect = React.useEffect
local useRef = React.useRef
local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local UIState = require(ReplicatedStorage.Shared.producers.UIState)
local SoundController = require(ReplicatedStorage.Shared.Controllers.SoundController) -- Added SoundController

local CustomerNode = require(script.Parent.CustomerNode)
local e = React.createElement

local player = game:GetService("Players").LocalPlayer
local playerId = player and tostring(player.UserId) or ""

local function CustomerManager(props)
	local customersState, setCustomersState = React.useState(nil)
	local customerInstances, setCustomerInstances = React.useState(nil)

	-- 1. Subscribe strictly to the Customers state slice
	useEffect(function()
		local unsub = GlobalState:subscribe(function(state)
			return state.Customers[playerId]
		end, function(newCustomers)
			setCustomersState(newCustomers or nil)
		end)

		local state = GlobalState:getState()
		if state.Customers and state.Customers[playerId] then
			setCustomersState(state.Customers[playerId] or nil)
		end

		return unsub
	end, { playerId })

	-- 2. Sync Table instances from CollectionService generically
	useEffect(function()
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

	-- 3. Check for new customers and play sound
	local prevCustomersRef = useRef(nil)
	useEffect(function()
		if customersState then
			-- If this isn't the very first load, check if any customer is completely new
			if prevCustomersRef.current ~= nil then
				local newCustomerFound = false

				for _, currentData in pairs(customersState) do
					local existedPreviously = false
					for _, prevData in pairs(prevCustomersRef.current) do
						if prevData.id == currentData.id then
							existedPreviously = true
							break
						end
					end

					if not existedPreviously then
						newCustomerFound = true
						break
					end
				end

				if newCustomerFound then
					SoundController.Sound("phaserUp6")
				end
			end
		end

		-- Update the ref for the next render
		prevCustomersRef.current = customersState
	end, { customersState })

	local children = {}

	if customersState and customerInstances then
		for i, customerData in pairs(customersState) do
			if i == 1 then
				UIState.setFirstCustomer(customerInstances[customerData.id])
			end
			children[customerData.id] = e(CustomerNode, {
				CustomerUid = customerData.id,
				CustomerData = customerData,
				Instance = customerInstances[customerData.id],
				numberInLine = i,
			})
		end
	end

	return e(React.Fragment, nil, children)
end

return CustomerManager
