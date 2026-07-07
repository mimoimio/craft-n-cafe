local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local IngredientParticle = require(script.Parent.IngredientParticle)

local function IngredientVFXContainer(props)
	local activeTrails = props.activeTrails
	local onTrailComplete = props.onTrailComplete
	local particles = {}

	if activeTrails then
		for id, trailData in pairs(activeTrails) do
			particles[id] = React.createElement(IngredientParticle, {
				id = id,
				ingredientId = trailData.ingredientId,
				image = trailData.image,
				startPos = trailData.startPos,
				targetPos = trailData.targetPos,
				onComplete = function(completedId, ingId)
					if onTrailComplete then
						onTrailComplete(completedId, ingId)
					end
				end,
			})
		end
	end

	return React.createElement("ScreenGui", {
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 101, -- Ensures this sits above the panel GUI
	}, particles)
end

return IngredientVFXContainer
