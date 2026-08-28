local React = require(game.ReplicatedStorage.Packages.React)
local ReactFlow = require(game.ReplicatedStorage.Packages.ReactFlow)
local e = React.createElement
local ReactRoblox = require(game.ReplicatedStorage.Packages.ReactRoblox)
local Grid = require(game.ReplicatedStorage.Shared.ReactComponents.ui.Grid)
local SmallText = require(game.ReplicatedStorage.Shared.ReactComponents.ui.SmallText)
local SmallButton = require(game.ReplicatedStorage.Shared.ReactComponents.ui.SmallButton)
local VStack = require(game.ReplicatedStorage.Shared.ReactComponents.ui.VStack)
local HStack = require(game.ReplicatedStorage.Shared.ReactComponents.ui.HStack)
local SoundController = require(game.ReplicatedStorage.Shared.Controllers.SoundController)
local PRIMARY_FOREGROUND = Color3.new(0.796078, 0.6, 0.2)
-- local PRIMARY_FOREGROUND = Color3.new(0.435294, 0, 1)
local function CloseButton(props: {
	Text: string?,
	Image: string?,
	Size: UDim2?,
})
	local color, setColor = ReactFlow.useSpring({
		start = 0,
		target = 0,
		damper = 1,
		speed = 40,
	})

	local pos, setPos = ReactFlow.useSpring({
		start = 1,
		target = 1,
		damper = 1,
		speed = 40,
	})
	local rot, setRot = ReactFlow.useSpring({
		start = 0,
		target = 0,
		damper = 1,
		speed = 40,
	})
	return e("Frame", {
		Size = props.Size or UDim2.new(0, 100, 0, 100),
		BackgroundTransparency = 1,
		AnchorPoint = props.AnchorPoint,
	}, {
		UIScale = e("UIScale", { Scale = pos }),

		e("ImageButton", {
			Size = props.Size or UDim2.new(0, 100, 0, 100),
			BackgroundTransparency = 1,
			Image = "rbxassetid://135201205917919",
			Rotation = rot:map(function(n)
				return n * 5
			end),
			[React.Event.Activated] = props[React.Event.Activated],
			[React.Event.MouseEnter] = function()
				setPos({
					target = 1.1,
					speed = 40,
					damper = 1,
				})
				setColor({
					target = 1,
					speed = 40,
					damper = 1,
				})
			end,
			[React.Event.MouseLeave] = function()
				setPos({
					target = 1,
					speed = 40,
					damper = 1,
				})
				setColor({
					target = 0,
					speed = 40,
					damper = 1,
				})
				setRot({
					target = 0,
					speed = 40,
					damper = 0.9,
				})
			end,
			[React.Event.MouseButton1Down] = function()
				setRot({
					target = 1,
					speed = 40,
					damper = 0.9,
				})

				if props.OnClick then
					props.OnClick()
				end
			end,
			[React.Event.MouseButton1Up] = function()
				setRot({
					target = 0,
					speed = 40,
					damper = 0.9,
				})
			end,
			-- HoverImage = "rbxassetid://12386390257",
			-- PressedImage = "rbxassetid://12386390257",
			ScaleType = Enum.ScaleType.Tile,
			Position = UDim2.new(0.5, 0, 0.5, 0),
			AutoButtonColor = true,
			AnchorPoint = Vector2.new(0.5, 0.5),
			TileSize = props.TileSize or UDim2.new(0, 100, 0, 100),
		}, {
			UIScale = e("UIScale", { Scale = pos }),
			UIStroke = e("UIStroke", {
				Thickness = 4,
				Color = Color3.new(1, 1, 1),
			}, {
				UIGradient = e("UIGradient", {

					Rotation = 90,
					Color = color:map(function(c)
						return ColorSequence.new({
							ColorSequenceKeypoint.new(0, PRIMARY_FOREGROUND),
							ColorSequenceKeypoint.new(1, Color3.new(c, 0, 0)),
						})
					end),
				}),
			}),

			UICorner = e("UICorner", { CornerRadius = UDim.new(0.2, 0) }),

			UIGradient = e("UIGradient", {
				Rotation = 90,
				Color = color:map(function(c)
					return ColorSequence.new({
						ColorSequenceKeypoint.new(0, PRIMARY_FOREGROUND),
						ColorSequenceKeypoint.new(1, Color3.new(c, 1 - 0.5 * c, 1 - c)),
					})
				end),
			}),
			ImageOverlay = e("ImageLabel", {
				Size = UDim2.new(0, 100, 0, 100),
				BackgroundTransparency = 1,
				Image = props.Image,
				Active = false,
				ZIndex = 1,
			}),
			TextOverlay = e(SmallText, {
				TextSize = rot:map(function(n)
					return 20 * (1 + n / 5)
				end),
				Position = UDim2.new(0.5, 0, 0.5, 0),
				ZIndex = 2,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Font = Enum.Font.Arcade,
				Text = props.Text,
			}, {
				-- UIScale = e("UIScale", { Scale =  }),
				UIStroke = e("UIStroke", {
					Thickness = 4,
					Color = Color3.new(1, 1, 1),
				}, {
					UIGradient = e("UIGradient", {
						Rotation = 90,
						Color = color:map(function(c)
							return ColorSequence.new({
								ColorSequenceKeypoint.new(0, PRIMARY_FOREGROUND),
								ColorSequenceKeypoint.new(1, Color3.new(c, 0, 0)),
							})
						end),
					}),
				}),
				UIGradient = e("UIGradient", {
					Rotation = 90,
					Color = color:map(function(c)
						return ColorSequence.new({
							ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
							ColorSequenceKeypoint.new(1, Color3.new(c, 1 - 0.2 * c, 1 - 0.8 * c)),
						})
					end),
				}),
			}),
		}),
	})
