local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local e = React.createElement

local function Grid(props)
	local children = props.children or {}
	local elements = {
		Layout = e("UIGridLayout", {
			CellSize = props.CellSize, -- somehow putting CellSize makes the UIGridLayout + AutomaticSize consistent. So it's mandatory
			-- CellSize = props.CellSize or UDim2.new(0, 100, 0, 100),
			CellPadding = props.CellPadding or UDim2.new(0, 6, 0, 6),
			FillDirection = props.FillDirection or Enum.FillDirection.Horizontal,
			FillDirectionMaxCells = props.FillDirectionMaxCells or 0,
			HorizontalAlignment = props.HorizontalAlignment or Enum.HorizontalAlignment.Center,
			VerticalAlignment = props.VerticalAlignment or Enum.VerticalAlignment.Top,
			SortOrder = props.SortOrder or Enum.SortOrder.LayoutOrder,
			StartCorner = props.StartCorner or Enum.StartCorner.TopLeft,
		}, {
			_UISizeConstraint = e("UISizeConstraint", {
				MinSize = props.MinSize or Vector2.new(30, 30),
				-- MaxSize = Vector2.new(100, 100),
			}),
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

	return e("Frame", {
		Size = props.Size or UDim2.fromScale(1, 1),
		AutomaticSize = props.AutomaticSize or Enum.AutomaticSize.None,
		BackgroundTransparency = props.BackgroundTransparency or 1,
		Active = false,
		[React.Change.AbsolutePosition] = props[React.Change.AbsolutePosition],
		[React.Change.AbsoluteSize] = props[React.Change.AbsoluteSize],
		BackgroundColor3 = props.BackgroundColor3,
		LayoutOrder = props.LayoutOrder,
	}, elements)
end

return Grid
