--!strict
-- ReplicatedStorage/Shared/Remotes.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local isRunning = RunService:IsRunning()
local isServer = RunService:IsServer()

-- /// pure-Lua Mock for UI Labs ///
local function CreateMockRemote(name: string)
	local listeners = {}

	return {
		Name = name,

		-- Client calls this in UI Labs
		FireServer = function(self, ...)
			-- Server logic expects a Player object as the first argument
			local dummyPlayer = Players.LocalPlayer or { Name = "StudioTester", UserId = 1 }
			for _, callback in ipairs(listeners) do
				task.spawn(callback, dummyPlayer, ...)
			end
		end,

		-- Server Logic connects to this
		OnServerEvent = {
			Connect = function(self, callback)
				table.insert(listeners, callback)
				return {
					Disconnect = function()
						local idx = table.find(listeners, callback)
						if idx then
							table.remove(listeners, idx)
						end
					end,
				}
			end,
		},

		-- Secret method to prevent duplicate connections on UI Labs hot-reloads
		_clearListeners = function()
			table.clear(listeners)
		end,
	}
end

-- /// Standard Roblox Network ///
local function CreateRemote(name: string)
	-- If we are in Studio Edit Mode (UI Labs), use the local mock
	if not isRunning then
		return CreateMockRemote(name)
	end

	-- Otherwise, standard game behavior
	local eventsFolder = ReplicatedStorage.Shared:FindFirstChild("Events")
	if not eventsFolder then
		eventsFolder = Instance.new("Folder")
		eventsFolder.Name = "Events"
		eventsFolder.Parent = ReplicatedStorage.Shared
	end

	if isServer then
		local remote = eventsFolder:FindFirstChild(name) or Instance.new("RemoteEvent")
		remote.Name = name
		remote.Parent = eventsFolder
		return remote
	else
		return eventsFolder:WaitForChild(name)
	end
end

return {
	dispatch = CreateRemote("dispatch"),
	start = CreateRemote("start"),

	-- AddIngredient = CreateRemote("AddIngredient"),
	MixDrink = CreateRemote("MixDrink"),
	PickUpDrink = CreateRemote("PickUpDrink"),
	PlaceDrink = CreateRemote("PlaceDrink"),
	TendCustomer = CreateRemote("TendCustomer"),
	BuyIngredient = CreateRemote("BuyIngredient"),
	LevelUp = CreateRemote("LevelUp"),
	ToggleCafeOpen = CreateRemote("ToggleCafeOpen"),
	Add500 = CreateRemote("Add500"),
	CompleteTutorial = CreateRemote("CompleteTutorial"),
}
