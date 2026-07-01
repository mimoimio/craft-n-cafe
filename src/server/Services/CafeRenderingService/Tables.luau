-- CafeRenderingService/Tables.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local e = React.createElement
local useState = React.useState
local useEffect = React.useEffect
local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local CafeTypes = require(script.Parent.CafeTypes)

-- 1. THE SLOT COMPONENT
local function SlotComponent(
	props: {
		PlayerId: string,
		SlotInstance: CafeTypes.Slot,
		DrinkId: string, -- Extracted directly from table state (e.g., "abc" or "none")
	}
)
	local drinkData, setDrinkData = useState(nil)

	-- Hydrate unique ID into actual drink data (e.g., finding out "abc" is a "latte")
	useEffect(function()
		print("Son😭😭😭")
		if not props.DrinkId or props.DrinkId == "none" then
			setDrinkData(nil)
			return
		end

		local unsub = GlobalState:subscribe(function(state: GlobalState.GlobalState)
			local drinks = state.Drinks[props.PlayerId]
			if drinks then
				for _, drink in drinks do
					if drink.id == props.DrinkId then
						return drink
					end
				end
			end
			return nil
		end, function(newDrinkData)
			setDrinkData(newDrinkData)
		end)

		-- Initial check
		local state = GlobalState:getState()
		local drinks = state.Drinks[props.PlayerId]
		if drinks then
			for _, drink in drinks do
				if drink.id == props.DrinkId then
					setDrinkData(drink)
					break
				end
			end
		end

		return unsub
	end, { props.PlayerId, props.DrinkId })

	-- Render physical drink
	useEffect(function()
		if not drinkData then
			return
		end

		local drinkTemplate = ReplicatedStorage.Shared.Models:FindFirstChild(drinkData.drinkId)
		if drinkTemplate then
			local clone = drinkTemplate:Clone()
			local placePart = props.SlotInstance:FindFirstChild("PlacePart")

			if placePart then
				clone:PivotTo(placePart.CFrame)
			end

			clone.Parent = props.SlotInstance

			return function()
				clone:Destroy()
			end
		end
	end, { drinkData, props.SlotInstance })

	return nil
end

-- 2. THE TABLE COMPONENT
local function TableComponent(
	props: {
		PlayerId: string,
		TableName: string,
		TableData: any, -- The specific table dictionary from state (TableId, Slots)
		TableAnchor: CafeTypes.Table, -- The anchor model inside CafeModel.Tables
	}
)
	local clonedTable, setClonedTable = useState(nil)

	-- Clone the dynamic table model (e.g., "woodentable")
	useEffect(function()
		local tableTemplate = ReplicatedStorage.Shared.Models:FindFirstChild(props.TableData.TableId)
		if tableTemplate then
			local clone = tableTemplate:Clone()
			local placePart = props.TableAnchor:FindFirstChild("PlacePart")

			if placePart then
				clone:PivotTo(placePart.CFrame)
			end

			clone.Name = "TableModel"
			clone.Parent = props.TableAnchor

			setClonedTable(clone)

			return function()
				clone:Destroy()
			end
		else
			warn("[Tables] Could not find table model:", props.TableData.TableId)
		end
	end, { props.TableData.TableId, props.TableAnchor })

	local children = {}

	-- Only render slots if the physical table exists
	if clonedTable then
		-- but use the cafe's rendered table base for slots.
		local slotsFolder = props.TableAnchor:FindFirstChild("Slots")
		if slotsFolder then
			for slotName, drinkId in props.TableData.Slots do
				local slotInstance = slotsFolder:FindFirstChild(slotName)
				if slotInstance then
					children[slotName] = e(SlotComponent, {
						PlayerId = props.PlayerId,
						SlotInstance = slotInstance,
						DrinkId = drinkId,
					})
				end
			end
		end
	end

	return e(React.Fragment, nil, children)
end

-- 3. THE TABLES MANAGER
local function Tables(props: {
	CafeModel: CafeTypes.Cafe,
	PlayerId: string,
	Stats: any,
})
	local tablesState, setTablesState = useState({})

	-- Subscribe strictly to this player's Tables slice
	useEffect(function()
		local unsub = GlobalState:subscribe(function(state: GlobalState.GlobalState)
			return state.Tables[props.PlayerId]
		end, function(newTablesState)
			setTablesState(newTablesState or {})
		end)

		-- Initial fetch
		local state = GlobalState:getState()
		if state.Tables[props.PlayerId] then
			setTablesState(state.Tables[props.PlayerId])
		end

		return unsub
	end, { props.PlayerId })

	local children = {}
	local tablesFolder = props.CafeModel:FindFirstChild("Tables")

	if tablesFolder then
		-- Loop through the state dictionary (Table1, Table2, etc.)
		for tableName, tableData in tablesState do
			-- Find the corresponding anchor in the 3D space
			local tableAnchor = tablesFolder:FindFirstChild(tableName)

			if tableAnchor then
				children[tableName] = e(TableComponent, {
					PlayerId = props.PlayerId,
					TableName = tableName,
					TableData = tableData,
					TableAnchor = tableAnchor,
				})
			end
		end
	end

	return e(React.Fragment, nil, children)
end

return Tables
