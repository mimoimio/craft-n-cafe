local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local React = require(ReplicatedStorage.Packages.React)
local ReactRoblox = require(ReplicatedStorage.Packages.ReactRoblox)
local e = React.createElement
local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local UIState = require(ReplicatedStorage.Shared.producers.UIState)
local LuckProb = require(ReplicatedStorage.Shared.ReactComponents.LuckProb)

local localPlayer = Players.LocalPlayer

-- 1. Create our mock GlobalState

-- 2. Create a Wrapper component to handle the layout and test callbacks
local function StoryWrapper()
	return e("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
	}, {
		LuckProb = e(LuckProb, {
			PlayerId = "",
			CafeModel = workspace,
		}),
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
