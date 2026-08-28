-- Shared/UpgradesModule.luau
local UpgradesModule = {}

-- ==========================
-- LUCK UPGRADES
-- ==========================

local luckEXP = 3

function UpgradesModule.GetLuckCost(currentLevel: number, increments: number)
	local cost = 0
	for i = 1, increments do
		cost += ((currentLevel + i) * 10) ^ luckEXP // 1
	end
	return cost
end

function UpgradesModule.GetMaxAffordableLuck(currentLevel: number, currentCash: number)
	local increments = 0
	local totalCost = 0

	while true do
		local nextLevelCost = ((currentLevel + increments + 1) * 10) ^ luckEXP // 1
		if totalCost + nextLevelCost <= currentCash then
			increments += 1
			totalCost += nextLevelCost
		else
			break
		end
	end

	return increments, totalCost
end

-- ==========================
-- CAFE CAPACITY UPGRADES
-- ==========================

function UpgradesModule.GetCapacityCost(currentCapacity: number, increments: number)
	local cost = 0
	for i = 1, increments do
		cost += 10 ^ (currentCapacity - 3 + i)
	end
	return cost
end

function UpgradesModule.GetMaxAffordableCapacity(currentCapacity: number, currentCash: number)
	local increments = 0
	local totalCost = 0

	while true do
		local nextLevelCost = 10 ^ (currentCapacity - 3 + increments + 1)
		if totalCost + nextLevelCost <= currentCash then
			increments += 1
			totalCost += nextLevelCost
		else
			break
		end
	end

	return increments, totalCost
end

return UpgradesModule
