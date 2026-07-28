local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ShopCycle = require(ReplicatedStorage.Shared.ShopCycle)
local VariationsConfig = require(ReplicatedStorage.Shared.Configs.VariationsConfig)

export type VariationConfig = VariationsConfig.VariationsConfig

local VariationService = {}
function VariationService.GetVariation(): VariationConfig?
	local currentShop = ShopCycle.getCurrentState()

	local rand = Random.new(Random.new():NextInteger(1, 999)):NextNumber()

	local total = 0
	local variationArray: { VariationConfig } = {}
	for i, variation: VariationConfig in VariationsConfig do
		-- if variation.VariationId == "none" then
		-- 	continue
		-- end

		total += variation.Weight
		table.insert(variationArray, variation)
	end
	table.sort(variationArray, function(vA: VariationConfig, vB: VariationConfig)
		return vA.Weight < vB.Weight
	end)

	local weightRand = total * rand

	local _total = 0
	for i, variation in variationArray do
		_total += variation.Weight
		if weightRand <= _total then
			if variation.VariationId == "none" then
				return nil -- return nil if no variation
			end
			return variation
		end
	end

	return nil
end

-- this is for event, must be special, cannot be "none"
function VariationService.GetCurrentVariationEvent(): VariationConfig?
	if not ShopCycle.getCurrentState().isSpecial then
		return
	end
	local currentShop = ShopCycle.getCurrentState()
	local seedNumber = tonumber(currentShop.seed)

	local rand = Random.new(seedNumber):NextNumber()

	local total = 0
	local variationArray: { VariationConfig } = {}
	for i, variation: VariationConfig in VariationsConfig do
		if variation.VariationId == "none" then
			continue
		end
		total += variation.Weight
		table.insert(variationArray, variation)
	end
	table.sort(variationArray, function(vA: VariationConfig, vB: VariationConfig)
		return vA.Weight < vB.Weight
	end)

	local weightRand = total * rand

	local _total = 0
	for i, variation in variationArray do
		if variation.VariationId == "none" then
			continue
		end
		_total += variation.Weight
		if weightRand <= _total then
			return variation
		end
	end

	return nil
end
return VariationService
