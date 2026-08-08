-- Shared/Utils/DrinkModelUtil.luau

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VariationsConfig = require(ReplicatedStorage.Shared.Configs.VariationsConfig)

export type DrinkRenderOptions = {
	Anchored: boolean?,
	CanCollide: boolean?,
	ParticleOffset: Vector3?,
	LerpAlpha: number?,
	Size: number,
}

local DrinkModelUtil = {}

--- Clones a drink, applies physics, tints ALL parts via Lerp, and attaches variation particles.
function DrinkModelUtil.BuildDrinkModel(drinkId: string, variationId: string?, options: DrinkRenderOptions)
	local opts = options or {}
	local size = opts.Size or 1
	local isAnchored = if opts.Anchored ~= nil then opts.Anchored else false
	local canCollide = if opts.CanCollide ~= nil then opts.CanCollide else false
	local particleOffset = opts.ParticleOffset or Vector3.new(0, 1, 0)
	local lerpAlpha = opts.LerpAlpha or 0.6 -- 60% variation color, 40% original color
	-- warn(`size: {size}`)

	local drinkTemplate = ReplicatedStorage.Shared.Models:FindFirstChild(drinkId)
	if not drinkTemplate then
		warn(`[DrinkModelUtil] Drink model {drinkId} not found! Building fallback.`)
		local model = Instance.new("Model")
		local part = Instance.new("Part", model)
		part.Name = "BasePart"
		model.PrimaryPart = part
		drinkTemplate = model
	end

	local clone = drinkTemplate:Clone()
	local modelBasePart = clone:FindFirstChildWhichIsA("BasePart", true)

	-- 1. Apply Physics Overrides
	for _, desc: BasePart in clone:GetDescendants() do
		if desc:IsA("BasePart") then
			desc.CollisionGroup = "Walls"
			desc.Anchored = isAnchored
			desc.CanCollide = canCollide
			desc.Massless = true
		end
	end

	-- 2. Apply Variation Tint and Particles
	if variationId and variationId ~= "none" then
		local variation = VariationsConfig[variationId]
		if variation then
			-- Lerp ALL parts to preserve shading
			if variation.ColorPrimary then
				for _, desc in clone:GetDescendants() do
					if desc:IsA("BasePart") then
						desc.Color = desc.Color:Lerp(variation.ColorPrimary, lerpAlpha)
						if desc:IsA("UnionOperation") then
							desc.UsePartColor = true
						end
					end
				end
			end

			-- Attach Particle
			local particleTemplate = ReplicatedStorage.Shared.Particles:FindFirstChild(variationId)
			if particleTemplate and modelBasePart then
				local part = particleTemplate:Clone() :: Part
				part.Transparency = 1
				part.CanCollide = false
				part.Massless = true
				part.Anchored = isAnchored
				part:PivotTo(clone:GetPivot() + particleOffset)
				part.Parent = modelBasePart

				local weld = Instance.new("WeldConstraint")
				weld.Part0 = part
				weld.Part1 = modelBasePart
				weld.Parent = part
			end
		end
	end

	-- 3. Apply Size Scaling
	local drinkSize = size or 1
	-- Size 1 = 1x scale | Size 5 = 1.8x scale (Adjust multiplier to fit your shelves!)
	local scaleMultiplier = 0.7 + (drinkSize * 0.3)

	if scaleMultiplier ~= 1 then
		clone:ScaleTo(clone:GetScale() * scaleMultiplier)
	end

	return clone, modelBasePart
end

return DrinkModelUtil
