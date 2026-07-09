local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)

local e = React.createElement
local SmallText = function(props)
	local children = props.children or {}
	children.UITextSizeConstraint = e("UITextSizeConstraint", {
		MaxTextSize = props.TextSize or 18,
		MinTextSize = props.TextSize or 18,
	})
	return e("TextLabel", {
		AutomaticSize = props.AutomaticSize or Enum.AutomaticSize.XY,
		BackgroundTransparency = props.BackgroundTransparency or 1,
		BackgroundColor3 = props.BackgroundColor3,
		TextColor3 = Color3.new(1, 1, 1),
		TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Left,
		TextStrokeTransparency = props.TextStrokeTransparency or 0,
		TextTransparency = props.TextTransparency or 0,
		Text = props.Text,
		AnchorPoint = props.AnchorPoint,
		Position = props.Position,
		TextWrapped = props.TextWrapped,
		Size = props.Size,
		TextScaled = props.TextScaled,
		Font = props.Font or "FredokaOne",
		LayoutOrder = props.LayoutOrder,
		Rotation = props.Rotation,
		ZIndex = props.ZIndex,
		RichText = props.RichText,
		ref = props.OnMount,
		Active = props.Active,
		Visible = props.Visible,
	}, children)
end
return SmallText
