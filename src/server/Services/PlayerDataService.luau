local DATASTORENAME = "DATASTORENAME"
local DRINKS_MIXED_DATASTORE = "DRINKS_MIXED_DATASTORE"
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ProfileStoreModule = require(game.ServerScriptService.Server.Modules.ProfileStore)
local Remotes = require(game.ReplicatedStorage.Shared.Remotes)
local Reflex = require(game.ReplicatedStorage.Packages.Reflex)
local Sift = require(game.ReplicatedStorage.Packages.Sift)

local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local Types = require(ReplicatedStorage.Shared.Types)
local Signal = require(game.ReplicatedStorage.Packages.Signal)
local ShopCycle = require(game.ReplicatedStorage.Shared.ShopCycle)

local IS_PLAYTESTING = true

type PlayerData = Types.PlayerData
type Profile = ProfileStoreModule.Profile<PlayerData> -- Typed Profile object

local PROFILE_TEMPLATE: PlayerData = {
	Stats = {
		Sfx = 0.5,
		Music = 0.5,
		SecondsPlayed = 0,
		Cash = 30,
		Level = 1,
		CafeOpen = true,
		MaxDrinksPerCustomer = 3,
		MaxCustomersAtOnce = 5,
		RollCooldown = 2,
	},
	Tables = {
		Table1 = {
			TableId = "woodentable",
			Slots = { Slot1 = "none", Slot2 = "none", Slot3 = "none", Slot4 = "none" },
		},
	},
	Drinks = {
		-- {
		-- 	id = "abc",
		-- 	variationId = "starlight",
		-- 	drinkId = "volcafrappuccino",
		-- 	stock = 999_999_999,
		-- },
		-- {
		-- 	id = "addbc",
		-- 	variationId = "starlight",
		-- 	drinkId = "volcafrappuccino",
		-- 	stock = 999_999_999,
		-- },
	},
	Mixers = {
		Mixer1 = { drinkId = "none" },
	},
	Ingredients = {
		-- milk = 100,
	},
	Customers = {},
	Shop = { shops = {} }, -- CRITICAL: Added so Reflex updates sync to the Profile!
	DiscoveredDrinks = {},
	Daily = {
		day = 1,
	},
	Spawner = {},
}

-- Recursively clones a table so we don't accidentally pass memory references
-- from the template into the player's actual data.
local function DeepCopy(target: any): any
	if type(target) ~= "table" then
		return target
	end

	local copy = {}
	for k, v in pairs(target) do
		copy[k] = DeepCopy(v)
	end

	return copy
end

-- Recursively scans the target against the template.
-- If the target is missing a nested key, it patches it in.
local function DeepReconcile(target: any, template: any): any
	for k, v in pairs(template) do
		if type(k) == "string" then
			-- 1. The key is completely missing in the player's save
			if target[k] == nil then
				target[k] = DeepCopy(v)

			-- 2. The key exists in both, and both are tables (Time to go deeper!)
			elseif type(target[k]) == "table" and type(v) == "table" then
				DeepReconcile(target[k], v)
			end
		end
	end

	return target
end

-- 3. Create the ProfileStore object using New()
local PlayerProfileStore = ProfileStoreModule.New(
	DATASTORENAME, -- Your DataStore name
	PROFILE_TEMPLATE
)
if IS_PLAYTESTING then
	PlayerProfileStore = PlayerProfileStore.Mock
end

-- 4. Cache for active player profiles on this server
local Profiles: { [Player]: Profile } = {}

-- Service module to return
local PlayerDataService = {}
PlayerDataService.GlobalState = {}
PlayerDataService.PROFILE_TEMPLATE = PROFILE_TEMPLATE
function PlayerDataService:GetProfile(player: Player)
	return Profiles[player]
end

-- create bindable events
local ProfileCreated = Signal.new()
PlayerDataService.ProfileCreated = ProfileCreated

local ProfileSessionEnded = Signal.new()
PlayerDataService.ProfileSessionEnded = ProfileSessionEnded

-- Function to handle when a player joins the game
local function OnPlayerAdded(player: Player)
	local profileKey = tostring(player.UserId) -- Use UserId as the key

	-- Load and session-lock the profile asynchronously
	local profile: Profile? = PlayerProfileStore:StartSessionAsync(profileKey)
	print("profile", profileKey, profile)
	if profile then
		-- Add GDPR compliance UserIds (Recommended)
		profile:AddUserId(player.UserId)

		-- 1. ProfileStore's native reconcile handles the top layer
		profile:Reconcile()

		-- 2. Our custom deep reconcile handles the nested layers
		profile.Data = DeepReconcile(profile.Data, PROFILE_TEMPLATE)

		-- Store the active profile in the cache
		Profiles[player] = profile

		ProfileCreated:Fire()
	else
		-- The profile couldn't be loaded
		warn(`Critical error: Failed to load profile for {player.Name} ({player.UserId}). Kicking.`)
		-- player:Kick("Failed to load your data. Please try rejoining the server.")
	end
