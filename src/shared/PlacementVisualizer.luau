-- PlacementVisualizer.luau
local RunService = game:GetService("RunService")

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
	self.lerpSpeed = 0.2

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
	self.primaryPart = self.ghostModel.PrimaryPart or self.ghostModel:FindFirstChildWhichIsA("BasePart")

	-- Strip collisions and set transparency
	for _, part in self.ghostModel:GetDescendants() do
		if part:IsA("BasePart") then
			part.CanCollide = false
			part.Transparency = 0.5
		end
	end

	self.ghostModel.Parent = workspace
end

function PlacementVisualizer:updateGhost(targetCFrame: CFrame, isValid: boolean)
	if not self.ghostModel or not self.primaryPart then
		warn("not self.ghostModel or not self.primaryPart ")
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
