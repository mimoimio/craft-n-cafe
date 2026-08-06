-- UpgradePanel.luau
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
local function UpgradeWall(props)
	local luck: number?, setLuck = useState(not player and 1 or nil)
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
			return resolve(cafeModel:WaitForChild("UpgradeWall"):WaitForChild("Part"))
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
		Thickness = 4,
	})

	return adornee
		and ReactRoblox.createPortal({
			e("SurfaceGui", {
				Adornee = adornee,
				CanvasSize = Vector2.new(2400 * (1 / 3), 1800 * (1 / 3)),
				ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
			}, {
				e("ImageLabel", {
					Size = UDim2.new(1, -0, 1, -0),
					-- BackgroundColor3 = Color3.fromRGB(255, 196, 162),
					-- BackgroundTransparency = 0.1,
					-- AnchorPoint = Vector2.new(0.5, 0.5),
					-- Position = UDim2.new(0.5, 0, 0.5, 0),
					-- Position = position:map(function(n)
					-- 	return UDim2.new(0.5 + n, 0, 0.5 + 0, 0)
					-- end),
					-- BorderSizePixel = 0,
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
					-- buttons = e(VStack, {
					-- 	AutomaticSize = Enum.AutomaticSize.XY,
					-- 	AnchorPoint = Vector2.new(1, 0),
					-- 	Spacing = UDim.new(0, 8),
					-- 	Size = UDim2.new(0, 80, 0, 0),
					-- }, buttons),
					-- Centered container
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

						-- Header
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
								Text = `Upgrades`,
								TextColor3 = ACCENT,
								TextSize = 20,
								Font = Enum.Font.FredokaOne,
								TextXAlignment = Enum.TextXAlignment.Left,
							}),
						}),

						-- Body
						Body = e(VStack, {
							Size = UDim2.new(1, 0, 1, -48),
							Position = UDim2.new(0, 0, 0, 48),
							BackgroundTransparency = 1,
							VerticalFlex = Enum.UIFlexAlignment.None,
							Spacing = UDim.new(0, 12),
							Padding = { All = UDim.new(0, 12) },
						}, {
							e(HStack, {
								Padding = { All = UDim.new(0, 12) },
								Size = UDim2.new(1, 0, 0, 0),
								AutomaticSize = Enum.AutomaticSize.XY,
								Position = UDim2.new(0, 0, 0, 48),
								HorizontalFlex = Enum.UIFlexAlignment.SpaceBetween,
								BackgroundTransparency = 0,
								LayoutOrder = 1,
							}, {
								e(SmallText, {
									TextSize = 48,
									LayoutOrder = 1,
									Text = `Luck Level: {luck}`,
								}, {
									uistroke,
								}),
								e(SmallButton, {
									TextSize = 48,
									ButtonClass = "ImageButton",
									Size = UDim2.new(0, 200, 0, 50),
									LayoutOrder = 2,
									BackgroundColor3 = Color3.new(0, 1, 0),
									[React.Event.Activated] = function()
										Remotes.UpgradeLuck:FireServer()
									end,
								}, {
									uistroke,
									e(SmallText, {
										TextSize = 48,
										LayoutOrder = 1,
										Text = `Upgrade ${((luck + 1) * 10) ^ 1.2 // 1}`,
									}, {
										uistroke,
									}),
								}),
							}),
							e(HStack, {
								Padding = { All = UDim.new(0, 12) },
								Size = UDim2.new(1, 0, 0, 0),
								AutomaticSize = Enum.AutomaticSize.XY,
								Position = UDim2.new(0, 0, 0, 48),
								HorizontalFlex = Enum.UIFlexAlignment.SpaceBetween,
								LayoutOrder = 2,
								BackgroundTransparency = 0,
							}, {
								e(SmallText, {
									TextSize = 48,
									LayoutOrder = 1,
									Text = `Cafe Capacity: {cafeCapacity}`,
								}, {
									uistroke,
								}),
								e(SmallButton, {
									TextSize = 48,
									ButtonClass = "ImageButton",
									Size = UDim2.new(0, 200, 0, 50),
									LayoutOrder = 2,
									BackgroundColor3 = Color3.new(0, 1, 0),
									[React.Event.Activated] = function()
										Remotes.UpgradeCafeCapacity:FireServer()
									end,
								}, {
									uistroke,
									e(SmallText, {
										TextSize = 48,
										LayoutOrder = 1,
										Text = `Upgrade $100`,
									}, {
										uistroke,
									}),
								}),
							}),
						}),
					}),
				}),
			}),
		}, player and player.PlayerGui or adornee)
end

return UpgradeWall
