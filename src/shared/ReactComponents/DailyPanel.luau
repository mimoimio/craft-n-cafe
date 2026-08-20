-- DailyPanel.luau
local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local React = require(ReplicatedStorage.Packages.React)
local ReactFlow = require(ReplicatedStorage.Packages.ReactFlow)
local useSpring = ReactFlow.useSpring
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local CoffeeModule = require(ReplicatedStorage.Shared.CoffeeModule)
local HStack = require(ReplicatedStorage.Shared.ReactComponents.ui.HStack)
local VStack = require(ReplicatedStorage.Shared.ReactComponents.ui.VStack)
local Grid = require(ReplicatedStorage.Shared.ReactComponents.ui.Grid)
local SmallButton = require(ReplicatedStorage.Shared.ReactComponents.ui.SmallButton)
local SmallText = require(ReplicatedStorage.Shared.ReactComponents.ui.SmallText)
local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local VariationsConfig = require(ReplicatedStorage.Shared.Configs.VariationsConfig)
local DailyConfig = require(ReplicatedStorage.Shared.Configs.DailyConfig)
local UIState = require(ReplicatedStorage.Shared.producers.UIState)
local player = game:GetService("Players").LocalPlayer
local playerId = player and tostring(player.UserId) or ""
-- CoffeeModule.Config is the keyed lookup (by Id)
local CoffeeConfig = CoffeeModule.Config

local e = React.createElement
local useState = React.useState
local useEffect = React.useEffect
local useRef = React.useRef

-- local RECIPES = getSortedRecipes()
local RECIPES = CoffeeModule.Array

local BG = Color3.fromRGB(25, 25, 30)
local PANEL_BG = Color3.fromRGB(37, 37, 88)
local ITEM_BG = Color3.fromRGB(255, 201, 150)
local ITEM_SELECTED_BG = Color3.fromRGB(255, 252, 208)
local ITEM_BG_LOCKED = Color3.fromRGB(148, 56, 33)
local ITEM_BG_LOCKED_SELECTED = Color3.fromRGB(122, 87, 40)
local ACCENT = Color3.fromRGB(255, 200, 80)
local TEXT = Color3.fromRGB(230, 230, 230)
local SUBTEXT = Color3.fromRGB(160, 160, 180)

