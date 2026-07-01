-- Toast, ToastContext, ToastProvider, useToast in one file Toasts.lua
local React = require(game.ReplicatedStorage.Packages.React)
local TweenService = game:GetService("TweenService")

-- ToastContext
type ToastContextType = {
	open: (message: string, duration: number?, color: Color3?) -> nil,
	close: (id: number) -> nil,
}
type toast = {
	open: (message: string, duration: number?, color: Color3?) -> nil,
	close: (id: number) -> nil,
}
local ToastContext = React.createContext(nil :: ToastContextType | nil)

-- Toast component
-- local START_SIZE = UDim2.new(0, 0, 0, 0)
local START_SIZE = UDim2.new(0, 200, 0, 50)
local NORMAL_SIZE = UDim2.new(0, 200, 0, 50)
local END_SIZE = UDim2.new(0, 200, 0, 50)
-- local END_SIZE = UDim2.new(0, 0, 0, 0)
local function Toast(props: {
	message: string,
	close: () -> nil,
	duration: number,
	LayoutOrder: number,
	color: Color3?,
	onMount: ((startClose: () -> nil) -> nil)?,
})
	local frameref = React.useRef()
	local textref = React.useRef()
	local closingRef = React.useRef(false) -- so it doesnt run twice

	local function startClose()
		if closingRef.current then
			return
		end
		closingRef.current = true
		local closeTime = props.duration / 10
		if frameref.current then
			TweenService:Create(
				frameref.current,
				TweenInfo.new(closeTime, Enum.EasingStyle.Cubic, Enum.EasingDirection.In),
				{ Size = END_SIZE }
			):Play()
		end
		if textref.current then
			TweenService:Create(
				textref.current,
				TweenInfo.new(closeTime, Enum.EasingStyle.Cubic, Enum.EasingDirection.In),
				{ TextTransparency = 1 }
			):Play()
		end
		task.delay(closeTime, function()
			props.close()
		end)
	end

	React.useEffect(function()
		-- opening animation
		local openTime = props.duration / 4
		if frameref.current then
			TweenService:Create(
				frameref.current,
				TweenInfo.new(openTime, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
				{ Size = NORMAL_SIZE }
			):Play()
		end
		if textref.current then
			TweenService:Create(
				textref.current,
				TweenInfo.new(openTime, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out),
				{ TextTransparency = 0 }
			):Play()
		end

		-- register with provider
		if props.onMount then
			props.onMount(startClose)
		end

		-- auto schedule close
		task.delay(props.duration, function()
			startClose()
		end)
	end, {})

	return React.createElement("Frame", {
		ref = frameref,
		Size = START_SIZE,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0.5, 0.50),
		Position = UDim2.new(0.5, 0, 0, 100),
		LayoutOrder = props.LayoutOrder,
		Active = false,
		ZIndex = 31,
	}, {
		Label = React.createElement("TextLabel", {
			RichText = true,
			TextTransparency = 1,
			ref = textref,
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			ZIndex = 32,
			TextStrokeTransparency = 0,
			TextColor3 = props.color or Color3.fromRGB(235, 235, 235),
			TextStrokeColor3 = Color3.new(0, 0, 0),
			Font = Enum.Font.FredokaOne,
			TextScaled = true,
			Text = props.message,
			TextXAlignment = Enum.TextXAlignment.Center,
		}),
	})
end

-- ToastProvider
local c = 0
local function count()
	c += 1
	return c
end

local function ToastProvider(props)
	local Toasts, setToasts =
		React.useState({} :: { { message: string, id: number, duration: number, color: Color3? } })

	-- Copy passed children correctly from React.Children symbol
	local children = {}
	for k, v in props.children do
		children[k] = v
	end

	local function closeToast(id: number)
		setToasts(function(prev)
			local new = {}
			for _, toast in ipairs(prev) do
				if toast.id ~= id then
					table.insert(new, toast)
				end
			end
			return new
		end)
	end

	local function openToast(message: string, duration: number?, color: Color3?)
		duration = duration or 3 -- default 3 seconds
		local id = count()
		local newToast = { id = id, message = message, duration = duration, color = color }

		setToasts(function(prev)
			local clone = table.clone(prev)
			table.insert(clone, newToast)
			return clone
		end)

		-- auto-close now deferred to Toast's startClose
		return true
	end

	local contextValue: toast = React.useMemo(function()
		return {
			open = openToast,
			close = closeToast,
		}
	end, {})

	local Flashes = {
		UIListLayout = React.createElement("UIListLayout", {
			FillDirection = Enum.FillDirection.Vertical,
			VerticalAlignment = Enum.VerticalAlignment.Top,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			SortOrder = "LayoutOrder",
		}),
	}

	local closersRef = React.useRef({} :: { [number]: () -> () })

	for i, toast in ipairs(Toasts) do
		local keepStart = math.max(#Toasts - 2, 1)
		local forceClose = i < keepStart
		Flashes["_" .. tostring(i)] = React.createElement(Toast, {
			key = toast.id,
			LayoutOrder = -toast.id,
			duration = toast.duration,
			message = toast.message,
			color = toast.color,
			close = function()
				closersRef.current[toast.id] = nil
				closeToast(toast.id)
			end,
			onMount = function(startClose)
				closersRef.current[toast.id] = startClose
				if forceClose then -- calls on startClose callback when forcing it to close
					startClose()
				end
			end,
		})
	end

	React.useEffect(function()
		if #Toasts <= 3 then
			return
		end
		local keepStart = math.max(#Toasts - 2, 1)
		for i, toast in ipairs(Toasts) do
			if i < keepStart then
				local closer = closersRef.current[toast.id]
				if closer then
					closer()
				end
			end
		end
	end, { Toasts })

	children["FlashDisplay"] = React.createElement("Frame", {
		Size = UDim2.new(0.5, 0, 0.5, 0),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		Active = false,
		ZIndex = 30,
	}, Flashes)

	return React.createElement(ToastContext.Provider, {
		value = contextValue,
	}, children)
end

-- useToast hook
local function useToast(): toast
	local ctx = React.useContext(ToastContext)
	return ctx
end

return {
	Toast = Toast,
	ToastProvider = ToastProvider,
	ToastContext = ToastContext,
	useToast = useToast,
}
