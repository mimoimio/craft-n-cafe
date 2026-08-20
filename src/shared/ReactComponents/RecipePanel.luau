local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local React = require(ReplicatedStorage.Packages.React)
local Mionum = require(ReplicatedStorage.Packages.Mionum)
local ReactFlow = require(ReplicatedStorage.Packages.ReactFlow)
local useSpring = ReactFlow.useSpring
local CoffeeConfigArray = require(ReplicatedStorage.Shared.Configs.CoffeeConfig)
local CoffeeModule = require(ReplicatedStorage.Shared.CoffeeModule)
local HStack = require(ReplicatedStorage.Shared.ReactComponents.ui.HStack)
local VStack = require(ReplicatedStorage.Shared.ReactComponents.ui.VStack)
local SmallButton = require(ReplicatedStorage.Shared.ReactComponents.ui.SmallButton)
local SmallText = require(ReplicatedStorage.Shared.ReactComponents.ui.SmallText)
local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local VariationsConfig = require(ReplicatedStorage.Shared.Configs.VariationsConfig)
local UIState = require(ReplicatedStorage.Shared.producers.UIState)
local Types = require(ReplicatedStorage.Shared.Types)
local BuildersIcon = require(ReplicatedStorage.Shared.Utils.BuildersIcon)
local CLOCK = BuildersIcon.clock
local STOCK = BuildersIcon["three-stacked-squares-tilted"]

local useBreakpoint = require(ReplicatedStorage.Shared.Hooks.useBreakpoint)

local player = game:GetService("Players").LocalPlayer
local playerId = player and tostring(player.UserId) or ""
-- CoffeeModule.Config is the keyed lookup (by Id)
local CoffeeConfig = CoffeeModule.Config

local e = React.createElement
local useState = React.useState
local useEffect = React.useEffect
local useRef = React.useRef

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

local function RecipeGridItem(props: {
	config: Types.CoffeeConfigType,
	isSelected: boolean,
	onSelect: () -> (),
	layoutOrder: number,
})
	local hovered, setHovered = useState(false)
	local locked = not props.discovered

	local xs, sm, md, lg, xl = useBreakpoint()
	local mobile = xs or sm

	local bg = if props.isSelected
		then (if locked then ITEM_BG_LOCKED_SELECTED else ITEM_SELECTED_BG)
		elseif hovered then (if locked then Color3.new(0.5, 0.5, 0.5) else Color3.new(1, 0.956862, 0.901960))
		else (if locked then ITEM_BG_LOCKED else ITEM_BG)
	return e("ImageButton", {
		Size = UDim2.new(0, 90, 0, 110),
		-- Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = bg,
		BorderSizePixel = 0,
		Image = "rbxassetid://103478691850846",
		AutoButtonColor = true,
		-- Text = "",
		ImageColor3 = bg,
		LayoutOrder = props.layoutOrder,
		[React.Event.MouseEnter] = function()
			setHovered(true)
		end,
		[React.Event.MouseLeave] = function()
			setHovered(false)
		end,
		[React.Event.MouseButton1Click] = props.onSelect,
	}, {
		UICorner = e("UICorner", { CornerRadius = UDim.new(0, 8) }),
		UIPadding = e("UIPadding", {
			PaddingLeft = UDim.new(0, mobile and 2 or 6),
			PaddingRight = UDim.new(0, mobile and 2 or 6),
			PaddingTop = UDim.new(0, mobile and 2 or 6),
			PaddingBottom = UDim.new(0, mobile and 2 or 12),
		}),
		Image = e("ImageLabel", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundColor3 = Color3.fromRGB(30, 30, 38),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Image = props.config.Image or "",
			ImageColor3 = bg,
			ScaleType = Enum.ScaleType.Fit,
			ZIndex = 10,
			Position = UDim2.new(0.5, 0, 0, 0),
			AnchorPoint = Vector2.new(0.5, 0),
		}, {
			UICorner = e("UICorner", { CornerRadius = UDim.new(0, 6) }),
			-- UIStroke = e("UIStroke", {
			-- 	Color = bg,
			-- 	Thickness = 4,
			-- }),
		}),
		-- Flare = e("ImageLabel", {
		-- 	Size = UDim2.new(0, 70, 0, 70),
		-- 	-- Size = UDim2.new(1, 0, 0, 70),
		-- 	BackgroundColor3 = Color3.fromRGB(30, 30, 38),
		-- 	BackgroundTransparency = 1,
		-- 	BorderSizePixel = 0,
		-- 	Position = UDim2.new(0.5, 0, 0, 0),
		-- 	AnchorPoint = Vector2.new(0.5, 0),
		-- 	Image = "rbxassetid://126550182137995",
		-- 	ScaleType = Enum.ScaleType.Fit,
		-- 	ZIndex = 5,
		-- 	ImageColor3 = bg,
		-- }, {
		-- 	UICorner = e("UICorner", { CornerRadius = UDim.new(0, 6) }),
		-- }),
		Label = not mobile and e("TextLabel", {
			Size = UDim2.new(1, 0, 0, 28),
			Position = UDim2.new(0, 0, 1, -28),
			BackgroundTransparency = 1,
			Text = locked and "???" or props.config.DisplayName,
			TextColor3 = if props.isSelected then ACCENT else TEXT,
			TextSize = 12,
			TextStrokeTransparency = 0,
			Font = Enum.Font.FredokaOne,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextYAlignment = Enum.TextYAlignment.Top,
			TextTruncate = Enum.TextTruncate.AtEnd,
			TextWrapped = true,
		}, {
			UITextSizeConstraint = e("UITextSizeConstraint", {
				MinTextSize = 11,
				MaxTextSize = 12,
			}),
		}) or nil,
	})
