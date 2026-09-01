local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundController = require(game.ReplicatedStorage.Shared.Controllers.SoundController)
local React = require(ReplicatedStorage.Packages.React)
local ReactFlow = require(ReplicatedStorage.Packages.ReactFlow)
local e = React.createElement
local useSpring = ReactFlow.useSpring
local useEffect = React.useEffect
local useState = React.useState

-- defaults to an imagebutton instead of textbutton
local function ScreenPromptButton(props: {
	ProximityPrompt: ProximityPrompt,
	Triggered: () -> (),
	PromptButtonHoldBegan: () -> (),
	PromptButtonHoldEnded: () -> (),
})
	local proximityPrompt: ProximityPrompt, setProximityPrompt = useState(props.ProximityPrompt)
	local shown: ProximityPrompt, setShown = useState(false)

	-- local visible = props.Visible == true and true or props.Visible == false and false or true

	local scale, setScale, stopScale = useSpring({
		start = 0,
		target = 0,
		damper = 0.8,
		speed = 40,
	})
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
		local function PromptButtonHoldBegan()
			if props.PromptButtonHoldBegan and type(props.PromptButtonHoldBegan) == "function" then
				props.PromptButtonHoldBegan()
			end
		end
		local function PromptButtonHoldEnded()
			if props.PromptButtonHoldEnded and type(props.PromptButtonHoldEnded) == "function" then
				props.PromptButtonHoldEnded()
			end
		end
		local function Triggered()
			if props.Triggered and type(props.Triggered) == "function" then
				props.Triggered()
			end
		end
		local connections = {
			proximityPrompt.Triggered:Connect(Triggered),
			proximityPrompt.PromptButtonHoldBegan:Connect(PromptButtonHoldBegan),
			proximityPrompt.PromptButtonHoldEnded:Connect(PromptButtonHoldEnded),
			proximityPrompt.PromptShown:Connect(onShown),
			proximityPrompt.PromptHidden:Connect(onHidden),
		}
		return function()
			for i, connection in connections do
				connection:Disconnect()
			end
		end
	end, {
		proximityPrompt,
		props.Triggered,
		props.PromptButtonHoldBegan,
		props.PromptButtonHoldEnded,
	})

	local buttonProps = {
		ref = props.OnMount,
		[React.Change.AbsolutePosition] = props[React.Change.AbsolutePosition],
		[React.Change.AbsoluteSize] = props[React.Change.AbsoluteSize],
		LayoutOrder = props.LayoutOrder,
		Size = props.Size or UDim2.new(0, 48, 0, 48),
		Rotation = props.Rotation,
		Visible = scale:map(function(n)
			return n > 0.2
		end),
		Position = props.Position,
		AnchorPoint = props.AnchorPoint,
		Active = props.Active,
		BackgroundColor3 = props.BackgroundColor3,
		BackgroundTransparency = props.BackgroundTransparency or 0.3,
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
	buttonProps.ImageTransparency = props.ImageTransparency or 0
	buttonProps.ImageColor3 = props.ImageColor3 or props.TextColor3
	buttonProps.ScaleType = props.ScaleType or Enum.ScaleType.Fit
	buttonProps.SliceCenter = props.SliceCenter

	local overlayColor = props.KeybindColor3 or props.TextColor3 or Color3.fromRGB(255, 255, 255)

	props.children = props.children or {}
	props.children.UIScale = e("UIScale", {
		Scale = scale,
	})
	props.children.Padding = e("UIPadding", {
		PaddingTop = props.Padding and (props.Padding.All or props.Padding.Top) or UDim.new(0, 4),
		PaddingBottom = props.Padding and (props.Padding.All or props.Padding.Bottom) or UDim.new(0, 4),
		PaddingLeft = props.Padding and (props.Padding.All or props.Padding.Left) or UDim.new(0, 4),
		PaddingRight = props.Padding and (props.Padding.All or props.Padding.Right) or UDim.new(0, 4),
	}) or nil

	return e("ImageButton", buttonProps, props.children)
end

return ScreenPromptButton
