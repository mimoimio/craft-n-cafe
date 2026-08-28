-- LuckProb.luau
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local React = require(ReplicatedStorage.Packages.React)
local Promise = require(ReplicatedStorage.Packages.Promise)
local ReactRoblox = require(ReplicatedStorage.Packages.ReactRoblox)
local Mionum = require(ReplicatedStorage.Packages.Mionum)
local CoffeeModule = require(ReplicatedStorage.Shared.CoffeeModule)
local HStack = require(ReplicatedStorage.Shared.ReactComponents.ui.HStack)
local VStack = require(ReplicatedStorage.Shared.ReactComponents.ui.VStack)
local SmallButton = require(ReplicatedStorage.Shared.ReactComponents.ui.SmallButton)
local SmallText = require(ReplicatedStorage.Shared.ReactComponents.ui.SmallText)
local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local LuckModule = require(ReplicatedStorage.Shared.LuckModule)
local UpgradesModule = require(ReplicatedStorage.Shared.UpgradesModule)

local e = React.createElement
local useState = React.useState
local useEffect = React.useEffect

local BG = Color3.fromRGB(25, 25, 30)
local PANEL_BG = Color3.fromRGB(37, 37, 88)
local ACCENT = Color3.fromRGB(255, 200, 80)

local player = game:GetService("Players").LocalPlayer
local playerId = player and tostring(player.UserId) or ""
local tag = playerId .. "Cafe"
local rolls = 1000

