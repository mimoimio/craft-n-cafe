local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local e = React.createElement
local function VStack(props)
	local children = props.children or {}
	local elements = {

		Layout = e("UIListLayout", {
			FillDirection = Enum.FillDirection.Vertical,
			HorizontalAlignment = props.HorizontalAlignment or Enum.HorizontalAlignment.Center,
			VerticalAlignment = props.VerticalAlignment or Enum.VerticalAlignment.Top,
			SortOrder = Enum.SortOrder.LayoutOrder,
			HorizontalFlex = props.HorizontalFlex or "Fill",
			VerticalFlex = props.VerticalFlex or "Fill",
			Padding = props.Spacing or UDim.new(0, 0),
			Wraps = props.Wraps,
		}),
		Padding = props.Padding and e("UIPadding", {
			PaddingTop = props.Padding.All or props.Padding.Top or UDim.new(0, 0),
			PaddingBottom = props.Padding.All or props.Padding.Bottom or UDim.new(0, 0),
			PaddingLeft = props.Padding.All or props.Padding.Left or UDim.new(0, 0),
			PaddingRight = props.Padding.All or props.Padding.Right or UDim.new(0, 0),
		}) or nil,
		FlexItem = props.FlexMode and e("UIFlexItem", { FlexMode = props.FlexMode }) or nil,
	}
	for k, v in pairs(children) do
		elements[k] = v
	end
	local isImageLabel = props.BackgroundImage

	return e(isImageLabel and "ImageLabel" or "Frame", {
		Size = props.Size or UDim2.fromScale(1, 1),
		Image = isImageLabel or nil,
		ImageColor3 = isImageLabel and props.BackgroundImageColor3 or nil,
		ImageTransparency = isImageLabel and props.BackgroundImageTransparency or nil,
		ScaleType = isImageLabel and props.ScaleType,
		TileSize = isImageLabel and props.TileSize,
		Rotation = props.Rotation,
		ClipsDescendants = props.ClipsDescendants,

		AutomaticSize = props.AutomaticSize or Enum.AutomaticSize.None,
		BackgroundTransparency = props.BackgroundTransparency or 1,
		BackgroundColor3 = props.BackgroundColor3,
		LayoutOrder = props.LayoutOrder,
		AnchorPoint = props.AnchorPoint,
		Position = props.Position,
		Active = props.Active,
		Visible = props.Visible,
	}, elements)
end

return VStack
