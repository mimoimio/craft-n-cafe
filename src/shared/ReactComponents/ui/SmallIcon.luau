local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)

local e = React.createElement
local SmallIcon = function(props)
	local children = props.children or {}
	return e("ImageLabel", {
		AutomaticSize = props.AutomaticSize or Enum.AutomaticSize.XY,
		BackgroundTransparency = 1,
		Image = props.Image,
		-- Size = ,
		-- TextColor3 = Color3.new(1, 1, 1),
		-- TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Left,
		-- TextStrokeTransparency = 0,
		-- Text = props.Text,
		Size = props.Size or UDim2.new(0, 32, 0, 32),
		-- ScaleType = props.ScaleType or Enum.ScaleType.Stretch,
		-- TextScaled = props.TextScaled,
		-- Font = "FredokaOne",
		AnchorPoint = props.AnchorPoint or Vector2.new(0.5, 0.5),
		Position = props.Position or UDim2.new(0.5, 0, 0.5, 0),

		LayoutOrder = props.LayoutOrder,
	}, children)
end
return SmallIcon
