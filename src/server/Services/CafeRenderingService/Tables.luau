-- Server/Services/CafeRenderingService/Tables.luau

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local React = require(ReplicatedStorage.Packages.React)
local e = React.createElement
local useState = React.useState
local useEffect = React.useEffect
local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local CafeTypes = require(game.ReplicatedStorage.Shared.CafeTypes) -- = require(script.Parent.CafeTypes)
local VariationsConfig = require(ReplicatedStorage.Shared.Configs.VariationsConfig)

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

			for i, desc: Part in clone:GetDescendants() do
				if not desc:IsA("BasePart") then
					continue
				end
				desc.CollisionGroup = "Walls"
				desc.Anchored = true
			end
			if placePart then
				clone:PivotTo(placePart.CFrame)
			end
			local modelBasePart = clone:FindFirstChildWhichIsA("BasePart", true)

			-- no need to unanchor on table
			for _, descendant in clone:GetDescendants() do
				if descendant:IsA("BasePart") then
					descendant.CanCollide = false
				end
			end

			if drinkData.variationId then
				local variation = VariationsConfig[drinkData.variationId]
				if variation then
					for _, descendant: BasePart in clone:GetDescendants() do
						if descendant:IsA("BasePart") and variation.ColorPrimary then
							descendant.Color = variation.ColorPrimary
						end
						if descendant:IsA("UnionOperation") then
							descendant.UsePartColor = true
						end
					end
				end
				local part = ReplicatedStorage.Shared.Particles:FindFirstChild(drinkData.variationId)
				if part then
					part = part:Clone()
					part.Transparency = 1
					part.CanCollide = false
					part.Massless = true
					part:PivotTo(clone:GetPivot() + Vector3.new(0, 1, 0))
					part.Parent = modelBasePart
					local weld = Instance.new("WeldConstraint")
					weld.Part0 = part
					weld.Part1 = modelBasePart
					weld.Parent = part
				end
			end
			local tag = props.PlayerId and props.PlayerId .. "DrinkModel" or ""
			clone:SetAttribute("uid", props.DrinkId)
			local basePartDescendants = 0
			for i, desc in clone:GetDescendants() do
				if not desc:IsA("BasePart") then
					continue
				end
				basePartDescendants += 1
			end
			clone:SetAttribute("BasePartDescendants", basePartDescendants)
			clone:AddTag(tag)

			-- clone.Parent = props.SlotInstance
			clone.Parent = workspace
			return function()
				clone:Destroy()
			end
		end
	end, {
		drinkData and drinkData.drinkId --[[rerender only when drinkId change and variationId]],
		drinkData and drinkData.variationId,
		props.SlotInstance,
	})
	useEffect(function()
		if not (props.SlotInstance and props.SlotInstance.Parent) then
			return
		end

		props.SlotInstance.PlacePart.Transparency = 1
		props.SlotInstance.PlacePart.TriggerPrompt.RequiresLineOfSight = false
		props.SlotInstance.PlacePart.TriggerPrompt.Enabled = true
		local conn = props.SlotInstance.PlacePart.TriggerPrompt.Triggered:Connect(function(player: Player)
			local TablesService = require(ServerScriptService.Server.Services.TablesService)
			local tool = player.Character:FindFirstChildWhichIsA("Tool")
			local drinkUid
			if tool then
				drinkUid = tool.Name
			end

			TablesService.PlaceDrink(
				player,
				drinkUid,
				props.SlotInstance.Parent.Parent.Name, -- the tableUid
				props.SlotInstance.Name -- the slot
			)
		end)
		return function()
			conn:Disconnect()
			if not (props.SlotInstance and props.SlotInstance.Parent) then
				print("destroyed already")
				return
			end
			props.SlotInstance.PlacePart.TriggerPrompt.Enabled = false
		end
	end, { props.SlotInstance })

	return e(React.Fragment)
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
			for i, desc: Part in clone:GetDescendants() do
				if not desc:IsA("BasePart") then
					continue
				end
				desc.CollisionGroup = "Walls"
			end

			if placePart then
				placePart.Transparency = 1
				clone:PivotTo(placePart.CFrame)
			end

			clone.Name = props.TableName
			clone.Parent = props.TableAnchor

			local tag = "Table" .. props.PlayerId
			props.TableAnchor:AddTag(tag) -- set tag to anchor insteadm cus anchor got Slots:: Model

			setClonedTable(clone)

			return function()
				if props.TableAnchor then
					props.TableAnchor:AddTag(tag)
				end
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
						key = slotName,
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
