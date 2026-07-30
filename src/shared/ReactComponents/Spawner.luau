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

local TAP_ICON =
	`<font family="rbxasset://LuaPackages/Packages/_Index/BuilderIcons/BuilderIcons/BuilderIcons.json">hand-half-ellipse</font>`

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
		TriggerPrompt: ProximityPrompt, -- wait for this child
	},
}

export type Spawner = Model & {
	Part: Part & {
		TriggerPrompt: ProximityPrompt,
	},
}

local function MixerManager(props)
	local spawner, setSpawner = useState({})
	local buyPadInstance, setBuyPadInstance = useState(nil)
	local spawnerInstance: Spawner, setSpawnerInstance = useState(nil)

	useEffect(function()
		--subscribe to spawner
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
				setSpawner({
					IngredientIds = { "milk", "milk" },
					TimePulled = workspace:GetServerTimeNow(),
				})
				task.wait(1)
				setSpawner({
					IngredientIds = { "milk", "milk" },
					TimePulled = workspace:GetServerTimeNow(),
				})
				task.wait(1)
				setSpawner({
					IngredientIds = { "milk", "milk" },
					TimePulled = workspace:GetServerTimeNow(),
				})
				task.wait(1)
				setSpawner({
					IngredientIds = { "milk", "milk" },
					TimePulled = workspace:GetServerTimeNow(),
				})
			end)
		end

		local unsubBuy = DispatchEvent.OnEvent("buyIngredientFromSpawner", function(
			_playerId: string--[[, payload: Types.BuyIngredientFromSpawnerPayload]]
		)
			if _playerId == playerId then
				SoundController.Sound("glass_004")
			end
		end)
		return function()
			unsubSpawner()
			unsubBuy()
		end
	end, { playerId })

	-- 2. Subscribe to the generic CollectionService tag
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
			setBuyPadInstance(currentInstances)
		end

		-- Initial sync
		syncBuyPad()
		syncSpawner()

		-- Listen for chunks streaming in/out
		local connAdd = CollectionService:GetInstanceAddedSignal(buyPadTag):Connect(syncBuyPad)
		local connRem = CollectionService:GetInstanceRemovedSignal(buyPadTag):Connect(syncBuyPad)
		local connAdd2 = CollectionService:GetInstanceAddedSignal(spawnerTag):Connect(syncSpawner)
		local connRem2 = CollectionService:GetInstanceRemovedSignal(spawnerTag):Connect(syncSpawner)

		return function()
			connAdd:Disconnect()
			connRem:Disconnect()
			connAdd2:Disconnect()
			connRem2:Disconnect()
		end
	end, { playerId })

	local children = {}

	children.Spawner = e(SpawnerNode, {
		Instance = spawnerInstance, -- Inject the physical instance
	})
	children.BuyPad = e(BuyPadNode, {
		Instance = buyPadInstance, -- Inject the physical instance
		IngredientIds = spawner.IngredientIds,
		TimePulled = spawner.TimePulled,
	})

	return e(React.Fragment, nil, children)
end

