-- CashierManager.luau -- client
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local useEffect = React.useEffect
local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local Types = require(ReplicatedStorage.Shared.Types)

local CashierNode = require(script.Parent.CashierNode)
local e = React.createElement

local player = Players.LocalPlayer
local playerId = player and tostring(player.UserId) or ""

local function CashierManager(props)
	local cashiersState: { Types.CashierEntity }, setCashiersState = React.useState(nil)
	local cashierInstances, setCashierInstances = React.useState(nil)

	-- 1. Subscribe strictly to the Cashiers state slice
	useEffect(function()
		local unsub = GlobalState:subscribe(function(state)
			return state.Cashiers and state.Cashiers[playerId]
		end, function(newCashiers)
			setCashiersState(newCashiers or nil)
		end)

		local state = GlobalState:getState()
		if state.Cashiers and state.Cashiers[playerId] then
			setCashiersState(state.Cashiers[playerId] or nil)
		end

		return unsub
	end, { playerId })

	-- 2. Sync Table instances from CollectionService generically
	useEffect(function()
		local tag = "Cashier" .. playerId

		local function syncInstances()
			local currentInstances = {}
			for _, inst in ipairs(CollectionService:GetTagged(tag)) do
				currentInstances[inst.Name] = inst
			end
			setCashierInstances(currentInstances)
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

	if cashiersState and cashierInstances then
		for _, cashierData in pairs(cashiersState) do
			local cashierId = cashierData.id
			if not cashierInstances[cashierId] then continue end
			local instance = cashierInstances[cashierId]
			-- local instance = cashierInstances[cashierId] and cashierInstances[cashierId]:FindFirstChildWhichIsA("BasePart")
			children[cashierId] = e(CashierNode, {
				CashierUid = cashierId,
				CashierData = cashierData,
				Instance = instance,
			})
		end
	end

	return e(React.Fragment, nil, children)
end

return CashierManager