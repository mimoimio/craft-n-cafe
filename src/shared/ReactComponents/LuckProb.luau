-- LuckProb.luau
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local React = require(ReplicatedStorage.Packages.React)
local Promise = require(ReplicatedStorage.Packages.Promise)
local ReactRoblox = require(ReplicatedStorage.Packages.ReactRoblox)
local CoffeeConfigArray = require(ReplicatedStorage.Shared.Configs.CoffeeConfig)
local CoffeeModule = require(ReplicatedStorage.Shared.CoffeeModule)
local HStack = require(ReplicatedStorage.Shared.ReactComponents.ui.HStack)
local VStack = require(ReplicatedStorage.Shared.ReactComponents.ui.VStack)
local SmallButton = require(ReplicatedStorage.Shared.ReactComponents.ui.SmallButton)
local SmallText = require(ReplicatedStorage.Shared.ReactComponents.ui.SmallText)
local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local VariationsConfig = require(ReplicatedStorage.Shared.Configs.VariationsConfig)
local CafeTypes = require(ReplicatedStorage.Shared.CafeTypes)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
-- CoffeeModule.Config is the keyed lookup (by Id)
local CoffeeConfig = CoffeeModule.Config

local e = React.createElement
local useState = React.useState
local useEffect = React.useEffect
local useRef = React.useRef

local RECIPES = CoffeeModule.Array

local BG = Color3.fromRGB(25, 25, 30)
local PANEL_BG = Color3.fromRGB(37, 37, 88)
local ITEM_BG = Color3.fromRGB(255, 201, 150)
local ITEM_SELECTED_BG = Color3.fromRGB(255, 252, 208)
local ITEM_BG_LOCKED = Color3.fromRGB(148, 56, 33)
local ITEM_BG_LOCKED_SELECTED = Color3.fromRGB(122, 87, 40)
local ACCENT = Color3.fromRGB(255, 200, 80)
local TEXT = Color3.fromRGB(230, 230, 230)
local SUBTEXT = Color3.fromRGB(160, 160, 180)

local variationOrder = {
	"none",
	"double",
	"gold",
	"diamond",
	"starlight",
}

local variation = nil

-- local IsEdit = RunService:IsStudio() and not RunService:IsRunMode()

