local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local ReactFlow = require(ReplicatedStorage.Packages.ReactFlow)
local e = React.createElement

local HStack = require(script.Parent.HStack)
local SmallButton = require(script.Parent.SmallButton)
local SmallText = require(script.Parent.SmallText)
local VStack = require(script.Parent.VStack)

local useSpring = ReactFlow.useSpring

local function Panel(props)
	local isOpen = props.Open
	if isOpen == nil then
		isOpen = true
	end

	local backgroundMode = props.BackgroundMode or "Slice"
	local useTile = backgroundMode == "Tile"

	local openPos = props.OpenPosition or UDim2.fromScale(0.5, 0.5)
	local hiddenPos = props.HiddenPosition or UDim2.fromScale(0.5, 1.2)
	local springSpeed = props.SpringSpeed or 18
	local springDamper = props.SpringDamper or 0.85

	local panelPosition, setPanelPosition = useSpring({
		start = isOpen and openPos or hiddenPos,
		target = isOpen and openPos or hiddenPos,
		speed = springSpeed,
		damper = springDamper,
	})

	React.useEffect(function()
		setPanelPosition({
			target = isOpen and openPos or hiddenPos,
			speed = springSpeed,
			damper = springDamper,
		})
	end, { isOpen, openPos, hiddenPos, springSpeed, springDamper })

	return e("Frame", {
		Size = props.Size or UDim2.fromScale(0.45, 0.6),
		AutomaticSize = props.AutomaticSize,
		AnchorPoint = props.AnchorPoint or Vector2.new(0.5, 0.5),
		Position = panelPosition,
		BackgroundTransparency = 1,
		BackgroundColor3 = props.BackgroundColor3,
		LayoutOrder = props.LayoutOrder,
		ClipsDescendants = props.ClipsDescendants,
		ZIndex = props.ZIndex,
		Visible = true,
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
			Padding = props.Padding or {
				Top = UDim.new(0, 10),
				Bottom = UDim.new(0, 10),
				Left = UDim.new(0, 12),
				Right = UDim.new(0, 12),
			},
			BackgroundTransparency = 1,
			LayoutOrder = 2,
			ZIndex = props.ContentZIndex or 2,
			VerticalFlex = Enum.UIFlexAlignment.Fill,
		}, {
			Header = e(HStack, {
				AutomaticSize = Enum.AutomaticSize.Y,
				Size = UDim2.fromScale(1, 0),
				HorizontalAlignment = Enum.HorizontalAlignment.Left,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				HorizontalFlex = Enum.UIFlexAlignment.Fill,
				Spacing = UDim.new(0, 8),
				BackgroundTransparency = 1,
				LayoutOrder = 1,
			}, {
				Title = e(SmallText, {
					Text = props.Title or "",
					TextSize = props.TitleSize or 18,
					LayoutOrder = 1,
				}),
				Spacer = e("Frame", {
					LayoutOrder = 2,
					Size = UDim2.fromScale(1, 0),
					BackgroundTransparency = 1,
				}),
				CloseButton = props.OnClose and e(SmallButton, {
					LayoutOrder = 3,
					Text = "X",
					BackgroundTransparency = props.CloseButtonBackgroundTransparency,
					BackgroundColor3 = props.CloseButtonBackgroundColor3,
					TextColor3 = props.CloseButtonTextColor3,
					[React.Event.Activated] = props.OnClose,
				}) or nil,
			}),
			Body = e(VStack, {
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				VerticalAlignment = props.VerticalAlignment,
				HorizontalAlignment = props.HorizontalAlignment,
				HorizontalFlex = Enum.UIFlexAlignment.Fill,
				VerticalFlex = Enum.UIFlexAlignment.Fill,
				LayoutOrder = 2,
			}, props.children),
		}),
	})
end

return Panel