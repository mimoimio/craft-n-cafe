-- InputAdapter.luau
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local InputAdapter = {}

function InputAdapter.getCursorWorldPosition(targetPlot: Part): Vector3
	local camera = Workspace.CurrentCamera
	if not camera then
		return targetPlot.Position
	end

	local lastInput = UserInputService:GetLastInputType()
	local isMobileOrConsole = lastInput == Enum.UserInputType.Touch or lastInput.Name:find("Gamepad")

	local pointX, pointY
	if isMobileOrConsole then
		-- Use the exact center of the screen for Touch/Gamepad
		local viewportSize = camera.ViewportSize
		pointX, pointY = viewportSize.X / 2, viewportSize.Y / 2
	else
		-- Fallback to actual mouse position for PC users
		local mouseLocation = UserInputService:GetMouseLocation()
		pointX, pointY = mouseLocation.X, mouseLocation.Y
	end

	local ray = camera:ViewportPointToRay(pointX, pointY)

	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Include
	raycastParams.FilterDescendantsInstances = { targetPlot }

	local result = Workspace:Raycast(ray.Origin, ray.Direction * 500, raycastParams)

	if result then
		return result.Position
	end

	-- Fallback if looking at the sky: project ray to the plot's Y plane
	local distance = (targetPlot.Position.Y - ray.Origin.Y) / ray.Direction.Y
	return ray.Origin + (ray.Direction * distance)
end
function InputAdapter.getHoveredItemUuid(targetBase: Instance): string?
	local camera = Workspace.CurrentCamera
	if not camera then
		return nil
	end

	local lastInput = UserInputService:GetLastInputType()
	local isMobileOrConsole = lastInput == Enum.UserInputType.Touch or lastInput.Name:find("Gamepad")

	local pointX, pointY
	if isMobileOrConsole then
		local viewportSize = camera.ViewportSize
		pointX, pointY = viewportSize.X / 2, viewportSize.Y / 2
	else
		local mouseLocation = UserInputService:GetMouseLocation()
		pointX, pointY = mouseLocation.X, mouseLocation.Y
	end

	local ray = camera:ViewportPointToRay(pointX, pointY)

	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Include
	-- targetBase should be the CafeBase model, which contains all the PlacedItem models
	raycastParams.FilterDescendantsInstances = { targetBase }

	local result = Workspace:Raycast(ray.Origin, ray.Direction * 500, raycastParams)

	if result and result.Instance then
		-- Traverse up the hierarchy to find the model with the Uuid tag
		local current = result.Instance
		while current and current ~= targetBase do
			local uuid = current:GetAttribute("Uuid")
			if uuid then
				return uuid
			end
			current = current.Parent
		end
	end

	return nil
end
return InputAdapter
