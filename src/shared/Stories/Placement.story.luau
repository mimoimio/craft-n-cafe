-- Placement.story.luau
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlacementController = require(ReplicatedStorage.Shared.Controllers.PlacementController)
local InputAdapter = require(ReplicatedStorage.Shared.Controllers.InputAdapter)

local function story(frame: Frame)
	local plot = workspace.CafeBase.Part
	local models = game.ReplicatedStorage.Shared.Models

	local controller = PlacementController.new(plot, 4, models)
	controller:setBuildMode(true)
	controller:selectItem("cup")

	local connection = RunService.RenderStepped:Connect(function()
		local hitPos = InputAdapter.getCursorWorldPosition(plot)

		controller:update(hitPos)
	end)

	local inputConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end
		if input.KeyCode == Enum.KeyCode.R then
			controller:rotateItem()
		elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
			local hitPos = InputAdapter.getCursorWorldPosition(plot)
			local success, uuid = controller:placeItem(hitPos)
			if success then
				print("Successfully placed item with UUID:", uuid)
			end
		end
	end)

	return function()
		connection:Disconnect()
		inputConnection:Disconnect()
		controller:setBuildMode(false)
	end
end

return story
