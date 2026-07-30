local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local React = require(ReplicatedStorage.Packages.React)
local ReactRoblox = require(ReplicatedStorage.Packages.ReactRoblox)
local e = React.createElement
local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local UIState = require(ReplicatedStorage.Shared.producers.UIState)
local UpgradePanel = require(ReplicatedStorage.Shared.ReactComponents.UpgradePanel)

-- We dynamically grab the LocalPlayer ID (or default to "0" if running in a weird Studio context)
-- so that it perfectly aligns with UpgradePanel's internal state lookup!
local localPlayer = Players.LocalPlayer
local mockPlayerId = localPlayer and tostring(localPlayer.UserId) or "0"

-- 1. Create our mock GlobalState

-- 2. Create a Wrapper component to handle the layout and test callbacks
local function StoryWrapper()
	return e("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
	}, {
		UpgradePanel = e(UpgradePanel, {
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
