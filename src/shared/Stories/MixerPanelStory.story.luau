local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local React = require(ReplicatedStorage.Packages.React)
local ReactRoblox = require(ReplicatedStorage.Packages.ReactRoblox)
local e = React.createElement
local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local UIState = require(ReplicatedStorage.Shared.producers.UIState)
local MixerPanel = require(ReplicatedStorage.Shared.ReactComponents.MixerPanel)
local ViewportController = require(ReplicatedStorage.Shared.Controllers.ViewportController)

-- We dynamically grab the LocalPlayer ID (or default to "0" if running in a weird Studio context)
-- so that it perfectly aligns with MixerPanel's internal state lookup!
local localPlayer = Players.LocalPlayer
local mockPlayerId = localPlayer and tostring(localPlayer.UserId) or "0"

-- 1. Create our mock GlobalState
local mockState = {
	Ingredients = {
		[mockPlayerId] = {
			espresso = 15,
			milk = 10,
			water = 20,
			ice = 8,
			-- Feel free to add any other ingredient keys here that match your CoffeeModule
		},
	},
}

-- 2. Create a Wrapper component to handle the layout and test callbacks
local function StoryWrapper()
	return e("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
	}, {
		Mixer = e(MixerPanel, {
			State = mockState,
			Open = true,
			MixerId = "Mock_Mixer_001",
			OnClose = function()
				-- print("MixerPanel: OnClose callback fired! The player wants to exit the panel.")
			end,
		}),
	})
end

-- 3. Mount the story
local function story(frame: Frame)
	local root = ReactRoblox.createRoot(frame)
	ViewportController.initialize()
	root:render(e(StoryWrapper))
	UIState.toggle("mixer")

	return function()
		ViewportController.cleanup()
		root:unmount()
	end
end

return story
