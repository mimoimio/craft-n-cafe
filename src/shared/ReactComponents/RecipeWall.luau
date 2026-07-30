local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local React = require(ReplicatedStorage.Packages.React)
local Promise = require(ReplicatedStorage.Packages.Promise)
local ReactRoblox = require(ReplicatedStorage.Packages.ReactRoblox)
local CoffeeConfigArray = require(ReplicatedStorage.Shared.Configs.CoffeeConfig)
local CoffeeModule = require(ReplicatedStorage.Shared.CoffeeModule)
local HStack = require(ReplicatedStorage.Shared.ReactComponents.ui.HStack)
local VStack = require(ReplicatedStorage.Shared.ReactComponents.ui.VStack)
local SmallButton = require(ReplicatedStorage.Shared.ReactComponents.ui.SmallButton)
local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local VariationsConfig = require(ReplicatedStorage.Shared.Configs.VariationsConfig)
local CafeTypes = require(ReplicatedStorage.Shared.CafeTypes)
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
	config: any,
	isSelected: boolean,
	onSelect: () -> (),
	layoutOrder: number,
})
	local hovered, setHovered = useState(false)
	local locked = not props.discovered
	-- useEffect(function()
	-- warn(hovered)
	-- end, { hovered })

	local bg = if props.isSelected
		then (if locked then ITEM_BG_LOCKED_SELECTED else ITEM_SELECTED_BG)
		elseif hovered then (if locked then Color3.new(0.5, 0.5, 0.5) else Color3.new(1, 0.956862, 0.901960))
		else (if locked then ITEM_BG_LOCKED else ITEM_BG)
	return e("ImageLabel", {
		-- return e("ImageButton", {
		Size = UDim2.new(0, 90, 0, 110),
		BackgroundColor3 = bg,
		BorderSizePixel = 0,
		Image = "rbxassetid://103478691850846",
		-- AutoButtonColor = true,
		-- Text = "",
		ImageColor3 = bg,
		LayoutOrder = props.layoutOrder,
		-- [React.Event.MouseEnter] = function(...)
		-- 	setHovered(true)
		-- end,
		-- [React.Event.MouseLeave] = function(...)
		-- 	setHovered(false)
		-- end,
		-- [React.Event.MouseButton1Click] = function(...)
		-- 	props.onSelect()
		-- end,
	}, {
		UICorner = e("UICorner", { CornerRadius = UDim.new(0, 8) }),
		UIPadding = e("UIPadding", {
			PaddingLeft = UDim.new(0, 6),
			PaddingRight = UDim.new(0, 6),
			PaddingTop = UDim.new(0, 6),
			PaddingBottom = UDim.new(0, 12),
		}),
		Image = e("ImageLabel", {
			Size = UDim2.new(0, 70, 0, 70),
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
		}),
		Label = e("TextLabel", {

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
		}),
	})
end

local variationOrder = {
	"none",
	"double",
	"gold",
	"diamond",
	"starlight",
}

-- local IsEdit = RunService:IsStudio() and not RunService:IsRunMode()

local function RecipeWall(props: {
	PlayerId: string,
	CafeModel: CafeTypes.Cafe,
})
	local selected, setSelected = useState(RECIPES[1])
	local variationId, setVariationId = useState("none")
	local playerId = props.PlayerId
	local discoveredDrinks, setDiscoveredDrinks = useState(IsEdit and { none = { espresso = true } } or nil)
	local drinksOfVariation: { [string]: true } = discoveredDrinks and discoveredDrinks[variationId] or {}

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

	local gridItems = {
		UIGridLayout = e("UIGridLayout", {
			CellSize = UDim2.new(0, 70, 0, 120),
			CellPadding = UDim2.new(0, 8, 0, 8),
			SortOrder = Enum.SortOrder.LayoutOrder,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
		}),
		UIPadding = e("UIPadding", {
			PaddingLeft = UDim.new(0, 8),
			PaddingRight = UDim.new(0, 8 + 32),
			PaddingTop = UDim.new(0, 8),
			PaddingBottom = UDim.new(0, 8),
		}),
	}
	local count = 0
	for drinkId, _ in drinksOfVariation do
		count += 1
	end
	local locked = false
	for i, variation in variationOrder do
		locked = locked or drinksOfVariation[variation]
		if not locked then
			break
		end
	end

	for i, config in ipairs(RECIPES) do
		local discovered

		if discoveredDrinks then
			for i, vId in variationOrder do
				if not discoveredDrinks[vId] then
					continue
				end
				discovered = discoveredDrinks[vId][config.Id] and true or false
				if discovered then
					break
				end
			end
		end
		gridItems["item_" .. config.Id] = e(RecipeGridItem, {
			config = config,
			isSelected = selected and selected.Id == config.Id,
			onSelect = function()
				setSelected(config)
			end,
			layoutOrder = i,
			discovered = discovered,
		})
	end
	local bg = (if locked then ITEM_BG_LOCKED else Color3.new(0.980392, 0.341176, 0.145098))

	-- local buttons = {}
	-- for variationId, variation in VariationsConfig do
	-- 	buttons[variationId] = e(SmallButton, {
	-- 		LayoutOrder = variation.Multiplier,
	-- 		OverlayText = variation.DisplayName,
	-- 		BackgroundColor3 = variationId ~= "none" and variation.ColorPrimary
	-- 			or Color3.new(0.768627, 0.549019, 0.549019),
	-- 		Image = variation.Image,
	-- 		[React.Event.Activated] = function()
	-- 			setVariationId(variationId)
	-- 		end,
	-- 	})
	-- end
	local variation = VariationsConfig[variationId]

	local adornee, setAdornee = useState(nil)
	useEffect(function()
		if not props.CafeModel then
			return
		end
		local promise = Promise.defer(function(resolve, reject)
			return resolve(props.CafeModel:WaitForChild("RecipeWall"):WaitForChild("Part"))
		end)
		promise
			:andThen(function(Part)
				setAdornee(Part)
			end)
			:catch(function(err)
				warn(err)
			end)
		return function()
			promise:cancel()
		end
	end, { props.CafeModel })
	return adornee
		and ReactRoblox.createPortal({
			e("SurfaceGui", {
				Adornee = adornee,
				CanvasSize = Vector2.new(2400 * (1 / 3), 1800 * (1 / 3)),
				ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
			}, {
				e("ImageLabel", {
					Size = UDim2.new(1, -0, 1, -0),
					-- BackgroundColor3 = Color3.fromRGB(255, 196, 162),
					-- BackgroundTransparency = 0.1,
					-- AnchorPoint = Vector2.new(0.5, 0.5),
					-- Position = UDim2.new(0.5, 0, 0.5, 0),
					-- Position = position:map(function(n)
					-- 	return UDim2.new(0.5 + n, 0, 0.5 + 0, 0)
					-- end),
					-- BorderSizePixel = 0,
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
					-- buttons = e(VStack, {
					-- 	AutomaticSize = Enum.AutomaticSize.XY,
					-- 	AnchorPoint = Vector2.new(1, 0),
					-- 	Spacing = UDim.new(0, 8),
					-- 	Size = UDim2.new(0, 80, 0, 0),
					-- }, buttons),
					-- Centered container
					Container = e("Frame", {
						Size = UDim2.new(1, 0, 1, 0),
						-- Size = UDim2.new(0, 720, 0, 440),
						AnchorPoint = Vector2.new(0.5, 0.5),
						Position = UDim2.new(0.5, 0, 0.5, 0),
						BackgroundColor3 = BG,
						BackgroundTransparency = 1,
						BorderSizePixel = 0,
					}, {
						UICorner = e("UICorner", { CornerRadius = UDim.new(0, 12) }),

						-- Header
						Header = e("Frame", {
							Size = UDim2.new(1, 0, 0, 48),
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
							-- CloseBtn = e("TextButton", {
							-- 	Size = UDim2.new(0, 32, 0, 32),
							-- 	Position = UDim2.new(1, -40, 0.5, 0),
							-- 	AnchorPoint = Vector2.new(0, 0.5),
							-- 	BackgroundColor3 = Color3.fromRGB(80, 40, 40),
							-- 	BorderSizePixel = 0,
							-- 	Text = "X",
							-- 	TextColor3 = Color3.fromRGB(255, 120, 120),
							-- 	TextSize = 16,
							-- 	Font = Enum.Font.FredokaOne,
							-- 	[React.Event.MouseButton1Click] = props.OnClose,
							-- }, {
							-- 	UICorner = e("UICorner", { CornerRadius = UDim.new(0, 6) }),
							-- }),
						}),

						-- Body
						Body = e(HStack, {
							Size = UDim2.new(1, 0, 1, -48),
							Position = UDim2.new(0, 0, 0, 48),
							BackgroundTransparency = 1,
						}, {
							-- Left grid
							GridPanel = e("ImageLabel", {
								Size = UDim2.new(1, 0, 1, 0),
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
								TopFill = e("Frame", {
									Size = UDim2.new(1, 0, 0, 10),
									BackgroundColor3 = PANEL_BG,
									BackgroundTransparency = 1,
									BorderSizePixel = 0,
								}),
								ScrollFrame = e("ScrollingFrame", {
									Size = UDim2.new(1, -8, 1, -8),
									Position = UDim2.new(0, 4, 0, 8),
									BackgroundTransparency = 1,
									BorderSizePixel = 0,
									ScrollBarThickness = 32,
									ScrollBarImageColor3 = Color3.fromRGB(80, 80, 100),
									CanvasSize = UDim2.new(0, 0, 0, 0),
									AutomaticCanvasSize = Enum.AutomaticSize.Y,
								}, gridItems),
							}),
						}),
					}),
				}),
			}),
		}, adornee)
end

return RecipeWall
