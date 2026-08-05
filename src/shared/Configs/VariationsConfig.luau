--Shared/Configs/VariationsConfig.luau
local VariationsConfig = {
	none = {
		VariationId = "none",
		DisplayName = "None",
		Multiplier = 1,
		ColorPrimary = Color3.new(0, 0, 0),
		Weight = 34 ^ 2,
	},
	double = {
		VariationId = "double",
		DisplayName = "Double Shot",
		Multiplier = 2,
		ColorPrimary = Color3.new(0.894117, 0.337254, 0.239215),
		Weight = 21 ^ 2,
		Image = "rbxassetid://5975764560",
	},
	gold = {
		VariationId = "gold",
		DisplayName = "Golden",
		Multiplier = 3,
		ColorPrimary = Color3.new(0.894117, 0.796078, 0.239215),
		Weight = 13 ^ 2,
		Image = "rbxassetid://5975764560",
	},
	diamond = {
		VariationId = "diamond",
		DisplayName = "Diamond",
		Multiplier = 4,
		ColorPrimary = Color3.new(0.015686, 0.592156, 0.858823),
		Weight = 8 ^ 2,
		Image = "rbxassetid://10051960116",
	},
	starlight = {
		VariationId = "starlight",
		DisplayName = "Starlit",
		Multiplier = 5,
		ColorPrimary = Color3.new(0.050980, 0, 1),
		Image = "rbxassetid://10051928285",
		Weight = 5 ^ 2,
	},
	hexed = {
		VariationId = "hexed",
		DisplayName = "Hexed",
		Multiplier = 6,
		ColorPrimary = Color3.new(0.764705, 0, 1),
		Image = "rbxassetid://10051928285",
		Weight = 3 ^ 2,
	},
}

return VariationsConfig
