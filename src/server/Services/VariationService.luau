-- Server/Services/VariationService.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ShopCycle = require(ReplicatedStorage.Shared.ShopCycle)
local VariationsConfig = require(ReplicatedStorage.Shared.Configs.VariationsConfig)

export type VariationConfig = typeof(VariationsConfig.none)

local VariationService = {}

function VariationService.GetVariation(): VariationConfig?
	local currentShop = ShopCycle.getCurrentState()
	local rand = Random.new(Random.new():NextInteger(1, 999)):NextNumber()

	local total = 0
	local variationArray: { VariationConfig } = {}
	for i, variation: VariationConfig in VariationsConfig do
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
				return nil
			end
			return variation
		end
	end

	return nil
end

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

-- Adds a steep weighted curve: Size 1 is extremely common, Size 5 is extremely rare.
function VariationService.GetSize(): number
	local weights = {
		[1] = 1000,
		[2] = 250,
		[3] = 50,
		[4] = 10,
		[5] = 1,
	}

	local totalWeight = 0
	for _, weight in weights do
		totalWeight += weight
	end

	local rand = Random.new():NextNumber() * totalWeight

	local currentWeight = 0
	for size, weight in weights do
		currentWeight += weight
		if rand <= currentWeight then
			return size
		end
	end

	return 1
end

return VariationService
