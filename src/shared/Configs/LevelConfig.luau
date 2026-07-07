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
		"foam",
	},
	[3] = {
		"ice",
		"chocolate",
	},
	[4] = {
		"teabag",
	},
	[5] = {
		"lemon",
	},
	[6] = {
		"carbonator",
	},
	[7] = {
		"icecream",
	},
	[8] = {
		"matcha",
		"boba",
	},
	[9] = {
		"cookies",
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
	[2] = 3000,
	[3] = 5000,
	[4] = 10_000,
	[5] = 50_000,
	[6] = 100_000,
	[7] = 150_000,
	[8] = 300_000,
	[9] = 900_000,
}

local LevelConfig = {}

for i = 1, 9 do
	LevelConfig[i] = {}
	LevelConfig[i].Ingredients = ingredients[i]
	LevelConfig[i].Cost = costs[i]
	LevelConfig[i].Tables = tables[i]
	LevelConfig[i].Mixers = mixers[i]
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
