-- Shared/ReactComponents/Spawner.luau
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local React = require(ReplicatedStorage.Packages.React)
local Mionum = require(ReplicatedStorage.Packages.Mionum)
local Promise = require(ReplicatedStorage.Packages.Promise)
local ReactFlow = require(ReplicatedStorage.Packages.ReactFlow)
local ReactRoblox = require(ReplicatedStorage.Packages.ReactRoblox)
local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local UIState = require(ReplicatedStorage.Shared.producers.UIState)
local SmallButton = require(ReplicatedStorage.Shared.ReactComponents.ui.SmallButton)
local CoffeeModule = require(ReplicatedStorage.Shared.CoffeeModule)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Types = require(ReplicatedStorage.Shared.Types)
local SmallText = require(ReplicatedStorage.Shared.ReactComponents.ui.SmallText)
local SoundController = require(ReplicatedStorage.Shared.Controllers.SoundController)
local DispatchEvent = require(ReplicatedStorage.Shared.Controllers.DispatchEvent)

local BuildersIcon = require(ReplicatedStorage.Shared.Utils.BuildersIcon)
local useInputDevice = require(ReplicatedStorage.Shared.Hooks.useInputDevice)

local e = React.createElement
local ANIM_DURATION = 1
local useEffect = React.useEffect
local useMemo = React.useMemo
local useState = React.useState
local useBinding = React.useBinding
local useRef = React.useRef
local useSpring = ReactFlow.useSpring

local player = game.Players.LocalPlayer
local playerId = player and tostring(player.UserId) or ""

local spawnerTag = playerId .. "Spawner"
local buyPadTag = playerId .. "BuyPad"

export type BuyPad = Model & {
	Part: Part,
	TriggerPart: Part & {
		TriggerPrompt: ProximityPrompt,
	},
}

export type Spawner = Model & {
	Part: Part & {
		TriggerPrompt: ProximityPrompt,
	},
}

