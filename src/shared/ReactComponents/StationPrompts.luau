-- Shared/ReactComponents/StationPrompts.luau
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local ReactRoblox = require(ReplicatedStorage.Packages.ReactRoblox)
local Promise = require(ReplicatedStorage.Packages.Promise)
local ReactFlow = require(ReplicatedStorage.Packages.ReactFlow)
local Reflex = require(ReplicatedStorage.Packages.Reflex)
local UIState = require(ReplicatedStorage.Shared.producers.UIState)
local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Types = require(ReplicatedStorage.Shared.Types)

local ScreenPromptButton = require(script.Parent.ui.ScreenPromptButton)
local SmallText = require(script.Parent.ui.SmallText)

local e = React.createElement
local useState = React.useState
local useEffect = React.useEffect
local useSpring = ReactFlow.useSpring
local useTween = ReactFlow.useTween

local player = Players.LocalPlayer
local playerId = player and tostring(player.UserId) or "MockUser"
local tag = "Station" .. playerId

-- Adjust this to control how fast the timing bar fills up while holding
local TIMING_BAR_DURATION = 1.5

local function TimingBar(props: {
	prompt: ProximityPrompt,
	isClosing: boolean,
	id: string,
})
	local prompt = props.prompt
	local scoreText, setScoreText = useState("")
	local scale, setScale = useSpring({
		start = 0,
		target = 0,
		speed = 22,
		damper = 0.5,
	})
	local rot, setRot = useSpring({
		start = 0,
		target = 0,
		damper = 0.5,
		speed = 20,
	})

	local progress, setProgress = useTween({
		start = 0,
		target = 0,
		info = TweenInfo.new(0.5, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
	})
	local textY, setTextY = useTween({
		start = 0,
		target = 0,
		info = TweenInfo.new(0.6, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out),
	})
	local textScale, setTextScale = useTween({
		start = 0,
		target = 0,
		info = TweenInfo.new(0.6, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out),
	})
	local textTransparency, setTextTransparency = useTween({
		start = 1,
		target = 1,
		info = TweenInfo.new(0.6, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out),
	})

	useEffect(function()
		setScale({
			start = 0,
			target = 1,
			speed = 22,
			damper = 0.5,
		})
	end, {})

	local frameRef = React.useRef(nil)
	useEffect(function()
		if not props.isClosing then
			setScale({
				start = 0,
				target = 1,
				speed = 22,
				damper = 0.5,
			})
			return
		end

		setScale({
			start = 1,
			target = 0,
			speed = 22,
			damper = 0.5,
		})
	end, { props.isClosing })

	local station = string.match(props.id or "", "^(.+)_station$")
	useEffect(function()
		if not props.id then
			return
		end
		if not station then
			return
		end

		if station == "cup" or station == "trash" then
			return
		end

		-- Since HoldDuration is 0, Triggered fires instantly upon press
		local triggeredConn = prompt.Triggered:Connect(function()
			setProgress({
				start = 0,
				target = 1,
				info = TweenInfo.new(TIMING_BAR_DURATION, Enum.EasingStyle.Exponential, Enum.EasingDirection.In),
			})
		end)

		-- TriggerEnded fires when the player releases the button
		local triggerEndedConn = prompt.TriggerEnded:Connect(function()
			local itemId = props.itemId
			local value = progress:getValue()

			-- Lock the visual progress where they let go
			setProgress({
				target = value,
				info = TweenInfo.new(0, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
			})

			task.spawn(function()
				local validatedScore = Remotes.UseStation:InvokeServer(itemId, value)
				if validatedScore == 1 then
					setRot({
						start = 4,
						target = 0,
						damper = 0.1,
						speed = 20,
					})
				elseif validatedScore == 2 then
					setRot({
						start = 6,
						target = 0,
						damper = 0.1,
						speed = 20,
					})
					setScoreText("Nice!")
					setTextY({
						start = 0,
						target = -80,
						info = TweenInfo.new(0.6, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out),
					})
					setTextScale({
						start = 0.5,
						target = 1.2,
						info = TweenInfo.new(0.6, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out),
					})
					setTextTransparency({
						start = 0,
						target = 1,
						info = TweenInfo.new(0.6, Enum.EasingStyle.Cubic, Enum.EasingDirection.In),
					})
				elseif validatedScore == 3 then
					setRot({
						start = 8,
						target = 0,
						damper = 0.1,
						speed = 20,
					})
					setScoreText("Perfect!")
					setTextY({
						start = 0,
						target = -80,
						info = TweenInfo.new(0.6, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out),
					})
					setTextScale({
						start = 0.5,
						target = 1.3,
						info = TweenInfo.new(0.6, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out),
					})
					setTextTransparency({
						start = 0,
						target = 1,
						info = TweenInfo.new(0.6, Enum.EasingStyle.Cubic, Enum.EasingDirection.In),
					})
				end
			end)
		end)

		return function()
			triggeredConn:Disconnect()
			triggerEndedConn:Disconnect()
		end
	end, { prompt, props.id })

	if not props.id then
		return
	end
	if not station then
		return
	end

	if station == "cup" or station == "trash" then
		return
	end
	return e("Frame", {
		Size = UDim2.new(0, 300, 0, 50),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(1, -200, 1, -270), -- Sits directly above ScreenPromptButton
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = 0.3,
		BorderSizePixel = 4,
		Rotation = rot,
		ref = frameRef,
	}, {
		UICorner = e("UICorner", { CornerRadius = UDim.new(0, 4) }),
		UIStroke = e("UIStroke", {
			Thickness = 4,
			Color = Color3.new(1, 1, 1),
		}),
		UIScale = e("UIScale", { Scale = scale }),
		Score2 = e("Frame", {
			Size = UDim2.new(0.5, 0, 1, 0),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(160, 160, 20),
			BackgroundTransparency = 0.3,
			BorderSizePixel = 0,
			Position = UDim2.new(0.5, 0, 0.5, 0),
			ZIndex = -3,
		}, {
			UICorner = e("UICorner", { CornerRadius = UDim.new(0, 4) }),
		}),
		Score3 = e("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			Size = UDim2.new(0.15, 0, 1, 0),
			BackgroundTransparency = 0.3,
			BackgroundColor3 = Color3.fromRGB(50, 200, 50),
			BorderSizePixel = 0,
			ZIndex = -2,
		}, {
			UICorner = e("UICorner", { CornerRadius = UDim.new(0, 4) }),
		}),
		Score1 = e("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			Size = UDim2.new(0.8, 0, 1, 0),
			BackgroundTransparency = 0.3,
			BackgroundColor3 = Color3.fromRGB(0, 100, 0),
			BorderSizePixel = 0,
			ZIndex = -5,
		}, {
			UICorner = e("UICorner", { CornerRadius = UDim.new(0, 4) }),
		}),

		ProgressFill = e("Frame", {
			Size = UDim2.new(0, 5, 2, 0),
			Position = progress:map(function(p)
				return UDim2.new(p, 0, 0.5, 0)
			end),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 0.3,
			BorderSizePixel = 0,
		}, {
			UICorner = e("UICorner", { CornerRadius = UDim.new(0, 4) }),
		}),
		ScoreText = scoreText ~= "" and e("TextLabel", {
			Text = scoreText,
			TextSize = 32,
			Font = "FredokaOne",
			TextStrokeTransparency = 0,
			TextColor3 = scoreText == "Perfect!" and Color3.fromRGB(0, 255, 150) or Color3.fromRGB(255, 255, 100),
			Size = UDim2.new(1, 0, 1, 0),
			Position = textY:map(function(y)
				return UDim2.new(0.5, 0, 0.5, y)
			end),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			TextTransparency = textTransparency,
			TextStrokeColor3 = Color3.new(0, 0, 0),
			ZIndex = 10,
		}, {
			UIScale = e("UIScale", {
				Scale = textScale,
			}),
		}),
	})
