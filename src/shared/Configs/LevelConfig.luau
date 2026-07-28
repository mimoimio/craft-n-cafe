local tables = {
	[1] = {
		"Table1",
	},
	[2] = {
		"Table2",
	},
	[3] = {
		"Table3",
		"Table4",
	},
	[4] = {
		"Table5",
		"Table6",
	},
	[5] = {
		"Table7",
		"Table8",
	},
	[6] = {
		"Table9",
		"Table10",
	},
	[7] = {
		"Table11",
		"Table12",
	},
	[8] = {
		"Table13",
		"Table14",
		"Table15",
	},
	[9] = {
		"Table16",
		"Table17",
		"Table18",
	},
}
local ingredients = {
	[1] = {
		"espresso",
		"water",
		"milk",
	},
	[2] = {
		"ice",
		"foam",
	},
	[3] = {
		"chocolate",
		"teabag",
	},
	[4] = {
		"icecream",
		"matchapowder",
	},
	[5] = {
		"lemon",
		"boba",
	},
	[6] = {
		"carbonator",
		"cookies",
	},
	[7] = {
		"daybloom",
		"blinkroot",
		"luckyclover",
	},
	[8] = {
		"moonglow",
		"glowshroom",
		"bloodthorn",
	},
	[9] = {
		"waterberry",
		"fireblossom",
	},
}
local mixers = {
	[1] = { "Mixer1" },
	[2] = { "Mixer2" },
	[3] = { "Mixer3" },
	[4] = { "Mixer4" },
	[5] = { "Mixer5" },
	[6] = { "Mixer6" },
	[7] = { "Mixer7" },
	[8] = { "Mixer8" },
	[9] = {
		"Mixer9",
		"Mixer10",
	},
}
local costs = {
	[1] = 0,
	[2] = 300,
	[3] = 2000,
	[4] = 10_000,
	[5] = 100_000,
	[6] = 200_000,
	[7] = 600_000,
	[8] = 1_000_000,
	[9] = 2_000_000,
}

local LevelConfig: {
	{
		Ingredients: { [string]: true },
		Cost: number,
		Tables: { string },
		Mixers: { string },
	}
} =
	{}

for i = 1, 9 do
	LevelConfig[i] = {}

	-- setting ingredients at level i:
	LevelConfig[i].Ingredients = {}
	for j = 1, i do
		for _, ingredient in ingredients[j] do
			LevelConfig[i].Ingredients[ingredient] = true
		end
	end
	LevelConfig[i].Cost = costs[i]
	LevelConfig[i].Tables = tables[i]
	LevelConfig[i].Mixers = mixers[i]
	LevelConfig[i].NewIngredients = ingredients[i]
end

--[[
or we could do somewhat for every another for the tables
-- ]]

-- local mixers = {
-- 	[1] = { "Mixer1" },
-- 	[2] = { "Mixer2" },
-- 	[3] = {},
-- 	[4] = { "Mixer3" },
-- 	[5] = {},
-- 	[6] = {
-- 		"Mixer4",
-- 	},
-- 	[7] = {},
-- 	[8] = {
-- 		"Mixer5",
-- 	},
-- 	[9] = {},
-- 	[10] = {
-- 		"Mixer6",
-- 	},
-- 	[11] = {},
-- 	[12] = {
-- 		"Mixer7",
-- 	},
-- 	[13] = {},
-- 	[14] = {
-- 		"Mixer8",
-- 	},
-- 	[15] = {
-- 		"Mixer9",
-- 	},
-- 	[16] = {
-- 		"Mixer10",
-- 	},
-- }
-- local tables = {
-- 	[1] = {
-- 		"Table1",
-- 	},
-- 	[2] = {
-- 		"Table2",
-- 	},
-- 	[3] = {
-- 		"Table3",
-- 		"Table4",
-- 	},
-- 	[4] = {},
-- 	[5] = {
-- 		"Table5",
-- 		"Table6",
-- 	},
-- 	[6] = {},
-- 	[7] = {
-- 		"Table7",
-- 		"Table8",
-- 	},
-- 	[8] = {},
-- 	[9] = {
-- 		"Table9",
-- 		"Table10",
-- 	},
-- 	[10] = {},
-- 	[11] = {
-- 		"Table11",
-- 		"Table12",
-- 	},
-- 	[12] = {},
-- 	[13] = {},
-- 	[14] = {
-- 		"Table13",
-- 		"Table14",
-- 		"Table15",
-- 	},
-- 	[15] = {},
-- 	[16] = {
-- 		"Table16",
-- 		"Table17",
-- 		"Table18",
-- 	},
-- }
return LevelConfig
--[[
		in this implementation, I made it mandatory for all levels,
		all level progressions are mandatory.
		if not, they might miss a table, and it could break the game,
		not letting the player use a table that is rendered on their cafe.
		by making the implementation this way, it is static, and the
		business logic is validated in the services, levelUp action
		
		though, it leaves a worry that one might miss a level and therefore
		making it broken
		]]
