-- Shared/ReactComponents/TableManager.luau
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)

local TableNode = require(script.Parent.TableNode)
local e = React.createElement

local player = game.Players.LocalPlayer
local playerId = player and tostring(player.UserId) or ""

local function TableManager(props)
	local tablesState, setTablesState = React.useState({})
	local drinks, setDrinks = React.useState({})
	local tableInstances, setTableInstances = React.useState({})

	-- 1. Subscribe strictly to the Tables state slice
	React.useEffect(function()
		local unsub = GlobalState:subscribe(function(state)
			return state.Tables[playerId]
		end, function(newTables)
			setTablesState(newTables or {})
		end)
		local unsub2 = GlobalState:subscribe(function(state)
			return state.Drinks[playerId]
		end, function(newDrinks)
			setDrinks(newDrinks or {})
		end)

		local state = GlobalState:getState()
		if state.Tables and state.Tables[playerId] then
			setTablesState(state.Tables[playerId])
		end
		if state.Drinks and state.Drinks[playerId] then
			setDrinks(state.Drinks[playerId])
		end

		return function()
			unsub()
			unsub2()
		end
	end, { playerId })

	-- 2. Sync Table instances from CollectionService generically
	React.useEffect(function()
		local tag = "Table" .. playerId

		local function syncInstances()
			local currentInstances = {}
			for _, inst in ipairs(CollectionService:GetTagged(tag)) do
				-- Discern specific table via its Name property (e.g. Table1, Table2)
				currentInstances[inst.Name] = inst
			end
			setTableInstances(currentInstances)
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

	for tableId, tableData in pairs(tablesState) do
		children[tableId] = e(TableNode, {
			TableId = tableId,
			TableData = tableData,
			Instance = tableInstances[tableId],
			Drinks = drinks,
		})
	end

	return e(React.Fragment, nil, children)
end

return TableManager
