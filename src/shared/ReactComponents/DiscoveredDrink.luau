-- Shared/ReactComponents/DiscoveredDrink.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local GamepadService = game:GetService("GamepadService")
local GuiService = game:GetService("GuiService")

local React = require(ReplicatedStorage.Packages.React)
local e = React.createElement
local useState = React.useState
local useBinding = React.useBinding
local useRef = React.useRef
local useEffect = React.useEffect
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local SoundController = require(ReplicatedStorage.Shared.Controllers.SoundController)
local CoffeeModule = require(ReplicatedStorage.Shared.CoffeeModule)
local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local VariationsConfig = require(ReplicatedStorage.Shared.Configs.VariationsConfig)

local useInputDevice = require(ReplicatedStorage.Shared.Hooks.useInputDevice)
local BuildersIcon = require(ReplicatedStorage.Shared.Utils.BuildersIcon)

local RECIPES = CoffeeModule.Array
local variationCount = 0
for i, variation in VariationsConfig do
	variationCount += 1
end

local Primitives = ReplicatedStorage.Shared.ReactComponents.ui
local DefaultPanel = require(script.Parent.DefaultPanel)
local DefaultScrollFrame = require(script.Parent.DefaultScrollFrame)
local SmallButton = require(Primitives.SmallButton)
local SmallText = require(Primitives.SmallText)
local VStack = require(Primitives.VStack)
local HStack = require(Primitives.HStack)

local player = game.Players.LocalPlayer
local playerId = player and tostring(player.UserId) or ""

-- ====================================================================
-- ANIMATION MAPPERS & UTILS
-- ====================================================================
local function getEaseOutProgress(t_current: number, startTime: number): number
	local elapsed = math.min(1, t_current - startTime)
	return 1 - ((1 - elapsed) ^ 10)
end

local function mapSizeUDim2(startTime: number, size: UDim2)
	return function(n: number)
		local progress = getEaseOutProgress(n, startTime)
		return UDim2.new(
			progress * size.X.Scale,
			progress * size.X.Offset,
			progress * size.Y.Scale,
			progress * size.Y.Offset
		)
	end
end

local function mapSize(startTime: number, maxPx: number)
	return function(n: number)
		local progress = getEaseOutProgress(n, startTime)
		return UDim2.new(0, progress * maxPx, 0, progress * maxPx)
	end
end

local function mapTextSize(startTime: number, maxTextSize: number)
	return function(n: number)
		local progress = getEaseOutProgress(n, startTime)
		return progress * maxTextSize
	end
end

local function mapFadeIn(startTime: number)
	return function(n: number)
		local progress = math.min(1, (n - startTime))
		return 1 - progress -- 1 (transparent) to 0 (opaque)
	end
end

local function mapFlare1Size(startTime: number)
	return function(n: number)
		local s = math.max(0, math.tan(5 / 4 * n + startTime))
		return UDim2.new(0, s * 400, 0, s * 400)
	end
end

local function mapFlare2Size()
	return function(n: number)
		local s = math.cos(2 * n + 1 + math.pi / 4) ^ 2 + 0.5
		return UDim2.new(0, s * 400, 0, s * 400)
	end
end

local function mapFlare1Rotation()
	return function(n: number)
		return (n * 90) % 360
	end
end

local function mapFlare2Rotation()
	return function(n: number)
		return (math.cos(2 * n + 1 + math.pi / 4) ^ 2 * 90) % 360
	end
end

local function mapFlareTransparency()
	return function(n: number)
		return math.cos(2 * n + 1 + math.pi / 4) ^ 2
	end
end

