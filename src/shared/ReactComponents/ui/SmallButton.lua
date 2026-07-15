local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundController = require(game.ReplicatedStorage.Shared.Controllers.SoundController)
local React = require(ReplicatedStorage.Packages.React)
local e = React.createElement

local function SmallButton(props)
	local scale, setScale = React.useBinding(1)

	local buttonClass = props.ButtonClass
	if buttonClass == nil then
		buttonClass = props.Image and "ImageButton" or "TextButton"
	end

	local bgTransparency = props.BackgroundTransparency
	if bgTransparency == nil then
		bgTransparency = 0.3
	end

	local buttonProps = {
		ref = props.OnMount,
		[React.Change.AbsolutePosition] = props[React.Change.AbsolutePosition],
		[React.Change.AbsoluteSize] = props[React.Change.AbsoluteSize],
		LayoutOrder = props.LayoutOrder,
		Size = props.Size or UDim2.new(0, 48, 0, 48),
		Rotation = props.Rotation,
		Visible = props.Visible,
		Position = props.Position,
		AnchorPoint = props.AnchorPoint,
		BackgroundColor3 = props.BackgroundColor3,
		BackgroundTransparency = bgTransparency,
		BorderSizePixel = 0,
		AutomaticSize = props.AutomaticSize or Enum.AutomaticSize.XY,
		ZIndex = props.ZIndex or 11,
		AutoButtonColor = props.AutoButtonColor,
		[React.Event.Activated] = props[React.Event.Activated] and function(rbx)
			props[React.Event.Activated](rbx)
			SoundController.Sound("drop_001")
			-- SoundController.Sound("Click")
		end or nil,
		[React.Event.MouseEnter] = function()
			setScale(1.05)
			-- SoundController.Sound("Plink")
		end,
		[React.Event.MouseLeave] = function()
			setScale(1)
			-- SoundController.Sound("drop_001")
		end,
	}

	if buttonClass == "ImageButton" then
		buttonProps.Image = props.Image
		buttonProps.ImageRectOffset = props.ImageRectOffset
		buttonProps.ImageRectSize = props.ImageRectSize
		buttonProps.ImageTransparency = props.ImageTransparency or 0
		buttonProps.ImageColor3 = props.ImageColor3 or props.TextColor3
		buttonProps.ScaleType = props.ScaleType or Enum.ScaleType.Fit
	else
		buttonProps.Text = props.Text or ""
		buttonProps.RichText = props.RichText
		buttonProps.TextWrapped = (props.TextWrapped == nil or props.TextWrapped == true) and true or false
		buttonProps.TextSize = props.TextSize or 16
		buttonProps.TextStrokeTransparency = props.TextStrokeTransparency or 1
		buttonProps.Font = props.Font or Enum.Font.FredokaOne

		buttonProps.TextColor3 = props.TextColor3 or Color3.fromRGB(255, 255, 255)
		props.children = props.children or {}
		props.children.UIStoke = e("UIStroke", {
			Thickness = 1,
		})
	end

	local overlayColor = props.KeybindColor3 or props.TextColor3 or Color3.fromRGB(255, 255, 255)

	props.children = props.children or {}
	props.children.UICorner = e("UICorner", { CornerRadius = props.CornerRadius or UDim.new(0, 8) })
	props.children.UITextSizeConstraint = e("UITextSizeConstraint", {
		MaxTextSize = props.MaxTextSize or props.TextSize or 18,
		MinTextSize = props.MinTextSize or props.TextSize or 18,
	})
	props.children.UIScale = e("UIScale", {
		Scale = props.Scale,
	})
	props.children.Padding = e("UIPadding", {
		PaddingTop = props.Padding and (props.Padding.All or props.Padding.Top) or UDim.new(0, 4),
		PaddingBottom = props.Padding and (props.Padding.All or props.Padding.Bottom) or UDim.new(0, 4),
		PaddingLeft = props.Padding and (props.Padding.All or props.Padding.Left) or UDim.new(0, 4),
		PaddingRight = props.Padding and (props.Padding.All or props.Padding.Right) or UDim.new(0, 4),
	}) or nil
	props.children.TextOverlay = props.OverlayText
			and e("TextLabel", {
				TextYAlignment = Enum.TextYAlignment.Bottom,
				LayoutOrder = 1,
				Size = UDim2.new(1, 0, 1, 0),
				AutomaticSize = Enum.AutomaticSize.XY,
				AnchorPoint = Vector2.new(0, 0),
				Position = UDim2.new(0, 0, 0, 0),
				BackgroundTransparency = 1,
				TextXAlignment = Enum.TextXAlignment.Center,
				Text = props.OverlayText,
				TextSize = props.OverlayTextSize or 20,
				TextTransparency = props.OverlayTextTransparency or 0,
				TextStrokeTransparency = props.OverlayTextStrokeTransparency or 0,
				Font = props.KeybindFont or Enum.Font.FredokaOne,
				TextWrapped = props.OverlayTextWrapped,
				TextColor3 = overlayColor,
				BorderSizePixel = 0,
				Active = false,
			}, {
				UITextSizeConstraint = e("UITextSizeConstraint", {
					MaxTextSize = props.OverlayTextSize or 18,
					MinTextSize = props.OverlayTextSize or 18,
				}),
				UICorner = e("UICorner", { CornerRadius = UDim.new(0, 8) }),
			})
		or nil

	return e(buttonClass, buttonProps, props.children)
end

return SmallButton
