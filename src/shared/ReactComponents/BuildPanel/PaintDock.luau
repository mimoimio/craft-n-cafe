-- Shared/ReactComponents/BuildPanel/CategoryRow.luau
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local React = require(ReplicatedStorage.Packages.React)
local ReactFlow = require(ReplicatedStorage.Packages.ReactFlow)
local Reflex = require(ReplicatedStorage.Packages.Reflex)

local UIState = require(ReplicatedStorage.Shared.producers.UIState)
local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local PlacementController = require(ReplicatedStorage.Shared.Controllers.PlacementController)
local PlaceablesModule = require(ReplicatedStorage.Shared.PlaceablesModule)
local PaintConfig = require(ReplicatedStorage.Shared.Configs.PaintConfig)
local Types = require(ReplicatedStorage.Shared.Types)
local BuildersIcon = require(ReplicatedStorage.Shared.Utils.BuildersIcon)

local Primitives = ReplicatedStorage.Shared.ReactComponents.ui
local Grid = require(Primitives.Grid)
local VStack = require(Primitives.VStack)
local HStack = require(Primitives.HStack)
local SmallButton = require(Primitives.SmallButton)
local SmallText = require(Primitives.SmallText)
local Padding = require(Primitives.Padding)
local SoundController = require(ReplicatedStorage.Shared.Controllers.SoundController)

local e = React.createElement
local useState = React.useState
local useEffect = React.useEffect
local DOWN_ICON = BuildersIcon["chevron-large-down"]

local function getContrastText(color: Color3): Color3
	local luminance = (color.R * 0.299) + (color.G * 0.587) + (color.B * 0.114)
	return luminance > 0.55 and Color3.new(0, 0, 0) or Color3.new(1, 1, 1)
end
local function playPaintSound(name: string, speed: number?)
	SoundController.Sound(name, {
		PlaybackSpeed = speed or 1,
	})
end

local function prettySwatchName(name: string?): string
	if not name then
		return "Default"
	end
	return (name:gsub("(%u)", " %1"):gsub("^%s+", ""))
