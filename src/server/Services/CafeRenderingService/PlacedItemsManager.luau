-- ServerScriptService/Server/Services/CafeRenderingService/PlacedItemsManager.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local Reflex = require(ReplicatedStorage.Packages.Reflex)
local e = React.createElement
local useState = React.useState
local useEffect = React.useEffect
local createSelector = Reflex.createSelector

local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local CafeTypes = require(ReplicatedStorage.Shared.CafeTypes)
local PlacedItemNode = require(script.Parent.PlacedItemNode)
local SpatialItemNode = require(script.Parent.SpatialItemNode) -- NEW: Require the Spatial node!

local function PlacedItemsManager(props: { PlayerId: string, BaseModel: CafeTypes.CafeBase, GridSize: number })
	local placedItems, setPlacedItems = useState({})
	local spatialItems, setSpatialItems = useState({}) -- NEW: Track spatial items in state

	useEffect(function()
		-- We map both dictionaries out of the state
		local unsub = GlobalState:subscribe(function(state)
			return state.Plot and state.Plot[props.PlayerId] and state.Plot[props.PlayerId] or nil
		end, function(plotState)
			setPlacedItems(plotState.placedItems)
			setSpatialItems(plotState.spatialItems)
		end)

		local state = GlobalState:getState()
		local plotState = state.Plot and state.Plot[props.PlayerId]

		setPlacedItems(plotState and plotState.placedItems or {})
		setSpatialItems(plotState and plotState.spatialItems or {})

		return function()
			unsub()
		end
	end, { props.PlayerId })

	local children = {}

	-- Render Structural Half-Grid Items
	for uuid, itemData in pairs(placedItems or {}) do
		children[uuid] = e(PlacedItemNode, {
			Uuid = uuid,
			ItemData = itemData,
			BaseModel = props.BaseModel,
			GridSize = props.GridSize,
			PlayerId = props.PlayerId,
		})
	end

	-- Render Spatial / Free Items
	for uuid, spatialData in pairs(spatialItems or {}) do
		children[uuid] = e(SpatialItemNode, {
			Uuid = uuid,
			ItemData = spatialData,
			BaseModel = props.BaseModel,
			PlayerId = props.PlayerId,
		})
	end

	return e(React.Fragment, nil, children)
end

return PlacedItemsManager
