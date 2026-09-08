-- Shared/PlacementVisualizer.luau
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Grid = require(ReplicatedStorage.Shared.Grid)

local PlacementVisualizer = {}
PlacementVisualizer.__index = PlacementVisualizer

export type PlacementVisualizer = typeof(setmetatable({}, PlacementVisualizer))

local GRID_TEXTURE = "rbxassetid://2600521419"

function PlacementVisualizer.new(plotPart: Part, gridSize: number)
	local self = setmetatable({}, PlacementVisualizer)

	self.plot = plotPart
	self.gridSize = gridSize
	self.ghostModel = nil :: Model?
	self.primaryPart = nil :: Part?
	self.lerpSpeed = 0.4 -- Adjusted slightly for smoother snapping

	-- Render Plot Grid
	self.texture = Instance.new("Texture")
	self.texture.StudsPerTileU = gridSize
	self.texture.StudsPerTileV = gridSize
	self.texture.Texture = GRID_TEXTURE
	self.texture.Face = Enum.NormalId.Top
	self.texture.Parent = self.plot

	return self
end

function PlacementVisualizer:setGhostItem(modelPrefab: Model?)
	-- Clean up existing ghost
	if self.ghostModel then
		self.ghostModel:Destroy()
		self.ghostModel = nil
		self.primaryPart = nil
	end

	if not modelPrefab then
		return
	end

	self.ghostModel = modelPrefab:Clone()

	-- 1. Grab the original bounding box center and size
	local originalCFrame, itemSize = self.ghostModel:GetBoundingBox()

	-- 2. Calculate the snapped footprint size
	local rawX, rawZ = Grid.getFootprint(itemSize, 0)
	local snappedSize = Vector3.new(rawX * Grid.SIZE, itemSize.Y, rawZ * Grid.SIZE)

	-- Strip package links just like the renderer
	repeat
		local pl = self.ghostModel:FindFirstChildWhichIsA("PackageLink", true)
		if pl then
			pl:Destroy()
		end
	until not pl

	-- 3. Create the dummy PrimaryPart
	local part = Instance.new("Part")
	part.Anchored = true
	part.Size = snappedSize
	part:PivotTo(originalCFrame) -- VERY IMPORTANT: Align to internal center first
	part.CanCollide = false
	part.Transparency = 0.5
	part.Color = Color3.new(0, 1, 0)
	part.Parent = self.ghostModel

	-- 4. Assign it so future PivotTo() calls move the whole assembly
	self.ghostModel.PrimaryPart = part
	self.primaryPart = part

	-- Strip collisions and set transparency for the rest of the meshes
	for _, desc in self.ghostModel:GetDescendants() do
		if desc:IsA("BasePart") and desc ~= part then
			desc.CanCollide = false
			-- desc.Transparency = 0.5

			local alpha = 1 - desc.Transparency
			desc.Transparency = 1 - alpha * 0.6
		end
	end

	self.ghostModel.Parent = workspace
end

function PlacementVisualizer:updateGhost(targetCFrame: CFrame, isValid: boolean)
	if not self.ghostModel or not self.primaryPart then
		return
	end

	-- Update Hitbox Color
	local targetColor = isValid and Color3.new(0, 1, 0) or Color3.new(1, 0, 0)
	self.primaryPart.Color = targetColor

	-- Lerp to position
	local currentPivot = self.ghostModel:GetPivot()
	self.ghostModel:PivotTo(currentPivot:Lerp(targetCFrame, self.lerpSpeed))
end

function PlacementVisualizer:destroy()
	if self.ghostModel then
		self.ghostModel:Destroy()
	end
	if self.texture then
		self.texture:Destroy()
	end
end

return PlacementVisualizer
