-- Shared/Utils/PaintUtil.luau
--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PaintConfig = require(ReplicatedStorage.Shared.Configs.PaintConfig)

local PaintUtil = {}

-- Resolves the string payloads and applies the colors directly to a model
function PaintUtil.ApplyColors(model: Model | Instance, primaryStr: string?, secondaryStr: string?)
	local pColor = PaintConfig.ResolveColor(primaryStr)
	local sColor = PaintConfig.ResolveColor(secondaryStr)

	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			local pName = part.Name

			-- Strict targeting: Only care about these two exact names
			if pName == "Primary" or pName == "Secondary" then
				-- 1. Cache the default original color so we can restore it when `nil` is passed
				if not part:GetAttribute("OriginalColor") then
					part:SetAttribute("OriginalColor", part.Color)
				end

				-- 2. Ensure UnionOperations accept standard Color3 changes
				if part:IsA("UnionOperation") and not part.UsePartColor then
					part.UsePartColor = true
				end

				-- 3. Apply the resolved color (or fall back to the OriginalColor if no paint is equipped)
				if pName == "Primary" then
					part.Color = pColor or part:GetAttribute("OriginalColor")
				elseif pName == "Secondary" then
					part.Color = sColor or part:GetAttribute("OriginalColor")
				end
			end
		end
	end
end

return PaintUtil
