-- Shared/ReactComponents/IngredientShopPanel.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local e = React.createElement
local useState = React.useState
local useBinding = React.useBinding
local useRef = React.useRef
local useEffect = React.useEffect
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local CoffeeModule = require(ReplicatedStorage.Shared.CoffeeModule)
local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local VariationsConfig = require(ReplicatedStorage.Shared.Configs.VariationsConfig)

local Primitives = ReplicatedStorage.Shared.ReactComponents.ui
local DefaultPanel = require(script.Parent.DefaultPanel)
local DefaultScrollFrame = require(script.Parent.DefaultScrollFrame)
local SmallButton = require(Primitives.SmallButton)
local SmallText = require(Primitives.SmallText)
local VStack = require(Primitives.VStack)
local HStack = require(Primitives.HStack)

local player = game.Players.LocalPlayer
local playerId = player and tostring(player.UserId) or ""
local function IngredientShopPanel(props: {})
	local discoveredDrinks, setDiscoveredDrinks = useState((not player) and {})
	local activeDrinks, setActiveDrinks = useState({})
	local t, setT = useBinding(tick())

	useEffect(function()
		local unsub = GlobalState:subscribe(function(state: GlobalState.GlobalState)
			return state.DiscoveredDrinks[playerId]
		end, function(dd)
			setDiscoveredDrinks(dd)
		end)
		local state = GlobalState:getState()
		local dd = state.DiscoveredDrinks[playerId]
		setDiscoveredDrinks(dd or {})
		if not player then
			task.delay(1, function()
				setDiscoveredDrinks(function(prev)
					local clone = table.clone(prev)
					clone.double = {}
					clone.double.americano = true
					return clone
				end)
				task.delay(1, function()
					setDiscoveredDrinks(function(prev)
						local clone = table.clone(prev)
						clone.starlight = {}
						clone.starlight.latte = true
						return clone
					end)
				end)
			end)
		end

		local timer = task.spawn(function()
			while task.wait() do
				setT(tick())
			end
		end)
		return function()
			unsub()
			task.cancel(timer)
		end
	end, {})

	local prevDrinkRef = useRef(nil)
	useEffect(function()
		if not discoveredDrinks then
			return
		end
		if not prevDrinkRef.current then
			prevDrinkRef.current = discoveredDrinks
			return
		end
		for variationId, drinksOfVariation in discoveredDrinks do
			if not prevDrinkRef.current[variationId] then
				prevDrinkRef.current[variationId] = {}
			end

			for drinkId, _ in drinksOfVariation do
				if prevDrinkRef.current[variationId][drinkId] then
					continue
				end
				prevDrinkRef.current[variationId][drinkId] = true
				local id = (tick())
				setActiveDrinks(function(prev)
					-- local clone = table.clone(prev)
					-- table.insert(clone, {
					-- 	id = tostring(id),
					-- 	drinkId = drinkId,
					-- 	StartTime = id,
					-- })
					-- props.closeAllPanels()
					return {
						{
							id = tostring(id),
							variationId = variationId,
							drinkId = drinkId,
							StartTime = id,
						},
					}
				end)
				break
			end
		end
		return
	end, { discoveredDrinks })

	local children = {}

	for i, drink in activeDrinks do
		local config = CoffeeModule.Config[drink.drinkId]
		local variation = drink.variationId and VariationsConfig[drink.variationId] or nil
		local textSizeMap = function(n)
			local start = math.min(1, (n - drink.StartTime))
			start = 1 - ((1 - start) ^ 10)
			return start * 32
		end
		local transMap = function(n)
			local start = math.min(1, (n - drink.StartTime))
			start = 1 - ((1 - start) ^ 10)
			return start
		end
		local ColorGradient = variation
				and ColorSequence.new({
					ColorSequenceKeypoint.new(0, variation.ColorPrimary),
					ColorSequenceKeypoint.new(0.22, variation.ColorPrimary),
					ColorSequenceKeypoint.new(0.255, Color3.new(1, 1, 1)),
					ColorSequenceKeypoint.new(0.3, Color3.new(1, 1, 1)),
					ColorSequenceKeypoint.new(0.35, variation.ColorPrimary),
					ColorSequenceKeypoint.new(0.399, variation.ColorPrimary),
					ColorSequenceKeypoint.new(0.4, Color3.new(1, 1, 1)),
					ColorSequenceKeypoint.new(0.6, Color3.new(1, 1, 1)),
					ColorSequenceKeypoint.new(0.601, variation.ColorPrimary),
					ColorSequenceKeypoint.new(0.62, variation.ColorPrimary),
					ColorSequenceKeypoint.new(0.655, Color3.new(1, 1, 1)),
					ColorSequenceKeypoint.new(0.7, Color3.new(1, 1, 1)),
					ColorSequenceKeypoint.new(0.9, variation.ColorPrimary),
					ColorSequenceKeypoint.new(1, variation.ColorPrimary),
				})
			or nil
		children[drink.id] = e("ImageButton", {
			AutomaticSize = Enum.AutomaticSize.None,
			[React.Event.Activated] = function()
				task.spawn(function()
					setActiveDrinks(function(prev)
						local clone = table.clone(prev)
						index = i
						for i, activeDrink in clone do
							if activeDrink.id ~= drink.id then
								continue
							end
							index = i
						end
						if not index then
							return prev
						end
						table.remove(clone, index)
						return clone
					end)
					-- 	return -- just remove immediately
				end)
			end,
			Image = config.Image,
			LayoutOrder = i,
			BackgroundTransparency = 0.9,
			-- Size = t:map(function(n)
			-- 	local start = math.min(1, (n - drink.StartTime))
			-- 	local End = drink.EndTime and math.min(1, (drink.EndTime - n + 1))
			-- 	return drink.EndTime and UDim2.new(0, End * 200, 0, End * 200)
			-- 		or UDim2.new(0, start * 200, 0, start * 200)
			-- end),

			SizeConstraint = Enum.SizeConstraint.RelativeXX,
			-- ImageColor3 = Color3.new(1, 0, 0),
		}, {
			UICorner = e("UICorner", {
				CornerRadius = UDim.new(1, 0),
			}),
			DrinkImage = e("ImageLabel", {
				ZIndex = 3,
				AutomaticSize = Enum.AutomaticSize.None,
				Active = false,
				Image = config.Image,
				LayoutOrder = i,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0.5, 0, 0.5, 0),
				BackgroundTransparency = 1,
				Size = t:map(function(n)
					local start = math.min(1, (n - drink.StartTime))
					start = 1 - ((1 - start) ^ 10)
					local End = drink.EndTime and math.min(1, (drink.EndTime - n + 1))
					return drink.EndTime and UDim2.new(0, End * 300, 0, End * 300)
						or UDim2.new(0, start * 300, 0, start * 300)
				end),
				SizeConstraint = Enum.SizeConstraint.RelativeXX,
				-- ImageColor3 = Color3.new(1, 0, 0),
			}, {}),
			flare1 = e("ImageLabel", {
				Image = "rbxassetid://12386383371",

				Size = t:map(function(n)
					-- local start = (n - drink.StartTime)
					-- local End = drink.EndTime and math.min(1, (drink.EndTime - n + 1))
					-- return drink.EndTime and UDim2.new(0, End * 400, 0, End * 400)
					-- 	or UDim2.new(0, start * 400, 0, start * 400)
					local s = math.max(0, math.tan(5 / 4 * n + drink.StartTime))
					return UDim2.new(0, s * 400, 0, s * 400)
				end),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0.5, 0, 0.5, 0),
				Active = false,
				BackgroundTransparency = 1,
				Rotation = t:map(function(n)
					return (n * 90) % 360
				end),
				ImageTransparency = t:map(function(n)
					return math.cos(2 * n + 1 + math.pi / 4) ^ 2
				end),
				ZIndex = 2,
			}),
			flare2 = e("ImageLabel", {
				Image = "rbxassetid://12386392796",

				-- Size = UDim2.new(0, 400, 0, 400),
				Size = t:map(function(n)
					-- local start = (n - drink.StartTime)
					-- local End = drink.EndTime and math.min(1, (drink.EndTime - n + 1))
					-- return drink.EndTime and UDim2.new(0, End * 400, 0, End * 400)
					-- 	or UDim2.new(0, start * 400, 0, start * 400)

					-- local s = math.max(0, math.tan(5 / 4 * n + drink.StartTime + math.pi / 4))
					local s = math.cos(2 * n + 1 + math.pi / 4) ^ 2 + 0.5

					return UDim2.new(0, s * 400, 0, s * 400)
				end),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0.5, 0, 0.5, 0),
				Active = false,
				ImageColor3 = Color3.new(1, 1, 0),
				BackgroundTransparency = 1,
				Rotation = t:map(function(n)
					return (math.cos(2 * n + 1 + math.pi / 4) ^ 2 * 90) % 360
				end),
				ImageTransparency = t:map(function(n)
					return math.cos(2 * n + 1 + math.pi / 4) ^ 2
				end),
				ZIndex = 1,
			}),
			e(SmallText, {
				Text = `<font size="32">{CoffeeModule.Config[drink.drinkId].DisplayName}</font>`,
				TextSize = t:map(textSizeMap),
				RichText = true,
				TextTransparency = t:map(function(n)
					local start = math.min(1, (n - drink.StartTime))
					local End = drink.EndTime and math.min(1, (drink.EndTime - n + 1))
					return drink.EndTime and start or End
				end),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0.5, 0, 0.5, 0),
				ZIndex = 5,
			}),
			e(SmallText, {
				TextXAlignment = Enum.TextXAlignment.Center,
				-- BackgroundTransparency = 0,
				Text = variation and variation.VariationId ~= "none" and variation.DisplayName or "",
				TextColor3 = variation and variation.ColorPrimary or Color3.new(1, 1, 1),
				TextSize = t:map(textSizeMap),
				LayoutOrder = 2,
				Active = false,
				TextTransparency = t:map(function(n)
					local start = math.min(1, (n - drink.StartTime))
					local End = drink.EndTime and math.min(1, (drink.EndTime - n + 1))
					return drink.EndTime and start or End
				end),
				ZIndex = 20,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0.5, 0, 0.5, 40),
			}, {
				UIStroke = e("UIStroke", {
					Thickness = 4,
					Color = Color3.new(0.070588, 0.070588, 0.168627),
				}, {

					UIGradient = e("UIGradient", {
						Color = ColorGradient,
						Rotation = 78,
					}),
				}),
				UIGradient = e("UIGradient", {
					Color = ColorGradient,
					Rotation = 69,
				}),
				UIPadding = e("UIPadding", {
					PaddingTop = UDim.new(0, 4),
					PaddingBottom = UDim.new(0, 4),
					PaddingLeft = UDim.new(0, 4),
					PaddingRight = UDim.new(0, 4),
				}),
			}),
		})
	end
	-- useEffect(function()
	-- warn("dds", discoveredDrinks)
	-- end, { discoveredDrinks })
	-- useEffect(function()
	-- warn("activedds", activeDrinks)
	-- end, { activeDrinks })
	local isactive = activeDrinks and type(activeDrinks) == "table" and #activeDrinks > 0
	return isactive
		and e("ScreenGui", {
			ResetOnSpawn = false,
			IgnoreGuiInset = true,
			ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
			DisplayOrder = 100,
		}, {
			e("TextButton", {
				Size = UDim2.new(1, 0, 1, 0),
				Text = "",
				BackgroundTransparency = 0.6,
				BackgroundColor3 = Color3.new(0, 0, 0),
				[React.Event.Activated] = function()
					setActiveDrinks(function(prev)
						local clone = table.clone(prev)
						table.remove(clone, 1)
						return clone
					end)
				end,
			}, {
				e(SmallText, {
					Text = "You Discovered a New Drink Variation!",
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.new(0.5, 0, 0.5, -150),
				}),
				e(HStack, {
					Size = UDim2.new(0.5, 0, 0.5, 0),
					-- MinSize = Vector2.new(500, 320),
					-- MaxSize = Vector2.new(500, 500),
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.new(0.5, 0, 0.5, 0),
					-- OnClose = props.OnClose,
					BackgroundTransparency = 1,
					VerticalFlex = Enum.UIFlexAlignment.None,
					HorizontalFlex = Enum.UIFlexAlignment.None,
					HorizontalAlignment = Enum.HorizontalAlignment.Center,
					-- BackgroundImage = "",
					-- BackgroundTransparency = 0,
				}, children),
			}),
		})
end

return IngredientShopPanel
