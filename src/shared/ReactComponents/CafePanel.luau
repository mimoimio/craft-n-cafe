local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local Mionum = require(ReplicatedStorage.Packages.Mionum)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local e = React.createElement
local useState = React.useState
local useEffect = React.useEffect
local useRef = React.useRef

local SmallButton = require(ReplicatedStorage.Shared.ReactComponents.ui.SmallButton)
local HStack = require(ReplicatedStorage.Shared.ReactComponents.ui.HStack)
local VStack = require(ReplicatedStorage.Shared.ReactComponents.ui.VStack)
local LevelConfig = require(ReplicatedStorage.Shared.Configs.LevelConfig)

local ICON =
	[[<font family="rbxasset://LuaPackages/Packages/_Index/BuilderIcons/BuilderIcons/BuilderIcons.json"><b>robux</b></font>]]

local function CafePanel(props: {
	Open: boolean,
})
	local children = {}
	for i, config in LevelConfig do
		local texts = {}
		table.insert(texts, `Cost: {Mionum.new(config.Cost):toString()} {ICON}`)
		table.insert(texts, `Ingredients Unlocked:`)
		for i, ingredient in config.Ingredients do
			table.insert(texts, `\t-{ingredient}`)
		end
		children[i] = e(SmallButton, {
			Text = table.concat(texts, "\n"),
			Size = UDim2.new(0, 0, 1, 0),
			RichText = true,
		})
	end
	return e(VStack, {
		Size = UDim2.new(1, -80, 1, -80),
		Visible = props.Open,
		VerticalFlex = Enum.UIFlexAlignment.Fill,
		BackgroundTransparency = 1,
	}, {
		Top = e("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 1, 0),
		}, {
			levels = e(HStack, {
				VerticalFlex = Enum.UIFlexAlignment.Fill,
				Spacing = UDim.new(0, 8),
			}, children),
		}),
		LevelUp = e(SmallButton, {
			Text = "Level Up",
			[React.Event.Activated] = function()
				Remotes.LevelUp:FireServer()
			end,
		}),
	})
end

return CafePanel
