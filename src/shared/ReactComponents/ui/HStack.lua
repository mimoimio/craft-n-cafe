local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local e = React.createElement
local function HStack(props)
	local children = props.children or {}
	local elements = {
		Layout = e("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = props.HorizontalAlignment or Enum.HorizontalAlignment.Left,
			VerticalAlignment = props.VerticalAlignment or Enum.VerticalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = props.Spacing or UDim.new(0, 0),
			HorizontalFlex = props.HorizontalFlex, -- Crucial for tabs!
		}),
		Padding = props.Padding and e("UIPadding", {
			PaddingTop = props.Padding.All or props.Padding.Top or UDim.new(0, 0),
			PaddingBottom = props.Padding.All or props.Padding.Bottom or UDim.new(0, 0),
			PaddingLeft = props.Padding.All or props.Padding.Left or UDim.new(0, 0),
			PaddingRight = props.Padding.All or props.Padding.Right or UDim.new(0, 0),
		}) or nil,
	}
	for k, v in pairs(children) do
		elements[k] = v
	end
	local isImageLabel = props.BackgroundImage

	return e("ImageLabel", {
		Image = isImageLabel or nil,
		ImageColor3 = isImageLabel and props.BackgroundImageColor3 or nil,
		ImageTransparency = isImageLabel and props.BackgroundImageTransparency or nil,
		ScaleType = isImageLabel and props.ScaleType or Enum.ScaleType.Tile,
		TileSize = isImageLabel and props.TileSize or UDim2.new(0, 200, 0, 200),
		Rotation = props.Rotation,

		Size = props.Size or UDim2.fromScale(1, 1),
		AutomaticSize = props.AutomaticSize or Enum.AutomaticSize.None,
		BackgroundTransparency = props.BackgroundTransparency or 1,
		AnchorPoint = props.AnchorPoint,
		Position = props.Position,
		BackgroundColor3 = props.BackgroundColor3,
		LayoutOrder = props.LayoutOrder,
		ZIndex = props.ZIndex,
	}, elements)
end

return HStack
