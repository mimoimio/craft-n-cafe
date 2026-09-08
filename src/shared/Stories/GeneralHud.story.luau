-- GeneralHud.story.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local React = require(ReplicatedStorage.Packages.React)
local e = React.createElement
local ReactRoblox = require(ReplicatedStorage.Packages.ReactRoblox)

local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local UIState = require(ReplicatedStorage.Shared.producers.UIState)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local ViewportController = require(ReplicatedStorage.Shared.Controllers.ViewportController)
local Main = require(ReplicatedStorage.Shared.ReactComponents.Main)

local PlacementController = require(ReplicatedStorage.Shared.Controllers.PlacementController)
local InputAdapter = require(ReplicatedStorage.Shared.Controllers.InputAdapter)

-- Require the rendering service (Note: This will work in Edit Mode, but will error if tested in a local Play Solo client since it is in ServerScriptService)
local CafeRenderingService = require(ServerScriptService.Server.Services.CafeRenderingService)

local function story(frame: Frame)
	-- Ensure the cafe base is correctly targeted.
	-- (Your BasesManager expects bases to be inside workspace.Bases)
	local plot = workspace.CafeBase.Part
	local models = game.ReplicatedStorage.Shared.Models

	-- 1. Initialize Mock State for UI Labs
	GlobalState.startPlayerSession("MockUser", {
		Plot = { occupiedCoordinates = {}, placedItems = {}, nextId = 1 },
		-- We MUST provide a Level in Stats, otherwise Cafe.luau won't mount the stations/placed items!
		Stats = {
			Level = 1,
		} :: any,
		Ingredients = {},
		Customers = {},
		Workers = {},
		Cups = {},
	})

	-- 2. Mock Server: Listen for Mock Remote Events
	local placeListener = Remotes.PlaceItem.OnServerEvent:Connect(function(player, itemId, startX, startZ, rotation)
		local playerId = player and tostring(player.UserId) or "MockUser"

		local prefab = game.ReplicatedStorage.Shared.Models:FindFirstChild(itemId)
		if not prefab then
			return
		end

		-- Server Authority: Calculate true footprint based on BoundingBox
		local _, itemSize = prefab:GetBoundingBox()
		local Grid = require(game.ReplicatedStorage.Shared.Grid)
		local width, length = Grid.getFootprint(itemSize, rotation)

		GlobalState.placeItem(playerId, {
			itemId = itemId,
			startX = startX,
			startZ = startZ,
			width = width,
			length = length,
			rotation = rotation,
		})
	end)
	local destroyListener = Remotes.DestroyItem.OnServerEvent:Connect(function(player, uuid)
		local playerId = player and tostring(player.UserId) or "MockUser"
		GlobalState.destroyItem(playerId, { uuid = uuid })
	end)
	-- 3. Initialize Controllers & Services
	PlacementController.new(plot, models) -- Removed the grid size argument here
	PlacementController:setBuildMode(false)

	-- Start rendering the physical cafe parts!
	CafeRenderingService.initialize()

	-- 4. Wire Inputs & Update Loop
	local connection = RunService.RenderStepped:Connect(function()
		local hitPos = InputAdapter.getCursorWorldPosition(plot)
		PlacementController:update(hitPos)
	end)

	local inputConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end

		if input.KeyCode == Enum.KeyCode.R then
			PlacementController:rotateItem()
		elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
			local hitPos = InputAdapter.getCursorWorldPosition(plot)
			local success, uuid = PlacementController:placeItem(hitPos)
			if success then
				print("Successfully placed item with UUID:", uuid)
			end
		end
	end)

	-- Render UI
	local root = ReactRoblox.createRoot(frame)
	root:render(e(Main))
	ViewportController.initialize()

	-- 5. Cleanup
	return function()
		connection:Disconnect()
		inputConnection:Disconnect()
		placeListener:Disconnect()
		destroyListener:Disconnect()

		PlacementController:setBuildMode(false)
		root:unmount()
		ViewportController.cleanup()

		-- Cleanup the physical renders
		CafeRenderingService.cleanup()

		GlobalState:resetState()
		UIState:resetState()

		-- Clear mock listeners just in case of hot-reloads
		Remotes.PlaceItem._clearListeners()
		Remotes.DestroyItem._clearListeners()
	end
end

return story
