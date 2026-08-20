-- Shared/ReactComponents/MixerNode.luau
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local ReactRoblox = require(ReplicatedStorage.Packages.ReactRoblox)
local Promise = require(ReplicatedStorage.Packages.Promise)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local SoundController = require(ReplicatedStorage.Shared.Controllers.SoundController)
local CoffeeModule = require(ReplicatedStorage.Shared.CoffeeModule)
local UIState = require(ReplicatedStorage.Shared.producers.UIState)
local toggleMixerInteract = UIState.toggleMixerInteract
local MixerProgressBar = require(script.Parent.MixerProgressBar)
local VStack = require(script.Parent.ui.VStack)
local ReactFlow = require(ReplicatedStorage.Packages.ReactFlow)
local useSpring = ReactFlow.useSpring
local SmallButton = require(script.Parent.ui.SmallButton)
local SmallText = require(script.Parent.ui.SmallText)

local BuildersIcon = require(ReplicatedStorage.Shared.Utils.BuildersIcon)
local useInputDevice = require(ReplicatedStorage.Shared.Hooks.useInputDevice)

local e = React.createElement
local useEffect = React.useEffect
local useState = React.useState
local useRef = React.useRef

local player = Players.LocalPlayer
local playerId = player and tostring(player.UserId) or ""

local DURATION = 1

local function delayedRevealSizeMap(startTimeRef, sec: number, finalSize: UDim2)
	return function(t)
		local startTime = startTimeRef.current

		if not startTime or startTime == math.huge then
			return UDim2.new(0, 0, 0, 0)
		end

		if t > startTime then
			if t > startTime + sec then
				local elapsed = (t - startTime - sec)
				elapsed = math.min(elapsed, DURATION) / DURATION
				elapsed = 1 - ((1 - elapsed) ^ 20)
				return UDim2.new(
					elapsed * finalSize.X.Scale,
					elapsed * finalSize.X.Offset,
					elapsed * finalSize.Y.Scale,
					elapsed * finalSize.Y.Offset
				)
			end
		end

		return UDim2.new(0, 0, 0, 0)
	end
end

