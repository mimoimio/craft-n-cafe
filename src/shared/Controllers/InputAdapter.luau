-- Shared/Controllers/InputAdapter.luau
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local InputAdapter = {}

-- UPDATED: Added targetElevation to support placing Roofs in the air
function InputAdapter.getCursorWorldPosition(targetPlot: Part, targetElevation: number?): Vector3
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

	-- [[ ELEVATION PLANE PROJECTION ]]
	-- If building a Roof, we mathematically project the ray onto an invisible hovering plane.
	-- This prevents the mouse from jittering when looking at walls and floors.
	if targetElevation then
		local planeY = targetPlot.Position.Y + targetElevation
		local distance = (planeY - ray.Origin.Y) / ray.Direction.Y

		-- Ensure we are looking towards the plane, not away from it
		if distance >= 0 then
			return ray.Origin + (ray.Direction * distance)
		end
	end

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

function InputAdapter.getSpatialRaycast(targetBase: Instance, ignoreList: { Instance }?): RaycastResult?
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

	-- FIX: Instead of switching to Exclude (which hits the whole world),
	-- we strictly Include the Cafe, and temporarily turn off collision for ignored items.
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Include
	raycastParams.FilterDescendantsInstances = { targetBase }

	-- Temporarily disable CanQuery for items we want to ignore (like the Ghost model)
	local modifiedParts = {}
	if ignoreList then
		for _, instance in ipairs(ignoreList) do
			if instance and instance:IsDescendantOf(targetBase) then
				for _, part in ipairs(instance:GetDescendants()) do
					if part:IsA("BasePart") and part.CanQuery then
						part.CanQuery = false
						table.insert(modifiedParts, part)
					end
				end
			end
		end
	end

	local result = Workspace:Raycast(ray.Origin, ray.Direction * 500, raycastParams)

	-- Re-enable CanQuery to clean up
	for _, part in ipairs(modifiedParts) do
		part.CanQuery = true
	end

	return result
end

return InputAdapter
