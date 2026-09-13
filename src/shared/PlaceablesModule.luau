-- Shared/PlaceablesModule.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.Shared.Types)

local PlaceablesConfigArray: { Types.PlaceableConfig } =
	require(ReplicatedStorage.Shared.Configs.PlaceablesConfig:Clone())

local PlaceablesModule = {}
local PlaceableLookup: { [string]: Types.PlaceableConfig } = {}

-- 1. Initialize Lookup & Assign Images
for _, config in ipairs(PlaceablesConfigArray) do
	-- Enforce default values
	config.MaxAllowed = config.MaxAllowed or math.huge
	config.UnlockLevel = config.UnlockLevel or 1
	config.Price = config.Price or 0

	PlaceableLookup[config.Id] = config

	-- Fetch Image from PackageLink if missing
	if not config.Image then
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

-- 2. Export Data
PlaceablesModule.Config = PlaceableLookup
PlaceablesModule.Array = PlaceablesConfigArray

-- 3. Methods
function PlaceablesModule.GetConfig(id: string): Types.PlaceableConfig?
	return PlaceableLookup[id]
end

function PlaceablesModule.GetUnlockedItems(playerLevel: number): { Types.PlaceableConfig }
	local unlocked = {}
	for _, config in ipairs(PlaceablesConfigArray) do
		if playerLevel >= config.UnlockLevel then
			table.insert(unlocked, config)
		end
	end
	return unlocked
end

return PlaceablesModule :: Types.PlaceablesModule
