-- Shared/CoffeeModule.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.Shared.Types)

local CoffeeConfigArray: { Types.CoffeeConfigType } = require(ReplicatedStorage.Shared.Configs.CoffeeConfig:Clone())
local IngredientConfigs: { Types.IngredientConfig } =
	require(ReplicatedStorage.Shared.Configs.IngredientsConfig:Clone())

local CoffeeModule = {}
local CoffeeConfig: { [string]: Types.CoffeeConfigType } = {}
CoffeeModule.IngredientLookup = {}

-- 1. Build Ingredient Lookup
for _, config in ipairs(IngredientConfigs) do
	CoffeeModule.IngredientLookup[config.Id] = config
end

-- 2. Filter out drinks that use non-existent ingredients
local validDrinksArray = {}
for _, config in ipairs(CoffeeConfigArray) do
	local isValid = true
	if config.Ingredients then
		for _, ingId in ipairs(config.Ingredients) do
			if not CoffeeModule.IngredientLookup[ingId] then
				isValid = false
				break
			end
		end
	end

	if isValid then
		table.insert(validDrinksArray, config)
	end
end
CoffeeConfigArray = validDrinksArray

-- Helper: Alphabetize and concatenate ingredients to create unique IDs
function CoffeeModule.GetId(ingredients: { string }): string
	local sorted = table.clone(ingredients)
	table.sort(sorted)
	return table.concat(sorted)
end

-- 3. Initialize Drink Lookup, Calculate Prices, and Build Instructions
local lookupTable: { [string]: Types.CoffeeConfigType } = {}

for _, config in ipairs(CoffeeConfigArray) do
	-- Assign the config to its base ID
	CoffeeConfig[config.Id] = config

	if not config.Ingredients then
		continue
	end

	-- Create the universal lookup ID (e.g., "espressomilk")
	local universalId = CoffeeModule.GetId(config.Ingredients)
	lookupTable[universalId] = config

	-- Calculate Price & Generate Flat Instruction String
	local totalPrice = 0
	local instructionNames = {}

	for _, ingId in ipairs(config.Ingredients) do
		local ingConfig = CoffeeModule.IngredientLookup[ingId]
		if ingConfig then
			totalPrice += (ingConfig.Price or 0)
			table.insert(instructionNames, ingConfig.DisplayName)
		end
	end

	config.Price = totalPrice

	if #instructionNames > 1 then
		config.Instruction = table.concat(instructionNames, " + ")
	end
end

-- Sort array by price (lowest to highest)
table.sort(CoffeeConfigArray, function(a, b)
	return (a.Price or 0) < (b.Price or 0)
end)

-- 4. PackageLink Image Fetching (Only if Image is not already set)
local function assignImagesFromModels(configs)
	for _, config in ipairs(configs) do
		if config.Image then
			continue
		end

		local model = ReplicatedStorage.Shared.Models:FindFirstChild(config.Id)
		if model then
			local pkgLink = model:FindFirstChildWhichIsA("PackageLink")
			if pkgLink then
				local numericId = string.match(tostring(pkgLink.PackageId), "%d+")
				if numericId then
					config.Image = string.format("rbxthumb://type=Asset&id=%s&w=150&h=150", numericId)
				end
			end
		end
	end
end

assignImagesFromModels(CoffeeConfigArray)
assignImagesFromModels(IngredientConfigs)

-- 5. Export Data
CoffeeModule.Config = CoffeeConfig
CoffeeModule.Array = CoffeeConfigArray
CoffeeModule.IngredientConfigs = IngredientConfigs

-- 6. The Core Crafting Method
function CoffeeModule.Craft(ingredients: { string }): Types.CoffeeConfigType?
	if not ingredients or #ingredients == 0 then
		return nil
	end

	local resultId = CoffeeModule.GetId(ingredients)
	return lookupTable[resultId]
end

return CoffeeModule :: Types.CoffeeModule
