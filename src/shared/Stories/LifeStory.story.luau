local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local React = require(ReplicatedStorage.Packages.React)
local ReactRoblox = require(ReplicatedStorage.Packages.ReactRoblox)
local e = React.createElement
local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local RebirthModule = require(ReplicatedStorage.Shared.RebirthModule)
local UIState = require(ReplicatedStorage.Shared.producers.UIState)
local LuckProb = require(ReplicatedStorage.Shared.ReactComponents.LuckProb)
local SmallButton = require(ReplicatedStorage.Shared.ReactComponents.ui.SmallButton)
local VStack = require(ReplicatedStorage.Shared.ReactComponents.ui.VStack)
local DefaultScrollFrame = require(ReplicatedStorage.Shared.ReactComponents.DefaultScrollFrame)

local localPlayer = Players.LocalPlayer

-- 1. Create our mock GlobalState

-- 2. Create a Wrapper component to handle the layout and test callbacks
local pad = e("UIPadding", {
	PaddingTop = UDim.new(0, 12),
	PaddingBottom = UDim.new(0, 12),
	PaddingLeft = UDim.new(0.2, 12),
	PaddingRight = UDim.new(0.2, 12),
})
local function StoryWrapper()
	local children = { pad }
	for i, ingsInLife in RebirthModule.IngredientsByLife do
		children[i] = e(SmallButton, {
			TextXAlignment = Enum.TextXAlignment.Left,
			AutomaticSize = Enum.AutomaticSize.XY,
			Text = `{i}) \n\t{table.concat(ingsInLife, ", ")}`,
			RichText = true,
			TextWrapped = true,
			Size = UDim2.new(),
		}, { pad })
	end
	return e(DefaultScrollFrame, {
		LayoutOrder = 1,
		AutomaticSize = Enum.AutomaticSize.XY,
	}, {
		e(VStack, {
			AutomaticSize = Enum.AutomaticSize.XY,
			-- Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Spacing = UDim.new(0, 8),
			Padding = { All = UDim.new(0, 8) },
		}, children),
	})
end

-- 3. Mount the story
local function story(frame: Frame)
	local root = ReactRoblox.createRoot(frame)

	root:render(e(StoryWrapper))
	UIState.toggle("mixer")

	return function()
		root:unmount()
	end
end

return story
