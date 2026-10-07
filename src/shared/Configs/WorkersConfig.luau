-- Shared/Configs/WorkersConfig.luau
export type WorkerTier = {
	Cost: number,
	UnlockLevel: number,
	Title: string,
}

local WorkersConfig: { WorkerTier } = {
	[1] = {
		Cost = 500,
		UnlockLevel = 3,
		Title = "Novice Barista",
	},
	[2] = {
		Cost = 2500,
		UnlockLevel = 8,
		Title = "Experienced Barista",
	},
	[3] = {
		Cost = 10000,
		UnlockLevel = 15,
		Title = "Senior Barista",
	},
	[4] = {
		Cost = 35000,
		UnlockLevel = 25,
		Title = "Master Barista",
	},
}

return WorkersConfig
