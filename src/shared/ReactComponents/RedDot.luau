local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)

-- Create the context to hold our single animation binding
local RedDotContext = React.createContext(nil)

-- RedDotProvider
local function RedDotProvider(props)
	-- We use a single binding for the animation step so it updates instantly
	-- without triggering a full React re-render every frame.
	local stepBinding, setStepBinding = React.useBinding(0)

	React.useEffect(function()
		local prevStep = nil
		local conn = RunService.Heartbeat:Connect(function()
			local currentStep = (tick() * ((92 / 60) * 16) // 1) % 16
			if prevStep ~= currentStep then
				setStepBinding(currentStep)
				prevStep = currentStep
			end
		end)

		return function()
			conn:Disconnect()
		end
	end, {})

	-- Copy passed children correctly
	local children = {}
	if props.children then
		for k, v in props.children do
			children[k] = v
		end
	end

	return React.createElement(RedDotContext.Provider, {
		value = stepBinding,
	}, children)
end

-- RedDot Component
local function RedDot(props: {
	Enabled: boolean?,
	SizeNum: number?,
	Position: UDim2,
})
	local stepBinding = React.useContext(RedDotContext)
	local size = props.SizeNum or 40

	-- If explicitly disabled, don't render the dot at all
	if props.Enabled == false then
		return nil
	end

	return React.createElement("ImageLabel", {
		ZIndex = 10,
		ScaleType = Enum.ScaleType.Fit,
		Size = UDim2.fromOffset(size, size),
		Position = props.Position,
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		ClipsDescendants = true,
	}, {
		Sprite = React.createElement("ImageLabel", {
			Image = "rbxassetid://74072152836235",
			ScaleType = Enum.ScaleType.Fit,
			Size = UDim2.fromOffset(4 * size, 4 * size),
			-- Map the provided context binding to the UDim2 position
			Position = stepBinding:map(function(n)
				if not n then
					return UDim2.new(0, 0, 0, 0)
				end
				local x = n % 4
				local y = n // 4
				return UDim2.new(0, -size * x, 0, -size * y)
			end),
			BackgroundTransparency = 1,
			ImageColor3 = Color3.new(0.8, 1, 0),
		}),
	})
end

return {
	RedDot = RedDot,
	RedDotProvider = RedDotProvider,
}
