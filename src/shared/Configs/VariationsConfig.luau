--Shared/Configs/VariationsConfig.luau
local VariationsConfig = {
	none = {
		VariationId = "none",
		DisplayName = "Basic",
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

local total = 0
for i, variation in VariationsConfig do
	total += variation.Weight
end
for i, variation in VariationsConfig do
	local chance = variation.Weight / total
	variation.Chance = chance
end

type EventId = string
type Weights = { [EventId]: number }
local totals = {}

for eventId, variation in VariationsConfig do
	variation.Weights = {}
	variation.Chances = {}
	totals[eventId] = 0
	local texts = { `\n{eventId}:` }
	for variationId, _variation in VariationsConfig do
		local weight = eventId == variationId and (_variation.Weight + 1 / 10 * total // 1) or _variation.Weight
		totals[eventId] += weight
		variation.Weights[variationId] = weight
		table.insert(texts, `{string.format("%-14s", `\t[{variationId}]`)}= {weight}`)
	end
	table.insert(texts, `total = {totals[eventId]}\n`)
	-- warn(table.concat(texts, "\n"))
end
local totals2 = {}
for eventId, variation in VariationsConfig do
	local texts = { `\n{eventId} Chances:` }
	totals2[eventId] = 0
	for _name, _variation in VariationsConfig do
		local chance = variation.Weights[_name] / totals[eventId]
		totals2[eventId] += chance
		variation.Chances[_name] = chance
		table.insert(
			texts,
			`{string.format("%-14s", `\t[{_name}]`)}= {chance * 1000 // 1 / 10}% ({string.format(
				`%7s/%-7s`,
				`{variation.Weights[_name]}`,
				`{totals[eventId]}`
			)})`
		)
	end

	table.insert(texts, `total = {totals2[eventId]}\n`)
	-- warn(table.concat(texts, "\n"))
end

return VariationsConfig
