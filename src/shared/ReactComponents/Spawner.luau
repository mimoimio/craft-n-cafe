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
local SmallButton = require(ReplicatedStorage.Shared.ReactComponents.ui.SmallButton)
local CoffeeModule = require(ReplicatedStorage.Shared.CoffeeModule)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Types = require(ReplicatedStorage.Shared.Types)
local SmallText = require(ReplicatedStorage.Shared.ReactComponents.ui.SmallText)
local SoundController = require(ReplicatedStorage.Shared.Controllers.SoundController)
local DispatchEvent = require(ReplicatedStorage.Shared.Controllers.DispatchEvent)

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
	Part: Part,
}

local function MixerManager(props)
	local spawner, setSpawner = useState({})
	local buyPadInstance, setBuyPadInstance = useState(nil)
	local spawnerInstance, setSpawnerInstance = useState(nil)

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
					IngredientId = "milk",
					TimePulled = workspace:GetServerTimeNow(),
				})
				task.wait(1)
				setSpawner({
					IngredientId = "milk",
					TimePulled = workspace:GetServerTimeNow(),
				})
				task.wait(1)
				setSpawner({
					IngredientId = "milk",
					TimePulled = workspace:GetServerTimeNow(),
				})
				task.wait(1)
				setSpawner({
					IngredientId = "milk",
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
		IngredientId = spawner.IngredientId or "none",
		TimePulled = spawner.TimePulled,
	})

	return e(React.Fragment, nil, children)
end

local GRAY = Color3.new(0.5, 0.5, 0.5)
local WHITE = Color3.new(1, 1, 1)
function SpawnerNode(props: { Instance: Instance? })
	local time, setTime = useBinding(0)
	local lastRolled, setLastRolled = useState(0)
	local rollCooldown, setRollCooldown = useState(0)
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
		Button = e(SmallButton, {
			Text = "Summon",
			Size = UDim2.new(1, 0, 1, 0),
			TextScaled = true,
			TextColor3 = colorMap,
			BackgroundColor3 = colorMap,
			[React.Event.Activated] = function()
				Remotes.RollIngredient:FireServer()
			end,
		}),
	})
end

function BuyPadNode(props: { Instance: Instance?, IngredientId: string?, TimePulled: number })
	local randomModels = useRef({})

	local prompt: ProximityPrompt, setPrompt = useState(nil)
	local shown, setShown = useState(false)
	local cash, setCash = useState(false)

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

		local configs = CoffeeModule.Array

		for i, config in configs do
			local template = ReplicatedStorage.Shared.Models:FindFirstChild(config.Id)
			if not template then
				continue
			end
			local model = template:Clone()
			model.Parent = cache
			local packageLink = model:FindFirstChild("PackageLink")

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

	-- local instanceRef = useRef(nil)
	-- local cacheFolderRef = useRef(nil)
	-- useEffect(function()
	-- 	instanceRef.current = props.Instance
	-- end, { props.Instance })
	-- useEffect(function()
	-- 	cacheFolderRef.current = cacheFolder
	-- end, { cacheFolder })

	local prevDrinkIdRef = useRef(nil)
	local size, setSize = useSpring({
		start = 0,
		target = 24,
		damper = 1,
		speed = 20,
	})

	useEffect(function()
		if not (props.IngredientId and props.Instance) then
			-- warn(`{props.IngredientId}{props.Instance}`)
			return
		end

		if not prevDrinkIdRef.current then
			-- initialize drinkId
			prevDrinkIdRef.current = props.IngredientId
		end

		if props.IngredientId ~= "none" then
			local model: Model = ReplicatedStorage.Shared.Models:FindFirstChild(props.IngredientId)
			if not model then
				warn("NOT MODEL", props.IngredientId)
				return
			end
			model = model:Clone()
			model:PivotTo(props.Instance:GetPivot() + Vector3.new(0, 2, 0))
			model.Parent = workspace
			-- model.Parent = props.Instance

			local scaleValue = Instance.new("NumberValue")
			scaleValue.Value = 0.1
			model:ScaleTo(0.1)

			local updateConn = scaleValue.Changed:Connect(function(newCFrame)
				model:ScaleTo(newCFrame)
			end)

			local promise = Promise.defer(function(resolve, reject, onCancel)
				local tween = TweenService:Create(
					scaleValue,
					TweenInfo.new(ANIM_DURATION, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out, 0, false, 0),
					{ Value = 1 }
				)
				setSize({
					start = 0,
					target = 32,
					damper = 0.4,
					speed = 30,
				})

				tween:Play()
				tween.Completed:Wait()

				return resolve()
			end):catch(function(err)
				warn(`Tween error: {err}`)
			end)
			return function()
				if model and model.Parent then
					model:Destroy()
				end
				promise:cancel()
				if updateConn then
					updateConn:Disconnect()
				end
			end
		else
			--render empty
		end
	end, { props.Instance, props.IngredientId, props.TimePulled })

	useEffect(function()
		if not randomModels then
			return
		end

		return
	end, { randomModels, props.IngredientId })
	local config = CoffeeModule.IngredientLookup[props.IngredientId]

	return e("BillboardGui", {
		Adornee = props.Instance,
		-- Size = UDim2.new(8, 0, 1, 0),
		Size = UDim2.new(0, 200, 0, 50),
		StudsOffsetWorldSpace = Vector3.new(0, 4, 0),
		AlwaysOnTop = true,
		MaxDistance = 50,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Active = true,
	}, {
		SmallText = e(SmallText, {
			Text = `{config and `{config.DisplayName}` or ""}`,
			TextXAlignment = Enum.TextXAlignment.Center,
			Size = UDim2.new(1, 0, 1, 0),
			TextSize = size,
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, -0.5, 0),
		}),
		Prompt = e("BillboardGui", {
			Adornee = props.Instance,
			Size = UDim2.new(0, 200, 0, 100),
			StudsOffsetWorldSpace = Vector3.new(0, 0, 0),
			AlwaysOnTop = true,
			MaxDistance = 50,
			ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
			Active = true,
		}, {
			SmallButton = shown and config and e(SmallButton, {
				Text = `{config and `Buy (${Mionum.new(config.Cost):toString()})` or ""}`,
				TextXAlignment = Enum.TextXAlignment.Center,
				AnchorPoint = Vector2.new(0.5, 0),
				Size = UDim2.new(1, 0, 0.5, 0),
				Position = UDim2.new(0.5, 0, 0.5, 0),
				BackgroundColor3 = config.Cost and cash and config.Cost > cash and Color3.new(1, 0, 0)
					or Color3.new(0, 1, 0),
				TextSize = size,
				[React.Event.Activated] = function()
					Remotes.BuyIngredientFromSpawner:FireServer()
				end,
			}),
		}),
	})
end

return MixerManager
