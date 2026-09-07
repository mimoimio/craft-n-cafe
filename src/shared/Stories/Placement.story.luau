-- Placement.story.luau
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlacementController = require(ReplicatedStorage.Shared.Controllers.PlacementController)
local InputAdapter = require(ReplicatedStorage.Shared.Controllers.InputAdapter)

local function story(frame: Frame)
	local plot = workspace.CafeBase.Part

	local models = Instance.new("Folder")
	local crate = Instance.new("Model")
	crate.Name = "crate"
	local cratePart = Instance.new("Part")
	cratePart.Size = Vector3.new(4, 12, 12)
	cratePart.Parent = crate
	crate.PrimaryPart = cratePart
	crate.Parent = models

	-- 2. Initialize Controller
	local controller = PlacementController.new(plot, 4, models)
	controller:setBuildMode(true)
	controller:selectItem("crate")

	-- 3. Wire the Update Loop
	local connection = RunService.RenderStepped:Connect(function()
		local hitPos = InputAdapter.getCursorWorldPosition(plot)

		controller:update(hitPos)
	end)

	-- 4. Wire Inputs
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

	-- 5. Cleanup
	return function()
		connection:Disconnect()
		inputConnection:Disconnect()
		controller:setBuildMode(false)
		models:Destroy()
	end
end

return story
