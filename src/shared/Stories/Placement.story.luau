-- Placement.story.luau
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlacementController = require(ReplicatedStorage.Shared.Controllers.PlacementController)
local InputAdapter = require(ReplicatedStorage.Shared.Controllers.InputAdapter)

local function story(frame: Frame)
	return function() end
end

return story