end

local function StationPromptNode(props: { Model: Model, stationId: string })
	local prompt, setPrompt = useState(nil)

	local visible, setVisible = useState(nil)
	useEffect(function()
		local function selectPanel(state)
			return state.panel
		end
		local unsub = UIState:subscribe(selectPanel, function(panel)
			setVisible(panel == "none")
		end)
		setVisible(selectPanel(UIState:getState()) == "none")
		return unsub
	end, {})

	useEffect(function()
		if not props.Model then
			return
		end
		-- Use recursive (true) because the prompt is inside the newCenterPart!
		local foundPrompt = props.Model:FindFirstChildWhichIsA("ProximityPrompt", true)
		local promise
		if not foundPrompt then
			promise = Promise.defer(function(resolve, reject, onCancel)
				local prompt = props.Model:WaitForChild("TriggerPrompt", 5)
				if not prompt then
					reject("not prompt")
				end
				resolve(prompt)
			end)
				:andThen(setPrompt)
				:catch(function(err)
					warn("err", err)
				end)
		end

		setPrompt(foundPrompt)
		return function()
			setPrompt(nil)
			if promise then
				promise:cancel()
			end
		end
	end, { props.Model })

	local shown, setShown = useState(false)
	useEffect(function()
		if not (prompt and prompt.Parent) then
			return
		end
		prompt.Style = Enum.ProximityPromptStyle.Custom
		local conn1 = prompt.PromptShown:Connect(function()
			setShown(true)
		end)
		local conn2 = prompt.PromptHidden:Connect(function()
			setShown(false)
		end)
		return function()
			setShown(false)
			conn1:Disconnect()
			conn2:Disconnect()
		end
	end, { prompt, prompt and prompt.Parent })

	return e(React.Fragment, {}, {
		TimingBar = prompt and e(TimingBar, {
			prompt = prompt,
			isClosing = not (visible and shown),
			id = props.stationId, -- Fallback to use as ingredientId
			itemId = props.Model.Name,
		}),
		PromptBtn = e(ScreenPromptButton, {
			ProximityPrompt = prompt,
			Position = UDim2.new(1, -200, 1, -200),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.fromOffset(200, 50),
			Visible = visible and shown,
		}, {
			e(SmallText, {
				Size = UDim2.new(1, 0, 1, 0),
				TextXAlignment = Enum.TextXAlignment.Center,
				Text = prompt and prompt.ActionText or "",
			}),
		}),
		hi = props.Model and ReactRoblox.createPortal({
			e("Highlight", {
				Adornee = props.Model,
				Enabled = visible and shown,
				FillColor = Color3.new(1, 1, 1),
				FillTransparency = 0.4,
				OutlineColor = Color3.new(),
			}),
		}, props.Model) or nil,
	})
