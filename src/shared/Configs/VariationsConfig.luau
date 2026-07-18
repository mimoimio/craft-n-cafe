export type VariationsConfig = {
	VariationId: "none" | "copper" | "silver" | "gold" | "diamond",
	DisplayName: "" | "Copper" | "Silver" | "Gold" | "Diamond",
	Multiplier: number,
	ColorPrimary: Color3,
	ColorSecondary: Color3?,
	Weight: number,
	Image: number?,
}

local VariationsConfig = {
	none = {
		VariationId = "none",
		DisplayName = "None",
		Multiplier = 1,
		ColorPrimary = Color3.new(0, 0, 0),
		Weight = 34 ^ 3,
	},
	double = {
		VariationId = "double",
		DisplayName = "Double Shot",
		Multiplier = 2,
		ColorPrimary = Color3.new(0.894117, 0.239215, 0.239215),
		Weight = 21 ^ 3,
		Image = "rbxassetid://5975764560",
	},
	gold = {
		VariationId = "gold",
		DisplayName = "Golden",
		Multiplier = 3,
		ColorPrimary = Color3.new(0.894117, 0.796078, 0.239215),
		Weight = 13 ^ 3,
		Image = "rbxassetid://5975764560",
	},
	diamond = {
		VariationId = "diamond",
		DisplayName = "Diamond",
		Multiplier = 4,
		ColorPrimary = Color3.new(0.015686, 0.592156, 0.858823),
		Weight = 8 ^ 3,
		Image = "rbxassetid://10051960116",
	},
	starlight = {
		VariationId = "starlight",
		DisplayName = "Starlit",
		Multiplier = 5,
		ColorPrimary = Color3.new(0.549019, 0.152941, 1),
		Image = "rbxassetid://10051928285",
		Weight = 5 ^ 3,
	},
}

return VariationsConfig
