local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local Reflex = require(ReplicatedStorage.Packages.Reflex)

local UIState = require(ReplicatedStorage.Shared.producers.UIState)
local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local useInputDevice = require(ReplicatedStorage.Shared.Hooks.useInputDevice)
local Primitives = ReplicatedStorage.Shared.ReactComponents.ui
local SmallText = require(Primitives.SmallText)

local e = React.createElement
local useEffect = React.useEffect
local useState = React.useState
local useBinding = React.useBinding
local useCallback = React.useCallback

local player = Players.LocalPlayer
local playerId = player and tostring(player.UserId) or "MockUser"

local function ScreenGuiCircle(props: { TargetButton: GuiObject?, Color: Color3? })
	local time, setTime = useBinding(workspace:GetServerTimeNow())

	useEffect(function()
		local running = true
		local t = task.spawn(function()
			while running do
				task.wait()
				setTime(workspace:GetServerTimeNow())
			end
		end)
		return function()
			running = false
			task.cancel(t)
		end
	end, {})

	local sizeMap = useCallback(function(t)
		local pulse = math.sin(t * 5) * 5
		return UDim2.fromOffset(60 + pulse, 60 + pulse)
	end, {})

	local posMap = useCallback(function(t)
		if not props.TargetButton then
			return UDim2.new()
		end
		local center = props.TargetButton.AbsolutePosition + (props.TargetButton.AbsoluteSize / 2)
		return UDim2.fromOffset(center.X, center.Y)
	end, { props.TargetButton })

	if not props.TargetButton then
		return nil
	end

	return e("ScreenGui", { DisplayOrder = 1010 }, {
		Wrapper = e("Frame", {
			BackgroundTransparency = 1,
			Position = time:map(posMap),
			Size = UDim2.fromOffset(60, 60),
			AnchorPoint = Vector2.new(0.5, 0.5),
		}, {
			Circle = e("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = time:map(sizeMap),
				BackgroundColor3 = props.Color or Color3.new(1, 1, 1),
				BackgroundTransparency = 0.8,
			}, {
				Corner = e("UICorner", { CornerRadius = UDim.new(1, 0) }),
				Stroke = e("UIStroke", {
					Color = props.Color or Color3.new(1, 1, 1),
					Thickness = 3,
				}),
			}),
		}),
	})
end

local function ShopTutorial()
	local globalStates, setGlobalStates = useState(GlobalState:getState())
	local uiStates, setUiStates = useState(UIState:getState())
	local time, setTime = useBinding(workspace:GetServerTimeNow())
	local hasCompleted, setHasCompleted = useState(false)

	useEffect(function()
		local unsubGlobal = GlobalState:subscribe(function(s)
			return s
		end, setGlobalStates)
		local unsubUI = UIState:subscribe(function(s)
			return s
		end, setUiStates)
		return function()
			unsubGlobal()
			unsubUI()
		end
	end, {})

	useEffect(function()
		local running = true
		local t = task.spawn(function()
			while running do
				task.wait(1 / 15)
				setTime(workspace:GetServerTimeNow())
			end
		end)
		return function()
			running = false
			task.cancel(t)
		end
	end, {})

	local stats = globalStates.Stats[playerId]
	local plotState = globalStates.Plot[playerId]
	local inventory = globalStates.Inventory[playerId] or {}
	local level = stats and stats.Level or 1

	local ownedIceStations = inventory["ice_station"] or 0
	local placedIceStations = 0
	if plotState then
		for _, item in pairs(plotState.placedItems or {}) do
			if item.id == "ice_station" then
				placedIceStations += 1
			end
		end
		for _, item in pairs(plotState.spatialItems or {}) do
			if item.id == "ice_station" then
				placedIceStations += 1
			end
		end
	end

	local totalIceStations = ownedIceStations + placedIceStations

	-- Latch completion so it doesn't reappear if they sell it later
	if placedIceStations > 0 and not hasCompleted then
		setHasCompleted(true)
	end

	-- Only run if Level 3+ and hasn't finished this specific tutorial
	if level < 3 or hasCompleted then
		return nil
	end

	local stepText = ""
	local circleTarget2D = nil
	local panel = uiStates.panel
	local targets = uiStates.tutorialTargets or {}

	if totalIceStations == 0 then
		if panel ~= "shop" then
			stepText = "You reached Level 3! Let's buy an Ice Station."
			circleTarget2D = targets["ShopButton"]
		elseif not targets["BuyButton"] then
			stepText = "Select the Ice Station from the catalog."
			circleTarget2D = targets["ShopItem_ice_station"]
		else
			stepText = "Buy the Ice Station!"
			circleTarget2D = targets["BuyButton"]
		end
	else
		if panel ~= "build" then
			stepText = "Awesome! Now let's place it. Open the Build Menu."
			circleTarget2D = targets["BuildButton"]
		elseif uiStates.buildItemId ~= "ice_station" then
			stepText = "Select the Ice Station from your inventory."
			circleTarget2D = targets["BuildItem_ice_station"]
		else
			local input = useInputDevice()
			local placeText = input == "Gamepad" and "R2" or input == "Touch" and "the Place Button" or "Left Click"
			stepText = `Place the Ice Station in your cafe using {placeText}!`
			circleTarget2D = targets["PlaceButton"] -- (If applicable on your mobile UI)
		end
	end

	local textRef = React.useRef("")
	useEffect(function()
		textRef.current = stepText
	end, { stepText })

	local textMap = useCallback(function(t)
		local finalTexts = {}
		local originalText = textRef.current or ""
		local length = string.len(originalText)
		for i = 1, length do
			local offset = (math.sin((t + i) * 5) + 1) * 2
			table.insert(finalTexts, `<font size="{18 + offset // 1}">{string.sub(originalText, i, i)}</font>`)
		end
		return table.concat(finalTexts)
	end, {})

	return e("ScreenGui", { DisplayOrder = 1006 }, {
		Banner = e("ImageLabel", {
			Size = UDim2.new(0.5, 0, 0, 40),
			AutomaticSize = Enum.AutomaticSize.XY,
			Position = UDim2.new(0.5, 0, 1, -140),
			AnchorPoint = Vector2.new(0.5, 1),
			Image = "rbxassetid://127657596958436",
			ImageTransparency = 0.6,
			ImageColor3 = Color3.new(0.2, 0.2, 0.2),
			ScaleType = Enum.ScaleType.Slice,
			SliceCenter = Rect.new(8, 8, 92, 92),
			BackgroundTransparency = 1,
		}, {
			Padding = e("UIPadding", {
				PaddingLeft = UDim.new(0, 20),
				PaddingRight = UDim.new(0, 20),
				PaddingTop = UDim.new(0, 10),
				PaddingBottom = UDim.new(0, 10),
			}),
			Text = e(SmallText, {
				RichText = true,
				Size = UDim2.new(1, 0, 1, 0),
				Text = time:map(textMap),
				TextXAlignment = Enum.TextXAlignment.Center,
				TextYAlignment = Enum.TextYAlignment.Center,
				MaxTextSize = 24,
			}),
		}),
		Circle = circleTarget2D
			and e(ScreenGuiCircle, { TargetButton = circleTarget2D, Color = Color3.new(1, 0.8, 0) }),
	})
end

return ShopTutorial
