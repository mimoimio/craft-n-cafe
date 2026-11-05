-- UpgradePanel.luau
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local React = require(ReplicatedStorage.Packages.React)
local Mionum = require(ReplicatedStorage.Packages.Mionum)
local Promise = require(ReplicatedStorage.Packages.Promise)
local ReactRoblox = require(ReplicatedStorage.Packages.ReactRoblox)
local CoffeeConfigArray = require(ReplicatedStorage.Shared.Configs.CoffeeConfig)
local CoffeeModule = require(ReplicatedStorage.Shared.CoffeeModule)
local HStack = require(ReplicatedStorage.Shared.ReactComponents.ui.HStack)
local VStack = require(ReplicatedStorage.Shared.ReactComponents.ui.VStack)
local SmallButton = require(ReplicatedStorage.Shared.ReactComponents.ui.SmallButton)
local SmallText = require(ReplicatedStorage.Shared.ReactComponents.ui.SmallText)
local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local UpgradesModule = require(ReplicatedStorage.Shared.UpgradesModule)
local VariationsConfig = require(ReplicatedStorage.Shared.Configs.VariationsConfig)
local CafeTypes = require(ReplicatedStorage.Shared.CafeTypes)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

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

local player = game:GetService("Players").LocalPlayer
local playerId = player and tostring(player.UserId) or ""
local tag = playerId .. "Cafe"
local function UpgradeWall(props)
	local luck: number, setLuck = useState(not player and 1 or 1)
	local cafeCapacity: number, setcafeCapacity = useState(not player and 1 or 1)
	local cash: number, setCash = useState(not player and 1e12 or 0) -- High default for Storyboard

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

	-- Unified GlobalState Stats Sync
	useEffect(function()
		local unsub = GlobalState:subscribe(function(state: GlobalState.GlobalState)
			local stats = state.Stats[playerId]
			if stats then
				setLuck(stats.Luck or 1)
				setcafeCapacity(stats.CafeCapacity or 1)
				setCash(stats.Cash or 0)
			end
		end)

		local state = GlobalState:getState()
		local stats = state.Stats[playerId]
		if stats then
			setLuck(stats.Luck or 1)
			setcafeCapacity(stats.CafeCapacity or 1)
			setCash(stats.Cash or 0)
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

	local uistroke = e("UIStroke", { Thickness = 4 })

	-- Determine Costs & Affordability
	local luckCost = UpgradesModule.GetLuckCost(luck, 1)
	local maxLuckInc, maxLuckCost = UpgradesModule.GetMaxAffordableLuck(luck, cash)

	local capCost = UpgradesModule.GetCapacityCost(cafeCapacity, 1)
	local maxCapInc, maxCapCost = UpgradesModule.GetMaxAffordableCapacity(cafeCapacity, cash)

	return adornee
		and ReactRoblox.createPortal({
			e("SurfaceGui", {
				ResetOnSpawn = false,
				Adornee = adornee,
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
								Text = `Upgrades`,
								TextColor3 = Color3.new(),
								TextSize = 20,
								Font = Enum.Font.FredokaOne,
								TextXAlignment = Enum.TextXAlignment.Left,
							}),
						}),
						Body = e(VStack, {
							Size = UDim2.new(1, 0, 1, -48),
							Position = UDim2.new(0, 0, 0, 48),
							BackgroundTransparency = 1,
							VerticalFlex = Enum.UIFlexAlignment.None,
							Spacing = UDim.new(0, 12),
							Padding = { All = UDim.new(0, 12) },
						}, {
							-- LUCK ROW
							e(HStack, {
								Padding = { All = UDim.new(0, 12) },
								Size = UDim2.new(1, 0, 0, 0),
								AutomaticSize = Enum.AutomaticSize.XY,
								HorizontalFlex = Enum.UIFlexAlignment.SpaceBetween,
								BackgroundTransparency = 0,
								LayoutOrder = 1,
							}, {
								e(SmallText, {
									TextSize = 30,
									LayoutOrder = 1,
									Text = `Luck Level: {luck}`,
								}, { uistroke }),

								e(HStack, {
									AutomaticSize = Enum.AutomaticSize.XY,
									Spacing = UDim.new(0, 12),
									LayoutOrder = 2,
									BackgroundTransparency = 1,
								}, {
									MaxButton = maxLuckInc > 1 and e(SmallButton, {
										TextSize = 36,
										ButtonClass = "ImageButton",
										Size = UDim2.new(0, 200, 1, 0),
										LayoutOrder = 1,
										BackgroundColor3 = Color3.fromRGB(235, 172, 38), -- Gold for Max
										[React.Event.Activated] = function()
											Remotes.UpgradeLuck:FireServer("Max")
										end,
									}, {
										uistroke,
										e(SmallText, {
											TextSize = 32,
											LayoutOrder = 1,
											Text = `Max +{maxLuckInc}\n${Mionum.new(maxLuckCost):toString()}`,
										}, { uistroke }),
									}),

									UpgradeButton = e(SmallButton, {
										TextSize = 30,
										ButtonClass = "ImageButton",
										Size = UDim2.new(0, 200, 1, 0),
										LayoutOrder = 2,
										BackgroundColor3 = Color3.new(0, 1, 0),
										[React.Event.Activated] = function()
											Remotes.UpgradeLuck:FireServer(1)
										end,
									}, {
										uistroke,
										e(SmallText, {
											TextSize = 30,
											LayoutOrder = 1,
											TextYAlignment = Enum.TextYAlignment.Center,
											Text = `Upgrade ${Mionum.new(luckCost):toString()}`,
										}, { uistroke }),
									}),
								}),
							}),

							-- CAPACITY ROW
							e(HStack, {
								Padding = { All = UDim.new(0, 12) },
								Size = UDim2.new(1, 0, 0, 0),
								AutomaticSize = Enum.AutomaticSize.XY,
								HorizontalFlex = Enum.UIFlexAlignment.SpaceBetween,
								LayoutOrder = 2,
								BackgroundTransparency = 0,
							}, {
								e(SmallText, {
									TextSize = 30,
									LayoutOrder = 1,
									Text = `Cafe Capacity: {cafeCapacity}`,
								}, { uistroke }),

								e(HStack, {
									AutomaticSize = Enum.AutomaticSize.XY,
									Spacing = UDim.new(0, 12),
									LayoutOrder = 2,
									BackgroundTransparency = 1,
								}, {
									MaxButton = maxCapInc > 1 and e(SmallButton, {
										TextSize = 36,
										ButtonClass = "ImageButton",
										Size = UDim2.new(0, 200, 1, 0),
										LayoutOrder = 1,
										BackgroundColor3 = Color3.fromRGB(235, 172, 38),
										[React.Event.Activated] = function()
											Remotes.UpgradeCafeCapacity:FireServer("Max")
										end,
									}, {
										uistroke,
										e(SmallText, {
											TextSize = 32,
											LayoutOrder = 1,
											Text = `Max +{maxCapInc}\n${Mionum.new(maxCapCost):toString()}`,
										}, { uistroke }),
									}),

									UpgradeButton = e(SmallButton, {
										TextSize = 30,
										ButtonClass = "ImageButton",
										Size = UDim2.new(0, 200, 1, 0),
										LayoutOrder = 2,
										BackgroundColor3 = Color3.new(0, 1, 0),
										[React.Event.Activated] = function()
											Remotes.UpgradeCafeCapacity:FireServer(1)
										end,
									}, {
										uistroke,
										e(SmallText, {
											TextSize = 30,
											LayoutOrder = 1,
											TextYAlignment = Enum.TextYAlignment.Center,
											Text = `Upgrade ${Mionum.new(capCost):toString()}`,
										}, { uistroke }),
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
