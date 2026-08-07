-- Shared/CoffeeModule.luau
local CoffeeConfigArray: { CoffeeConfigType } = require(game.ReplicatedStorage.Shared.Configs.CoffeeConfig)
local IngredientConfigs: { IngredientConfig } = require(game.ReplicatedStorage.Shared.Configs.IngredientsConfig)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.Shared.Types)

export type CoffeeConfigType = Types.CoffeeConfigType
export type IngredientConfig = Types.IngredientConfig
local CoffeeModule = {}

-- Build lookup by Id and track config order for ingredient priority
local CoffeeConfig: { [string]: CoffeeConfigType } = {}
local ingredientPriority: { [string]: number } = {} -- lower = earlier in config = removed last

for index, config in ipairs(IngredientConfigs) do
	ingredientPriority[config.Id] = index
end
for index, config in ipairs(CoffeeConfigArray) do
	CoffeeConfig[config.Id] = config
end

function CoffeeModule.GetId(Ingredients: { string }): string
	-- Sort ingredients by alphabet and concatenate
	local sorted = table.clone(Ingredients)
	table.sort(sorted)
	return table.concat(sorted)
end

-- Initialize lookup table by assigning each config's resulting ingredients GetId to the config
local lookupTable: { [string]: CoffeeConfigType } = {}

for i, config in ipairs(CoffeeConfigArray) do
	local id = CoffeeModule.GetId(config.Ingredients)
	lookupTable[id] = config
end

-- Compute Instructions: recursively trace back to a single base ingredient,
-- then reverse to show the step-by-step ingredients to add.
-- Ingredients later in config array are removed first (higher priority number).

local function getIngredientDisplayName(id: string): string
	local cfg = CoffeeConfig[id]
	return cfg and cfg.DisplayName or id
end

-- Sort ingredients by removal priority: higher index in config = removed first
local function sortByRemovalPriority(ingredients: { string }): { string }
	local sorted = table.clone(ingredients)
	table.sort(sorted, function(a, b)
		local pa = ingredientPriority[a] or 9999
		local pb = ingredientPriority[b] or 9999
		return pa > pb -- higher priority number = try to remove first
	end)
	return sorted
end

-- Recursively find a path of ingredient IDs to add, starting from a base ingredient
local function findInstructionPathIds(ingredients: { string }): { string }?
	-- Base case: single ingredient is the starting point
	if #ingredients == 1 then
		return { ingredients[1] }
	end

	-- Sort by removal priority (later in config = removed first)
	local sortedIngredients = sortByRemovalPriority(ingredients)

	-- Try removing each ingredient in priority order
	for _, removedIngredient in ipairs(sortedIngredients) do
		local reduced = {}
		for _, ing in ipairs(ingredients) do
			if ing ~= removedIngredient then
				table.insert(reduced, ing)
			end
		end

		local baseId = CoffeeModule.GetId(reduced)
		local baseConfig = lookupTable[baseId]

		if baseConfig then
			-- Found a valid base, recurse to find the full path
			local basePath = findInstructionPathIds(reduced)
			if basePath then
				table.insert(basePath, removedIngredient)
				return basePath
			end
		end
	end
	task.spawn(function()
		error("CRITICAL ERROR: DISCONNECTED RECIPE PATH: " .. table.concat(ingredients, ", "))
	end)
	return nil
end

-- Recursively find a path of ingredients to add, starting from a base ingredient
local function findInstructionPath(ingredients: { string }): { string }?
	-- Base case: single ingredient is the starting point
	if #ingredients == 1 then
		return { getIngredientDisplayName(ingredients[1]) }
	end

	-- Sort by removal priority (later in config = removed first)
	local sortedIngredients = sortByRemovalPriority(ingredients)

	-- Try removing each ingredient in priority order
	for _, removedIngredient in ipairs(sortedIngredients) do
		local reduced = {}
		for _, ing in ipairs(ingredients) do
			if ing ~= removedIngredient then
				table.insert(reduced, ing)
			end
		end

		local baseId = CoffeeModule.GetId(reduced)
		local baseConfig = lookupTable[baseId]

		if baseConfig then
			-- Found a valid base, recurse to find the full path
			local basePath = findInstructionPath(reduced)
			if basePath then
				table.insert(basePath, getIngredientDisplayName(removedIngredient))
				return basePath
			end
		end
	end
	task.spawn(function()
		error("CRITICAL ERROR: DISCONNECTED RECIPE PATH: " .. table.concat(ingredients, ", "))
	end)
	return nil
end

for _, config in ipairs(CoffeeConfigArray) do
	if not config.Ingredients then
		continue
	end
	local pathIds = findInstructionPathIds(config.Ingredients)
	local pathDisplay = findInstructionPath(config.Ingredients)
	if pathDisplay and #pathDisplay > 1 then
		config.Instruction = table.concat(pathDisplay, " -> ")
	end
	config.RecipePath = pathIds
end

-- Assign Image from model PackageLink
for _, config in ipairs(CoffeeConfigArray) do
	local model = ReplicatedStorage.Shared.Models:FindFirstChild(config.Id)
	if model then
		local ingredientPackageLink = model:FindFirstChildWhichIsA("PackageLink")
		if ingredientPackageLink then
			local numericId = string.match(tostring(ingredientPackageLink.PackageId), "%d+")
			config.Image = string.format("rbxthumb://type=Asset&id=%s&w=150&h=150", numericId)
		end
	end
end
for _, config in ipairs(IngredientConfigs) do
	local model = ReplicatedStorage.Shared.Models:FindFirstChild(config.Id)
	if model then
		local ingredientPackageLink = model:FindFirstChildWhichIsA("PackageLink")
		if ingredientPackageLink then
			local numericId = string.match(tostring(ingredientPackageLink.PackageId), "%d+")
			config.Image = string.format("rbxthumb://type=Asset&id=%s&w=150&h=150", numericId)
		end
	end
end

-- Export the keyed config for external use
CoffeeModule.Config = CoffeeConfig
CoffeeModule.Array = CoffeeConfigArray
CoffeeModule.IngredientConfigs = IngredientConfigs
CoffeeModule.IngredientLookup = {}
for i, config in IngredientConfigs do
	CoffeeModule.IngredientLookup[config.Id] = config
end

for index, config in ipairs(CoffeeConfigArray) do
	CoffeeConfig[config.Id] = config
	config.Price = 0
	for i, ing in config.Ingredients do
		config.Price += CoffeeModule.IngredientLookup[ing].Cost
	end
end
table.sort(CoffeeConfigArray, function(a, b)
	return a.Price < b.Price
end)

for index, config in ipairs(CoffeeConfigArray) do
	config.Rate = index
end

function CoffeeModule.Craft(ingredients: { string }): CoffeeConfigType?
	-- Support any number of items
	if #ingredients == 0 then
		return nil
	end

	-- Get resulting Id and lookup
	local resultId = CoffeeModule.GetId(ingredients)
	return lookupTable[resultId]
end

return CoffeeModule :: Types.CoffeeModule
