local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundController = require(game.ReplicatedStorage.Shared.Controllers.SoundController)
local React = require(ReplicatedStorage.Packages.React)
local ReactFlow = require(ReplicatedStorage.Packages.ReactFlow)
local e = React.createElement
local useSpring = ReactFlow.useSpring
local useEffect = React.useEffect

local function SmallButton(props)
	local visible = props.Visible == true and true or props.Visible == false and false or true
	-- only not visible when expicitly stated so
	
	local scale, setScale = useSpring({
				start = 1,
				target = 1,
				damper = 0.8,
				speed = 10,
			})
	useEffect(function()
		if not visible then
			setScale({
				target = 0,
				damper = 0.8,
				speed = 10,
			})
			return
		end
		setScale({
			start = 0,
			target = 1,
			damper = 0.8,
			speed = 10,
		})
	end, {visible})

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
		Visible = visible,
		TextTruncate = props.TextTruncate,
		Position = props.Position,
		AnchorPoint = props.AnchorPoint,
		Active = props.Active,
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
			setScale({
				target = 1.05,
				speed = 10,
				damper = 0.8,
			})
			-- SoundController.Sound("Plink")
		end,
		[React.Event.MouseLeave] = function()
			setScale({
				target = 1,
				speed = 10,
				damper = 0.8,
			})
			-- SoundController.Sound("drop_001")
		end,
		[React.Event.MouseButton1Down] = props[React.Event.MouseButton1Down],
		[React.Event.MouseButton1Up] = props[React.Event.MouseButton1Up],
	}

	if buttonClass == "ImageButton" then
		buttonProps.Image = props.Image
		buttonProps.ImageRectOffset = props.ImageRectOffset
		buttonProps.ImageRectSize = props.ImageRectSize
		buttonProps.ImageTransparency = props.ImageTransparency or 0
		buttonProps.ImageColor3 = props.ImageColor3 or props.TextColor3
		buttonProps.ScaleType = props.ScaleType or Enum.ScaleType.Fit
		buttonProps.SliceCenter = props.SliceCenter
	else
		buttonProps.TextScaled = props.TextScaled
		buttonProps.Text = props.Text or ""
		buttonProps.RichText = props.RichText
		buttonProps.TextTransparency = props.TextTransparency
		buttonProps.TextStrokeTransparency = props.TextStrokeTransparency or 1
		buttonProps.TextWrapped = (props.TextWrapped == nil or props.TextWrapped == true) and true or false
		buttonProps.TextSize = props.TextSize or 16
		buttonProps.Font = props.Font or Enum.Font.FredokaOne

		buttonProps.TextColor3 = props.TextColor3 or Color3.fromRGB(255, 255, 255)
		props.children = props.children or {}
		props.children.UIStoke = e("UIStroke", {
			Thickness = props.TextThickness,
		})
	end

	local overlayColor = props.KeybindColor3 or props.TextColor3 or Color3.fromRGB(255, 255, 255)

	props.children = props.children or {}
	props.children.UICorner = props.Rounded ~= false
			and e("UICorner", { CornerRadius = props.CornerRadius or UDim.new(0, 8) })
		or nil
	props.children.SCALE = props.HoverScale == true and e("UIScale", {
		Scale = scale,
	})
	props.children.UITextSizeConstraint = not props.TextScaled
			and e("UITextSizeConstraint", {
				MaxTextSize = props.MaxTextSize or props.TextSize or 18,
				MinTextSize = props.MinTextSize or props.TextSize or 18,
			})
		or nil
	props.children.UIScale = props.Scale and e("UIScale", {
		Scale = props.Scale,
	}) or props.children.UIScale
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
