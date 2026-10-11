-- Shared/Configs/WorkersConfig.luau
export type WorkerTier = {
	Cost: number,
	UnlockLevel: number,
	Title: string,
}

export type StatLevelEntry = {
	Value: number,
	Cost: number, -- Cost to reach this level (Level 1 is 0 since it's the starting level)
}

export type StatUpgradeConfig = {
	Id: string,
	DisplayName: string,
	FormatValue: (val: number) -> string,
	Levels: { StatLevelEntry },
}

local WorkersConfig = {
	[1] = {
		Cost = 500,
		UnlockLevel = 5,
		Title = "Barista",
	},
	[2] = {
		Cost = 600,
		UnlockLevel = 6,
		Title = "Barista",
	},
	[3] = {
		Cost = 700,
		UnlockLevel = 7,
		Title = "Barista",
	},
	[4] = {
		Cost = 800,
		UnlockLevel = 9,
		Title = "Barista",
	},

	-- Individual Worker Stat Upgrades
	StatUpgrades = {
		walkSpeed = {
			Id = "walkSpeed",
			DisplayName = "Walk Speed",
			FormatValue = function(val: number)
				return `{val} studs/s`
			end,
			Levels = {
				[1] = { Value = 6, Cost = 0 },
				[2] = { Value = 9, Cost = 250 },
				[3] = { Value = 12, Cost = 400 },
				[4] = { Value = 15, Cost = 500 },
				[5] = { Value = 18, Cost = 600 },
			},
		},
		craftSpeed = {
			Id = "craftSpeed",
			DisplayName = "Station Speed",
			FormatValue = function(val: number)
				return `{string.format("%.1f", val)}s`
			end,
			Levels = {
				[1] = { Value = 1.5, Cost = 0 },
				[2] = { Value = 1.2, Cost = 200 },
				[3] = { Value = 0.9, Cost = 300 },
				[4] = { Value = 0.6, Cost = 400 },
				[5] = { Value = 0.3, Cost = 500 },
			},
		},
		quality = {
			Id = "quality",
			DisplayName = "Drink Quality",
			FormatValue = function(val: number)
				return `Score {val}`
			end,
			Levels = {
				[1] = { Value = 1, Cost = 0 }, -- Starts at 1 ("Good Enough")
				[2] = { Value = 2, Cost = 400	 }, -- Upgrades to 2 ("Nice")
				[3] = { Value = 3, Cost = 800 }, -- Upgrades to 3 ("Perfect")
			},
		},
	},
}

function WorkersConfig.GetWalkSpeed(level: number?): number
	local lvl = math.clamp(level or 1, 1, #WorkersConfig.StatUpgrades.walkSpeed.Levels)
	return WorkersConfig.StatUpgrades.walkSpeed.Levels[lvl].Value
end

function WorkersConfig.GetStationDuration(level: number?): number
	local lvl = math.clamp(level or 1, 1, #WorkersConfig.StatUpgrades.craftSpeed.Levels)
	return WorkersConfig.StatUpgrades.craftSpeed.Levels[lvl].Value
end

function WorkersConfig.GetQualityScore(level: number?): number
	local lvl = math.clamp(level or 1, 1, #WorkersConfig.StatUpgrades.quality.Levels)
	return WorkersConfig.StatUpgrades.quality.Levels[lvl].Value
end

function WorkersConfig.GetNextUpgrade(statType: string, currentLevel: number?): (number?, StatLevelEntry?)
	local statConfig = WorkersConfig.StatUpgrades[statType]
	if not statConfig then
		return nil, nil
	end
	local nextLevel = (currentLevel or 1) + 1
	local nextEntry = statConfig.Levels[nextLevel]
	if not nextEntry then
		return nil, nil
	end
	return nextLevel, nextEntry
end

return WorkersConfig
-- Shared/Configs/WorkersConfig.luau