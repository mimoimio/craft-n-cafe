-- Shared/Configs/PlaytestConfig.luau
-- Edit these values before a playtest run.
return {
	-- Shown in the CSV logger as the run label.
	Variant = "no-pass",

	-- Keep false for multi-session runs and published playtests.
	UseMockProfileStore = false,

	-- While in Studio, ignore real gamepass ownership and use OwnedPasses below.
	UseGamePassOverrideInStudio = true,
	-- Force no-pass for published admin playtests without affecting real players.
	AlwaysNoPassUserIds = {
		[5470482596] = true,
	},
	OwnedPasses = {
		DoubleCash = false,
		PremiumPaint = false,
	},
}
