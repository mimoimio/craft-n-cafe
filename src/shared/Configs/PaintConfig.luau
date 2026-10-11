-- Shared/Configs/PaintConfig.luau
--!strict

local PaintConfig = {}

-- Curated presets for the UI picker (you can add as many as you like here!)
PaintConfig.Swatches = {
	["White"] = Color3.fromHex("#FFFFFF"),
	["Black"] = Color3.fromHex("#111111"),
	["Slate"] = Color3.fromHex("#3A3C42"),
	["Cream"] = Color3.fromHex("#F5F5DC"),

	["WoodOak"] = Color3.fromHex("#8B5A2B"),
	["WoodWalnut"] = Color3.fromHex("#4D3319"),
	["WoodPine"] = Color3.fromHex("#C19A6B"),

	["Espresso"] = Color3.fromHex("#2B1B17"),
	["Matcha"] = Color3.fromHex("#8A9A5B"),
	["PastelPink"] = Color3.fromHex("#FFD1DC"),
	["SkyBlue"] = Color3.fromHex("#87CEEB"),
	["Crimson"] = Color3.fromHex("#990000"),
}

-- Takes a string (either a Swatch ID or a Hex Code) and returns the Color3
function PaintConfig.ResolveColor(val: string?): Color3?
	if type(val) ~= "string" or val == "" then
		return nil
	end

	-- 1. Check if it's a known Swatch Preset
	if PaintConfig.Swatches[val] then
		return PaintConfig.Swatches[val]
	end

	-- 2. Otherwise, treat it as a custom Hex Code (with or without #)
	local success, color = pcall(function()
		return Color3.fromHex(val)
	end)

	if success then
		return color
	end

	return nil
end

return PaintConfig
