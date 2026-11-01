local React = require(game.ReplicatedStorage.Packages.React)
local e = React.createElement
local Primitives = game.ReplicatedStorage.Shared.ReactComponents.ui

local VStack = require(Primitives.VStack)
local SmallText = require(Primitives.SmallText)

local function BaseComponent(props)
	local backgroundMode = props.BackgroundMode or "Slice"
	local useTile = backgroundMode == "Tile"

	return e("Frame", {
		Size = props.Size or UDim2.fromScale(1, 1),
		AutomaticSize = props.AutomaticSize,
		BackgroundTransparency = props.BackgroundTransparency or 1,
		BackgroundColor3 = props.BackgroundColor3,
		LayoutOrder = props.LayoutOrder,
		AnchorPoint = props.AnchorPoint,
		Position = props.Position,
		ClipsDescendants = props.ClipsDescendants,
		ZIndex = props.ZIndex,
	}, {
		Background = props.BackgroundImage and e("ImageLabel", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Image = props.BackgroundImage,
			ImageColor3 = props.BackgroundImageColor3,
			ImageTransparency = props.BackgroundImageTransparency or 0,
			ScaleType = useTile and Enum.ScaleType.Tile or Enum.ScaleType.Slice,
			SliceCenter = useTile and nil or (props.SliceCenter or Rect.new(8, 8, 248, 248)),
			TileSize = useTile and (props.TileSize or UDim2.new(0, 200, 0, 200)) or nil,
			ZIndex = props.BackgroundZIndex or 1,
		}),
		Content = e(VStack, {
			Size = UDim2.fromScale(1, 1),
			AutomaticSize = props.ContentAutomaticSize,
			Spacing = props.Spacing or UDim.new(0, 8),
			Padding = props.Padding,
			BackgroundTransparency = 1,
			LayoutOrder = 2,
			ZIndex = props.ContentZIndex or 2,
		}, {
			Title = props.Title and e(SmallText, {
				Text = props.Title,
				TextSize = props.TitleSize or 18,
				LayoutOrder = 1,
			}) or nil,
			Content = props.children,
		}),
	})
end

return BaseComponent