end
local function PaintDock(props: {
	activeChannel: string,
	primaryColor: string?,
	secondaryColor: string?,
	premiumPaintOwned: boolean,
	mobile: boolean,
	paintMode: boolean,
	onSelectChannel: (channel: string) -> (),
	onSelectColor: (name: string) -> (),
	onClear: () -> (),
	onOpenStore: () -> (),
})
	local open, setOpen = useState(false)
	local activeColor = if props.activeChannel == "Primary" then props.primaryColor else props.secondaryColor
	local activeColor3 = activeColor and PaintConfig.Swatches[activeColor] or Color3.fromRGB(45, 42, 50)
	local activeName = prettySwatchName(activeColor)
	local tab, setTab = useState(PaintConfig.IsPremium(activeColor) and "premium" or "free")
	local cellSize = props.mobile and 32 or 48
	local columns = props.mobile and 6 or 8

	useEffect(function()
		setTab(PaintConfig.IsPremium(activeColor) and "premium" or "free")
	end, { activeColor })

	useEffect(function()
		if props.paintMode then
			setOpen(true)
		end
	end, { props.paintMode })

	local function toggleOpen()
		local nextOpen = not open
		if nextOpen then
			setTab(PaintConfig.IsPremium(activeColor) and "premium" or "free")
		end
		setOpen(nextOpen)
		playPaintSound(nextOpen and "glass_003" or "glass_004", nextOpen and 1.12 or 0.9)
	end

	local function closePalette()
		setOpen(false)
		playPaintSound("glass_004", 0.9)
	end

	local function selectChannel(channel: string)
		if channel ~= props.activeChannel then
			props.onSelectChannel(channel)
			playPaintSound("glass_004", 1.05)
		end
		if not open then
			setOpen(true)
		end
	end

	local function selectColor(name: string)
		props.onSelectColor(name)
		playPaintSound("bottle_pop_2", 0.95 + math.random() * 0.1)
	end

	local function clearColor()
		props.onClear()
		playPaintSound("bottle_pop_2", 0.8)
	end

	local rounded = false
	local freeSwatchButtons = {}
	local premiumSwatchButtons = {}
	freeSwatchButtons.Default = e(SmallButton, {
		Size = UDim2.fromOffset(cellSize, cellSize),
		AutomaticSize = Enum.AutomaticSize.None,
		BackgroundColor3 = Color3.fromRGB(238, 238, 238),
		LayoutOrder = 0,
		Padding = { All = UDim.new(0, 0) },
		[React.Event.Activated] = function()
			clearColor()
		end,
		Rounded = rounded,
	}, {
		e(SmallText, {
			Text = "X",
			TextSize = 12,
			TextColor3 = Color3.fromRGB(200, 40, 40),
			TextXAlignment = Enum.TextXAlignment.Center,
			TextYAlignment = Enum.TextYAlignment.Center,
			Size = UDim2.fromScale(1, 1),
			AutomaticSize = Enum.AutomaticSize.None,
			TextStrokeTransparency = 0,
			ZIndex = 2,
		}),
		activeColor == nil and e("UIStroke", { Thickness = 3, Color = Color3.new(0.2, 1, 0.4) }) or nil,
	})

	for order, swatch in ipairs(PaintConfig.SwatchList) do
		local name = swatch.Name
		local locked = swatch.Premium and not props.premiumPaintOwned
		local selected = activeColor == name

		local button = e(SmallButton, {
			Size = UDim2.fromOffset(cellSize, cellSize),
			AutomaticSize = Enum.AutomaticSize.None,
			BackgroundColor3 = swatch.Color,
			-- BackgroundTransparency = locked and 0.55 or 0,
			BackgroundTransparency = 1,
			LayoutOrder = order,
			Padding = { All = UDim.new(0, 0) },
			Rounded = false,
			-- Rounded = rounded,
			ImageColor3 = swatch.Color,

			Image = "rbxassetid://98971826989596",
			ScaleType = Enum.ScaleType.Slice,
			SliceCenter = Rect.new(5, 5, 40, 40),

			[React.Event.Activated] = function()
				if locked then
					playPaintSound("bottle_pop_2", 0.72)
					props.onOpenStore()
					return
				end
				selectColor(name)
			end,
		}, {
			locked and e(SmallText, {
				Text = "P",
				TextSize = 10,
				TextColor3 = Color3.new(1, 1, 1),
				TextXAlignment = Enum.TextXAlignment.Center,
				TextYAlignment = Enum.TextYAlignment.Center,
				Size = UDim2.fromScale(1, 1),
				AutomaticSize = Enum.AutomaticSize.None,
				TextStrokeTransparency = 0,
				ZIndex = 2,
			}) or nil,
			selected and e("UIStroke", { Thickness = 3, Color = Color3.new(0, 0, 0) }) or nil,
		})

		if swatch.Premium then
			premiumSwatchButtons[name] = button
		else
			freeSwatchButtons[name] = button
		end
	end

	local channelChip = function(channel: string, colorKey: string?)
		local color = colorKey and PaintConfig.Swatches[colorKey] or Color3.fromRGB(65, 62, 70)
		local selected = props.activeChannel == channel
		local label = if props.mobile then (channel == "Primary" and "1" or "2") else channel

		return e(SmallButton, {
			Text = label,
			Size = UDim2.fromOffset(props.mobile and 44 or 88, props.mobile and 40 or 46),
			AutomaticSize = Enum.AutomaticSize.None,
			BackgroundColor3 = color,
			BackgroundTransparency = colorKey and 0 or 0.25,
			-- TextColor3 = colorKey and getContrastText(color) or Color3.new(1, 1, 1),
			TextColor3 = Color3.new(1, 1, 1),
			TextSize = props.mobile and 14 or 15,
			LayoutOrder = channel == "Primary" and 1 or 2,
			Padding = { All = UDim.new(0, 0) },
			[React.Event.Activated] = function()
				selectChannel(channel)
			end,
		}, {
			e("UIStroke", {
				Thickness = selected and 3 or 2,
				Color = Color3.new(0, 0, 0),
				-- Color = selected and Color3.new(0.2, 1, 0.4) or Color3.new(1, 1, 1),
				Transparency = selected and 0 or 0.7,
			}),
		})
	end
	return e(VStack, {
		Size = UDim2.new(0, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.XY,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
		Spacing = UDim.new(0, 8),
		-- BackgroundTransparency = 0.2,
		LayoutOrder = 1,
		ZIndex = 10,
	}, {
		Popover = open and e(VStack, {
			Size = UDim2.fromOffset(props.mobile and 270 or 360, 0),
			AutomaticSize = Enum.AutomaticSize.XY,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalFlex = "Fill",
			-- VerticalFlex = "None", -- changed to fill. Now this made "Bar" down there not squished when is open
			Spacing = UDim.new(0, 8),
			Padding = { All = UDim.new(0, 10) },
			BackgroundColor3 = Color3.fromRGB(26, 24, 30),
			BackgroundImage = "rbxassetid://120520009441669",
			ScaleType = Enum.ScaleType.Slice,
			SliceCenter = Rect.new(8, 8, 92, 92),
			-- BackgroundTransparency = 0.08,
			LayoutOrder = 1,
			ZIndex = 12,
		}, {
			-- UICorner = e("UICorner", { CornerRadius = UDim.new(0, 12) }),
			-- UIStroke = e("UIStroke", { Thickness = 2, Color = Color3.fromRGB(90, 85, 100), Transparency = 0.3 }),
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
			-- Swatches = e(Grid, { -- The Grid component is buggy, doesnt work well with other flex components. So if you want grid use HStack, turn on Wraps, and use fixed sizes for children.
			Swatches = e(HStack, {
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				CellSize = UDim2.fromOffset(cellSize, cellSize),
				CellPadding = UDim2.fromOffset(6, 6),
				Wraps = true,
				FillDirectionMaxCells = columns,
				Spacing = UDim.new(0, 8),
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
		Bar = e(HStack, {
			Size = UDim2.new(0, props.mobile and 300 or 400, 0, 0),
			-- Size = UDim2.new(0, props.mobile and 300 or 400, 0, props.mobile and 44 or 48),
			AutomaticSize = Enum.AutomaticSize.Y,
			HorizontalAlignment = Enum.HorizontalAlignment.Left,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			HorizontalFlex = "None",
			-- VerticalFlex = "None", -- this doesnt matter idk why
			Spacing = UDim.new(0, 6),
			Padding = { All = UDim.new(0, 4) },
			BackgroundColor3 = Color3.fromRGB(26, 24, 30),
			LayoutOrder = 2,
			ZIndex = 11,
			-- BackgroundTransparency = 0.15,
			BackgroundImage = "rbxassetid://120520009441669",
			ScaleType = Enum.ScaleType.Slice,
			SliceCenter = Rect.new(8, 8, 92, 92),
		}, {
			-- UICorner = e("UICorner", { CornerRadius = UDim.new(0, 12) }),
			-- UIStroke = e("UIStroke", { Thickness = 1, Color = Color3.fromRGB(90, 85, 100), Transparency = 0.5 }),
			Primary = channelChip("Primary", props.primaryColor),
			Secondary = channelChip("Secondary", props.secondaryColor),
			Palette = e(SmallButton, {
				Size = UDim2.fromOffset(props.mobile and 100 or 140, props.mobile and 40 or 46),
				AutomaticSize = Enum.AutomaticSize.None,
				BackgroundColor3 = Color3.fromRGB(42, 39, 48),
				BackgroundTransparency = 0.1,
				LayoutOrder = 3,
				Padding = { All = UDim.new(0, 4) },
				[React.Event.Activated] = toggleOpen,
			}, {
				Content = e(HStack, {
					Size = UDim2.new(1, 0, 1, 0),
					AutomaticSize = Enum.AutomaticSize.None,
					HorizontalAlignment = Enum.HorizontalAlignment.Center,
					VerticalAlignment = Enum.VerticalAlignment.Center,
					Spacing = UDim.new(0, 5),
				}, {
					Preview = e("Frame", {
						Size = UDim2.fromOffset(18, 18),
						BackgroundColor3 = activeColor3,
						BackgroundTransparency = activeColor and 0 or 0.15,
						LayoutOrder = 1,
					}, {
						UICorner = e("UICorner", { CornerRadius = UDim.new(0, 4) }),
						UIStroke = e("UIStroke", { Thickness = 1, Color = Color3.new(1, 1, 1), Transparency = 0.5 }),
					}),
					e(SmallText, {
						Text = "Palette",
						TextSize = props.mobile and 12 or 15,
						TextColor3 = Color3.fromRGB(235, 230, 240),
						LayoutOrder = 2,
					}),
				}),
			}),
		}),
	})
end
return PaintDock