local player = game.Players.LocalPlayer
local playerId = player and tostring(player.UserId) or ""
local tag = playerId .. "Cafe"
local function LuckProb(props)
	local luck: number?, setLuck = useState(not player and 1.3 or nil)
	local cafeCapacity: number?, setcafeCapacity = useState(not player and 1 or nil)
	local cafeModel, setCafeModel = useState(nil)
	-- 2. Sync Table instances from CollectionService generically
	-- 2. Subscribe to the generic CollectionService tag
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

		-- Initial sync
		syncSpawner()

		-- Listen for chunks streaming in/out
		local connAdd2 = CollectionService:GetInstanceAddedSignal(tag):Connect(syncSpawner)
		local connRem2 = CollectionService:GetInstanceRemovedSignal(tag):Connect(syncSpawner)

		return function()
			connAdd2:Disconnect()
			connRem2:Disconnect()
		end
	end, { playerId })

	useEffect(function()
		local unsub = GlobalState:subscribe(function(state: GlobalState.GlobalState)
			local luck = state.Stats[playerId] and state.Stats[playerId].Luck or nil
			if luck then
				setLuck(luck)
			end
		end)

		local state = GlobalState:getState()
		local luck = state.Stats[playerId] and state.Stats[playerId].Luck or nil
		if luck then
			setLuck(luck)
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

	local adornee, setAdornee = useState(nil)
	useEffect(function()
		if not cafeModel then
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

	local uistroke = e("UIStroke", {
		Thickness = 1,
	})
	local bars = {}
	-- local luck = 5
	-- local luck = 2
	-- local luck = 1
	useEffect(function()
		local t = task.defer(function()
			while true do
				setLuck(2 ^ (workspace:GetServerTimeNow() % 4))
				task.wait(0.3)
				-- task.wait()
			end
		end)
		return function()
			task.cancel(t)
		end
	end, {})
	local fn = function(z)
		return -luck ^ 2 * z ^ (luck - 1) * math.log(z)
	end
	local fs = {}
	local max = 0
	local RANGE = #CoffeeModule.Array
	for i = 1, RANGE do
		-- local y = math.min(fn((i - 1 / 2) / (RANGE - 1)), 10)
		local y = math.min(fn((i - 1 / 2) / RANGE), 10) -- kept the original, cuz if not, the final config wont get it
		fs[i] = y
		max = math.max(max, y)
		-- warn(`{i}) {CoffeeModule.Array[i].DisplayName}`)
	end
	local counts = {}
	local layoutOrders = {}
	for i, y in fs do
		bars[i] = e(SmallButton, {
			ButtonClass = "ImageButton",
			AutomaticSize = Enum.AutomaticSize.XY,
			Size = UDim2.new(0, 0, y / max, 0),
			LayoutOrder = i,
			BackgroundColor3 = Color3.new(0, 1, 0),
		}, {
			uistroke,
		})
		local s = CoffeeModule.Array[i].Id
		counts[s] = 0
		layoutOrders[s] = i
	end
	max = 0
	for i = 1, 10000 do
		local z = ((math.random() * math.random()) ^ (1 / luck))
		local num = (z * #CoffeeModule.Array) // 1 + 1

		local config = CoffeeModule.Array[num]
		counts[config.Id] = (counts[config.Id] or 0) + 1
		max = math.max(counts[config.Id] or 0, max)
	end

	local spawned = {}
	for id, count in counts do
		spawned[layoutOrders[id] .. ")" .. id] = e(SmallButton, {
			ButtonClass = "ImageButton",
			AutomaticSize = Enum.AutomaticSize.XY,
			Size = UDim2.new(0, 0, count / max, 0),
			LayoutOrder = layoutOrders[id],
			BackgroundColor3 = Color3.new(0, 1, 0),
			[React.Event.Activated] = warn,
		}, {
			uistroke,
		})
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
					ImageColor3 = variation and variation.VariationId ~= "none" and variation.ColorPrimary
						or Color3.new(0.768627, 0.549019, 0.549019),
					ScaleType = Enum.ScaleType.Slice,
					SliceCenter = Rect.new(8, 8, 92, 92),
					BorderSizePixel = 0,
				}, {
					Container = e("Frame", {
						Size = UDim2.new(1, 0, 1, 0),
						-- Size = UDim2.new(0, 720, 0, 440),
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
							-- Bottom fill to hide bottom corner rounding
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
								Text = `Luck: {luck * 100 // 1 / 100}`,

								TextColor3 = ACCENT,
								TextSize = 48,
								Font = Enum.Font.FredokaOne,
								TextXAlignment = Enum.TextXAlignment.Left,
							}),
						}),

						-- Body
						Body = e(VStack, {
							Size = UDim2.new(1, 0, 1, -48),
							Position = UDim2.new(0, 0, 0, 48),
							BackgroundTransparency = 1,
							VerticalFlex = Enum.UIFlexAlignment.Fill,
							Spacing = UDim.new(0, 12),
							Padding = { All = UDim.new(0, 12) },
						}, {
							e(HStack, {
								Padding = { All = UDim.new(0, 12) },
								Size = UDim2.new(1, 0, 1, 0),
								AutomaticSize = Enum.AutomaticSize.None,
								Position = UDim2.new(0, 0, 0, 48),
								HorizontalFlex = Enum.UIFlexAlignment.Fill,
								Spacing = UDim.new(0, 0),
								VerticalAlignment = Enum.VerticalAlignment.Bottom,
								VerticalFlex = Enum.UIFlexAlignment.None,
								BackgroundTransparency = 1,
								LayoutOrder = 1,
							}, bars),
							e(SmallText, {
								LayoutOrder = 2,
								Text = "2,000 rolls:",
							}),
							e(HStack, {
								Padding = { All = UDim.new(0, 12) },
								Size = UDim2.new(1, 0, 1, 0),
								AutomaticSize = Enum.AutomaticSize.None,
								Position = UDim2.new(0, 0, 0, 48),
								HorizontalFlex = Enum.UIFlexAlignment.Fill,
								Spacing = UDim.new(0, 0),
								VerticalAlignment = Enum.VerticalAlignment.Bottom,
								VerticalFlex = Enum.UIFlexAlignment.None,
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
