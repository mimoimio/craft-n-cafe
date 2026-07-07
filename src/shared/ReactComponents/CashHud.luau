--#region
-- CashHud.luau

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local COINICON = "robux"
local React = require(ReplicatedStorage.Packages.React)
local ReactFlow = require(ReplicatedStorage.Packages.ReactFlow)

local Primitives = ReplicatedStorage.Shared.ReactComponents.ui
local SmallText = require(Primitives.SmallText)

local e = React.createElement
local useState = React.useState
local useSpring = ReactFlow.useSpring
local useEffect = React.useEffect
local useCallback = React.useCallback
local useRef = React.useRef

-- ✨ New sleek, localized Toast Component specifically for the Cash HUD!
local function CashToast(props: {
	message: string,
	layoutOrder: number,
	onClose: () -> (),
})
	local anim, setAnim = useSpring({
		target = 0,
		start = 0,
		speed = 15,
		damper = 0.7,
	})

	useEffect(function()
		-- Pop in!
		setAnim({ target = 1, speed = 15, damper = 0.7 })

		-- Wait a few seconds, animate out, and tell the parent to remove us
		local thread = task.delay(2.5, function()
			setAnim({ target = 0, speed = 12, damper = 1 })
			task.delay(0.3, props.onClose)
		end)

		return function()
			task.cancel(thread)
		end
	end, {})

	return e("Frame", {
		AutomaticSize = Enum.AutomaticSize.XY,
		BackgroundTransparency = 1,
		LayoutOrder = props.layoutOrder,
	}, {
		text = e(SmallText, {
			Text = props.message,
			TextSize = 28,
			-- Using your SmallText component, we bind the spring alpha for a smooth slide & fade!
			TextTransparency = anim:map(function(v)
				return 1 - v
			end),
			Position = anim:map(function(v)
				return UDim2.new(0.5, 0, 0, (1 - v) * 15)
			end),
			AnchorPoint = Vector2.new(0.5, 0),
			AutomaticSize = Enum.AutomaticSize.XY,
			-- You can conditionally color this based on the message (e.g., green for +, red for -)
			TextColor3 = Color3.fromRGB(85, 255, 85),
		}),
	})
end

local function CashHud(props: {
	coins: number,
	OnMount: () -> (),
})
	local coins = props.coins
	local prevCoins = useRef(coins)

	local toasts, setToasts = useState({})
	local toastIdCounter = useRef(0)

	local hudRot, setHudRot = useSpring({
		target = 0,
		start = 0,
		speed = 0,
		damper = 0.6,
	})

	-- Helper to safely remove a toast by its ID
	local removeToast = useCallback(function(id: number)
		setToasts(function(prev)
			local newToasts = {}
			for _, t in ipairs(prev) do
				if t.id ~= id then
					table.insert(newToasts, t)
				end
			end
			return newToasts
		end)
	end, {})

	-- Helper to push a new toast to the HUD
	local addToast = useCallback(function(message: string)
		toastIdCounter.current += 1
		local id = toastIdCounter.current
		setToasts(function(prev)
			local clone = table.clone(prev)
			table.insert(clone, { id = id, message = message })
			return clone
		end)
	end, {})

	useEffect(function()
		-- Bump the rotation spring
		setHudRot({
			target = 0,
			start = 10,
			speed = 10,
			damper = 0.6,
		})

		-- ✨ Automagically spawn a toast if the coins value changes!
		if prevCoins.current ~= nil then
			local diff = coins - prevCoins.current
			if diff > 0 then
				addToast("+" .. tostring(diff) .. "$")
			elseif diff < 0 then
				addToast(tostring(diff)) -- Already has negative sign
			end
		end
		prevCoins.current = coins
	end, { coins })

	-- Build out the toast list
	local toastElements = {
		layout = e("UIListLayout", {
			FillDirection = Enum.FillDirection.Vertical,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 4),
		}),
	}

	for _, toast in ipairs(toasts) do
		toastElements["Toast_" .. toast.id] = e(CashToast, {
			message = toast.message,
			layoutOrder = -toast.id, -- Negative layout order pushes newest to the top of the stack!
			onClose = function()
				removeToast(toast.id)
			end,
		})
	end

	-- Main HUD Frame is now a vertical list to stack the SmallText and Toast Container
	return e("Frame", {
		AutomaticSize = Enum.AutomaticSize.XY,
		Position = UDim2.new(0.5, 0, 0, 0),
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundTransparency = 1,
	}, {
		-- Stacks the Text and the Toasts Container
		layout = e("UIListLayout", {
			FillDirection = Enum.FillDirection.Vertical,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 5),
		}),

		text = e("Frame", {
			AutomaticSize = Enum.AutomaticSize.XY,
			BackgroundTransparency = 1,
		}, {
			e(SmallText, {
				Text = (
					([[<font family="rbxasset://LuaPackages/Packages/_Index/BuilderIcons/BuilderIcons/BuilderIcons.json">%s</font>]]):format(
						COINICON
					) .. [[%s]]
				):format(coins),
				RichText = true,
				TextSize = 42,
				TextColor3 = Color3.new(1, 1, 0),
				OnMount = props.OnMount,
				AutomaticSize = Enum.AutomaticSize.XY,
				Rotation = hudRot,
				LayoutOrder = 1, -- Force it to stay on top
			}),
		}),

		-- Container exclusively for toasts right underneath
		toastContainer = e("Frame", {
			AutomaticSize = Enum.AutomaticSize.XY,
			BackgroundTransparency = 1,
			LayoutOrder = 2,
			Position = UDim2.new(1, 0, 0, 0),
		}, toastElements),
	})
end

return CashHud

--#endregion

-- -- CashHud.luau

-- local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- local COINICON = "robux"
-- local React = require(ReplicatedStorage.Packages.React)
-- local ReactFlow = require(ReplicatedStorage.Packages.ReactFlow)

-- local Primitives = ReplicatedStorage.Shared.ReactComponents.ui
-- local SmallText = require(Primitives.SmallText)

-- local e = React.createElement
-- local useState = React.useState
-- local useSpring = ReactFlow.useSpring
-- local useEffect = React.useEffect

-- local function CashHud(props: {
-- 	coins: number,
-- 	OnMount: () -> (),
-- })
-- 	local coins = props.Coins
-- 	local hudRot, setHudRot = useSpring({
-- 		target = 0,
-- 		start = 0,
-- 		speed = 0,
-- 		damper = 0.6,
-- 	})

-- 	useEffect(function()
-- 		setHudRot({
-- 			target = 0,
-- 			start = 10,
-- 			speed = 10,
-- 			damper = 0.6,
-- 		})
-- 	end, { coins })
-- 	return e("Frame", {
-- 		AutomaticSize = Enum.AutomaticSize.XY,
-- 		Position = UDim2.new(0.5, 0, 0, 0),
-- 		AnchorPoint = Vector2.new(0.5, 0),
-- 		BackgroundTransparency = 1,
-- 	}, {
-- 		-- toast = ,
-- 		text = e(SmallText, {
-- 			Text = (
-- 				([[<font family="rbxasset://LuaPackages/Packages/_Index/BuilderIcons/BuilderIcons/BuilderIcons.json">%s</font>]]):format(
-- 					COINICON
-- 				) .. [[%s]]
-- 			):format(coins),
-- 			RichText = true,
-- 			TextSize = 42,
-- 			TextColor3 = Color3.new(1, 1, 0),
-- 			OnMount = props.OnMount,
-- 			AutomaticSize = Enum.AutomaticSize.XY,
-- 			Rotation = hudRot,
-- 		}),
-- 	})
-- end

-- return CashHud