end

-- Function to handle when a player leaves the game
local function OnPlayerRemoving(player: Player)
	local profile = Profiles[player]
	if profile then
		-- End the session - this saves the data and unlocks the session
		profile.Data.LastOnline = workspace:GetServerTimeNow()
		-- profile:EndSession()
		print(`Ending session profile for {player.Name} ({player.UserId}) on leave.`)
	end
end

-- Function to handle server shutdown
local function OnShutdown()
	-- warn("Server shutting down. Ending sessions for all active player profiles...")
	local startTime = os.clock()

	-- Iterate through all active profiles and end sessions concurrently
	local threads = {}
	for player, profile in pairs(Profiles) do
		-- Check if the profile session is still active before trying to end it
		if profile:IsActive() then -- IsActive() is still valid
			table.insert(
				threads,
				task.spawn(function()
					profile:EndSession() -- Yields until saved and released
					print(`Profile session for {player.Name} ended during shutdown.`)
				end)
			)
		end
	end

	-- Wait for all end session threads to complete
	repeat
		local complete = true
		for _, thread in ipairs(threads) do
			complete = complete and coroutine.status(thread) == "dead"
		end
		if complete then
			break
		end
		task.wait()
	until complete

	local duration = os.clock() - startTime
	warn(`All profile sessions ended. Shutdown process took {string.format("%.2f", duration)} seconds.`)
end

function PlayerDataService.initialize()
	PlayerDataService.initialized = true
	Players.PlayerAdded:Connect(OnPlayerAdded)
	Players.PlayerRemoving:Connect(OnPlayerRemoving)
	-- Bind the shutdown function
	game:BindToClose(OnShutdown)
end

local broadcaster = Reflex.createBroadcaster({
	producers = {
		GlobalState = GlobalState,
	},
	beforeHydrate = function(
		player --[[,state]]
	) -- somehow state here is an empty table
		local state = GlobalState:getState()
		local playerId = tostring(player.UserId)
		-- warn("before hydrate", s, state)

		-- filter later
		return state
	end,
	dispatch = function(player, actions)
		local playerId = tostring(player.UserId)

		local relevantActions = {}
		for _, action in actions do
			-- just add all for now
			-- if action.name == `__hydrate__` then
			-- 	warn("dispatched", action.name, action.arguments)
			-- end
			table.insert(relevantActions, action)
		end

		if #relevantActions > 0 then
			Remotes.dispatch:FireClient(player, relevantActions)
		end
	end,
})

GlobalState:applyMiddleware(broadcaster.middleware)

Remotes.start.OnServerEvent:Connect(function(player)
	broadcaster:start(player)
	local profile
	local timeout = 10 -- seconds
	local elapsed = 0
	repeat
		profile = Profiles[player]
		task.wait(0.1)
		elapsed += 0.1
		if elapsed >= timeout then
			player:Kick("Failed to load your data. Please try rejoining.")
			return
		end
		print("waiting for", profile)
	until profile

	local playerId = tostring(player.UserId)
	local state = GlobalState:getState()
	if state.Stats[playerId] then
		warn(`player({playerId}) already started`)
		return
	end
	-- local playersShop = state.Shop

	-- Require ShopService to access the deterministic generator
	local ShopService = require(game.ServerScriptService.Server.Services.ShopService)
	local shopCycleState = ShopCycle.getCurrentState()

	local currentSeed = shopCycleState.seed
	local seedString = tostring(currentSeed)
	local generatedShop = ShopService.GenerateDeterministicShop(currentSeed)

	local VariationService = require(game.ServerScriptService.Server.Services.VariationService)
	local variation = VariationService.GetCurrentVariationEvent() or nil
	GlobalState.startPlayerSession(playerId, profile.Data, {
		variationEvent = variation and variation.VariationId or nil,
		newestShop = generatedShop,
		newestSeed = currentSeed,
	})
	player:RequestStreamAroundAsync(Vector3.new())

	local unsubscribe = GlobalState:subscribe(function(state, prevData)
		local newData = {}
		for key, slice in state do
			local playersSliceRecord = slice[playerId]
			if not playersSliceRecord then
				continue
			end
			newData[key] = playersSliceRecord
		end
		profile.Data = Sift.Dictionary.merge(profile.Data, newData)
	end)

	player.CharacterAdded:Connect(function(character) end)

	profile.OnSessionEnd:Connect(function()
		unsubscribe()
		Profiles[player] = nil
		GlobalState.endPlayerSession(playerId)
		player:Kick("Your data session has ended. Please rejoin.")
		ProfileSessionEnded:Fire()
	end)
end)

return PlayerDataService
