-- Shared/Configs/PaintConfig.luau
--!strict

export type Swatch = {
	Name: string,
	Color: Color3,
	Premium: boolean,
}

local PaintConfig = {}

local swatches: { [string]: Color3 } = {
	-- Free essentials
	White = Color3.fromHex("#FFFFFF"),
	Cream = Color3.fromHex("#F5F5DC"),
	Black = Color3.fromHex("#111111"),
	Slate = Color3.fromHex("#3A3C42"),
	WoodOak = Color3.fromHex("#8B5A2B"),
	WoodWalnut = Color3.fromHex("#4D3319"),

	-- Premium woods and coffee tones
	WoodPine = Color3.fromHex("#C19A6B"),
	Espresso = Color3.fromHex("#2B1B17"),
	Matcha = Color3.fromHex("#8A9A5B"),
	PastelPink = Color3.fromHex("#FFD1DC"),
	SkyBlue = Color3.fromHex("#87CEEB"),
	Crimson = Color3.fromHex("#990000"),

	-- Premium accents
	Gold = Color3.fromHex("#D4AF37"),
	RoseGold = Color3.fromHex("#B76E79"),
	Copper = Color3.fromHex("#B87333"),
	Marble = Color3.fromHex("#E8E6E1"),
	Sandstone = Color3.fromHex("#C2B280"),
	BrickRed = Color3.fromHex("#8C3A2B"),
	Midnight = Color3.fromHex("#1B1F3B"),
	Ocean = Color3.fromHex("#1F6F8B"),
	NeonGreen = Color3.fromHex("#39FF14"),
	NeonPurple = Color3.fromHex("#B026FF"),
	Lavender = Color3.fromHex("#B497D6"),
	Mint = Color3.fromHex("#98FF98"),
}

local freeKeys = {
	"White",
	"Cream",
	"Black",
	"Slate",
	"WoodOak",
	"WoodWalnut",
}

local premiumKeys = {
	"WoodPine",
	"Espresso",
	"Matcha",
	"PastelPink",
	"SkyBlue",
	"Crimson",
	"Gold",
	"RoseGold",
	"Copper",
	"Marble",
	"Sandstone",
	"BrickRed",
	"Midnight",
	"Ocean",
	"NeonGreen",
	"NeonPurple",
	"Lavender",
	"Mint",
}

local swatchList: { Swatch } = {}
local premiumLookup: { [string]: boolean } = {}

for _, name in ipairs(freeKeys) do
	table.insert(swatchList, {
		Name = name,
		Color = swatches[name],
		Premium = false,
	})
end

for _, name in ipairs(premiumKeys) do
	premiumLookup[name] = true
	table.insert(swatchList, {
		Name = name,
		Color = swatches[name],
		Premium = true,
	})
end

PaintConfig.Swatches = swatches
PaintConfig.SwatchList = swatchList
PaintConfig.FreeKeys = freeKeys
PaintConfig.PremiumKeys = premiumKeys

function PaintConfig.IsPremium(name: string?): boolean
	return type(name) == "string" and premiumLookup[name] == true
end

function PaintConfig.IsKnown(name: string?): boolean
	return type(name) == "string" and swatches[name] ~= nil
end

function PaintConfig.IsAllowedPaint(name: string?, premiumOwned: boolean?): boolean
	if name == nil or name == "" then
		return true
	end
	if not PaintConfig.IsKnown(name) then
		return false
	end
	if PaintConfig.IsPremium(name) and not premiumOwned then
		return false
	end
	return true
end

-- Takes a string (either a Swatch ID or a Hex Code) and returns the Color3.
-- ResolveColor is intentionally permissive so legacy saved hex colors still render.
function PaintConfig.ResolveColor(val: string?): Color3?
	if type(val) ~= "string" or val == "" then
		return nil
	end

	if PaintConfig.Swatches[val] then
		return PaintConfig.Swatches[val]
	end

	local success, color = pcall(function()
		return Color3.fromHex(val)
	end)

	if success then
		return color
	end

	return nil
end

return PaintConfig
