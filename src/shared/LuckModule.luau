-- Shared/LuckModule.luau
local LuckModule = {}

-- Converts the player's Luck Level into the actual Math Multiplier (L)
function LuckModule.GetMultiplier(level: number): number
	return 0.7 + (level / 200)
end

-- Evaluates the Probability Density Function: f(z) = -L^2 * z^(L-1) * ln(z)
-- Domain: z is between (0, 1]
function LuckModule.CalculatePDF(z: number, luckMultiplier: number): number
	-- Prevent domain errors with math.log(0)
	if z <= 0 or z > 1 then
		return 0
	end
	return -(luckMultiplier ^ 2) * (z ^ (luckMultiplier - 1)) * math.log(z)
end

-- Generates a random Z value [0, 1] mapped to the Luck distribution.
function LuckModule.GenerateZ(luckMultiplier: number): number
	return (math.random() * math.random()) ^ (1 / luckMultiplier)
end

-- Rolls an index between 1 and maxRange, weighted by the Luck distribution
function LuckModule.RollIndex(luckMultiplier: number, maxRange: number): number
	local z = LuckModule.GenerateZ(luckMultiplier)
	return (z * maxRange) // 1 + 1
end

return LuckModule