end

return function()
	local instances, setInstances = useState({})
	local placedItems, setPlacedItems = useState(nil)
	local spatialItems, setSpatialItems = useState(nil)

	useEffect(function()
		local function updateInstances()
			setInstances(CollectionService:GetTagged(tag))
		end

		local onTagAdded = CollectionService:GetInstanceAddedSignal(tag):Connect(updateInstances)
		local onTagRemoved = CollectionService:GetInstanceRemovedSignal(tag):Connect(updateInstances)

		updateInstances()

		local unsub = GlobalState:subscribe(function(state: GlobalState.GlobalState)
			return state.Plot[playerId] and state.Plot[playerId] or nil
		end, function(plot)
			if not plot then
				return
			end

			setPlacedItems(plot.placedItems)
			setSpatialItems(plot.spatialItems)
		end)
		local playersPlot = GlobalState:getState().Plot[playerId]
		setPlacedItems(playersPlot and playersPlot.placedItems or nil)
		setSpatialItems(playersPlot and playersPlot.spatialItems or nil)

		return function()
			onTagAdded:Disconnect()
			onTagRemoved:Disconnect()
			unsub()
		end
	end, {})

	if not instances or #instances == 0 then
		return nil
	end

	local children = {}
	-- warn("🔄️🔄️🔄️placedItems", placedItems and true or false)
	for _, instance in ipairs(instances) do
		-- Using the instance's UUID name as the React key
		local placedItemId = placedItems and placedItems[instance.Name] and placedItems[instance.Name].id or nil
		-- warn("placedItemId", placedItemId)
		local spatialItemId = spatialItems and spatialItems[instance.Name] and spatialItems[instance.Name].id or nil
		-- warn("spatialItemId", spatialItemId)
		local id = placedItemId or spatialItemId or nil
		-- warn("id", id)
		children[instance.Name] = e(StationPromptNode, {
			Model = instance,
			stationId = id,
		})
	end

	return e(React.Fragment, {}, children)
end
