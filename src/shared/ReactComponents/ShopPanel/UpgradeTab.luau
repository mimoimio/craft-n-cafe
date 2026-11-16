-- Shared/ReactComponents/ShopPanel/UpgradeTab.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)

local PlaceablesModule = require(ReplicatedStorage.Shared.PlaceablesModule)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local PlotExpansionsConfig = require(ReplicatedStorage.Shared.Configs.PlotExpansionsConfig)
local UpgradesConfig = require(ReplicatedStorage.Shared.Configs.UpgradesConfig)

local Primitives = ReplicatedStorage.Shared.ReactComponents.ui
local VStack = require(Primitives.VStack)
local HStack = require(Primitives.HStack)
local SmallButton = require(Primitives.SmallButton)
local SmallText = require(Primitives.SmallText)
local useBreakpoint = require(ReplicatedStorage.Shared.Hooks.useBreakpoint)

local e = React.createElement
local useState = React.useState

local SUB_TABS = {
	{ id = "cash", label = "Cash" },
	{ id = "ingredients", label = "Ingredients" },
	{ id = "expansion", label = "Expansion" },
}

local function UpgradeTab(props: { plotState: any, playerStats: any })
	local subTab, setSubTab = useState("ingredients")
	local children = {}
	local xs, sm, md = useBreakpoint()
	local mobile = xs or sm or md

	local subTabButtons = {}
	for idx, tab in ipairs(SUB_TABS) do
		local isActive = subTab == tab.id
		subTabButtons[tab.id] = e(SmallButton, {
			LayoutOrder = idx,
			Size = UDim2.new(0, 0, 0, 32),
			AutomaticSize = Enum.AutomaticSize.X,
			BackgroundTransparency = 1,
			Image = "rbxassetid://128846321008253",
			ImageColor3 = not isActive and Color3.new(0.4, 0.4, 0.6) or nil,
			ScaleType = Enum.ScaleType.Slice,
			SliceCenter = Rect.new(50, 50, 54, 57),
			Rounded = false,
			HoverScale = true,
			Padding = {
				Right = UDim.new(0, 8),
				Left = UDim.new(0, 8),
				All = UDim.new(0, 0),
			},
			[React.Event.Activated] = function()
				setSubTab(tab.id)
			end,
		}, {
			e(SmallText, {
				Text = tab.label,
				Size = UDim2.new(1, 0, 1, 0),
				TextSize = props.mobile and (isActive and 15 or 11) or (isActive and 17 or 13),
				TextXAlignment = Enum.TextXAlignment.Center,
				TextYAlignment = Enum.TextYAlignment.Center,
				TextTransparency = isActive and 0 or 0.4,
				Thickness = isActive and 3 or nil,
			}),
		})
	end

	children.SubTabs = e(HStack, {
		LayoutOrder = 1,
		Size = UDim2.new(1, 0, 0, mobile and 28 or 40),
		AutomaticSize = Enum.AutomaticSize.None,
		-- AutomaticSize = Enum.AutomaticSize.XY,
		Spacing = UDim.new(0, 6),
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalFlex = Enum.UIFlexAlignment.None,
		Padding = { All = UDim.new(0, 0) },
	}, subTabButtons)

	if subTab == "expansion" then
		local currentSize = props.plotState.plotSize or 32
		local nextTier = nil
		for _, tier in ipairs(PlotExpansionsConfig) do
			if tier.Size > currentSize then
				nextTier = tier
				break
			end
		end

		if nextTier then
			local canAfford = props.playerStats.Cash >= nextTier.Cost
			local levelMet = props.playerStats.Level >= nextTier.UnlockLevel
			local statusText = `(${nextTier.Cost})`
			local bgColor = Color3.new(0.8, 0.6, 0.1)

			if not levelMet then
				statusText = `(Unlocks Lvl {nextTier.UnlockLevel})`
				bgColor = Color3.new(0.4, 0.4, 0.4)
			elseif not canAfford then
				statusText = `(${nextTier.Cost} - Not Enough Cash)`
				bgColor = Color3.new(0.6, 0.2, 0.2)
			end

			children.PlotExpansion = e(SmallButton, {
				Size = UDim2.new(1, -8, 0, 64),
				AutomaticSize = Enum.AutomaticSize.None,
				BackgroundColor3 = bgColor,
				LayoutOrder = 1,
				[React.Event.Activated] = function()
					if levelMet and canAfford then
						Remotes.ExpandPlot:FireServer()
					end
				end,
			}, {
				e("UIStroke", { Thickness = 2, Color = Color3.new(1, 0.8, 0) }),
				e(SmallText, {
					Text = ` <b>Expand Cafe to {nextTier.Size}x{nextTier.Size}</b> \n<font size="13">{statusText}</font>`,
					RichText = true,
					Size = UDim2.new(1, 0, 1, 0),
					TextXAlignment = Enum.TextXAlignment.Center,
					TextYAlignment = Enum.TextYAlignment.Center,
				}),
			})
		else
			children.PlotExpansionMax = e(SmallButton, {
				Size = UDim2.new(1, -8, 0, 64),
				AutomaticSize = Enum.AutomaticSize.None,
				BackgroundColor3 = Color3.new(0.35, 0.35, 0.35),
				LayoutOrder = 1,
			}, {
				e("UIStroke", { Thickness = 2, Color = Color3.new(0.7, 0.7, 0.7) }),
				e(SmallText, {
					Text = ` <b>Max Cafe Size Reached ({currentSize}x{currentSize})</b> `,
					RichText = true,
					Size = UDim2.new(1, 0, 1, 0),
					TextXAlignment = Enum.TextXAlignment.Center,
					TextYAlignment = Enum.TextYAlignment.Center,
				}),
			})
		end
	else
		local wantedCategory = subTab == "cash" and "Global" or "Ingredient"
		local playerUpgrades = props.playerStats.Upgrades or {}

		for idx, upg in ipairs(UpgradesConfig.Array) do
			if upg.Category == wantedCategory then
				local currentLevel = playerUpgrades[upg.Id] or 0
				local isMaxed = currentLevel >= upg.MaxLevel
				local nextLevel = currentLevel + 1
				local cost = not isMaxed and upg.GetCost(nextLevel) or 0

				local reqLevel = upg.UnlockLevel
				if upg.IngredientId then
					local stationCfg = PlaceablesModule.GetConfig(upg.IngredientId .. "_station")
					if stationCfg then
						reqLevel = math.max(reqLevel, stationCfg.UnlockLevel)
					end
				end

				local levelMet = props.playerStats.Level >= reqLevel
				local canAfford = props.playerStats.Cash >= cost

				local bgColor = Color3.new(0.2, 0.65, 0.3)
				local actionLabel = `${cost}`
				local image = "rbxassetid://76169596898587"

				if isMaxed then
					bgColor = Color3.new(0.35, 0.35, 0.35)
					actionLabel = "MAXED"
				elseif not levelMet then
					bgColor = Color3.new(0.4, 0.4, 0.4)
					actionLabel = `Unlocks Lvl {reqLevel}`
				elseif not canAfford then
					bgColor = Color3.new(0.65, 0.25, 0.25)
					actionLabel = `${cost}`
				end

				local descText = upg.Description(math.max(currentLevel, 1))

				local rowChildren = {
					Content = e(HStack, {
						VerticalFlex = "None",
						HorizontalFlex = "Fill",
						Spacing = UDim.new(0, 8),
						Padding = { All = UDim.new(0, 8) },
					}, {
						e(SmallText, {
							Text = `<font size="12">{descText}</font>`,
							RichText = true,
							Size = UDim2.new(1, 0, 1, 0),
							TextXAlignment = Enum.TextXAlignment.Left,
							TextYAlignment = Enum.TextYAlignment.Center,
							AutomaticSize = Enum.AutomaticSize.XY,
							TextWrapped = true,
						}),
						e(SmallButton, {
							Size = UDim2.new(1, 0, 0, 56),
							AutomaticSize = Enum.AutomaticSize.None,
							BackgroundColor3 = bgColor,
							BackgroundTransparency = 1,
							Rounded = false,
							LayoutOrder = idx,
							Image = (isMaxed or not canAfford or not levelMet) and "rbxassetid://91750414973277"
								or "rbxassetid://128846321008253",
							HoverScale = true,
							ScaleType = Enum.ScaleType.Slice,
							SliceCenter = Rect.new(50, 50, 54, 57),
							[React.Event.Activated] = function()
								if isMaxed or not levelMet then
									return
								end
								if canAfford and Remotes.BuyUpgrade then
									Remotes.BuyUpgrade:FireServer({ upgradeId = upg.Id })
								end
							end,
							Padding = { All = UDim.new(0, 0) },
						}, {
							e("UIStroke", { Thickness = 2, Color = Color3.new(0.85, 0.85, 0.85) }),
							e(HStack, {
								VerticalFlex = Enum.UIFlexAlignment.Fill,
								HorizontalFlex = Enum.UIFlexAlignment.Fill,
								VerticalAlignment = Enum.VerticalAlignment.Center,
								HorizontalAlignment = Enum.HorizontalAlignment.Center,
								Size = UDim2.new(1, 0, 1, 0),
								AutomaticSize = Enum.AutomaticSize.XY,
							}, {
								e(SmallText, {
									Text = `{actionLabel}`,
									RichText = true,
									Size = UDim2.new(0, 0, 0, 0),
									Position = UDim2.new(0.5, 0, 0.5, 0),
									AnchorPoint = Vector2.new(0.5, 0.5),
									TextXAlignment = "Center",
									TextYAlignment = "Center",
								}),
							}),
						}),
					}),
				}

				if not levelMet then
					rowChildren.Dim = e("Frame", {
						Size = UDim2.fromScale(1, 1),
						BackgroundColor3 = Color3.new(0, 0, 0),
						BackgroundTransparency = 0.45,
						Active = false,
						ZIndex = 20,
					})
				end

				children["UPG_" .. upg.Id] = e("ImageLabel", {
					Size = UDim2.new(1, 0, 0, 72),
					AutomaticSize = Enum.AutomaticSize.None,
					Image = image,
					ScaleType = Enum.ScaleType.Slice,
					SliceCenter = Rect.new(8, 8, 92, 92),
					BackgroundTransparency = 1,
					LayoutOrder = idx,
				}, rowChildren)
			end
		end
	end

	return e(VStack, {
		Size = UDim2.new(1, 0, 1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		VerticalFlex = "None",
		Spacing = UDim.new(0, 8),
		Padding = { All = UDim.new(0, 12) },
	}, children)
end

return UpgradeTab
