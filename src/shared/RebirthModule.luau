-- ReplicatedStorage/Shared/RebirthModule.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Sift = require(ReplicatedStorage.Packages.Sift)

local RebirthModule = {}
local NewIngredientsByLife = {
	[1] = {
		"espresso",
		"water",
		"milk",
		"ice",
		"foam",
		"chocolate",
		"teabag",
		"icecream",
		"matchapowder",
		"lemon",
		"boba",
		"carbonator",
	},
	[2] = {
		"daybloom",
	},
	[3] = {
		"blinkroot",
	},
	[5] = {
		"moonglow",
	},
	[8] = {
		"blinkroot",
	},
	[13] = {
		"waterberry",
	},
	[21] = {
		"fireblossom",
	},
	[34] = {
		"heartcrystal",
	},
}

local UnlockedIngredientsByLife = {}
for i, ings in NewIngredientsByLife do
	UnlockedIngredientsByLife[i] = ings
end
local lastLifesIngredients = {}
for i = 1, 100 do
	local unlockedIds = NewIngredientsByLife[i]
	if not unlockedIds then
		UnlockedIngredientsByLife[i] = lastLifesIngredients
		continue
	end
	lastLifesIngredients = Sift.Array.merge(lastLifesIngredients, unlockedIds)
	UnlockedIngredientsByLife[i] = lastLifesIngredients
end
RebirthModule.IngredientsByLife = UnlockedIngredientsByLife

-- function RebirthModule.GetUnlockedIngredientsByLife(life: number): string
-- 	return ids
-- end

return RebirthModule