-- [NEW] Isolated Component for Individual Ingredients
function SpawnedIngredient(props: {
	Instance: Instance,
	IngredientId: string,
	Index: number,
	TotalCount: number,
	Phase: "empty" | "spin" | "show",
	ModelsCache: { Model }?,
})
	local size, setSize = useSpring({
		start = 0,
		target = 24,
		damper = 1,
		speed = 20,
	})

	-- Perfectly fan out items left to right
	local offset = (props.Index - (props.TotalCount + 1) / 2) * 2

	-- Flawlessly stagger the Y position based on even/odd indices to prevent UI overlay
	local yOffset = 3 + (props.Index % 2 == 0 and 1.5 or 0)

	useEffect(function()
		if props.Phase == "empty" or not props.Instance then
			return
		end

		local isCancelled = false
		local activeModel = nil
		local spinPool = {} -- Keeps track of cloned models to reuse
		local cframeValue = nil
		local scaleValue = nil
		local updateConn = nil
		local tween = nil
		local spinThread = nil

		local function cleanup()
			isCancelled = true

			if activeModel then
				activeModel:Destroy()
			end

			-- Destroy all pooled models to free up memory when phase changes
			for _, pooledModel in pairs(spinPool) do
				if pooledModel then
					pooledModel:Destroy()
				end
			end
			table.clear(spinPool)

			if cframeValue then
				cframeValue:Destroy()
			end
			if scaleValue then
				scaleValue:Destroy()
			end
			if updateConn then
				updateConn:Disconnect()
			end
			if tween then
				tween:Cancel()
			end
			if spinThread then
				task.cancel(spinThread)
			end
		end

		local centerCFrame = props.Instance:GetPivot() * CFrame.new(0, -5, 0)
		local targetCFrame = props.Instance:GetPivot() * CFrame.new(offset, yOffset, 0)

		if props.Phase == "spin" then
			cframeValue = Instance.new("CFrameValue")
			cframeValue.Value = centerCFrame
			cframeValue.Changed:Connect(function(cf)
				if activeModel then
					activeModel:PivotTo(cf)
				end
			end)

			tween = TweenService:Create(
				cframeValue,
				TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
				{ Value = targetCFrame }
			)
			tween:Play()

			spinThread = task.defer(function()
				local cache = props.ModelsCache
				while not isCancelled and cache and #cache > 0 do
					local randomIndex = math.random(1, #cache)
					local nextModel = spinPool[randomIndex]

					-- Lazy clone: Only clone if we haven't rolled this specific model yet
					if not nextModel then
						nextModel = cache[randomIndex]:Clone()
						spinPool[randomIndex] = nextModel
					end

					-- REPARENT logic: Hide the old one, show the new one. No destroying!
					if activeModel and activeModel ~= nextModel then
						activeModel.Parent = nil
					end

					activeModel = nextModel
					activeModel:PivotTo(cframeValue.Value)
					activeModel.Parent = workspace
					activeModel:ScaleTo(1)

					task.wait(0.1)
				end
			end)
		elseif props.Phase == "show" then
			if props.IngredientId == "none" then
				return cleanup
			end

			local modelTemplate = ReplicatedStorage.Shared.Models:FindFirstChild(props.IngredientId)
			if not modelTemplate then
				warn("NOT MODEL", props.IngredientId)
				return cleanup
			end

			-- Dynamic Ascending Pitch! Each iteration scales up the playback speed slightly!
			SoundController.Sound("skate-trick-1", {
				PlaybackSpeed = 1 + (props.Index * 0.1),
			})
			-- warn("played", props.IngredientId)

			setSize({
				start = 0,
				target = 32,
				damper = 0.4,
				speed = 30,
			})

			activeModel = modelTemplate:Clone()
			local packageLink = activeModel:FindFirstChildWhichIsA("PackageLink")
			if packageLink then
				packageLink:Destroy()
			end

			activeModel:PivotTo(targetCFrame)
			activeModel.Parent = workspace

			scaleValue = Instance.new("NumberValue")
			scaleValue.Value = 0.1
			activeModel:ScaleTo(0.1)

			updateConn = scaleValue.Changed:Connect(function(newScale)
				if activeModel and activeModel.Parent then
					activeModel:ScaleTo(newScale)
				end
			end)

			tween = TweenService:Create(
				scaleValue,
				TweenInfo.new(ANIM_DURATION, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out, 0, false, 0),
				{ Value = 1 }
			)
			tween:Play()
		end

		return cleanup
	end, { props.Phase, props.IngredientId, props.Index, props.TotalCount, props.Instance })

	local config = CoffeeModule.IngredientLookup[props.IngredientId]

	return props.Phase == "show"
			and config
			and e("Part", {
				Transparency = 1,
				Anchored = true,
				CanCollide = false,
				Size = Vector3.new(0.01, 0.01, 0.01),
				CFrame = props.Instance:GetPivot() * CFrame.new(offset, yOffset + 2, 0),
				Parent = props.Instance,
			}, {
				NameTag = e("BillboardGui", {
					Size = UDim2.new(0, 200, 0, 50),
					AlwaysOnTop = true,
					MaxDistance = 50,
					ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
					Active = true,
				}, {
					SmallText = e(SmallText, {
						Text = config.DisplayName,
						TextXAlignment = Enum.TextXAlignment.Center,
						Size = UDim2.new(1, 0, 1, 0),
						TextSize = size,
						AnchorPoint = Vector2.new(0.5, 0),
						Position = UDim2.new(0.5, 0, -0.5, 0),
					}),
				}),
			})
		or nil
end

local function Spawner(props)
	local spawner, setSpawner = useState({})
	local buyPadInstance, setBuyPadInstance = useState(nil)
	local spawnerInstance: Spawner, setSpawnerInstance = useState(nil)

	useEffect(function()
		local unsubSpawner = GlobalState:subscribe(function(state)
			return state.Spawner[playerId]
		end, function(newMixers)
			setSpawner(newMixers or {})
		end)

		local state = GlobalState:getState()
		if state.Spawner and state.Spawner[playerId] then
			setSpawner(state.Spawner[playerId])
		end

		if not player then
			task.defer(function()
				task.wait(1)
				setSpawner({ IngredientIds = { "milk", "milk" }, TimePulled = workspace:GetServerTimeNow() })
				task.wait(1)
				setSpawner({ IngredientIds = { "milk", "milk" }, TimePulled = workspace:GetServerTimeNow() })
				task.wait(1)
				setSpawner({ IngredientIds = { "milk", "milk" }, TimePulled = workspace:GetServerTimeNow() })
				task.wait(1)
				setSpawner({ IngredientIds = { "milk", "milk" }, TimePulled = workspace:GetServerTimeNow() })
			end)
		end

		local unsubBuy = DispatchEvent.OnEvent("buyIngredientFromSpawner", function(_playerId: string)
			if _playerId == playerId then
				SoundController.Sound("glass_004")
			end
		end)
		return function()
			unsubSpawner()
			unsubBuy()
		end
	end, { playerId })

	useEffect(function()
		local function syncSpawner()
			local currentInstances
			for _, inst in ipairs(CollectionService:GetTagged(spawnerTag)) do
				currentInstances = inst
				break
			end
			UIState.setSpawnerInstance(currentInstances)
			setSpawnerInstance(currentInstances)
		end
		local function syncBuyPad()
			local currentInstances
			for _, inst in ipairs(CollectionService:GetTagged(buyPadTag)) do
				currentInstances = inst
				break
			end
			UIState.setBuypadInstance(currentInstances)
			setBuyPadInstance(currentInstances)
		end

		syncBuyPad()
		syncSpawner()

		local connAdd = CollectionService:GetInstanceAddedSignal(buyPadTag):Connect(syncBuyPad)
		local connRem = CollectionService:GetInstanceRemovedSignal(buyPadTag):Connect(syncBuyPad)
		local connAdd2 = CollectionService:GetInstanceAddedSignal(spawnerTag):Connect(syncSpawner)
		local connRem2 = CollectionService:GetInstanceRemovedSignal(spawnerTag):Connect(syncSpawner)

		return function()
			connAdd:Disconnect()
			connRem:Disconnect()
			connAdd2:Disconnect()
			connRem2:Disconnect()
			setSpawnerInstance(nil)
			setBuyPadInstance(nil)
		end
	end, { playerId })

	local children = {}

	children.Spawner = e(SpawnerNode, {
		Instance = spawnerInstance,
	})
	children.BuyPad = e(BuyPadNode, {
		Instance = buyPadInstance,
		IngredientIds = spawner.IngredientIds,
		TimePulled = spawner.TimePulled,
	})

	return e(React.Fragment, nil, children)
end

local GRAY = Color3.new(0.5, 0.5, 0.5)
local WHITE = Color3.new(1, 1, 1)

function SpawnerNode(props: { Instance: Spawner? })
	local currentInput = useInputDevice()

	local time, setTime = useBinding(0)
	local lastRolled, setLastRolled = useState(0)
	local rollCooldown, setRollCooldown = useState(0)

	local shown, setShown = useState(false)
	local prompt: ProximityPrompt, setPrompt = useState(nil)

	useEffect(function()
		if not props.Instance then
			return
		end
		local promise = Promise.defer(function(resolve)
			setPrompt(props.Instance:WaitForChild("Part"):WaitForChild("TriggerPrompt"))
			return resolve()
		end):catch(function(err)
			warn(`Spawner's triggerprompt error: {err}`)
		end)
		return function()
			promise:cancel()
		end
	end, { props.Instance })

	useEffect(function()
		if not prompt then
			return
		end
		prompt.RequiresLineOfSight = false
		local conn = prompt.PromptShown:Connect(function()
			UIState.setSpawnerPromptShown(true)
			setShown(true)
		end)
		local conn2 = prompt.PromptHidden:Connect(function()
			UIState.setSpawnerPromptShown(false)
			setShown(false)
		end)
		local conn3 = prompt.Triggered:Connect(function()
			Remotes.RollIngredient:FireServer()
		end)
		return function()
			conn:Disconnect()
			conn2:Disconnect()
			conn3:Disconnect()
		end
	end, { prompt })

	useEffect(function()
		local t = task.defer(function()
			while task.wait(1 / 15) do
				setTime(workspace:GetServerTimeNow())
			end
		end)
		local unsub = GlobalState:subscribe(function(state: GlobalState.GlobalState)
			local lastRolled = state.Spawner[playerId] and state.Spawner[playerId].TimePulled
			if lastRolled then
				setLastRolled(lastRolled)
			end
		end)
		local unsub2 = GlobalState:subscribe(function(state: GlobalState.GlobalState)
			local rollCooldown = state.Stats[playerId] and state.Stats[playerId].RollCooldown
			if rollCooldown then
				setRollCooldown(rollCooldown)
			end
		end)
		return function()
			if t then
				task.cancel(t)
			end
			unsub()
			unsub2()
		end
	end, {})

	local colorMap = React.useMemo(function()
		return time:map(function(n)
			return n < lastRolled + rollCooldown and GRAY or WHITE
		end)
	end, { lastRolled, rollCooldown })

	-- Derived automatically based on the hook and prompt config!
	local interactIcon = prompt
			and BuildersIcon.GetPromptText(
				currentInput == "Gamepad" and prompt.GamepadKeyCode or prompt.KeyboardKeyCode,
				currentInput
			)
		or BuildersIcon.GetPromptText(
			currentInput == "Gamepad" and Enum.KeyCode.ButtonY or Enum.KeyCode.F,
			currentInput
		)

	return e("SurfaceGui", {
		PixelsPerStud = 50,
		ResetOnSpawn = false,
		Adornee = props.Instance and props.Instance:FindFirstChild("Part") or nil,
		SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud,
	}, {
		Button = shown and e(SmallButton, {
			Text = `Summon\n{interactIcon}`,
			Size = UDim2.new(1, 0, 1, 0),
			TextScaled = true,
			TextColor3 = colorMap,
			[React.Event.Activated] = function()
				Remotes.RollIngredient:FireServer()
			end,
			RichText = true,
		}),
	})
end

function BuyPadNode(props: { Instance: Instance?, IngredientIds: { string }?, TimePulled: number })
	local currentInput = useInputDevice()

	local randomModels = useRef({})

	local prompt: ProximityPrompt, setPrompt = useState(nil)
	local shown, setShown = useState(false)
	local cash, setCash = useState(0)

	local phase, setPhase = useState("empty") -- "empty" | "spin" | "reveal"
	local revealedCount, setRevealedCount = useState(0)
	local promptRef = useRef(nil)

	-- [NEW] Track the last pull time to intercept 1-frame React tears
	local lastTimePulled = useRef(props.TimePulled)

	useEffect(function()
		if not props.Instance then
			return
		end
		local promise = Promise.defer(function(resolve)
			setPrompt(props.Instance:WaitForChild("TriggerPart"):WaitForChild("TriggerPrompt"))
			return resolve()
		end):catch(function(err)
			warn(`err:{err}`)
		end)
		return function()
			promise:cancel()
		end
	end, { props.Instance })

	useEffect(function()
		promptRef.current = prompt
	end, { prompt })

	local totalCost = 0
	for i, id in props.IngredientIds or {} do
		local config = CoffeeModule.IngredientLookup[id]
		if config then
			totalCost += config.Cost
		end
	end

	local promptBuyText = useRef("Buy")
	promptBuyText.current = totalCost > 0 and `Buy ({Mionum.new(totalCost):toString()})` or ""

	useEffect(function()
		if not prompt then
			return
		end
		prompt.Style = Enum.ProximityPromptStyle.Custom
		prompt.RequiresLineOfSight = false
		local conn = prompt.Triggered:Connect(function()
			Remotes.BuyIngredientFromSpawner:FireServer()
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
	end, { prompt })

	useEffect(function()
		local unsub = GlobalState:subscribe(function(state: GlobalState.GlobalState)
			local playerStats = state.Stats[playerId]
			if playerStats then
				setCash(playerStats.Cash)
			end
		end)
		return unsub
	end, {})

	useEffect(function()
		local models = {}
		local cache = Instance.new("Folder", ReplicatedStorage)
		cache.Name = "__cache"

		for i, config in CoffeeModule.IngredientConfigs do
			local template = ReplicatedStorage.Shared.Models:FindFirstChild(config.Id)
			if not template then
				continue
			end

			local model = template:Clone()
			model.Parent = cache
			local packageLink = model:FindFirstChild("PackageLink")
			for i, desc in model:GetDescendants() do
				if desc:IsA("BasePart") then
					desc.CanCollide = false
				end
			end
			if packageLink then
				packageLink:Destroy()
			end

			local hi = Instance.new("Highlight", model)
			hi.FillColor = Color3.new()
			hi.FillTransparency = 0.2
			hi.DepthMode = Enum.HighlightDepthMode.Occluded
			table.insert(models, model)
		end
		randomModels.current = models
		return function()
			for i = #models, 1, -1 do
				models[i]:Destroy()
				models[i] = nil
			end
			cache:Destroy()
			randomModels.current = {}
		end
	end, {})

	local combinedIds = props.IngredientIds and table.concat(props.IngredientIds) or nil
	local count = props.IngredientIds and #props.IngredientIds or 0

	-- [NEW] Calculate Effective State for this exact render frame!
	local isNewRoll = props.TimePulled ~= lastTimePulled.current
	local activePhase = phase
	local activeRevealedCount = revealedCount

	if count == 0 then
		activePhase = "empty"
		activeRevealedCount = 0
	elseif isNewRoll then
		-- Force the spin phase immediately if a new roll just came in!
		activePhase = "spin"
		activeRevealedCount = 0
	end

	useEffect(function()
		-- Sync the ref now that we are processing the new effect
		lastTimePulled.current = props.TimePulled

		if count == 0 then
			setPhase("empty")
			setRevealedCount(0)
			return
		end

		local isCancelled = false
		setPhase("spin")
		setRevealedCount(0)

		local promise = Promise.defer(function(resolve, reject, onCancel)
			onCancel(function()
				isCancelled = true
			end)

			local state = GlobalState:getState()
			local rollCooldown = (state.Stats and state.Stats[playerId] and state.Stats[playerId].RollCooldown) or 1
			local start = workspace:GetServerTimeNow()

			while workspace:GetServerTimeNow() - start < rollCooldown do
				if isCancelled then
					return
				end
				SoundController.Sound("glass_005")
				task.wait(0.1)
			end

			if isCancelled then
				return
			end
			setPhase("reveal")

			for i = 1, count do
				if isCancelled then
					return
				end
				setRevealedCount(i)
				task.wait(0.25)
			end
			resolve()
		end):catch(function(err)
			if err ~= Promise.Error.Cancelled then
				warn(`Timeline Error: {err}`)
			end
		end)

		return function()
			promise:cancel()
		end
	end, { combinedIds, props.TimePulled, count })

	useEffect(function()
		if not promptRef.current then
			return
		end
		if activePhase == "empty" then
			promptRef.current.Enabled = true
		elseif activePhase == "spin" then
			promptRef.current.Enabled = false
		elseif activePhase == "reveal" and activeRevealedCount == count then
			promptRef.current.Enabled = true
		end
	end, { activePhase, activeRevealedCount, count })

	local ingredientElements = {}
	for i = 1, count do
		local id = props.IngredientIds[i]
		local itemPhase = "empty"

		-- [NEW] Rely exclusively on the active intercept state
		if activePhase == "spin" then
			itemPhase = "spin"
		elseif activePhase == "reveal" then
			itemPhase = (i <= activeRevealedCount) and "show" or "spin"
		end

		ingredientElements["Ingredient_" .. i] = e(SpawnedIngredient, {
			Instance = props.Instance,
			IngredientId = id,
			Index = i,
			TotalCount = count,
			Phase = itemPhase,
			ModelsCache = randomModels.current,
		})
	end

	-- Derived automatically based on the hook and prompt config!
	local interactIcon = prompt
			and BuildersIcon.GetPromptText(
				currentInput == "Gamepad" and prompt.GamepadKeyCode or prompt.KeyboardKeyCode,
				currentInput
			)
		or BuildersIcon.GetPromptText(
			currentInput == "Gamepad" and Enum.KeyCode.ButtonX or Enum.KeyCode.E,
			currentInput
		)

	local finalBuyText = `{interactIcon} {promptBuyText.current}`

	ingredientElements.Prompt = (player or props.Instance)
			and ReactRoblox.createPortal({
				e("BillboardGui", {
					ResetOnSpawn = false,
					Adornee = props.Instance,
					Size = UDim2.new(0, 200, 0, 100),
					StudsOffsetWorldSpace = Vector3.new(0, 0, 0),
					AlwaysOnTop = true,
					MaxDistance = 50,
					ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
					Active = true,
				}, {
					SmallButton = (activePhase == "reveal" and activeRevealedCount == count)
						and shown
						and finalBuyText
						and e(SmallButton, {
							AnchorPoint = Vector2.new(0.5, 0),
							Size = UDim2.new(1.2, 0, 0.5, 0),
							Position = UDim2.new(0.5, 0, 0.5, 0),
							TextWrapped = false,
							[React.Event.Activated] = function()
								Remotes.BuyIngredientFromSpawner:FireServer()
							end,
							BackgroundTransparency = 1,
							Image = "rbxassetid://127657596958436",
							Rounded = false,
							ScaleType = Enum.ScaleType.Slice,
							HoverScale = true,
							SliceCenter = Rect.new(8, 8, 92, 92),
							ImageColor3 = (totalCost > 0 and cash and totalCost > cash) and Color3.new(1, 0, 0)
								or Color3.new(0, 1, 0),
						}, {
							e(SmallText, {
								Text = finalBuyText,
								Size = UDim2.new(1, 0, 1, 0),
								BackgroundTransparency = 1,
								RichText = true,
								TextWrapped = false,
								TextSize = 32,
								AutomaticSize = Enum.AutomaticSize.None,
								TextXAlignment = Enum.TextXAlignment.Center,
								TextYAlignment = Enum.TextYAlignment.Center,
							}, {}),
						}),
				}),
			}, (player and player.PlayerGui) or props.Instance)
		or nil

	return e(React.Fragment, nil, ingredientElements)
end

return Spawner
