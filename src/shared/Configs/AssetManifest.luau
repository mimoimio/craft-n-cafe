-- Shared/Configs/AssetManifest.luau
-- Static list of content IDs that are not discoverable as instances at runtime.
-- Instance-based assets (Shared.SFX, Shared.Musics, Shared.Models) are collected
-- automatically by PreloadController.

local AssetManifest = {}

AssetManifest.Images = {
	-- Common icons
	"rbxassetid://103478691850846", -- Generic wood/palette icon (BuildPanel, CashHud, EXPOverlay, RecipePanel, RecipeWall, ShopPanel)
	"rbxassetid://127657596958436", -- Modal backdrop texture (most panels/prompts)
	"rbxassetid://15402844695", -- Cash icon (CashHud)
	"rbxassetid://17368060122", -- Coin particle (CoinParticle)

	-- BuildPanel
	"rbxassetid://17368208554", -- Hammer icon
	"rbxassetid://15403015683", -- Eye open toggle
	"rbxassetid://15403018096", -- Eye closed toggle
	"rbxassetid://17368204793", -- Delete icon
	"rbxassetid://18609516625", -- Brush/palette icon
	"rbxassetid://9559111831",

	-- ShopPanel
	"rbxassetid://17368177673",

	-- Sidebar
	"rbxassetid://15403066964",
	"rbxassetid://127110909372919",
	"rbxassetid://17368183719",
	"rbxassetid://17368089841",

	-- Panels and popups
	"rbxassetid://14197626379", -- LevelUp/DailyClaim background
	"rbxassetid://139964930837848", -- DailyPanel
	"rbxassetid://129501359972452", -- DailyPanel
	"rbxassetid://126550182137995", -- RecipePanel
	"rbxassetid://74072152836235", -- RedDot
	"rbxassetid://144082822", -- CustomerPrompts
	"rbxassetid://82823552269615", -- CustomersOrder

	-- World / beams / placement
	"rbxassetid://2600521419", -- Placement grid texture (PlacementVisualizer, PlacementHandler)
	"rbxassetid://17476697388", -- PointerBeam texture
	"rbxassetid://8152628560", -- Bouncing arrow (PointerBeam, Tutorial)
	"rbxassetid://139863296810113", -- Tutorial beam texture

	-- Variation images (VariationsConfig)
	"rbxassetid://5975764560",
	"rbxassetid://10051960116",
	"rbxassetid://10051928285",
}

AssetManifest.Sounds = {
	"rbxassetid://4096049827", -- Clock bell (server/Services/Clock.lua)
	"rbxassetid://79020702281821", -- Customer order sound (server/Services/CafeRenderingService/Customers.luau)
	"rbxassetid://133313033428402", -- Customer order sound (Customers.luau)
	"rbxassetid://132299423186452", -- Customer order sound (Customers.luau)
}

return AssetManifest
