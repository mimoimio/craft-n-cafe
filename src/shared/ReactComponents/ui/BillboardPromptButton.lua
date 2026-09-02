local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local SoundController = require(game.ReplicatedStorage.Shared.Controllers.SoundController)
local React = require(ReplicatedStorage.Packages.React)
local ReactRoblox = require(ReplicatedStorage.Packages.ReactRoblox)
local ReactFlow = require(ReplicatedStorage.Packages.ReactFlow)
local e = React.createElement
local useSpring = ReactFlow.useSpring
local useEffect = React.useEffect
local useState = React.useState
local useBinding = React.useBinding
local useCallback = React.useCallback
local useRef = React.useRef

local player = Players.LocalPlayer

--[[

native ProximityPrompt signals:
	PromptShown:
		- when player gets within max activation distance and in view.
		- doesnt fire if connected AFTER player already within max
			activation distance and in view. But will fire again
			if was hidden and shown again

	PromptHidden:
		- when player leave the proximity
		- player looks away
		- doesnt fire if not already shown

	PromptButtonHoldBegan:
		- Fired when keycode is fired
		- Fired when prompt:InputHoldBegin()
		- Fired ONLY if HoldDuration > 0, even if directly prompt:InputHoldBegin()

	PromptButtonHoldEnded:
		- Fired when keycode is released
		- Fired when prompt.Triggered signal is fired. Therefore it wont be fired again when prompt.TriggerEnded
		- Fired when prompt:InputHoldEnded()
		- Fired ONLY if HoldDuration > 0, even if directly prompt:InputHoldEnded()

	Triggered:
		- Fired when duration of InputHoldBegin reached prompt.HoldDuration
		- Fired immediately if prompt.HoldDuration == 0

	TriggerEnded:
		- Fired ONLY if
			1. prompt is already Triggered
			2. prompt's KeyCode is released

native ui behaviors:
	HoldDuration > 0:
		PromptButtonHoldBegan -> image and everything that has transparency turned to 1 (invisible)
			Starts showing and playing progress bar.
			Progress bar plays until the length of HoldDuration
			PromptButtonHoldEnded is fired
			And then Triggered signal is fired
		PromptButtonHoldEnded -> hides progress bar
		Triggered -> nothing

		TriggerEnded -> set transparencies back to original

	HoldDuration == 0:
		Triggered ->  image and everything that has transparency turned to 1 (invisible)

		TriggerEnded -> set transparencies back to original

abstracted states:
	buttonShown: boolean
	progressShown: boolean
	triggered: boolean
	holdStartTime: { current:number }

abstracted stages:
	PromptButtonHoldBegan:
		set holdStartTime to now
		set buttonShown to false
		set progressShown to true
		connnect to Heartbeat: set progress binding

	PromptButtonHoldEnded:
		set ProgressShown to false
		disconnnect to Heartbeat
		if not triggered then
			set buttonShown to true -- this cannot be done cus triggered at this time will always falsey
		end

	Triggered:
		set buttonShown to false

	TriggerEnded:
		set buttonShown to true
]]
local function ScreenPromptButton(props: {
	ProximityPrompt: ProximityPrompt,
	Adornee: () -> (),
	PromptShown: (() -> ())?,
	PromptHidden: (() -> ())?,
	PromptButtonHoldBegan: (() -> ())?,
	PromptButtonHoldEnded: (() -> ())?,
	Triggered: (() -> ())?,
	TriggerEnded: (() -> ())?,
})
	local proximityPrompt = props.ProximityPrompt
	local promptShown: boolean, setPromptShown = useState(false)

	-- local visible = props.Visible == true and true or props.Visible == false and false or true

	local scale, setScale = useSpring({
		start = 0,
		target = 0,
		damper = 0.8,
		speed = 40,
	})
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

	useEffect(function()
		if buttonShown then
			setButtonTransparency({
				target = 0,
				damper = 0.8,
				speed = 40,
			})
		else
			setButtonTransparency({
				target = 1,
				damper = 0.8,
				speed = 40,
			})
		end
	end, { buttonShown })
	useEffect(function()
		if progressShown then
			setProgressTransparency({
				target = 0,
				damper = 0.8,
				speed = 40,
			})
		else
			setProgressTransparency({
				target = 1,
				damper = 0.8,
				speed = 40,
			})
		end
	end, { progressShown })

	-- connect to proximity prompt events
	useEffect(function()
		if not (proximityPrompt and proximityPrompt.Parent) then
			return
		end

		local progressConnection: RBXScriptConnection?

		local connections = {
			proximityPrompt.PromptButtonHoldBegan:Connect(function()
				local startTime = workspace:GetServerTimeNow()
				setButtonShown(false)
				setProgressShown(true)
				progressConnection = RunService.RenderStepped:Connect(function()
					if proximityPrompt and proximityPrompt.Parent then
						local elapsed = workspace:GetServerTimeNow() - startTime
						setProgress(math.clamp(elapsed / proximityPrompt.HoldDuration, 0, 1))
					end
				end)
			end),
			proximityPrompt.PromptButtonHoldEnded:Connect(function()
				setButtonShown(true) -- reveal button here. if Triggered and Triggered signal immediately fire after, it shouldnt flicker
				setProgressShown(false)
				if progressConnection then
					progressConnection:Disconnect()
					progressConnection = nil
				end
				-- setProgress(0)
			end),

			proximityPrompt.Triggered:Connect(function()
				setButtonShown(false) -- hopefully doesnt flicker
			end),
			proximityPrompt.TriggerEnded:Connect(function()
				setButtonShown(true)
			end),

			proximityPrompt.PromptShown:Connect(function()
				setPromptShown(true)
			end),
			proximityPrompt.PromptHidden:Connect(function()
				setPromptShown(false)
			end),
		}
		return function()
			for i, connection in connections do
				connection:Disconnect()
			end
			if progressConnection then
				progressConnection:Disconnect()
				progressConnection = nil
			end
		end
	end, { proximityPrompt })

	-- play the prompt animation
	useEffect(function()
		if not promptShown then
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
	end, { promptShown })

	local children = props.children or {}
	children.UIScale = e("UIScale", {
		Scale = scale,
	})
	children.Padding = e("UIPadding", {
		PaddingTop = props.Padding and (props.Padding.All or props.Padding.Top) or UDim.new(0, 4),
		PaddingBottom = props.Padding and (props.Padding.All or props.Padding.Bottom) or UDim.new(0, 4),
		PaddingLeft = props.Padding and (props.Padding.All or props.Padding.Left) or UDim.new(0, 4),
		PaddingRight = props.Padding and (props.Padding.All or props.Padding.Right) or UDim.new(0, 4),
	}) or nil

	-- local releaseConnectionRef = useRef(nil)
	-- local mouseButton1Down = useCallback(function(rbx)
	-- 	proximityPrompt:InputHoldBegin()

	-- 	-- Create a temporary connection to detect when the user lets go ANYWHERE on the screen
	-- 	if releaseConnectionRef.current then
	-- 		releaseConnectionRef.current:Disconnect()
	-- 		releaseConnectionRef.current = nil
	-- 	end
	-- 	releaseConnectionRef.current = UserInputService.InputEnded:Connect(function(endInput)
	-- 		-- Ensure we are releasing the same input type that started the hold
	-- 		if
	-- 			endInput.UserInputType == Enum.UserInputType.Touch
	-- 			or endInput.UserInputType == Enum.UserInputType.MouseButton1
	-- 		then
	-- 			proximityPrompt:InputHoldEnd()
	-- 			if releaseConnectionRef.current then
	-- 				releaseConnectionRef.current:Disconnect()
	-- 				releaseConnectionRef.current = nil
	-- 			end
	-- 		end
	-- 	end)
	-- end, { proximityPrompt })
	-- useEffect(function()
	-- 	return function()
	-- 		if releaseConnectionRef.current then
	-- 			releaseConnectionRef.current:Disconnect()
	-- 			releaseConnectionRef.current = nil
	-- 		end
	-- 	end
	-- end, {})

	return props.Adornee
			and props.Adornee.Parent
			and ReactRoblox.createPortal({
				e("BillboardGui", {
					Size = UDim2.new(0, 200, 0, 50),
					ResetOnSpawn = false,
					AlwaysOnTop = true,
					Adornee = props.Adornee,
					Active = true,
					ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
				}, {
					-- defaults to an imagebutton instead of textbutton,
					e("ImageButton", {
						[React.Change.AbsolutePosition] = props[React.Change.AbsolutePosition],
						[React.Change.AbsoluteSize] = props[React.Change.AbsoluteSize],
						LayoutOrder = props.LayoutOrder,
						Size = UDim2.fromScale(1, 1),
						Rotation = props.Rotation,
						Visible = scale:map(function(n)
							return n > 0.2
						end),
						Position = UDim2.fromScale(0.5, 0.5),
						AnchorPoint = Vector2.new(0.5, 0.5),
						Active = props.Active,
						BackgroundColor3 = props.BackgroundColor3,
						BackgroundTransparency = props.BackgroundTransparency or 1,
						BorderSizePixel = 0,
						AutomaticSize = props.AutomaticSize or Enum.AutomaticSize.XY,
						ZIndex = props.ZIndex or 11,
						AutoButtonColor = props.AutoButtonColor,
						--#region
						-- [React.Event.MouseEnter] = function()
						-- 	-- setScale({
						-- 	-- 	target = 1.05,
						-- 	-- 	speed = 40,
						-- 	-- 	damper = 0.8,
						-- 	-- })
						-- 	-- do something other than scale cuz it could mess up the scale
						-- 	-- SoundController.Sound("Plink")
						-- end,
						-- [React.Event.MouseLeave] = function()
						-- 	-- setScale({
						-- 	-- 	target = 1,
						-- 	-- 	speed = 40,
						-- 	-- 	damper = 0.8,
						-- 	-- })
						-- 	-- do something other than scale cuz it could mess up the scale
						-- 	-- SoundController.Sound("drop_001")
						-- end,
						--#endregion
						[React.Event.MouseButton1Down] = function()
							proximityPrompt:InputHoldBegin()
						end,
						[React.Event.MouseButton1Up] = function()
							proximityPrompt:InputHoldEnd()
						end,
						Image = "rbxassetid://127657596958436",
						ImageRectOffset = props.ImageRectOffset,
						ImageTransparency = buttonTransparency:map(function(n)
							return 0.4 + 0.6 * n
						end),
						ImageRectSize = props.ImageRectSize,
						ScaleType = Enum.ScaleType.Slice,
						SliceCenter = Rect.new(8, 8, 92, 92),
						ImageColor3 = Color3.new(0, 1, 0),
					}, children),
				}),
				e("BillboardGui", {
					Size = UDim2.new(0, 200, 0, 200),
					ResetOnSpawn = false,
					AlwaysOnTop = true,
					Adornee = props.Adornee,
					Active = true,
					-- Enabled = progressShown,
					ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
				}, {
					-- defaults to an imagebutton instead of textbutton,
					e("ImageLabel", {
						LayoutOrder = props.LayoutOrder,
						Size = progress:map(function(n)
							return UDim2.fromScale(n, 1)
						end),
						Visible = scale:map(function(n)
							return n > 0.2
						end),
						Position = UDim2.fromScale(0.5, 0.5),
						AnchorPoint = Vector2.new(0.5, 0.5),
						Active = props.Active,
						BackgroundColor3 = props.BackgroundColor3,
						BackgroundTransparency = 1,
						Image = "rbxassetid://127657596958436",
						ImageRectOffset = props.ImageRectOffset,
						ImageTransparency = progressTransparency,
						ScaleType = Enum.ScaleType.Slice,
						SliceCenter = Rect.new(8, 8, 92, 92),
						ImageColor3 = Color3.new(0, 1, 0),
					}, children),
				}),
				e("Highlight", {
					Enabled = progressShown,
					DepthMode = Enum.HighlightDepthMode.AlwaysOnTop,
					FillTransparency = progress:map(function(n)
						return 1 - n
					end),
					Adornee = props.Adornee,
				}),
			}, player and player.PlayerGui or props.Adornee)
		or nil
end

return ScreenPromptButton
