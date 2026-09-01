local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local e = React.createElement
local useState = React.useState
local ReactRoblox = require(ReplicatedStorage.Packages.ReactRoblox)
local DefaultScrollFrame = require(ReplicatedStorage.Shared.ReactComponents.DefaultScrollFrame)
local SmallText = require(ReplicatedStorage.Shared.ReactComponents.ui.SmallText)
local ScreenPromptButton = require(ReplicatedStorage.Shared.ReactComponents.ui.ScreenPromptButton)
local Grid = require(ReplicatedStorage.Shared.ReactComponents.ui.Grid)

local function App(props: { module: {} })
	return e(ScreenPromptButton, {
		Size = UDim2.new(0, 50, 0, 50),
		ProximityPrompt = workspace.PromptButton.ProximityPrompt,
		-- Adornee = workspace.PromptButton,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
	}, {
		e(SmallText, {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			Text = "Son",
		}),
	})
end

local function story(frame: Frame)
	local root = ReactRoblox.createRoot(frame)
	root:render(e(App))

	return function()
		root:unmount()
	end
end

return story
