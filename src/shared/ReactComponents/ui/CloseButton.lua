local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)

local e = React.createElement

local function SmallButton(props)
	local buttonProps = {
		LayoutOrder = props.LayoutOrder,
		Size = props.Size or UDim2.new(0, 48, 0, 48),
		Position = props.Position,
		Visible = props.Visible,
		TextSize = props.TextSize or 18,
		TextColor3 = props.TextColor3 or Color3.new(1, 1, 1),
		Font = Enum.Font.FredokaOne,
		AnchorPoint = props.AnchorPoint,
		BorderSizePixel = 0,
		Text = "X",
		ZIndex = props.ZIndex,
		AutoButtonColor = props.AutoButtonColor,
		[React.Event.Activated] = props[React.Event.Activated],
		BackgroundTransparency = props.BackgroundTransparency or 0.3,
		BackgroundColor3 = props.BackgroundColor3 or Color3.fromRGB(255, 60, 55),
		AutomaticSize = Enum.AutomaticSize.XY,
	}

	return e("TextButton", buttonProps, {
		UICorner = e("UICorner", { CornerRadius = props.CornerRadius or UDim.new(1, 0) }),
		UITextSizeConstraint = e("UITextSizeConstraint", {
			MaxTextSize = 18,
			MinTextSize = 18,
		}),
	})
end

return SmallButton
