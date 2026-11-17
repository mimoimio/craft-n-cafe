-- Shared/ReactComponents/ShopPanel/ItemTab.luau
--TODO: reddot on category tabs.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)

local UIState = require(ReplicatedStorage.Shared.producers.UIState)
local PlaceablesModule = require(ReplicatedStorage.Shared.PlaceablesModule)

local Primitives = ReplicatedStorage.Shared.ReactComponents.ui
local VStack = require(Primitives.VStack)
local HStack = require(Primitives.HStack)
local Padding = require(Primitives.Padding)
local Types = require(ReplicatedStorage.Shared.Types)
local SmallButton = require(Primitives.SmallButton)
local SmallText = require(Primitives.SmallText)
local ItemButton = require(script.Parent.ItemButton)
local ShopTabConfig = require(script.Parent.ShopTabConfig)
local RedDot = require(script.Parent.Parent.RedDot).RedDot

local e = React.createElement
local useState = React.useState
local useEffect = React.useEffect
local function StationsItemButton(props: {
	isSelected: boolean,
	isLocked: boolean,
	maxed: boolean?,
	config: Types.PlaceableConfig,
	mobile: boolean,
	cleared: boolean,
	selectingCategory: React.ReactBinding<boolean>?,
	Visible: boolean?,
	OnMount: ((GuiObject) -> ())?,
})
	local itemId = props.config.Id
	local isSelected = props.isSelected
	local isLocked = props.isLocked
	local currentCamera: Camera, setCurrentCamera = useState(nil)
	local worldModel, setWorldModel = useState(nil)
	local modelClone, setModelClone = useState(nil)
	local mobile = props.mobile

	useEffect(function()
		if not worldModel then
			return
		end
		local prefab = ReplicatedStorage.Shared.Models:FindFirstChild(itemId)
		if not prefab then
			return
		end

		local clone = prefab:Clone()
		clone:PivotTo(CFrame.new(Vector3.zero))
		clone.Parent = worldModel
		setModelClone(clone)

		return function()
			clone:Destroy()
			setModelClone(nil)
		end
	end, { worldModel })

	useEffect(function()
		if not (worldModel and currentCamera and modelClone) then
			return
		end
		currentCamera:ZoomToExtents(modelClone:GetBoundingBox())
	end, { worldModel, currentCamera, modelClone })

	return e(SmallButton, {
		-- Size = UDim2.new(0.5, 0, mobile and 0.5 or 0.3, 0),
		Size = UDim2.fromOffset(284, 430):Lerp(UDim2.fromOffset(0, 0), 1 / (mobile and 2 or 3)),
		AutomaticSize = Enum.AutomaticSize.None,
		[React.Event.Activated] = props[React.Event.Activated],
		-- BackgroundColor3 = isSelected and Color3.new(0.2, 0.6, 0.2) or nil,
		LayoutOrder = props.config.UnlockLevel,
		Padding = { All = UDim.new() },
		-- Image = "rbxassetid://76169596898587",

		Rounded = false,
		BackgroundTransparency = 1,
		ScaleType = Enum.ScaleType.Stretch,
		-- SliceCenter = Rect.new(8, 8, 92, 92),
		Visible = props.Visible,
		OnMount = props.OnMount,
		Selectable = props.selectingCategory and props.selectingCategory:map(function(is)
			return not is
		end) or nil,
		-- Image = isSelected and "rbxassetid://79718487292366" or "rbxassetid://127798397798290",
		Image = "rbxassetid://90029908240504",
	}, {
		stroke = e("UIStroke", { Thickness = isSelected and 2 or 0 }),
		-- Make reddot cleared when GuiService.SelectedObject == this.
		reddot = not props.cleared and e(RedDot, { Position = UDim2.new(1, -8, 0, 8), SizeNum = 48 }),
		e(Padding, { All = UDim.new(0, 12) }),
		e("ViewportFrame", {
			ZIndex = 1,
			CurrentCamera = currentCamera,
			Size = UDim2.new(1, 0, 1, 0),
			LightDirection = Vector3.new(0, -1, -1),
			BackgroundTransparency = 1,
			Active = false,
			ImageColor3 = isLocked and Color3.new(0, 0, 0) or nil,
			-- ImageTransparency = isLocked and 0.5 or 0,
		}, {
			World = e("WorldModel", { ref = setWorldModel }, {
				Camera = e("Camera", {
					ref = setCurrentCamera,
					CFrame = CFrame.new(Vector3.new(20, 20, -20), Vector3.zero),
					FieldOfView = 45,
				}),
			}),
		}),
		e(VStack, {
			Size = UDim2.new(1, 0, 1, 0),
		}, {
			e(SmallText, {
				Text = props.config and props.config.DisplayName,
				TextWrapped = true,
				Size = UDim2.new(1, 0, 1, 0),

				ZIndex = 3,
				TextXAlignment = Enum.TextXAlignment.Center,
				TextYAlignment = Enum.TextYAlignment.Top,
			}),
			e(SmallText, {
				Text = props.maxed and "✅" or (isLocked and "🔒") or "",
				ZIndex = 4,
				TextSize = 48,
				Size = UDim2.fromScale(1, 1),
				TextXAlignment = Enum.TextXAlignment.Center,
				TextYAlignment = Enum.TextYAlignment.Center,
			}),
		}),
		e(SmallText, {
			Text = props.config and "Level " .. props.config.UnlockLevel,
			TextWrapped = true,
			Size = UDim2.new(0.8, 0, 0.8, 0),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			TextSize = 14,
			TextXAlignment = Enum.TextXAlignment.Center,
		}),
	})
end
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
			OnMount = function(rbx)
				UIState.setTutorialTarget("ShopSubTab_" .. category, rbx)
			end,
			[React.Event.Activated] = function()
				props.onSelectSubTab(category)
			end,
		}, {
			e(SmallText, {
				Text = ShopTabConfig.getCategoryLabel(category),
				TextSize = props.mobile and (isActive and 15 or 11) or (isActive and 17 or 13),
				Size = UDim2.new(1, 0, 1, 0),
				TextXAlignment = Enum.TextXAlignment.Center,
				TextYAlignment = Enum.TextYAlignment.Center,
				TextTransparency = isActive and 0 or 0.4,
				Thickness = isActive and 3 or nil,
			}),
		})
	end

	local itemButtons = {}
	local isStations = props.subTab == "Station"
	for _, config in ipairs(PlaceablesModule.Array) do
		if config.Category == props.subTab then
			local isLocked = props.playerStats.Level < config.UnlockLevel
			local maxed = props.amount and ((props.amount[config.Id] or 0) >= config.MaxAllowed) or nil

			itemButtons[config.Id] = e(isStations and StationsItemButton or ItemButton, {
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
			-- Wraps = not isStations,
			Wraps = true,
			Spacing = UDim.new(0, 8),
			BackgroundTransparency = 1,
			VerticalAlignment = Enum.VerticalAlignment.Top,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalFlex = "None",
			HorizontalFlex = "None",
			-- Padding = { All = UDim.new(0, 12) },
		}, itemButtons),
	})
end

return ItemTab