end

local function IngredientChip(props: { name: string, layoutOrder: number })
	local xs, sm, md, lg, xl = useBreakpoint()
	local mobile = xs or sm
	return e("Frame", {
		Size = UDim2.new(0, 0, 0, mobile and 18 or 26),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = props.type and 1 or 0,
		BackgroundColor3 = Color3.fromRGB(55, 55, 68),
		BorderSizePixel = 0,
		LayoutOrder = props.layoutOrder,
	}, {
		UICorner = e("UICorner", { CornerRadius = UDim.new(0.5, 0) }),
		UIPadding = e("UIPadding", {
			PaddingLeft = UDim.new(0, 10),
			PaddingRight = UDim.new(0, 10),
		}),
		Label = e("TextLabel", {
			Size = UDim2.new(0, 0, 1, 0),
			AutomaticSize = Enum.AutomaticSize.X,
			BackgroundTransparency = 1,
			Text = props.name,
			TextColor3 = SUBTEXT,
			TextSize = mobile and 10 or 13,
			Font = Enum.Font.FredokaOne,
		}),
	})
end -- RecipePanel.luau
local function RecipeDetail(props: {
	config: Types.CoffeeConfigType?,
	onNext: () -> (),
	onPrev: () -> (),
	locked: boolean,
	variation: Types.VariationConfig,
})
	local config = props.config or {}
	local xs, sm, md, lg, xl = useBreakpoint()
	local mobile = xs or sm

	-- 1. Build the 3x3 Grid Elements matching MixerPanel's IngredientList
	local selectedIngredientElements = {}
	local recipePath = config.RecipePath or {}

	for i = 1, 9 do
		local id = recipePath[i]
		local ingConfig = id and CoffeeModule.IngredientLookup[id]

		-- Handle undiscovered (locked) visualization
		local text = ingConfig and ingConfig.DisplayName or "////"
		local imageColor
		local image = ingConfig and ingConfig.Image

		if props.locked and id then
			text = "???"
			imageColor = Color3.new()
		end

		selectedIngredientElements[i] = e(SmallButton, {
			OverlayText = id and text or "",
			OverlayTextSize = mobile and 8 or 10,
			LayoutOrder = i,
			OverlayTextWrapped = true,
			ButtonClass = "ImageButton",
			AutomaticSize = Enum.AutomaticSize.None,
			Image = image,
			ImageColor3 = imageColor,
			-- Dynamically scale button sizes for mobile landscape constraints
			Size = mobile and UDim2.new(0, 36, 0, 36) or UDim2.new(0, 50, 0, 50),
			Padding = { All = UDim.new(0, 4) },
			BackgroundColor3 = id and Color3.fromRGB(84, 52, 52) or Color3.fromRGB(50, 50, 60),
			BackgroundTransparency = id and 0 or 0.6, -- Dims empty slots to maintain the 3x3 layout
		})
	end

	local price = config and config.Price or nil
	local stock = config and config.InitialStock or nil
	local min = config and config.Duration // 60 or nil
	local sec = config and config.Duration % 60 or nil
	local detailsLabel = config
		and `$$$: {price and Mionum.new(price):toString()} $\n{CLOCK}: {min > 0 and `{min} min ` or ""}{sec} sec\n{STOCK}: {stock}x`
	return e("Frame", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
	}, {
		Frame = e("Frame", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
		}, {
			UIListLayout = e("UIListLayout", {
				FillDirection = Enum.FillDirection.Vertical,
				Padding = UDim.new(0, mobile and 4 or 8),
				SortOrder = Enum.SortOrder.LayoutOrder,
				HorizontalFlex = Enum.UIFlexAlignment.Fill,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				VerticalFlex = Enum.UIFlexAlignment.None,
			}),
			UIPadding = e("UIPadding", {
				PaddingLeft = UDim.new(0, mobile and 4 or 16),
				PaddingRight = UDim.new(0, mobile and 4 or 16),
				PaddingTop = UDim.new(0, mobile and 4 or 16),
			}),
			CenterStage = e(HStack, {
				Size = UDim2.new(1, 0, 0, mobile and 22 or 28),
				HorizontalFlex = Enum.UIFlexAlignment.Fill,
				VerticalFlex = Enum.UIFlexAlignment.None,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				LayoutOrder = 2,
				ClipsDescendants = false,
			}, {
				Title = e("TextLabel", {
					Size = UDim2.new(1, 0, 0, 30),
					TextWrapped = true,
					Text = props.locked and "???" or config.DisplayName,
					TextColor3 = ACCENT,
					TextSize = mobile and 16 or 22,
					TextStrokeTransparency = 0,
					Font = Enum.Font.SpecialElite,
					TextXAlignment = Enum.TextXAlignment.Left,
					BackgroundTransparency = 1,
					LayoutOrder = 2,
					AutomaticSize = Enum.AutomaticSize.Y,
					ClipsDescendants = false,
				}),
				PrevButton = e("TextButton", {
					Size = UDim2.new(0, mobile and 30 or 50, 1, 0),
					BackgroundColor3 = Color3.fromRGB(50, 50, 65),
					BorderSizePixel = 0,
					Text = "<",
					TextColor3 = TEXT,
					TextSize = 24,
					Font = Enum.Font.FredokaOne,
					LayoutOrder = 1,
					[React.Event.Activated] = props.onPrev,
				}, {
					UICorner = e("UICorner", { CornerRadius = UDim.new(0, 8) }),
				}),

				NextButton = e("TextButton", {
					Size = UDim2.new(0, mobile and 30 or 50, 1, 0),
					BackgroundColor3 = Color3.fromRGB(50, 50, 65),
					BorderSizePixel = 0,
					Text = ">",
					TextColor3 = TEXT,
					TextSize = 24,
					Font = Enum.Font.FredokaOne,
					LayoutOrder = 3,
					[React.Event.Activated] = props.onNext,
				}, {
					UICorner = e("UICorner", { CornerRadius = UDim.new(0, 8) }),
				}),
			}),

			-- 2. The Core Visual Flow: < [ 3x3 Grid ] = [ Flare + Result ] >

			RecipeFlow = e(HStack, {
				AutomaticSize = Enum.AutomaticSize.X,
				Spacing = UDim.new(0, mobile and 6 or 16),
				Size = UDim2.new(0, 0, 0, mobile and 100 or 170),
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				HorizontalFlex = Enum.UIFlexAlignment.Fill,
				LayoutOrder = 2,
			}, {
				-- 3x3 Grid (Left)
				IngredientsGrid = e(VStack, {
					AutomaticSize = Enum.AutomaticSize.X,
					Spacing = UDim.new(0, 2),
					Size = UDim2.new(0, 0, 1, 0),
					LayoutOrder = 1,
				}, {
					Row1 = e(HStack, {
						AutomaticSize = Enum.AutomaticSize.XY,
						Spacing = UDim.new(0, mobile and 0 or 2),
						LayoutOrder = 1,
					}, {
						selectedIngredientElements[1],
						selectedIngredientElements[2],
						selectedIngredientElements[3],
					}),
					Row2 = e(HStack, {
						AutomaticSize = Enum.AutomaticSize.XY,
						Spacing = UDim.new(0, mobile and 0 or 2),
						LayoutOrder = 2,
					}, {
						selectedIngredientElements[4],
						selectedIngredientElements[5],
						selectedIngredientElements[6],
					}),
					Row3 = e(HStack, {
						AutomaticSize = Enum.AutomaticSize.XY,
						Spacing = UDim.new(0, mobile and 0 or 2),
						LayoutOrder = 3,
					}, {
						selectedIngredientElements[7],
						selectedIngredientElements[8],
						selectedIngredientElements[9],
					}),
				}),

				-- Equals Sign (Center)
				Equals = e("TextLabel", {
					Size = UDim2.new(0, mobile and 20 or 30, 0, 50),
					BackgroundTransparency = 1,
					Text = "=",
					TextColor3 = TEXT,
					TextSize = mobile and 32 or 48,
					Font = Enum.Font.FredokaOne,
					LayoutOrder = 2,
				}),

				-- Result Graphic (Right)
				ResultGraphic = e(VStack, {
					Size = mobile and UDim2.new(0, 80, 1, 0) or UDim2.new(0, 110, 1, 0),
					-- BackgroundTransparency = 0,
					LayoutOrder = 3,
					VerticalAlignment = Enum.VerticalAlignment.Top,
					VerticalFlex = "None",
				}, {
					Flare = e("ImageLabel", {
						Size = mobile and UDim2.new(0, 80, 0, 80) or UDim2.new(0, 110, 0, 110),
						BackgroundColor3 = Color3.fromRGB(30, 30, 38),
						BackgroundTransparency = 1,
						BorderSizePixel = 0,
						Image = "rbxassetid://126550182137995",
						ImageColor3 = props.locked and Color3.new(0.5, 0.5, 0.5) or Color3.new(1, 1, 1),
						ScaleType = Enum.ScaleType.Fit,
						ZIndex = 1,
						LayoutOrder = 1,
						-- Position = UDim2.new(0.5, 0, 0.5, 0),
						-- AnchorPoint = Vector2.new(0.5, 0.5),
					}, {
						UICorner = e("UICorner", { CornerRadius = UDim.new(0, 6) }),
						Image = e("ImageLabel", {
							Size = mobile and UDim2.new(0, 80, 0, 80) or UDim2.new(0, 110, 0, 110),
							BackgroundTransparency = 1,
							BorderSizePixel = 0,
							Image = props.config.Image or "",
							ImageColor3 = props.locked and Color3.new(0.5, 0.5, 0.5) or nil,
							ScaleType = Enum.ScaleType.Fit,
							ZIndex = 10,
							Position = UDim2.new(0.5, 0, 0.5, 0),
							AnchorPoint = Vector2.new(0.5, 0.5),
						}),
						e(SmallText, {
							Text = `${Mionum.new(
								(config and config.Rate or 0) * (props.variation and props.variation.Multiplier or 1)
							):toString()}/s`,
							TextXAlignment = Enum.TextXAlignment.Center,
							AnchorPoint = Vector2.new(0.5, 0),
							Position = UDim2.new(0.5, 0, 0, 12),
							BackgroundTransparency = 1,
							Size = UDim2.new(1, 0, 0, 0),
							RichText = true,
							ZIndex = 11,
							TextSize = mobile and 14 or 18,
						}),
					}),
					e(SmallText, {
						LayoutOrder = 2,
						Text = detailsLabel,
						RichText = true,
						TextSize = mobile and 14 or 18,
					}),
				}),
			}),
			InstructionLabel = e("TextLabel", {
				Size = UDim2.new(1, 0, 0, 20),
				BackgroundTransparency = 1,
				Text = config.Instruction and "How to make:" or "",
				TextColor3 = SUBTEXT,
				TextSize = mobile and 12 or 14,
				Font = Enum.Font.FredokaOne,
				TextXAlignment = Enum.TextXAlignment.Left,
				LayoutOrder = 3,
			}),
			ItemTip = not props.locked and e("TextLabel", {
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				Text = `{config.ItemTip or ""}\nPrice: {config.Price}\nMixing Duration: {config.Duration}`,
				TextColor3 = SUBTEXT,
				TextSize = mobile and 12 or 14,
				TextStrokeTransparency = 0,
				Font = Enum.Font.FredokaOne,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextWrapped = true,
				LayoutOrder = 4,
			}) or nil,
			Divider = e("Frame", {
				Size = UDim2.new(1, 0, 0, 1),
				BackgroundColor3 = Color3.fromRGB(60, 60, 75),
				BorderSizePixel = 0,
				LayoutOrder = 5,
			}),
		}),
	})
