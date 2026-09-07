-- InputAdapter.luau
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local InputAdapter = {}

function InputAdapter.getCursorWorldPosition(targetPlot: Part): Vector3
	local camera = Workspace.CurrentCamera
	if not camera then
		return targetPlot.Position
	end

	local mouseLocation = UserInputService:GetMouseLocation()
	local ray = camera:ViewportPointToRay(mouseLocation.X, mouseLocation.Y)

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

return InputAdapter