local function getVariationGradient(variation: any)
	if not variation then
		return nil
	end
	return ColorSequence.new({
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
end

-- ====================================================================
-- COMPONENT
-- ====================================================================
local function DiscoveredDrink(props: {})
	local currentInput = useInputDevice()

	local discoveredDrinks, setDiscoveredDrinks = useState(nil)
	local activeDrink, setActiveDrink = useState(nil)
	local t, setT = useBinding(tick())

	useEffect(function()
		local unsub = GlobalState:subscribe(function(state: GlobalState.GlobalState)
			return state.DiscoveredDrinks[playerId]
		end, function(dd)
			setDiscoveredDrinks(dd)
		end)

		setDiscoveredDrinks(GlobalState:getState().DiscoveredDrinks[playerId])

		if not player then
			task.delay(1, function()
				warn("bruh")
				setDiscoveredDrinks(function(prev)
					local clone = prev and table.clone(prev) or {}
					warn(clone)
					clone.double = clone.double or {}
					clone.double.americano = true
					return clone
				end)
				task.delay(1, function()
					setDiscoveredDrinks(function(prev)
						local clone = prev and table.clone(prev) or {}
						clone.starlight = clone.starlight or {}
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
			local clone = {}
			for varId, drinks in discoveredDrinks do
				clone[varId] = table.clone(drinks)
			end
			prevDrinkRef.current = clone
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
				local id = tick()
				setActiveDrink({
					id = tostring(id),
					variationId = variationId,
					drinkId = drinkId,
					StartTime = id,
				})

				SoundController.Sound("fanfare")

				return -- Break out immediately, only queue one drink
			end
		end
	end, { discoveredDrinks })

	local setGamepadFocus = React.useCallback(function(rbx)
		xpcall(function()
			if rbx and rbx.Parent and rbx.Visible then
				GuiService.SelectedObject = rbx
				return
			end
			GuiService.SelectedObject = nil
		end, function(err)
			warn(`SelectedObject Error ({rbx}): {err}`)
		end)
	end, {})

	-- If there's no active drink, render nothing.
	if not activeDrink then
		return nil
	end

	local config = CoffeeModule.Config[activeDrink.drinkId]
	local variation = activeDrink.variationId and VariationsConfig[activeDrink.variationId] or nil
	local colorGradient = getVariationGradient(variation)
	local startTime = activeDrink.StartTime
	local count = 0

	for i, variation in VariationsConfig do
		for _drinkId, _ in discoveredDrinks[variation.VariationId] or {} do
			count += 1
		end
	end

	-- Dynamically formulate the dismissal text based on the active device
	local dismissText = "OK"
	if currentInput == "Gamepad" then
		-- Using ButtonA here since GuiService relies on A to activate the SelectedObject
		dismissText = `{BuildersIcon.GetPromptText(Enum.KeyCode.ButtonA, currentInput)} OK`
	end

	-- We use useCallback so React doesn't recreate this function on every render,
	-- which would cause it to set GuiService.SelectedObject repeatedly.

	return e("ScreenGui", {
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
				setActiveDrink(nil)
			end,
		}, {
			e(SmallText, {
				Text = `You Discovered a New Drink Variation! ({count}/{#RECIPES * variationCount})`,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0.5, 0, 0.5, -150),
			}),

			e("ImageLabel", {
				AutomaticSize = Enum.AutomaticSize.None,
				Image = config.Image,
				BackgroundTransparency = 0.9,
				SizeConstraint = Enum.SizeConstraint.RelativeXX,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0.5, 0, 0.5, 0),
			}, {
				UICorner = e("UICorner", {
					CornerRadius = UDim.new(1, 0),
				}),
				DrinkImage = e("ImageLabel", {
					ZIndex = 3,
					AutomaticSize = Enum.AutomaticSize.None,
					Active = false,
					Image = config.Image,
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.new(0.5, 0, 0.5, 0),
					BackgroundTransparency = 1,
					Size = t:map(mapSize(startTime, 300)),
					SizeConstraint = Enum.SizeConstraint.RelativeXX,
				}),
				flare1 = e("ImageLabel", {
					Image = "rbxassetid://12386383371",
					Size = t:map(mapFlare1Size(startTime)),
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.new(0.5, 0, 0.5, 0),
					Active = false,
					BackgroundTransparency = 1,
					Rotation = t:map(mapFlare1Rotation()),
					ImageTransparency = t:map(mapFlareTransparency()),
					ZIndex = 2,
				}),
				flare2 = e("ImageLabel", {
					Image = "rbxassetid://12386392796",
					Size = t:map(mapFlare2Size()),
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.new(0.5, 0, 0.5, 0),
					Active = false,
					ImageColor3 = Color3.new(1, 1, 0),
					BackgroundTransparency = 1,
					Rotation = t:map(mapFlare2Rotation()),
					ImageTransparency = t:map(mapFlareTransparency()),
					ZIndex = 1,
				}),
				DrinkNameText = e(SmallText, {
					Text = `<font size="32">{config.DisplayName}</font>`,
					TextSize = t:map(mapTextSize(startTime, 32)),
					RichText = true,
					TextTransparency = t:map(mapFadeIn(startTime)),
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.new(0.5, 0, 0.5, 0),
					ZIndex = 5,
				}),
				VariationNameText = e(SmallText, {
					TextXAlignment = Enum.TextXAlignment.Center,
					Text = (variation and variation.VariationId ~= "none") and variation.DisplayName or "",
					TextColor3 = variation and variation.ColorPrimary or Color3.new(1, 1, 1),
					TextSize = t:map(mapTextSize(startTime, 32)),
					Active = false,
					TextTransparency = t:map(mapFadeIn(startTime)),
					ZIndex = 20,
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.new(0.5, 0, 0.5, 40),
				}, {
					UIStroke = e("UIStroke", {
						Thickness = 4,
						Color = Color3.new(0.070588, 0.070588, 0.168627),
					}, {
						UIGradient = e("UIGradient", {
							Color = colorGradient,
							Rotation = 78,
						}),
					}),
					UIGradient = e("UIGradient", {
						Color = colorGradient,
						Rotation = 69,
					}),
					UIPadding = e("UIPadding", {
						PaddingTop = UDim.new(0, 4),
						PaddingBottom = UDim.new(0, 4),
						PaddingLeft = UDim.new(0, 4),
						PaddingRight = UDim.new(0, 4),
					}),
				}),
			}),
			e(SmallButton, {
				OnMount = setGamepadFocus,
				[React.Event.Activated] = function()
					setActiveDrink(nil)
				end,

				Image = "rbxassetid://127657596958436",
				ImageColor3 = Color3.new(0.933333, 0.933333, 0.184313),
				BackgroundTransparency = 1,
				ScaleType = Enum.ScaleType.Slice,
				SliceCenter = Rect.new(8, 8, 92, 92),
				AutomaticSize = Enum.AutomaticSize.None,
				Rounded = false,
				Position = UDim2.new(0.5, 0, 0.5, 100),
				AnchorPoint = Vector2.new(0.5, 1),
				Visible = t:map(mapFadeIn(startTime)),
				Size = t:map(mapSizeUDim2(startTime, UDim2.new(0, 100, 0, 40))),
				HoverScale = true,
			}, {
				Son = e(SmallText, {
					AutomaticSize = Enum.AutomaticSize.None,
					Text = dismissText,
					RichText = true,
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromScale(0.5, 0.5),
					Size = t:map(mapSizeUDim2(startTime, UDim2.new(0, 200, 0, 40))),
					TextTransparency = t:map(mapFadeIn(startTime)),
					TextSize = 32,
					TextXAlignment = Enum.TextXAlignment.Center,
				}),
			}),
		}),
	})
end

return DiscoveredDrink
