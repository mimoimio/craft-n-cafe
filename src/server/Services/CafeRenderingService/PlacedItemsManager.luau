-- ServerScriptService/Server/Services/CafeRenderingService/PlacedItemsManager.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local e = React.createElement
local useState = React.useState
local useEffect = React.useEffect

local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local CafeTypes = require(ReplicatedStorage.Shared.CafeTypes)
local PlacedItemNode = require(script.Parent.PlacedItemNode)

local function PlacedItemsManager(props: { PlayerId: string, BaseModel: CafeTypes.CafeBase, GridSize: number })
	local placedItems, setPlacedItems = useState({})

	useEffect(function()
		local unsub = GlobalState:subscribe(function(state)
			local plotState = state.Plot and state.Plot[props.PlayerId]
			return plotState and plotState.placedItems or {}
		end, function(newItems)
			setPlacedItems(newItems)
		end)

		local state = GlobalState:getState()
		local plotState = state.Plot and state.Plot[props.PlayerId]
		local newItems = plotState and plotState.placedItems or nil
		setPlacedItems(newItems)
		return function()
			unsub()
		end
	end, { props.PlayerId })

	local children = {}

	warn("placedItems", placedItems)
	for uuid, itemData in placedItems do
		children[uuid] = e(PlacedItemNode, {
			Uuid = uuid,
			ItemData = itemData,
			BaseModel = props.BaseModel,
			GridSize = props.GridSize,
			PlayerId = props.PlayerId,
		})
	end

	return e(React.Fragment, nil, children)
end

return PlacedItemsManager
