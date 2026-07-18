-- Shared/ReactComponents/MixerNode.luau
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local Promise = require(ReplicatedStorage.Packages.Promise)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local SoundController = require(ReplicatedStorage.Shared.Controllers.SoundController)
local CoffeeModule = require(ReplicatedStorage.Shared.CoffeeModule)
local UIState = require(ReplicatedStorage.Shared.producers.UIState)
local toggleMixerInteract = UIState.toggleMixerInteract
local MixerProgressBar = require(script.Parent.MixerProgressBar)
local VStack = require(script.Parent.ui.VStack)
local SmallButton = require(script.Parent.ui.SmallButton)
local TAP_ICON =
	`<font family="rbxasset://LuaPackages/Packages/_Index/BuilderIcons/BuilderIcons/BuilderIcons.json">hand-half-ellipse</font>`

local e = React.createElement
local useEffect = React.useEffect
local useState = React.useState
local useRef = React.useRef

local function MixerNode(props: {
	MixerName: string,
	MixerData: any,
	Instance: Instance?,
})
	local isOccupied = props.MixerData.drinkId ~= "none"

	-- State for asynchronously resolved descendants
	local prompt: ProximityPrompt?, setPrompt = useState(nil)
	local shown: boolean, setShown = useState(false)
	local progress, setProgress = React.useBinding(0)
	local finishRangRef = React.useRef(false)
	local time, setTime = React.useBinding(math.huge)
	local config = CoffeeModule.Config[props.MixerData.drinkId]
	local duration = (config and config.Duration) or nil
	local startTime = props.MixerData.startTime
	local mobile = useRef(false)

	React.useEffect(function()
		local running = true
		local t = task.spawn(function()
			while running do
				task.wait(1 / 15)
				if not (startTime and duration) then
					continue
				end
				local now = workspace:GetServerTimeNow()
				local timePassed = now - startTime
				local p = math.clamp(timePassed / duration, 0, 1)

				setProgress(p)
				setTime(now)

				if p >= 1 then
					if finishRangRef.current == true then
						continue
					end
					finishRangRef.current = true
					SoundController.Sound("Success")
				end
			end
		end)

		return function()
			running = false
			finishRangRef.current = false
			task.cancel(t)
		end
	end, {
		startTime,
		duration,
		-- config and config.DisplayName or "",
	})

	-- 1. Asynchronously resolve descendants following CafeTypes strictly
	useEffect(function()
		if not props.Instance then
			return
		end

		local promise = Promise.defer(function(resolve, reject)
			-- CafeTypes dictates: Mixer -> Part -> TriggerPrompt
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
			promise:cancel()
		end
	end, { props.Instance })

	-- 2. Bind the ProximityPrompt safely
	useEffect(function()
		if not prompt then
			return
		end

		prompt.ActionText = isOccupied and "Pick Up" or "Craft"
		prompt.Style = Enum.ProximityPromptStyle.Custom

		local conn = prompt.Triggered:Connect(function(player)
			if player == Players.LocalPlayer then
				if isOccupied then
					if startTime and duration then
						local now = workspace:GetServerTimeNow()
						local elapsed = now - startTime
						local left = startTime + duration - now
						if left > 30 then
							warn("skippable")
							-- Remotes.SkipMix:FireServer(props.MixerName)
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
		local conn2 = prompt.PromptShown:Connect(function(inputType: Enum.ProximityPromptInputType)
			local isMobile = inputType == Enum.ProximityPromptInputType.Touch
			mobile.current = isMobile
			setShown(true)
		end)
		local conn3 = prompt.PromptHidden:Connect(function(inputType: Enum.ProximityPromptInputType)
			local isMobile = inputType == Enum.ProximityPromptInputType.Touch
			mobile.current = isMobile
			setShown(false)
		end)

		return function()
			conn:Disconnect()
			conn2:Disconnect()
			conn3:Disconnect()
		end
	end, { prompt, isOccupied, props.MixerName })

	-- set UIState's mixernodeshown
	useEffect(function()
		if not prompt then
			return
		end
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

	-- 3. Sound Effects
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

	-- 4. Render Progress Bar
	local progressBar
	if props.Instance and isOccupied and props.MixerData.startTime then
		progressBar = e(MixerProgressBar, {
			StartTime = props.MixerData.startTime,
			Duration = duration,
			DrinkName = config and config.DisplayName or "",
			Config = config,
			Variation = props.MixerData.variationId,
			time = time,
			progress = progress,
		})
	end
	local textMap = React.useCallback(function(t)
		if not (startTime and duration) then
			return "Craft"
		end
		local now = t
		local timePassed = now - startTime
		local p = math.clamp(timePassed / duration, 0, 1)
		local timeLeft = duration - timePassed

		if p >= 1 then
			return `{mobile.current and TAP_ICON or `[E]`} Pick Up`
		elseif timeLeft > 30 then
			return `{mobile.current and TAP_ICON or `[E]`} Skip?`
		else
			return `Mixing...`
		end
		return
	end, { startTime, duration })

	return e("BillboardGui", {
		Adornee = props.Instance,
		Size = UDim2.new(6, 0, 6, 0),
		StudsOffset = Vector3.new(0, progressBar and 2 or -3, 0),
		AlwaysOnTop = true,
		MaxDistance = 50,
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
			-- Size = UDim2.new(0, 100, 0, 100),
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundColor3 = Color3.new(0.15, 0.15, 0.15),
			HorizontalFlex = Enum.UIFlexAlignment.None,
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0, 0),
		}, {
			ProgressBar = progressBar,
			Button = shown and e(SmallButton, {
				Text = time:map(textMap),
				ZIndex = 100,
				LayoutOrder = 2,
				Visible = shown,
				TextWrapped = false,
				Active = true,
				Size = UDim2.new(1, 0, 1 / 4, 0),
				TextSize = 24,
				TextTruncate = Enum.TextTruncate.SplitWord,
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
			}) or nil,
		}) or nil,
		WhenEmpty = not progressBar and e(SmallButton, {
			Text = duration and startTime and time:map(textMap) or "Craft",
			LayoutOrder = 2,
			Visible = shown,
			TextWrapped = false,
			TextSize = 24,
			ZIndex = 100,
			TextTruncate = Enum.TextTruncate.SplitWord,
			Size = UDim2.new(1, 0, 1 / 4, 0),
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
		}) or nil,
	})
end

return MixerNode