local function MixerNode(props: {
	MixerName: string,
	MixerData: any,
	Instance: Instance?,
})
	local currentInput = useInputDevice()
	local isOccupied = props.MixerData.drinkId ~= "none"

	local prompt: ProximityPrompt?, setPrompt = useState(nil)
	local shown: boolean, setShown = useState(false)
	local progress, setProgress = React.useBinding(0)
	local finishRangRef = React.useRef(false)
	local time, setTime = React.useBinding(math.huge)
	local config = CoffeeModule.Config[props.MixerData.drinkId]
	local duration = (config and config.Duration) or nil
	local startTime = props.MixerData.startTime
	local buttonShownStart = useRef(math.huge)

	React.useEffect(function()
		local running = true
		local t = task.spawn(function()
			while running do
				task.wait()
				local now = workspace:GetServerTimeNow()
				if startTime and duration then
					local timePassed = now - startTime
					local p = math.clamp(timePassed / duration, 0, 1)
					setProgress(p)
					if p >= 1 then
						if finishRangRef.current ~= true then
							SoundController.Sound("Success")
						end
						finishRangRef.current = true
					end
				end
				setTime(now)
			end
		end)

		return function()
			running = false
			finishRangRef.current = false
			task.cancel(t)
		end
	end, { startTime, duration })

	useEffect(function()
		if not props.Instance then
			return
		end

		UIState.setMixerInstance(props.Instance)

		local promise = Promise.defer(function(resolve, reject)
			local part = props.Instance:WaitForChild("Part", 5)
			if not part then
				return reject("Mixer 'Part' replication timeout")
			end

			local resolvedPrompt = part:WaitForChild("TriggerPrompt", 5)
			if not resolvedPrompt then
				return reject("TriggerPrompt replication timeout")
			end

			resolve(resolvedPrompt)
		end)

		promise
			:andThen(function(resolvedPrompt)
				setPrompt(resolvedPrompt)
			end)
			:catch(function(err)
				warn(`[MixerNode] Failed to resolve descendants for {props.MixerName}: {err}`)
			end)

		return function()
			UIState.setMixerInstance(nil)
			promise:cancel()
		end
	end, { props.Instance })

	useEffect(function()
		if not prompt then
			return
		end

		prompt.ActionText = isOccupied and "Pick Up" or "Craft"
		prompt.Style = Enum.ProximityPromptStyle.Custom
		prompt.RequiresLineOfSight = false

		local conn = prompt.Triggered:Connect(function(player)
			if player == Players.LocalPlayer then
				if isOccupied then
					if startTime and duration then
						local now = workspace:GetServerTimeNow()
						local left = startTime + duration - now
						if left > 15 then
							Remotes.SkipMix:FireServer(props.MixerName)
							return
						end
					end
					Remotes.PickUpDrink:FireServer(props.MixerName)
					return
				else
					toggleMixerInteract(props.MixerName)
				end
			end
		end)
		local conn2 = prompt.PromptShown:Connect(function()
			setShown(true)
		end)
		local conn3 = prompt.PromptHidden:Connect(function()
			setShown(false)
		end)

		return function()
			conn:Disconnect()
			conn2:Disconnect()
			conn3:Disconnect()
		end
	end, { prompt, isOccupied, props.MixerName, startTime })

	useEffect(function()
		if not prompt then
			return
		end
		prompt.RequiresLineOfSight = false
		local conn = prompt.PromptShown:Connect(function()
			UIState.setMixerNodeShown(props.MixerName)
		end)
		local conn2 = prompt.PromptHidden:Connect(function()
			UIState.setMixerNodeShown(nil)
		end)
		return function()
			conn:Disconnect()
			conn2:Disconnect()
		end
	end, { prompt })

	local isOccupiedRef = useRef(nil)
	useEffect(function()
		if isOccupiedRef.current == nil then
			isOccupiedRef.current = isOccupied
			return
		end
		if isOccupied then
			SoundController.Sound("maximize_006")
		else
			SoundController.Sound("drop_001")
		end
		isOccupiedRef.current = isOccupied
	end, { isOccupied })

	local progressBar
	if props.Instance and isOccupied and props.MixerData.startTime then
		progressBar = e(MixerProgressBar, {
			StartTime = props.MixerData.startTime,
			Duration = duration,
			DrinkName = config and config.DisplayName or "",
			Config = config,
			Variation = props.MixerData.variationId,
			Size = props.MixerData.size or 1, -- NEW: Pass Size
			time = time,
			progress = progress,
		})
	end

	local interactIcon = prompt
			and BuildersIcon.GetPromptText(
				currentInput == "Gamepad" and prompt.GamepadKeyCode or prompt.KeyboardKeyCode,
				currentInput
			)
		or BuildersIcon.GetPromptText(
			currentInput == "Gamepad" and Enum.KeyCode.ButtonX or Enum.KeyCode.E,
			currentInput
		)

	local textMap = React.useCallback(function(t)
		if startTime and duration then
			local now = t
			local timePassed = now - startTime
			local p = math.clamp(timePassed / duration, 0, 1)
			local timeLeft = duration - timePassed
			if p >= 1 then
				return `{interactIcon} Pick Up`
			elseif timeLeft > 15 then
				return `{interactIcon} Skip?`
			else
				return `Mixing...`
			end
		end
		return `{interactIcon} Mix`
	end, { startTime, duration, interactIcon })

	useEffect(function()
		if not shown then
			buttonShownStart.current = math.huge
			return
		end
		buttonShownStart.current = workspace:GetServerTimeNow()
		return function()
			buttonShownStart.current = math.huge
		end
	end, { shown })

	local mappedSize = time:map(delayedRevealSizeMap(buttonShownStart, 0, UDim2.new(1, 0, 1 / 4, 0)))
	return e(React.Fragment, nil, {
		e("BillboardGui", {
			Adornee = props.Instance,
			Size = UDim2.new(6, 0, 6, 0),
			StudsOffset = Vector3.new(0, progressBar and 2 or 0, 0),
			ResetOnSpawn = false,
			AlwaysOnTop = true,
			MaxDistance = 300,
			ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
			Active = true,
		}, {
			shown and e("Highlight", {
				Adornee = props.Instance,
				FillColor = Color3.new(1, 1, 1),
				FillTransparency = 0.9,
				OutlineColor = Color3.new(1, 1, 1),
				OutlineTransparency = 0,
			}) or nil,
			WhenOccupied = progressBar and e(VStack, {
				Size = UDim2.new(1, 0, 1, 0),
				BackgroundColor3 = Color3.new(0.15, 0.15, 0.15),
				HorizontalFlex = Enum.UIFlexAlignment.None,
				VerticalFlex = Enum.UIFlexAlignment.None,
				AnchorPoint = Vector2.new(0.5, 0),
				Position = UDim2.new(0.5, 0, 0, 0),
			}, {
				ProgressBar = progressBar,
			}) or nil,
		}),
		e("BillboardGui", {
			ResetOnSpawn = false,
			Adornee = props.Instance,
			Size = UDim2.new(0, 200, 0, 100),
			StudsOffsetWorldSpace = Vector3.new(0, 0, 0),
			AlwaysOnTop = true,
			MaxDistance = math.huge,
			ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
			Active = true,
		}, {
			SmallButton = shown and e(SmallButton, {
				AnchorPoint = Vector2.new(0.5, 0),
				Size = UDim2.new(1.2, 0, 0.5, 0),
				Position = UDim2.new(0.5, 0, 0.5, 0),
				BackgroundTransparency = 1,
				Image = "rbxassetid://127657596958436",
				Rounded = false,
				ScaleType = Enum.ScaleType.Slice,
				HoverScale = true,
				SliceCenter = Rect.new(8, 8, 92, 92),
				ImageColor3 = Color3.new(0, 1, 0),
				[React.Event.MouseButton1Down] = function()
					if prompt then
						prompt:InputHoldBegin()
					end
				end,
				[React.Event.MouseButton1Up] = function()
					if prompt then
						prompt:InputHoldEnd()
					end
				end,
			}, {
				e(SmallText, {
					Text = time:map(textMap),
					Size = UDim2.new(1, 0, 1, 0),
					BackgroundTransparency = 1,
					RichText = true,
					TextSize = 24,
					TextWrapped = false,
					AutomaticSize = Enum.AutomaticSize.None,
					TextXAlignment = Enum.TextXAlignment.Center,
					TextYAlignment = Enum.TextYAlignment.Center,
				}),
			}),
		}),
	})
end

return MixerNode