local function Rewards(props)
	local children = {}
	local n = #DailyConfig

	local currentDay = props.currentDay or 1
	local canClaim = props.canClaim
	if canClaim == nil then
		canClaim = true
	end

	-- Modulo logic to handle players who are on Day 8+, looping back to the first visual day
	local actualCurrentDay = currentDay
	if n > 0 then
		actualCurrentDay = ((currentDay - 1) % n) + 1
	end

	local seventh

	for i, config in DailyConfig do
		local isCurrentDay = (i == actualCurrentDay)
		local isHighlighted = isCurrentDay and canClaim
		-- if i==#DailyConfig then
		-- 	continue
		-- end
		-- FIX: Prevent darkening future days!
		local cardColor
		if isHighlighted then
			cardColor = ITEM_SELECTED_BG -- Highlighted active day!
		elseif i < actualCurrentDay then
			cardColor = ITEM_BG_LOCKED -- Past days previously claimed
		else
			cardColor = ITEM_BG -- Future days OR today if we already claimed!
		end

		local rewards = {}
		local texts = {}
		for ingredient, amount in config do
			local itemConfig = CoffeeModule.IngredientLookup[ingredient]
			table.insert(
				rewards,
				e("ImageLabel", {
					Size = UDim2.new(0, 40, 0, 40),
					Image = itemConfig and itemConfig.Image or "",
					-- BackgroundTransparency = 1,
					BackgroundTransparency = 0.8,
				}, {
					UICorner = e("UICorner", { CornerRadius = UDim.new(0, 12) }),
					e(SmallText, {
						Text = `{amount}x`,
						Size = UDim2.new(1, 0, 1, 0),
						TextSize = 18,
						TextTruncate = Enum.TextTruncate.AtEnd,
					}),
				})
			)
		end
		local rewardsCom = e("Frame", {
			Size = UDim2.new(1, 0, 1, 0),
			ClipsDescendants = true,
			BackgroundTransparency = 1,
		}, {
			e(VStack, {
				HorizontalFlex = Enum.UIFlexAlignment.None,
				VerticalFlex = Enum.UIFlexAlignment.None,
				Spacing = UDim.new(0, 0),
			}, {
				UIPadding = e("UIPadding", {
					PaddingTop = UDim.new(0, 0),
					PaddingBottom = UDim.new(0, 40),
					PaddingLeft = UDim.new(0, 0),
					PaddingRight = UDim.new(0, 0),
				}),
				e(SmallText, {
					Text = `Day {i}`,
					TextSize = 24,
					TextTruncate = Enum.TextTruncate.AtEnd,
				}),
				e(HStack, {
					VerticalFlex = Enum.UIFlexAlignment.None,
					HorizontalFlex = Enum.UIFlexAlignment.None,
					VeticalAlignment = Enum.VerticalAlignment.Top,
					HorizontalAlignment = Enum.HorizontalAlignment.Center,
					Wraps = true,
				}, rewards),
			}),
		})

		local currentDayReward = e("Frame", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
		}, {
			e(SmallButton, {
				Size = UDim2.new(1, 0, 1, 0),
				Image = "rbxassetid://103478691850846",
				ImageColor3 = cardColor,
				SliceCenter = Rect.new(8, 8, 90, 102),
				ScaleType = Enum.ScaleType.Slice,
				Rounded = false,
				BackgroundTransparency = 1,
				AutomaticSize = Enum.AutomaticSize.None,
				AnchorPoint = Vector2.new(0.5, 0.5),
				HoverScale = true,
				Position = UDim2.new(0.5, 0, 0.5, 0),
			}, { rewardsCom }),

			c = e("UIAspectRatioConstraint", {
				AspectRatio = 1,
				AspectType = Enum.AspectType.ScaleWithParentSize,
			}),
		})
		if i == #DailyConfig then
			seventh = currentDayReward
		else
			children[i] = currentDayReward
		end
	end
	return e(HStack, {
		HorizontalFlex = Enum.UIFlexAlignment.Fill,
		Padding = { All = UDim.new(0, 8) },
		ClipsDescendants = true,
		VerticalAlignment = Enum.VerticalAlignment.Center,
	}, {
		-- e("ScrollingFrame", {
		-- 	Size = UDim2.new(1, 0, 1, 0),
		-- 	ScrollingDirection = Enum.ScrollingDirection.X,
		-- 	ClipsDescendants = false,
		-- 	CanvasSize = UDim2.new(1, 0, 1, 0),
		-- 	AutomaticCanvasSize = Enum.AutomaticSize.X,
		-- 	BackgroundTransparency = 1,
		-- 	ScrollBarThickness = 16,
		-- }, {
		e("Frame", {
			Size = UDim2.new(0.6, 0, 1, 0),
			ClipsDescendants = false,
			BackgroundTransparency = 1,
		}, {
			e(Grid, {
				HorizontalFlex = Enum.UIFlexAlignment.None,
				Padding = { Bottom = UDim.new(0, 0) },
				-- BackgroundTransparency = 0,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				Spacing = UDim.new(0, 8),
				CellSize = UDim2.new(0, 100, 0, 100),
				FillDirectionMaxCells = 3,
			}, children),
		}),
		e("Frame", {
			Size = UDim2.new(0.4, 0, 1, 0),
			ClipsDescendants = false,
			BackgroundTransparency = 1,
		}, {
			seventh,
			-- e(Grid, {
			-- 	HorizontalFlex = Enum.UIFlexAlignment.None,
			-- 	Padding = { Bottom = UDim.new(0, 24) },
			-- 	Spacing = UDim.new(0, 8),
			-- }, children),
		}),
	})
end

local function DailyPanel(props: {
	onClose: () -> (),
})
	local visible, setVisible = useState(false)
	local variationId, setVariationId = useState("none")
	local discoveredDrinks, setDiscoveredDrinks = useState(not player and { none = { espresso = true } } or nil)
	local drinksOfVariation: { [string]: true } = discoveredDrinks and discoveredDrinks[variationId] or {}
	local dailyInfo, setDailyInfo = useState(nil)

	useEffect(function()
		local unsub = GlobalState:subscribe(function(state: any)
			return state.DiscoveredDrinks[playerId]
		end, function(dd)
			setDiscoveredDrinks(dd)
		end)

		local state = GlobalState:getState()
		local dd = state.DiscoveredDrinks[playerId]
		if dd then
			setDiscoveredDrinks(dd or {})
		end
		return unsub
	end, {})

	-- Subscribe to Daily State!
	useEffect(function()
		local unsub = GlobalState:subscribe(function(state: any)
			return state.Daily and state.Daily[playerId]
		end, function(daily)
			setDailyInfo(daily)
		end)

		local state = GlobalState:getState()
		if state.Daily and state.Daily[playerId] then
			setDailyInfo(state.Daily[playerId])
		end
		return unsub
	end, {})

	-- listen to panel
	useEffect(function()
		local unsub = UIState:subscribe(function(state: any)
			setVisible(state.panel == "daily")
		end)
		local panel = UIState:getState().panel
		if panel then
			setVisible(panel == "daily")
		end
		return unsub
	end, {})

	local position, setPosition = useSpring({
		start = -1,
		target = -1,
		speed = 1,
		damper = 1,
	})

	useEffect(function()
		if visible then
			setPosition({
				target = 0,
				speed = 30,
				damper = 0.6,
			})
		else
			setPosition({
				target = -1,
				speed = 30,
				damper = 0.6,
			})
		end
	end, { visible })

	-- Process Daily Variables
	local currentDay = dailyInfo and dailyInfo.day or 1
	local lastClaimedDaily = dailyInfo and dailyInfo.lastClaimedDaily

	-- Subscribes successfully to the new state variable injected by the server!
	local today = dailyInfo and dailyInfo.today or math.floor(workspace:GetServerTimeNow() / 86400)

	local canClaim = true

	if lastClaimedDaily then
		if lastClaimedDaily > 1000000000 then
			local lastDate = os.date("!*t", lastClaimedDaily)
			local currDate = os.date("!*t", os.time())
			if lastDate.year == currDate.year and lastDate.yday == currDate.yday then
				canClaim = false
			end
		else
			if lastClaimedDaily == today then
				canClaim = false
			end
		end
	end

	return e("Frame", {
		LayoutOrder = 2,
		Size = UDim2.new(
			0,
			workspace.CurrentCamera.ViewportSize.X + 60,
			0,
			workspace.CurrentCamera.ViewportSize.Y + 60
		),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = position:map(function(n)
			return UDim2.new(0.5 + 2 * n, 0, 0.5 + 0, 0)
		end),
		BackgroundColor3 = Color3.new(),
		BackgroundTransparency = position:map(function(n)
			return -n + 0.2
		end),
	}, {
		e("ImageLabel", {
			Size = UDim2.new(1, -20, 1, -0),
			ZIndex = 20,
			BackgroundColor3 = PANEL_BG,
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			Image = "rbxassetid://103478691850846",
			ImageColor3 = Color3.new(0.768627, 0.549019, 0.549019),
			ScaleType = Enum.ScaleType.Slice,
			SliceCenter = Rect.new(8, 8, 92, 92),
			BorderSizePixel = 0,
			ClipsDescendants = false,
		}, {
			UIAspectRatioConstraint = e("UIAspectRatioConstraint", {
				AspectRatio = 2,
			}),
			UISizeConstraint = e("UISizeConstraint", {
				MaxSize = Vector2.new(workspace.CurrentCamera.ViewportSize.X * 0.95, 380),
			}),

			Container = e("Frame", {
				Size = UDim2.new(1, -20, 1, -20),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0.5, 0, 0.5, 0),
				BackgroundColor3 = BG,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				LayoutOrder = 2,
			}, {
				UICorner = e("UICorner", { CornerRadius = UDim.new(0, 12) }),
				e("UIPadding", {
					PaddingTop = UDim.new(0, 12),
					PaddingBottom = UDim.new(0, 12),
					PaddingLeft = UDim.new(),
					PaddingRight = UDim.new(),
				}),
				CloseBtn = e("TextButton", {
					Size = UDim2.new(0, 32, 0, 32),
					Position = UDim2.new(1, 32, 0, -32),
					AnchorPoint = Vector2.new(1, 0),
					BackgroundColor3 = Color3.fromRGB(80, 40, 40),
					BorderSizePixel = 0,
					Text = "X",
					TextColor3 = Color3.fromRGB(255, 120, 120),
					TextSize = 16,
					Font = Enum.Font.FredokaOne,
					[React.Event.MouseButton1Click] = function()
						UIState.toggle("none")
					end,
				}, {
					UICorner = e("UICorner", { CornerRadius = UDim.new(0, 6) }),
				}),
				-- }),
				Body = e(HStack, {
					Size = UDim2.new(1, 0, 1, -24),
					Position = UDim2.new(0, 0, 0, 0),
					BackgroundTransparency = 1,
					Padding = { All = UDim.new() },
				}, {
					DetailPanel = e("ImageLabel", {
						Size = UDim2.new(1, 0, 1, 0),
						Position = UDim2.new(0, 0, 0, 0),
						BackgroundTransparency = 1,
						BackgroundColor3 = PANEL_BG,
						Image = "rbxassetid://127657596958436",
						ImageColor3 = Color3.new(0.505882, 0.254901, 0.254901),
						ImageTransparency = 1,
						ScaleType = Enum.ScaleType.Slice,
						SliceCenter = Rect.new(8, 8, 92, 92),
						BorderSizePixel = 0,
					}, {
						Rewards = e(Rewards, {
							currentDay = currentDay,
							canClaim = canClaim,
						}),
					}),
				}),
			}),
			e(SmallButton, {
				LayoutOrder = 3,
				Text = canClaim and "Claim!" or "Claimed Today!",
				[React.Event.Activated] = function()
					if canClaim then
						Remotes.ClaimDaily:FireServer()
					end
				end,
				Position = UDim2.new(0.5, 0, 1, -4),
				BackgroundTransparency = canClaim and 0 or 0.5,
				AnchorPoint = Vector2.new(0.5, 1),
				CornerRadius = UDim.new(1, 0),
			}),
		}),
	})
end

return DailyPanel
