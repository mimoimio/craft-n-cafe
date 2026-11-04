# Buggy Grid component
===
from src/shared/ReactComponents/ui/Grid.luau
Avoid using this as it breaks flex
doesnt work well with other flex components.
So if you want grid use HStack, turn on Wraps, and use fixed sizing
Popover = open and e(VStack, {
			Size = UDim2.fromOffset(props.mobile and 270 or 360, 0),
			AutomaticSize = Enum.AutomaticSize.XY,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalFlex = "Fill",
			-- VerticalFlex = "None", -- changed to fill. Now this made "Bar" down there not squished when is open
			Spacing = UDim.new(0, 8),
			Padding = { All = UDim.new(0, 10) },
			BackgroundColor3 = Color3.fromRGB(26, 24, 30),
			BackgroundTransparency = 0.08,
			LayoutOrder = 1,
			ZIndex = 12,
		}, {
			UICorner = e("UICorner", { CornerRadius = UDim.new(0, 12) }),
			UIStroke = e("UIStroke", { Thickness = 2, Color = Color3.fromRGB(90, 85, 100), Transparency = 0.3 }),
			Header = e(HStack, {
				AutomaticSize = Enum.AutomaticSize.XY,
				-- AutomaticSize = Enum.AutomaticSize.None,
				Size = UDim2.new(1, 0, 0, 0),
				-- Size = UDim2.new(1, 0, 0, 28),
				HorizontalFlex = "SpaceBetween",
				VerticalFlex = "Fill",
				VerticalAlignment = Enum.VerticalAlignment.Center,
				LayoutOrder = 1,
			}, {
				Title = e(SmallText, {
					Text = `{props.activeChannel} · {activeName}`,
					TextSize = props.mobile and 14 or 16,
					TextColor3 = Color3.fromRGB(255, 235, 190),
					LayoutOrder = 1,
				}),
				Close = e(SmallButton, {
					Text = "X",
					Size = UDim2.fromOffset(28, 28),
					AutomaticSize = Enum.AutomaticSize.None,
					BackgroundColor3 = Color3.fromRGB(110, 35, 35),
					BackgroundTransparency = 0.2,
					TextSize = 12,
					LayoutOrder = 2,
					Padding = { All = UDim.new(0, 0) },
					[React.Event.Activated] = closePalette,
				}),
			}),
			Tabs = e(HStack, {
				AutomaticSize = Enum.AutomaticSize.XY,
				-- AutomaticSize = Enum.AutomaticSize.None,
				-- VerticalFlex = Enum.UIFlexAlignment.None,
				Size = UDim2.new(1, 0, 0, 0),
				-- Size = UDim2.new(1, 0, 0, 28),

				HorizontalFlex = "Fill",
				BackgroundTransparency = 0,
				BackgroundColor3 = Color3.new(1, 0, 0),
				VerticalAlignment = "Center",
				Spacing = UDim.new(0, 6),
				LayoutOrder = 2,
			}, {
				Free = e(SmallButton, {
					Text = "Free",
					-- Size = UDim2.new(0, 0, 1, 0),
					Size = UDim2.new(0, 0, 0, 40),
					AutomaticSize = Enum.AutomaticSize.None,
					BackgroundColor3 = tab == "free" and Color3.fromRGB(55, 105, 80) or Color3.fromRGB(42, 39, 48),
					BackgroundTransparency = tab == "free" and 0 or 0.35,

					TextSize = 12,
					LayoutOrder = 1,
					Padding = { All = UDim.new(0, 12) },
					[React.Event.Activated] = function()
						setTab("free")
						playPaintSound("glass_004", 1.1)
					end,
				}),
				Premium = e(SmallButton, {
					Text = "Premium",
					-- Size = UDim2.new(0, 0, 1, 0),
					Size = UDim2.new(0, 0, 0, 40),
					AutomaticSize = Enum.AutomaticSize.None,
					BackgroundColor3 = tab == "premium" and Color3.fromRGB(70, 65, 130) or Color3.fromRGB(42, 39, 48),
					BackgroundTransparency = tab == "premium" and 0 or 0.35,
					TextSize = 12,
					LayoutOrder = 2,
					Padding = { All = UDim.new(0, 12) },
					[React.Event.Activated] = function()
						setTab("premium")
						playPaintSound("glass_004", 1.1)
					end,
				}),
			}),
			-- Swatches = e(Grid, { -- The Grid component is buggy, doesnt work well with other flex components. So if you want grid use HStack, turn on Wrapped, and use fixed sizes for children.
			Swatches = e(HStack, {
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				CellSize = UDim2.fromOffset(cellSize, cellSize),
				CellPadding = UDim2.fromOffset(6, 6),
				BackgroundTransparency = 0,
				BackgroundColor3 = Color3.new(0, 0, 1),
				FillDirectionMaxCells = columns,
				LayoutOrder = 3,
			}, if tab == "free" then freeSwatchButtons else premiumSwatchButtons),
			Footer = if props.premiumPaintOwned or tab ~= "premium"
				then nil
				else e(HStack, {
					Size = UDim2.new(1, 0, 0, 0),
					AutomaticSize = Enum.AutomaticSize.XY,
					HorizontalFlex = "SpaceBetween",
					VerticalAlignment = Enum.VerticalAlignment.Center,
					LayoutOrder = 4,
				}, {
					e(SmallText, {
						Text = "Premium colors",
						TextSize = 11,
						TextColor3 = Color3.fromRGB(175, 170, 185),
						LayoutOrder = 1,
					}),
					e(SmallButton, {
						Text = "Unlock",
						Size = UDim2.fromOffset(72, 26),
						AutomaticSize = Enum.AutomaticSize.None,
						BackgroundColor3 = Color3.fromRGB(45, 115, 160),
						TextSize = 12,
						LayoutOrder = 2,
						Padding = { All = UDim.new(0, 0) },
						[React.Event.Activated] = function()
							playPaintSound("powerUp7", 1.1)
							props.onOpenStore()
						end,
					}),
				}),
		}) or nil,