local function LuckProb(props)
	-- Track the Level instead of the raw multiplier
	local luckLevel: number, setLuckLevel = useState(not player and 1 or 1)
	local cafeCapacity: number?, setcafeCapacity = useState(not player and 1 or nil)
	local cafeModel, setCafeModel = useState(nil)

	useEffect(function()
		if not player then
			setCafeModel(workspace)
			return
		end
		local function syncSpawner()
			local currentInstances
			for _, inst in ipairs(CollectionService:GetTagged(tag)) do
				currentInstances = inst
				break
			end
			setCafeModel(currentInstances)
		end

		syncSpawner()

		local connAdd2 = CollectionService:GetInstanceAddedSignal(tag):Connect(syncSpawner)
		local connRem2 = CollectionService:GetInstanceRemovedSignal(tag):Connect(syncSpawner)

		return function()
			connAdd2:Disconnect()
			connRem2:Disconnect()
		end
	end, { playerId })

	useEffect(function()
		local unsub = GlobalState:subscribe(function(state: GlobalState.GlobalState)
			local level = state.Stats[playerId] and state.Stats[playerId].Luck or nil
			if level then
				setLuckLevel(level)
			end
		end)

		local state = GlobalState:getState()
		local level = state.Stats[playerId] and state.Stats[playerId].Luck or nil
		if level then
			setLuckLevel(level)
		end
		return unsub
	end, {})

	useEffect(function()
		local unsub = GlobalState:subscribe(function(state: GlobalState.GlobalState)
			local capacity = state.Stats[playerId] and state.Stats[playerId].CafeCapacity or nil
			if capacity then
				setcafeCapacity(capacity)
			end
		end)

		local state = GlobalState:getState()
		local capacity = state.Stats[playerId] and state.Stats[playerId].CafeCapacity or nil
		if capacity then
			setcafeCapacity(capacity)
		end
		return unsub
	end, {})

	local adornee, setAdornee = useState(not player and workspace.UpgradeWall.Part or nil)
	useEffect(function()
		if not cafeModel or not player then
			return
		end
		local promise = Promise.defer(function(resolve, reject)
			return resolve(cafeModel:WaitForChild("RecipeWall"):WaitForChild("Part"))
		end)
			:andThen(function(Part)
				setAdornee(Part)
			end)
			:catch(function(err)
				warn(`Upgradewall err:{err}`)
			end)
		return function()
			promise:cancel()
		end
	end, { cafeModel })

	local uistroke = e("UIStroke", { Thickness = 1 })

	-- Interactive Luck Level Animation (Runs only in Storyboard/Studio)
	useEffect(function()
		if player then
			return
		end
		local t = task.defer(function()
			while true do
				-- Cycles luck level from 1 to ~300 over 6 seconds
				local time = workspace:GetServerTimeNow()
				local simulatedLevel = 1 + math.floor((time % 10) * 50)
				setLuckLevel(simulatedLevel)
				task.wait(0.1)
			end
		end)
		return function()
			task.cancel(t)
		end
	end, {})

	-- 1. Calculate the actual Luck Multiplier (L) from the Level using the unified module
	local luckMultiplier = LuckModule.GetMultiplier(luckLevel)

	-- Calculate the cumulative cost to reach this level from level 1
	local totalCost = UpgradesModule.GetLuckCost(1, math.max(0, luckLevel - 1))
	local formattedCost = Mionum.new(totalCost):toString()

	-- 2. Calculate Expected PDF (Green Bars)
	local bars = {}
	local maxPdf = 0
	-- local RANGE = #CoffeeModule.IngredientConfigs
	local RANGE = #CoffeeModule.Array
	local fs = {}
	for i = 1, RANGE do
		local z = (i - 0.5) / RANGE
		local y = math.min(LuckModule.CalculatePDF(z, luckMultiplier), 10)
		fs[i] = y
		maxPdf = math.max(maxPdf, y)
	end
	local counts = {}
	local layoutOrders = {}

	for i, y in fs do
		bars[i] = e(SmallButton, {
			ButtonClass = "ImageButton",
			AutomaticSize = Enum.AutomaticSize.XY,
			Size = UDim2.new(0, 0, maxPdf > 0 and (y / maxPdf) or 0, 0),
			LayoutOrder = i,
			BackgroundColor3 = Color3.new(0, 1, 0),
		}, { uistroke })

		local s = CoffeeModule.Array[i].Id
		counts[s] = 0
		layoutOrders[s] = i
	end

	-- 3. Simulate 10,000 Rolls for empirical results (Spawned bars)
	local maxCount = 0
	for i = 1, rolls do
		local num = LuckModule.RollIndex(luckMultiplier, RANGE)
		local config = CoffeeModule.Array[num]

		if config then
			counts[config.Id] = (counts[config.Id] or 0) + 1
			maxCount = math.max(counts[config.Id] or 0, maxCount)
		end
	end

	local spawned = {}
	for id, count in counts do
		spawned[layoutOrders[id] .. ")" .. id] = e(SmallButton, {
			ButtonClass = "ImageButton",
			AutomaticSize = Enum.AutomaticSize.XY,
			Size = UDim2.new(0, 0, maxCount > 0 and (count / maxCount) or 0, 0),
			LayoutOrder = layoutOrders[id],
			BackgroundColor3 = Color3.new(0, 1, 0),
			[React.Event.Activated] = warn,
		}, { uistroke })
	end

	return adornee
		and ReactRoblox.createPortal({
			e("SurfaceGui", {
				Adornee = adornee,
				ResetOnSpawn = false,
				CanvasSize = Vector2.new(2400 * (1 / 3), 1800 * (1 / 3)),
				ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
			}, {
				e("ImageLabel", {
					Size = UDim2.new(1, -0, 1, -0),
					ZIndex = 20,
					BackgroundColor3 = PANEL_BG,
					BackgroundTransparency = 1,
					Image = "rbxassetid://127657596958436",
					ScaleType = Enum.ScaleType.Slice,
					SliceCenter = Rect.new(8, 8, 92, 92),
					BorderSizePixel = 0,
				}, {
					Container = e("Frame", {
						Size = UDim2.new(1, 0, 1, 0),
						AnchorPoint = Vector2.new(0.5, 0.5),
						Position = UDim2.new(0.5, 0, 0.5, 0),
						BackgroundColor3 = BG,
						BackgroundTransparency = 1,
						BorderSizePixel = 0,
					}, {
						UICorner = e("UICorner", { CornerRadius = UDim.new(0, 12) }),
						Header = e("Frame", {
							Size = UDim2.new(1, 0, 0, 48),
							BackgroundColor3 = PANEL_BG,
							BackgroundTransparency = 1,
							BorderSizePixel = 0,
							ZIndex = 2,
						}, {
							UICorner = e("UICorner", { CornerRadius = UDim.new(0, 12) }),
							BottomFill = e("Frame", {
								Size = UDim2.new(1, 0, 0, 12),
								Position = UDim2.new(0, 0, 1, -12),
								BackgroundColor3 = PANEL_BG,
								BorderSizePixel = 0,
								BackgroundTransparency = 1,
							}),
							Title = e("TextLabel", {
								Size = UDim2.new(1, -56, 1, 0),
								Position = UDim2.new(0, 16, 0, 0),
								BackgroundTransparency = 1,
								Text = string.format(
									"Level %d (L: %.2f) | Cost: %s",
									luckLevel,
									luckMultiplier,
									formattedCost
								),
								TextColor3 = Color3.new(),
								TextSize = 48,

								Font = Enum.Font.FredokaOne,
								TextXAlignment = Enum.TextXAlignment.Left,
							}),
						}),
						Body = e(VStack, {
							Size = UDim2.new(1, 0, 1, -48),
							Position = UDim2.new(0, 0, 0, 48),
							BackgroundTransparency = 1,
							VerticalFlex = Enum.UIFlexAlignment.Fill,
							Spacing = UDim.new(0, 12),
							Padding = { All = UDim.new(0, 12) },
						}, {
							ExpectedBars = e(HStack, {
								Padding = { All = UDim.new(0, 12) },
								Size = UDim2.new(1, 0, 1, 0),
								HorizontalFlex = Enum.UIFlexAlignment.Fill,
								VerticalAlignment = Enum.VerticalAlignment.Bottom,
								BackgroundTransparency = 1,
								LayoutOrder = 1,
							}, bars),
							Label = e(SmallText, {
								LayoutOrder = 2,
								Text = `{Mionum.new(rolls):toString()} rolls:`,
							}),
							SpawnedBars = e(HStack, {
								Padding = { All = UDim.new(0, 12) },
								Size = UDim2.new(1, 0, 1, 0),
								HorizontalFlex = Enum.UIFlexAlignment.Fill,
								VerticalAlignment = Enum.VerticalAlignment.Bottom,
								BackgroundTransparency = 1,
								LayoutOrder = 3,
							}, spawned),
						}),
					}),
				}),
			}),
		}, player and player.PlayerGui or adornee)
end

return LuckProb