end

local function DefaultPanel(props)
	local children = props.children
	return e(VStack, {
		BackgroundTransparency = props.BackgroundTransparency or 1,
		BackgroundImage = props.BackgroundImage or "rbxassetid://135201205917919",
		BackgroundImageTransparency = props.BackgroundImageTransparency or 1,
		ScaleType = props.ScaleType or Enum.ScaleType.Tile,
		TileSize = props.TileSize or UDim2.new(0, 50, 0, 50),
		Size = props.Size or UDim2.new(0.5, 0, 0.5, 0),
		Position = props.Position or UDim2.new(0.5, 0, 0.5, 0),
		AnchorPoint = props.AnchorPoint or Vector2.new(0.5, 0.5),
		-- AutomaticSize = Enum.AutomaticSize.Y,
		Rotation = props.Rotation,
		Visible = props.Open,
		Spacing = UDim.new(0, 4),
		Padding = {
			Top = UDim.new(0, 0),
			Right = UDim.new(0, 0),
			Left = UDim.new(0, 0),
			Bottom = UDim.new(0, 0),
		},
		VerticalFlex = Enum.UIFlexAlignment.Fill,
		HorizontalFlex = Enum.UIFlexAlignment.None,
		HorizontalAlignment = Enum.HorizontalAlignment.Left,
	}, {
		UISizeConstraint = e("UISizeConstraint", {
			MinSize = props.MinSize or Vector2.new(300, 200),
			MaxSize = props.MaxSize or Vector2.new(400, 400),
		}),
		UIStroke = props.Stroke and e("UIStroke", {
			Thickness = 4,
			Color = Color3.new(1, 1, 1),
		}, {
			UIGradient = e("UIGradient", {
				Rotation = 90,
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, PRIMARY_FOREGROUND),
					ColorSequenceKeypoint.new(1, Color3.new(1, 1, 1)),
				}),
			}),
		}) or nil,
		UICorner = e("UICorner", { CornerRadius = UDim.new(0, 12) }),
		-- UIGradient = e("UIGradient", {
		-- 	Rotation = 90,
		-- 	Color = ColorSequence.new({
		-- 		ColorSequenceKeypoint.new(0, PRIMARY_FOREGROUND),
		-- 		ColorSequenceKeypoint.new(1, Color3.new(0, 1 - 0.5 * 0, 1 - 0)),
		-- 	}),
		-- }),
		Header = e(HStack, {
			BackgroundTransparency = 1,
			BackgroundImage = props.BackgroundImage or "rbxassetid://135201205917919",
			BackgroundImageTransparency = props.BackgroundImageTransparency or 1,
			ScaleType = props.ScaleType or Enum.ScaleType.Tile,
			TileSize = UDim2.new(0, 50, 0, 50),
			Size = UDim2.new(1, 0, 0, 50),
			Position = UDim2.new(0, 0, 0.5, 0),
			AnchorPoint = Vector2.new(0, 0.5),
			AutomaticSize = Enum.AutomaticSize.Y,
			Spacing = UDim.new(0, 24),
			Padding = {
				Top = UDim.new(0, 12),
				Right = UDim.new(0, 12),
				Left = UDim.new(0, 12),
				Bottom = UDim.new(0, 12),
			},
			VerticalFlex = Enum.UIFlexAlignment.Fill,
			HorizontalFlex = Enum.UIFlexAlignment.SpaceBetween,
			HorizontalAlignment = Enum.HorizontalAlignment.Left,
		}, {

			UICorner = e("UICorner", { CornerRadius = UDim.new(0, 4) }),
			UIGradient = e("UIGradient", {
				Rotation = 90,
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, PRIMARY_FOREGROUND),

					-- ColorSequenceKeypoint.new(1, PRIMARY_FOREGROUND),
					ColorSequenceKeypoint.new(1, Color3.new(0, 1 - 0.5 * 0, 1 - 0)),
				}),
			}),

			Text = e(SmallText, {
				Text = props.Title or "Panel",
				LayoutOrder = 1,
			}),
			CloseHolder = e("Frame", {
				LayoutOrder = 2,
			}, {

				e(CloseButton, {
					Size = UDim2.new(0, 50, 0, 50),
					AnchorPoint = Vector2.new(0.5, 1),
					Text = "X",
					TileSize = UDim2.new(0, 50, 0, 50),
					[React.Event.Activated] = props.OnClose,
				}),
			}),
		}),
		Body = e(VStack, {
			Size = UDim2.new(1, 0, 1, 0),
			-- AutomaticSize = Enum.AutomaticSize.Y,
			VerticalFlex = Enum.UIFlexAlignment.Fill,
			HorizontalFlex = Enum.UIFlexAlignment.SpaceBetween,
			HorizontalAlignment = Enum.HorizontalAlignment.Left,
			Spacing = UDim.new(0, 20),
			Padding = {
				Top = UDim.new(0, 12),
				Right = UDim.new(0, 12),
				Left = UDim.new(0, 12),
				Bottom = UDim.new(0, 12),
			},
		}, children),
	})
end

return DefaultPanel
