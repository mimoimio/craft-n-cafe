-- Shared/Configs/PlaytestConfig.luau
-- Edit these values before a playtest run.
return {
	-- Shown in the CSV logger as the run label.
	Variant = "no-pass",

	-- While in Studio, ignore real gamepass ownership and use OwnedPasses below.
	UseGamePassOverrideInStudio = true,
	OwnedPasses = {
		DoubleCash = false,
		PremiumPaint = false,
	},
}
