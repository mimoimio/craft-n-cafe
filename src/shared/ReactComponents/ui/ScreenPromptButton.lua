-- ScreenPromptButton.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundController = require(game.ReplicatedStorage.Shared.Controllers.SoundController)
local React = require(ReplicatedStorage.Packages.React)
local ReactFlow = require(ReplicatedStorage.Packages.ReactFlow)
local e = React.createElement
local useSpring = ReactFlow.useSpring
local useEffect = React.useEffect
local useState = React.useState
local useBinding = React.useBinding

-- defaults to an imagebutton instead of textbutton
local function ScreenPromptButton(props: {
	ProximityPrompt: ProximityPrompt,
	Triggered: (() -> ())?,
	PromptButtonHoldBegan: (() -> ())?,
	PromptButtonHoldEnded: (() -> ())?,
	PromptShown: (() -> ())?,
	PromptHidden: (() -> ())?,
})
	local proximityPrompt = props.ProximityPrompt
	local shown: boolean, setShown = useState(false)

	local scale, setScale, stopScale = useSpring({
		start = 0,
		target = 0,
		damper = 0.8,
		speed = 40,
	})

	-- Added: Haptic state management from Billboard Gui
	local buttonTransparency, setButtonTransparency = useSpring({
		start = 0,
		target = 0,
		damper = 0.8,
		speed = 40,
	})
	local progressTransparency, setProgressTransparency = useSpring({
		start = 0,
		target = 0,
		damper = 0.8,
		speed = 40,
	})
	local progress, setProgress = useBinding(0)
	local buttonShown, setButtonShown = useState(true)
	local progressShown, setProgressShown = useState(false)

	-- Added: Effects to map state to visual springs
	useEffect(function()
		setButtonTransparency({
			target = buttonShown and 0 or 1,
			damper = 0.8,
			speed = 40,
		})
	end, { buttonShown })

	useEffect(function()
		setProgressTransparency({
			target = progressShown and 0 or 1,
			damper = 0.8,
			speed = 40,
		})
	end, { progressShown })

	useEffect(function()
		if not shown then
			setScale({
				target = 0,
				damper = 1,
				speed = 40,
			})
			return
		end
		setScale({
			start = 0,
			target = 1,
			damper = 0.2,
			speed = 40,
		})
	end, { shown })

	useEffect(function()
		if not (proximityPrompt and proximityPrompt.Parent) then
			return
		end

		local progressConnection: RBXScriptConnection?

		local function onShown()
			if props.PromptShown and type(props.PromptShown) == "function" then
				props.PromptShown()
			end
			setShown(true)
		end
		local function onHidden()
			if props.PromptHidden and type(props.PromptHidden) == "function" then
				props.PromptHidden()
			end
			setShown(false)
		end
		local function onHoldBegan()
			if props.PromptButtonHoldBegan and type(props.PromptButtonHoldBegan) == "function" then
				props.PromptButtonHoldBegan()
			end

			-- Added: Begin scaling progress horizontally mapped to server time
			local startTime = workspace:GetServerTimeNow()
			setButtonShown(false)
			setProgressShown(true)
			progressConnection = RunService.RenderStepped:Connect(function()
				if proximityPrompt and proximityPrompt.Parent then
					local elapsed = workspace:GetServerTimeNow() - startTime
					setProgress(math.clamp(elapsed / proximityPrompt.HoldDuration, 0, 1))
				end
			end)
		end
		local function onHoldEnded()
			if props.PromptButtonHoldEnded and type(props.PromptButtonHoldEnded) == "function" then
				props.PromptButtonHoldEnded()
			end

			-- Added: Stop progress and revert standard state
			setButtonShown(true)
			setProgressShown(false)
			if progressConnection then
				progressConnection:Disconnect()
				progressConnection = nil
			end
		end
		local function onTriggered()
			if props.Triggered and type(props.Triggered) == "function" then
				props.Triggered()
			end
			setButtonShown(false)
		end
		local function onTriggerEnded()
			setButtonShown(true)
		end

		-- Added: Hook up TriggerEnded natively
		local connections = {
			proximityPrompt.Triggered:Connect(onTriggered),
			proximityPrompt.TriggerEnded:Connect(onTriggerEnded),
			proximityPrompt.PromptButtonHoldBegan:Connect(onHoldBegan),
			proximityPrompt.PromptButtonHoldEnded:Connect(onHoldEnded),
			proximityPrompt.PromptShown:Connect(onShown),
			proximityPrompt.PromptHidden:Connect(onHidden),
		}
		return function()
			for _, connection in connections do
				connection:Disconnect()
			end
			if progressConnection then
				progressConnection:Disconnect()
				progressConnection = nil
			end
		end
	end, {
		proximityPrompt,
		props.Triggered,
		props.PromptButtonHoldBegan,
		props.PromptButtonHoldEnded,
		props.PromptShown,
		props.PromptHidden,
	})

	local buttonProps = {
		ref = props.OnMount,
		[React.Change.AbsolutePosition] = props[React.Change.AbsolutePosition],
		[React.Change.AbsoluteSize] = props[React.Change.AbsoluteSize],
		LayoutOrder = props.LayoutOrder,
		Size = props.Size or UDim2.new(0, 48, 0, 48),
		Rotation = props.Rotation,
		Visible = scale:map(function(n)
			return props.Visible and n > 0.2
		end),
		Position = props.Position,
		AnchorPoint = props.AnchorPoint,
		Active = props.Active,
		BackgroundColor3 = props.BackgroundColor3,
		-- Added: Maps 0 to 1 scaling safely onto base transparency prop values
		BackgroundTransparency = buttonTransparency:map(function(n)
			local base = props.BackgroundTransparency or 0.3
			return base + (1 - base) * n
		end),
		BorderSizePixel = 0,
		AutomaticSize = props.AutomaticSize or Enum.AutomaticSize.XY,
		ZIndex = props.ZIndex or 11,
		AutoButtonColor = props.AutoButtonColor,
		[React.Event.Activated] = props[React.Event.Activated] and function(rbx)
			props[React.Event.Activated](rbx)
			SoundController.Sound("drop_001")
		end or nil,
		[React.Event.MouseEnter] = function()
			setScale({
				target = 1.05,
				speed = 40,
				damper = 0.8,
			})
			-- SoundController.Sound("Plink")
		end,
		[React.Event.MouseLeave] = function()
			setScale({
				target = 1,
				speed = 40,
				damper = 0.8,
			})
			-- SoundController.Sound("drop_001")
		end,
		[React.Event.MouseButton1Down] = proximityPrompt and function()
			proximityPrompt:InputHoldBegin()
		end,
		[React.Event.MouseButton1Up] = proximityPrompt and function()
			proximityPrompt:InputHoldEnd()
		end,
	}

	buttonProps.Image = props.Image
	buttonProps.ImageRectOffset = props.ImageRectOffset
	buttonProps.ImageRectSize = props.ImageRectSize

	-- Added: Map the transparency onto the image layer as well
	buttonProps.ImageTransparency = buttonTransparency:map(function(n)
		local base = props.ImageTransparency or 0
		return base + (1 - base) * n
	end)

	buttonProps.ImageColor3 = props.ImageColor3 or props.TextColor3
	buttonProps.ScaleType = props.ScaleType or Enum.ScaleType.Fit
	buttonProps.SliceCenter = props.SliceCenter

	local overlayColor = props.KeybindColor3 or props.TextColor3 or Color3.fromRGB(255, 255, 255)

	-- Added: Defensively copy children to prevent React prop mutation violations
	local children = {}
	if props.children then
		for k, v in pairs(props.children) do
			children[k] = v
		end
	end

	children.UIScale = e("UIScale", {
		Scale = scale,
	})
	children.Padding = e("UIPadding", {
		PaddingTop = props.Padding and (props.Padding.All or props.Padding.Top) or UDim.new(0, 4),
		PaddingBottom = props.Padding and (props.Padding.All or props.Padding.Bottom) or UDim.new(0, 4),
		PaddingLeft = props.Padding and (props.Padding.All or props.Padding.Left) or UDim.new(0, 4),
		PaddingRight = props.Padding and (props.Padding.All or props.Padding.Right) or UDim.new(0, 4),
	}) or nil

	-- Added: Identical Progress Bar implementation to Billboard. Maps perfectly to either a provided image format or raw frame layout.
	if props.Image then
		children.Progress = e("ImageLabel", {
			Size = progress:map(function(n)
				return UDim2.fromScale(n, 1)
			end),
			Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			Image = props.Image,
			ImageRectOffset = props.ImageRectOffset,
			ImageRectSize = props.ImageRectSize,
			ImageTransparency = progressTransparency,
			ImageColor3 = Color3.new(0, 1, 0), -- Use Billboard's green
			ScaleType = props.ScaleType or Enum.ScaleType.Fit,
			SliceCenter = props.SliceCenter,
			ZIndex = (props.ZIndex or 11) + 1,
		})
	else
		children.Progress = e("Frame", {
			Size = progress:map(function(n)
				return UDim2.fromScale(n, 1)
			end),
			Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.new(0, 1, 0),
			BackgroundTransparency = progressTransparency,
			BorderSizePixel = 0,
			ZIndex = (props.ZIndex or 11) + 1,
		})
	end

	return e("ImageButton", buttonProps, children)
end

return ScreenPromptButton