end

local function RecipePanel(props: {
	onClose: () -> (),
})
	local selected, setSelected = useState(RECIPES[1])
	local visible, setVisible = useState(false)
	local variationId, setVariationId = useState("none")
	local discoveredDrinks, setDiscoveredDrinks = useState(not player and { none = { espresso = true } } or nil)
	local drinksOfVariation: { [string]: true } = discoveredDrinks and discoveredDrinks[variationId] or {}
	local xs, sm, md, lg, xl = useBreakpoint()
	local mobile = xs or sm

	useEffect(function()
		local unsub = GlobalState:subscribe(function(state: GlobalState.GlobalState)
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
	local panelRef = useRef(nil)
	-- listen to panel
	useEffect(function()
		local unsub = UIState:subscribe(function(state: UIState.UIState)
			local isOpen = state.panel == "recipe"
			return isOpen
		end, function(isOpen)
			-- this is important, if just doing it at top, it will enable gamepadcursor everytime any under UIState changes
			if isOpen and panelRef.current then
				game:GetService("GamepadService"):EnableGamepadCursor(panelRef.current)
				-- else
				-- 	game:GetService("GamepadService"):DisableGamepadCursor()
			end
			setVisible(isOpen)
		end)
		local panel = UIState:getState().panel
		if panel then
			setVisible(panel == "recipe")
		end
		return unsub
	end, {})
	local function navigateRecipe(direction: number)
		local currentIndex = 1
		for i, recipe in ipairs(RECIPES) do
			if selected and recipe.Id == selected.Id then
				currentIndex = i
				break
			end
		end

		local newIndex = currentIndex + direction
		if newIndex > #RECIPES then
			newIndex = 1
		elseif newIndex < 1 then
			newIndex = #RECIPES
		end

		setSelected(RECIPES[newIndex])
	end

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

	local gridItems = {
		UIGridLayout = e("UIGridLayout", {
			CellSize = mobile and UDim2.new(0, 45, 0, 50) or UDim2.new(0, 70, 0, 120),
			CellPadding = UDim2.new(0, mobile and 2 or 8, 0, mobile and 2 or 8),
			SortOrder = Enum.SortOrder.LayoutOrder,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
		}),
		UIPadding = e("UIPadding", {
			PaddingLeft = UDim.new(0, mobile and 4 or 8),
			PaddingRight = UDim.new(0, mobile and 4 or 8),
			PaddingTop = UDim.new(0, mobile and 4 or 8),
			PaddingBottom = UDim.new(0, mobile and 4 or 8),
		}),
	}
	local count = 0
	for drinkId, _ in drinksOfVariation do
		count += 1
	end
	local varCount = 5
	local total = varCount * #RECIPES
	local locked = player and not (drinksOfVariation and drinksOfVariation[selected and selected.Id]) or false

	for i, config in ipairs(RECIPES) do
		gridItems["item_" .. config.Id] = e(RecipeGridItem, {
			config = config,
			isSelected = selected and selected.Id == config.Id,
			onSelect = function()
				setSelected(config)
			end,
			layoutOrder = i,
			discovered = (not player) or drinksOfVariation and drinksOfVariation[config.Id] or false,
		})
	end

	local bg = (if locked then ITEM_BG_LOCKED else Color3.new(0.980392, 0.341176, 0.145098))

	local buttons = {}
	for variationId, variation in VariationsConfig do
		buttons[variationId] = e(SmallButton, {
			LayoutOrder = variation.Multiplier,
			BackgroundColor3 = variationId ~= "none" and variation.ColorPrimary
				or Color3.new(0.768627, 0.549019, 0.549019),
			Image = variation.Image,
			[React.Event.Activated] = function()
				setVariationId(variationId)
			end,
			Size = UDim2.new(1, 0, 0, 32),
			AutomaticSize = Enum.AutomaticSize.None,
		}, {
			e(SmallText, {
				Text = variation.DisplayName,
				TextSize = 14,
				TextWrapped = true,
				Size = UDim2.new(1, 0, 0, 28),
			}),
		})
	end
	local variation = VariationsConfig[variationId]

	return e("ImageLabel", {
		Size = UDim2.new(0.8, -48, 1, -48),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = position:map(function(n)
			return UDim2.new(0.5 + n, 0, 0.5 + 0, 0)
		end),
		ZIndex = 20,

		BackgroundColor3 = PANEL_BG,
		BackgroundTransparency = 1,
		Image = "rbxassetid://127657596958436",
		ImageColor3 = variation and variation.VariationId ~= "none" and variation.ColorPrimary
			or Color3.new(0.768627, 0.549019, 0.549019),
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(8, 8, 92, 92),
		BorderSizePixel = 0,
	}, {
		UIAspectRatioConstraint = e("UIAspectRatioConstraint", {
			AspectRatio = 1.5,
		}),
		UISizeConstraint = e("UISizeConstraint", {
			MaxSize = Vector2.new(1000, 1000),
		}),
		buttons = e(VStack, {
			AutomaticSize = Enum.AutomaticSize.None,
			AnchorPoint = Vector2.new(1, 0),
			Spacing = UDim.new(0, 8),
			Size = UDim2.new(0, 80, 0, 0),
			VerticalFlex = Enum.UIFlexAlignment.None,
		}, buttons),
		-- Centered container
		Container = e("Frame", {
			Size = UDim2.new(1, -0, 1, -0),
			-- Size = UDim2.new(0, 720, 0, 440),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			BackgroundColor3 = BG,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ref = panelRef,
		}, {
			UICorner = e("UICorner", { CornerRadius = UDim.new(0, 12) }),

			-- Header
			Header = e("Frame", {
				Size = UDim2.new(1, 0, 0, (mobile and 24 or 48)),
				BackgroundColor3 = PANEL_BG,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				ZIndex = 2,
			}, {
				UICorner = e("UICorner", { CornerRadius = UDim.new(0, 12) }),
				-- Bottom fill to hide bottom corner rounding
				BottomFill = e("Frame", {
					Size = UDim2.new(1, 0, 0, 12),
					Position = UDim2.new(0, 0, 1, -12),
					BackgroundColor3 = PANEL_BG,
					BorderSizePixel = 0,
					BackgroundTransparency = 1,
				}),
				Title = e("TextLabel", {
					Size = UDim2.new(1, -56, 1, 0),
					Position = UDim2.new(0, 16, 0, 0),
					BackgroundTransparency = 1,
					Text = `Recipe Mastery Book ({count}/{#RECIPES})`,
					TextColor3 = ACCENT,
					TextSize = 20,
					Font = Enum.Font.FredokaOne,
					TextXAlignment = Enum.TextXAlignment.Left,
				}),
				CloseBtn = e("TextButton", {
					Size = UDim2.new(0, 32, 0, 32),
					Position = UDim2.new(1, -40, 0.5, 0),
					AnchorPoint = Vector2.new(0, 0.5),
					BackgroundColor3 = Color3.fromRGB(80, 40, 40),
					BorderSizePixel = 0,
					Text = "X",
					TextColor3 = Color3.fromRGB(255, 120, 120),
					TextSize = 16,
					Font = Enum.Font.FredokaOne,
					[React.Event.MouseButton1Click] = props.OnClose,
				}, {
					UICorner = e("UICorner", { CornerRadius = UDim.new(0, 6) }),
				}),
			}),

			-- Body
			Body = e(HStack, {
				Size = UDim2.new(1, 0, 1, -(mobile and 24 or 48)),
				Position = UDim2.new(0, 0, 0, (mobile and 24 or 48)),
				BackgroundTransparency = 1,
			}, {
				-- Left grid
				GridPanel = e("ImageLabel", {
					Size = UDim2.new(0.5, 0, 1, 0),
					-- Size = UDim2.new(1, 0, 1, 0),
					BackgroundColor3 = PANEL_BG,
					BackgroundTransparency = 1,
					-- Image = "rbxassetid://127657596958436",
					-- ImageColor3 = Color3.new(0.768627, 0.549019, 0.549019),
					-- ImageColor3 = PANEL_BG,
					ScaleType = Enum.ScaleType.Slice,
					SliceCenter = Rect.new(8, 8, 92, 92),
					BorderSizePixel = 0,
				}, {
					-- UICorner = e("UICorner", { CornerRadius = UDim.new(0, 10) }),
					-- Top fill for flat top
					-- TopFill = e("Frame", {
					-- 	Size = UDim2.new(1, 0, 0, 10),
					-- 	BackgroundColor3 = PANEL_BG,
					-- 	BackgroundTransparency = 1,
					-- 	BorderSizePixel = 0,
					-- }),
					padding = e("UIPadding", {
						PaddingLeft = UDim.new(0, mobile and 2 or 6),
						PaddingRight = UDim.new(0, mobile and 2 or 6),
						PaddingTop = UDim.new(0, mobile and 2 or 6),
						PaddingBottom = UDim.new(0, mobile and 2 or 12),
					}),
					ScrollFrame = e("ScrollingFrame", {
						Size = UDim2.new(1, -0, 1, -0),
						Position = UDim2.new(0, 0, 0, 0),
						BackgroundTransparency = 1,
						BorderSizePixel = 0,
						ScrollBarThickness = 4,
						ScrollBarImageColor3 = Color3.fromRGB(80, 80, 100),
						CanvasSize = UDim2.new(0, 0, 0, 0),
						AutomaticCanvasSize = Enum.AutomaticSize.Y,
					}, gridItems),
				}),

				-- Right detail
				Holder = e("Frame", {
					Size = UDim2.new(0.5, 0, 1, 0),
					Position = UDim2.new(0, 328, 0, 0),
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
				}, {
					padding = e("UIPadding", {
						PaddingLeft = UDim.new(0, mobile and 4 or 6),
						PaddingRight = UDim.new(0, mobile and 4 or 6),
						PaddingTop = UDim.new(0, mobile and 4 or 6),
						PaddingBottom = UDim.new(0, mobile and 4 or 12),
					}),
					DetailPanel = e("ImageLabel", {
						Size = UDim2.new(1, 0, 1, 0),
						BackgroundTransparency = 1,

						BackgroundColor3 = PANEL_BG,
						Image = "rbxassetid://127657596958436",
						ImageColor3 = bg, --Color3.new(0.505882, 0.254901, 0.254901),
						-- ImageColor3 = PANEL_BG,
						ScaleType = Enum.ScaleType.Slice,
						SliceCenter = Rect.new(8, 8, 92, 92),
						BorderSizePixel = 0,
					}, {
						if selected
							then e(RecipeDetail, {
								locked = locked,
								variation = VariationsConfig[variationId],
								config = selected,
								onNext = function()
									navigateRecipe(1)
								end,
								onPrev = function()
									navigateRecipe(-1)
								end,
							})
							else nil,
					}),
				}),
			}),
		}),
	})
end

return RecipePanel
