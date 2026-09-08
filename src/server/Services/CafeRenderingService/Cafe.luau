-- ServerScriptService/Server/Services/CafeRenderingService/Cafe.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local e = React.createElement
local CafeTypes = require(ReplicatedStorage.Shared.CafeTypes)

local PlacedItemsManager = require(script.Parent.PlacedItemsManager)
local Customers = require(script.Parent.Customers)

local function Cafe(props: { BaseModel: CafeTypes.CafeBase, PlayerId: string })
	local children = {}

	-- The PlacedItemsManager now builds the entire physical cafe
	children.PlacedItems = e(PlacedItemsManager, {
		PlayerId = props.PlayerId,
		BaseModel = props.BaseModel,
		GridSize = 4,
	})

	-- Customers will eventually need to read the PlotState to know where tables/queues are
	children.Customers = e(Customers, {
		PlayerId = props.PlayerId,
		BaseModel = props.BaseModel,
	})

	return e(React.Fragment, nil, children)
end

return Cafe