local GRAY = Color3.new(0.5, 0.5, 0.5)
local WHITE = Color3.new(1, 1, 1)
function SpawnerNode(props: { Instance: Spawner? })
	local time, setTime = useBinding(0)
	local lastRolled, setLastRolled = useState(0)
	local rollCooldown, setRollCooldown = useState(0)

	local shown, setShown = useState(nil)
	local prompt: ProximityPrompt, setPrompt = useState(nil)
	local text, setText = useState("Summon")

	useEffect(function()
		if not props.Instance then
			return
		end

		local promise = Promise.defer(function(resolve, reject, onCancel)
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

		local conn = prompt.PromptShown:Connect(function(inputType: Enum.ProximityPromptInputType)
			local isMobile = inputType == Enum.ProximityPromptInputType.Touch
			local isConsole = inputType == Enum.ProximityPromptInputType.Gamepad
			setText("Summon\n" .. (isConsole and `(Y)` or isMobile and TAP_ICON or `[F]`))
			UIState.setSpawnerPromptShown(true)
			setShown(true)
		end)
		local conn2 = prompt.PromptHidden:Connect(function(inputType: Enum.ProximityPromptInputType)
			local isMobile = inputType == Enum.ProximityPromptInputType.Touch
			local isConsole = inputType == Enum.ProximityPromptInputType.Gamepad
			setText("Summon\n" .. (isConsole and `(Y)` or isMobile and TAP_ICON or `[F]`))
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
			local color = n < lastRolled + rollCooldown and GRAY or WHITE
			return color
		end)
	end, { lastRolled, rollCooldown })

	return e("SurfaceGui", {
		PixelsPerStud = 50,
		Adornee = props.Instance and props.Instance:FindFirstChild("Part") or nil,
		SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud,
	}, {
		Button = shown and e(SmallButton, {
			Text = text,
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

function BuyPadNode(props: { Instance: Instance?, IngredientId: string?, TimePulled: number })
	local randomModels = useRef({})

	local prompt: ProximityPrompt, setPrompt = useState(nil)
	local shown, setShown = useState(false)
	local cash, setCash = useState(false)
	local phase: "spin" | "show" | "empty", setPhase = useState("empty")

	useEffect(function()
		if not props.Instance then
			return
		end
		local promise = Promise.defer(function(resolve, reject, onCancel)
			setPrompt(props.Instance:WaitForChild("TriggerPart"):WaitForChild("TriggerPrompt"))
			return resolve
		end):catch(function(err)
			warn(`err:{err}`)
		end)
		return function()
			promise:cancel()
		end
	end, { props.Instance })

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
			if conn then
				conn:Disconnect()
			end
			if conn2 then
				conn2:Disconnect()
			end
			if conn3 then
				conn3:Disconnect()
			end
		end
	end, { prompt })

	useEffect(function()
		local unsub = GlobalState:subscribe(function(state: GlobalState.GlobalState)
			local playerStats = state.Stats[playerId]
			if not playerStats then
				setCash(0)
				return
			end
			setCash(playerStats.Cash)
		end)
		return unsub
	end, {})

	useEffect(function()
		local models = {}
		local cache = Instance.new("Folder", ReplicatedStorage)
		cache.Name = "__cache"

		local configs = CoffeeModule.IngredientConfigs

		for i, config in configs do
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
			table.insert(models, model)
		end
		randomModels.current = models
		return function()
			for i = #models, 1, -1 do
				local model = models[i]
				model:Destroy()
				models[i] = nil
			end
			cache:Destroy()
			randomModels.current = {}
		end
	end, {})

	local prevDrinkIdRef = useRef(nil)
	local size, setSize = useSpring({
		start = 0,
		target = 24,
		damper = 1,
		speed = 20,
	})
	local promptRef = useRef(nil)
	local combinedIds = props.IngredientIds and table.concat(props.IngredientIds) or nil
	-- rely on combined, so it wont reset to phase "spin" when reflex rehydrates

	useEffect(function()
		if props.IngredientIds == nil or not promptRef.current then
			return
		end
		if #props.IngredientIds > 0 then
			-- new time means spin
			promptRef.current.Enabled = false
			setPhase("spin")
		else
			-- just bought
			promptRef.current.Enabled = true
			setPhase("empty")
		end
	end, { combinedIds, props.TimePulled })

	useEffect(function()
		promptRef.current = prompt
	end, { prompt })

	-- useEffect(function()
	-- 	warn(`\nphase == "show" ({phase == "show"}), \nshown ({shown}), combinedIds ({combinedIds})`)
	-- end, { phase == "show", shown, combinedIds })
	-- The Magic Spin + Tween Animation Effect
	useEffect(function()
		if not (props.IngredientIds and props.Instance) then
			return
		end

		if not prevDrinkIdRef.current then
			prevDrinkIdRef.current = props.IngredientIds
		end

		local activeSpinModel = nil -- Keep track of the spinning cached model
		local finalModels = {} -- Keep track of the final tweened models

		-- We defer the initial spin promise
		local promise = Promise.defer(function(resolve, reject, onCancel)
			local state = GlobalState:getState()
			local rollCooldown = (state.Stats and state.Stats[playerId] and state.Stats[playerId].RollCooldown) or 1

			local modelsList = randomModels.current
			local startTime = workspace:GetServerTimeNow()
			local cancelled = false

			onCancel(function()
				cancelled = true
			end)

			setPhase("spin")
			if promptRef.current and promptRef.current.Parent then
				promptRef.current.Enabled = false
			end -- SPIN PHASE! Cycle through models at rapid speed by hiding and showing
			if #modelsList > 0 and props.IngredientIds and #props.IngredientIds ~= 0 then
				while workspace:GetServerTimeNow() - startTime < rollCooldown and not cancelled do
					-- Hide the previous model by removing it from the workspace
					if activeSpinModel then
						activeSpinModel.Parent = nil
					end
					SoundController.Sound("glass_005")

					-- Grab a random pre-cloned model from the ref
					activeSpinModel = modelsList[math.random(1, #modelsList)]
					activeSpinModel:PivotTo(props.Instance:GetPivot() + Vector3.new(0, 2, 0))
					activeSpinModel.Parent = workspace
					activeSpinModel:ScaleTo(1)

					task.wait(0.1)
				end
			end

			if cancelled then
				return
			end

			-- Safely hide the last spinning model before doing our beautiful final reveal
			if activeSpinModel then
				activeSpinModel.Parent = nil
				activeSpinModel = nil
			end

			resolve()
		end)
			:andThen(function()
				-- FINAL REVEAL PHASE!
				local promises = {}
				for i, id in props.IngredientIds do
					table.insert(
						promises,
						Promise.defer(function(resolve, reject, onCancel)
							task.wait(i / 8)
							if id == "none" then
								return resolve()
							end

							SoundController.Sound("glass_003")
							setPhase("show")
							if promptRef.current and promptRef.current.Parent then
								promptRef.current.Enabled = true
							end
							setSize({
								start = 0,
								target = 32,
								damper = 0.4,
								speed = 30,
							})

							local modelTemplate = ReplicatedStorage.Shared.Models:FindFirstChild(id)
							if not modelTemplate then
								warn("NOT MODEL", id)
								return resolve()
							end

							-- We clone the actual final model here since it stays out permanently
							local finalModel = modelTemplate:Clone()
							table.insert(finalModels, finalModel)
							local packageLink = finalModel:FindFirstChildWhichIsA("PackageLink")
							if packageLink then
								packageLink:Destroy()
							end
							finalModel:PivotTo(props.Instance:GetPivot() + Vector3.new(0, 2 * (i - 0), 0))
							finalModel.Parent = workspace

							local scaleValue = Instance.new("NumberValue")
							scaleValue.Value = 0.1
							finalModel:ScaleTo(0.1)

							local updateConn = scaleValue.Changed:Connect(function(newScale)
								if finalModel then
									finalModel:ScaleTo(newScale)
								end
							end)
							onCancel(function()
								if updateConn then
									updateConn:Disconnect()
								end
								scaleValue:Destroy()
							end)

							local tween = TweenService:Create(
								scaleValue,
								TweenInfo.new(
									ANIM_DURATION,
									Enum.EasingStyle.Bounce,
									Enum.EasingDirection.Out,
									0,
									false,
									0
								),
								{ Value = 1 }
							)

							tween:Play()
							tween.Completed:Wait()

							if updateConn then
								updateConn:Disconnect()
							end
							scaleValue:Destroy()
							warn("Done")
							return resolve()
						end)
					)
				end
				return Promise.all(promises)
			end)
			:catch(function(err)
				if err ~= Promise.Error.Cancelled then
					warn(`Animation Chain Error: {err}`)
				end
			end)

		return function()
			promise:cancel()
			-- Ensures whatever cached model is currently flashing gets safely hidden
			if activeSpinModel then
				activeSpinModel.Parent = nil
			end
			-- Safely destroy the final spawned model if we unmount
			for i, finalModel in finalModels do
				if finalModel and finalModel.Parent then
					finalModel:Destroy()
				end
			end
		end
	end, { props.Instance, combinedIds, props.TimePulled })

	local totalCost = 0
	for i, id in props.IngredientIds or {} do
		local config = CoffeeModule.IngredientLookup[id]
		totalCost += config.Cost
	end

	local hoverTexts = {}

	local total
	for i, ingId in props.IngredientIds or {} do
		local config = CoffeeModule.IngredientLookup[ingId]
		local displayName = `{config and `{config.DisplayName}` or ""}`
		table.insert(hoverTexts, displayName)
		total = (total or 0) + config.Cost
	end
	local buyText = total and `{`Buy (${total})` or ""}`

	local hoverText = table.concat(hoverTexts, "\n")

	return e(React.Fragment, nil, {
		-- Prompt = e("BillboardGui", {
		-- 	ResetOnSpawn = false,
		-- 	Adornee = props.Instance,
		-- 	Size = UDim2.new(0, 200, 0, 100),
		-- 	StudsOffsetWorldSpace = Vector3.new(0, 0, 0),
		-- 	AlwaysOnTop = true,
		-- 	MaxDistance = 50,
		-- 	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		-- 	Active = true,
		-- }, {
		-- 	SmallButton = phase == "show" and shown and config and e(SmallButton, {
		-- 		Text = `{config and `Buy (${Mionum.new(totalCost):toString()})` or ""}`,
		-- 		TextXAlignment = Enum.TextXAlignment.Center,
		-- 		AnchorPoint = Vector2.new(0.5, 0),
		-- 		Size = UDim2.new(1, 0, 0.5, 0),
		-- 		Position = UDim2.new(0.5, 0, 0.5, 0),
		-- 		BackgroundColor3 = totalCost and cash and totalCost > cash and Color3.new(1, 0, 0)
		-- 			or Color3.new(0, 1, 0),
		-- 		TextSize = size,
		-- 		[React.Event.Activated] = function()
		-- 			Remotes.BuyIngredientFromSpawner:FireServer()
		-- 		end,
		-- 	}),
		-- }),
		Text = e("BillboardGui", {
			ResetOnSpawn = false,
			Adornee = props.Instance,
			Size = UDim2.new(0, 200, 0, 50),
			StudsOffsetWorldSpace = Vector3.new(0, 4, 0),
			AlwaysOnTop = true,
			MaxDistance = 50,
			ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
			Active = true,
		}, {
			SmallText = phase == "show" and e(SmallText, {
				Text = hoverText,
				TextXAlignment = Enum.TextXAlignment.Center,
				Size = UDim2.new(1, 0, 1, 0),
				TextSize = size,
				AnchorPoint = Vector2.new(0.5, 0),
				Position = UDim2.new(0.5, 0, -0.5, 0),
			}),

			Prompt = player and ReactRoblox.createPortal({
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
					SmallButton = phase == "show" and shown and buyText and e(SmallButton, {
						Text = buyText,
						TextXAlignment = Enum.TextXAlignment.Center,
						AnchorPoint = Vector2.new(0.5, 0),
						Size = UDim2.new(1, 0, 0.5, 0),
						Position = UDim2.new(0.5, 0, 0.5, 0),
						BackgroundColor3 = totalCost and cash and totalCost > cash and Color3.new(1, 0, 0)
							or Color3.new(0, 1, 0),
						TextSize = size,
						[React.Event.Activated] = function()
							Remotes.BuyIngredientFromSpawner:FireServer()
						end,
					}),
				}),
			}, player.PlayerGui) or nil,
		}),
	})
end

return MixerManager
