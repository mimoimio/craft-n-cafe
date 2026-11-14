-- Shared/ReactComponents/ShopPanel/ItemTab.luau
--TODO: reddot on category tabs.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)

local UIState = require(ReplicatedStorage.Shared.producers.UIState)
local PlaceablesModule = require(ReplicatedStorage.Shared.PlaceablesModule)

local Primitives = ReplicatedStorage.Shared.ReactComponents.ui
local VStack = require(Primitives.VStack)
local HStack = require(Primitives.HStack)
local SmallButton = require(Primitives.SmallButton)
local SmallText = require(Primitives.SmallText)
local ItemButton = require(script.Parent.ItemButton)
local ShopTabConfig = require(script.Parent.ShopTabConfig)

local e = React.createElement

local function ItemTab(props: {
	tab: string,
	mobile: boolean,
	playerStats: any,
	amount: { [string]: number }?,
	selectedItem: string?,
	subTab: string,
	unackedUnlocks: { [string]: boolean },
	selectingCategory: any,
	onSelectSubTab: (string) -> (),
	onSelectItem: (string) -> (),
	onClearUnlock: (string) -> (),
})
	local subTabButtons = {}
	for index, category in ipairs(ShopTabConfig.getItemSubTabs()) do
		local isActive = props.subTab == category
		subTabButtons[category] = e(SmallButton, {
			LayoutOrder = index,
			Size = UDim2.new(0, 0, 0, 32),
			AutomaticSize = Enum.AutomaticSize.X,
			BackgroundTransparency = 1,
			Image = "rbxassetid://128846321008253",
			ImageColor3 = isActive and nil or Color3.new(0.4, 0.4, 0.6),
			ScaleType = Enum.ScaleType.Slice,
			SliceCenter = Rect.new(50, 50, 54, 57),
			Rounded = false,
			HoverScale = true,
			Padding = {
				Right = UDim.new(0, 8),
				Left = UDim.new(0, 8),
				All = UDim.new(0, 0),
			},
			OnMount = function(rbx)
				UIState.setTutorialTarget("ShopSubTab_" .. category, rbx)
			end,
			[React.Event.Activated] = function()
				props.onSelectSubTab(category)
			end,
		}, {
			e(SmallText, {
				Text = ShopTabConfig.getCategoryLabel(category),
				TextSize = props.mobile and 11 or 13,
				Size = UDim2.new(1, 0, 1, 0),
				TextXAlignment = Enum.TextXAlignment.Center,
				TextYAlignment = Enum.TextYAlignment.Center,
				TextTransparency = isActive and 0 or 0.4,
			}),
		})
	end

	local itemButtons = {}
	for _, config in ipairs(PlaceablesModule.Array) do
		if config.Category == props.subTab then
			local isLocked = props.playerStats.Level < config.UnlockLevel
			local maxed = props.amount and ((props.amount[config.Id] or 0) >= config.MaxAllowed) or nil

			itemButtons[config.Id] = e(ItemButton, {
				config = config,
				Visible = true,
				maxed = maxed,
				isSelected = props.selectedItem == config.Id,
				isLocked = isLocked,
				mobile = props.mobile,
				cleared = not props.unackedUnlocks[config.Id],
				selectingCategory = props.selectingCategory,
				OnMount = (config.Id == "ice_station" or config.Id == "Cashier2") and function(rbx)
					UIState.setTutorialTarget("ShopItem_" .. config.Id, rbx)
				end or nil,
				[React.Event.Activated] = function()
					props.onSelectItem(config.Id)
					props.onClearUnlock(config.Id)
				end,
			})
		end
	end

	return e(VStack, {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.XY,
		VerticalFlex = "None",
		Spacing = UDim.new(0, 8),
		BackgroundTransparency = 1,
		BackgroundImage = "rbxassetid://99700456312840",
		SliceCenter = Rect.new(8, 8, 92, 92),
		ScaleType = Enum.ScaleType.Slice,
		Padding = { All = UDim.new(0, 4) },
	}, {
		SubTabs = e(HStack, {
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			Wraps = true,
			Spacing = UDim.new(0, props.mobile and 4 or 6),
			BackgroundTransparency = 1,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalFlex = "None",
			LayoutOrder = 1,
		}, subTabButtons),
		Items = e(HStack, {
			LayoutOrder = 2,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.XY,
			Wraps = true,
			Spacing = UDim.new(0, 8),
			BackgroundTransparency = 1,
			VerticalAlignment = Enum.VerticalAlignment.Top,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalFlex = "None",
			-- Padding = { All = UDim.new(0, 12) },
		}, itemButtons),
	})
end

return ItemTab
