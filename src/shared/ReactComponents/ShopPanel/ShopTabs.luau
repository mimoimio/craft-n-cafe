-- Shared/ReactComponents/ShopPanel/ShopTabs.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)

local UIState = require(ReplicatedStorage.Shared.producers.UIState)
local Primitives = ReplicatedStorage.Shared.ReactComponents.ui
local HStack = require(Primitives.HStack)
local SmallButton = require(Primitives.SmallButton)
local SmallText = require(Primitives.SmallText)
local Toasts = require(script.Parent.Parent.Parent.ReactComponents.Toasts)
local ShopTabConfig = require(script.Parent.ShopTabConfig)

local useBreakpoint = require(ReplicatedStorage.Shared.Hooks.useBreakpoint)
local e = React.createElement

local function ShopTabs(props: {
	mobile: boolean,
	setTab: (string) -> ()?,
	tab: string,
	LayoutOrder: number?,
	level: number,
})
	local toast = Toasts.useToast()
	local xs, sm, md = useBreakpoint()
	local mobile = xs or sm or md

	local function handleTab(tabName: string, reqLevel: number)
		if props.level >= reqLevel then
			if props.setTab then
				props.setTab(tabName)
			end
		else
			if toast then
				toast.open(`Unlocks at Level {reqLevel}`, 3, Color3.new(1, 0.3, 0.3))
			end
		end
	end

	local children = {}
	for index, tab in ipairs(ShopTabConfig.Tabs) do
		local unlocked = props.level >= tab.level
		local isActive = props.tab == tab.id
		children[tab.id] = e(SmallButton, {
			LayoutOrder = index,
			Size = UDim2.new(0, props.mobile and 78 or 110, 0, 34),
			AutomaticSize = Enum.AutomaticSize.None,
			-- BackgroundColor3 = (not unlocked) and Color3.new(0.4, 0.4, 0.4) or nil,
			BackgroundTransparency = 1,
			ImageColor3 = not isActive and Color3.new(0.4, 0.4, 0.6) or nil,
			ImageTransparency = (not unlocked) and 0.8 or 0,
			Image = "rbxassetid://128846321008253",
			HoverScale = true,
			ScaleType = Enum.ScaleType.Slice,
			SliceCenter = Rect.new(50, 50, 54, 57),
			Rounded = false,
			OnMount = function(rbx)
				UIState.setTutorialTarget("ShopTab_" .. tab.id, rbx)
			end,
			[React.Event.Activated] = function()
				handleTab(tab.id, tab.level)
			end,
		}, {

			e(HStack, {
				VerticalFlex = "Fill",
				Size = UDim2.new(1, 0, 1, 0),
				HorizontalFlex = "Fill",
			}, {
				e(SmallText, {
					Text = tab.label,
					TextSize = props.mobile and (isActive and 18 or 12) or (isActive and 20 or 14),
					-- Size = UDim2.new(1, 0, 1, 0),
					Thickness = isActive and 3 or nil,
					TextXAlignment = Enum.TextXAlignment.Center,
					-- BackgroundTransparency = 0,
					TextYAlignment = Enum.TextYAlignment.Center,
					TextTransparency = props.tab == tab.id and 0 or 0.6,
					TextStrokeTransparency = props.tab == tab.id and 0 or 0.6,
				}),
			}),
		})
	end

	return e(HStack, {
		Size = UDim2.new(1, 0, 0, 0),
		LayoutOrder = props.LayoutOrder,
		AutomaticSize = Enum.AutomaticSize.Y,
		-- BackgroundTransparency = 0,
		VerticalFlex = "Fill",
		Wraps = true,
		Spacing = UDim.new(0, props.mobile and 4 or 6),
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		BackgroundImage = "rbxassetid://99700456312840",
		SliceCenter = Rect.new(8, 8, 92, 92),
		ScaleType = Enum.ScaleType.Slice,
		Padding = { All = UDim.new(0, mobile and 4 or 8) },
	}, children)
end

return ShopTabs
